function [rxnID, producing,matchedAll] = getRxnIDs(project, referenceModel, pattern)
% Finds reactions matching a pattern across model fields.
%
% This function filters reactions for visualization using a regex pattern.
% The pattern can match subsystems, genes, reaction names, or metabolites.
% Multiple patterns can be combined with & (AND) or | (OR) operators.
%
% Arguments:
%   project (struct): Project object from singleModelAnalysis and
%       modelsComparison.
%   referenceModel (string): Reference model to search in.
%   pattern (string): Regex pattern(s) to match. Use & to require
%       multiple patterns simultaneously (e.g. "^lac_.* & ^Glycolysis.*")
%       or | to match any of several patterns (e.g. "^lac.* | ^pyr.*").
%
% Returns:
%   rxnID (cell): Reaction indices in the reference model for each
%       pattern.
%   producing (cell): Logical vector indicating whether matched
%       metabolites are produced or consumed in each reaction, based on
%       stoichiometry.
%   matchedAll (cell): Actual strings matched by each pattern (reaction,
%       gene, metabolite, or subsystem names).
%
% Examples:
%   ```matlab
%   % Find reactions in Glycolysis involving lactate
%   [rxnID, producing, matched] = getRxnIDs(project, "model1", ...
%       "^lac_.* & ^Glycolysis.*");
%
%   % Find reactions involving lactate or pyruvate
%   [rxnID, producing, matched] = getRxnIDs(project, "model1", ...
%       "^lac.* | ^pyr.*");
%
%   % Find reactions in a single subsystem
%   [rxnID, producing, matched] = getRxnIDs(project, "model1", ...
%       "^TCA cycle.*");
%   ```
%
% Note:
%   If no match is found in model fields, the function searches the
%   gene ID dictionary (settings.dico) to match gene names, symbols, or
%   other identifiers. A pattern cannot contain both & and | operators.

    arguments
        project (1,1) struct
        referenceModel (1,1) string
        pattern (1,:) string
    end

    model = project.models.(referenceModel).model;
    dict = project.models.(referenceModel).settings.dico;
    rxnID = {};
    producing = {};
    matchedAll = {};

    for n= 1:numel(pattern)
        
        singlePat = pattern(n);

        assert(~(contains(singlePat, "|") & contains(singlePat, "&")),...
               'The pattern can not contain both & + |, this function is only written for either or !')
            
        if contains(singlePat, "|")
            patCond =  strtrim(strsplit(singlePat, "|"));
        elseif contains(singlePat, "&")
            patCond =  strtrim(strsplit(singlePat, "&"));  
        else
            patCond = strtrim(singlePat);
        end
        
        % filter out all fields that can not be matched to pattern 
        fieldsToCheck = structfun(@(x) (ischar(x) || isstring(x) || iscell(x) ) ...
                                        && ((size(x,2) == 1 && size(x,1) == size(model.mets,1) || size(x,1) == size(model.rxns,1)|| size(x,1) == size(model.genes,1))),...
                                  model);
        namesToCheck = fieldnames(model);
        namesToNotCheck = namesToCheck(~fieldsToCheck);
        slotsCheck = rmfield(model,namesToNotCheck);
    
        [rxnsIDsAll,producingMetAll,matched] = cellfun(@(pat) findPatternsInStruct(pat,slotsCheck,model,dict),...
                                               patCond, 'UniformOutput', false);
    
        if contains(singlePat, "&")
            commonRxns = rxnsIDsAll{1};
            commonProd = producingMetAll{1};
            for i = 2:numel(rxnsIDsAll)
                [commonRxns, ia] = intersect(commonRxns, rxnsIDsAll{i});
                commonProd = commonProd(ia);
            end
            resultRxns = commonRxns;
            resultProd = commonProd;
            
        elseif contains(singlePat, "|")
            allRxns = vertcat(rxnsIDsAll{:});
            allProd = vertcat(producingMetAll{:});
            [resultRxns, ia] = unique(allRxns, 'stable');
            resultProd = allProd;
        else
            resultRxns = rxnsIDsAll{:,:};
            resultProd = producingMetAll{:,:};
            
        end
        
        rxnID{n} = resultRxns;
        producing{n} = resultProd;
        matchedAll{n} = string(vertcat(matched{:}));
        assert(~isempty(matchedAll{n}), 'No reactions were found! Check your pattern for spelling mistakes!')
    end
end

function [rxnIDs, producingMet,matched] = findPatternsInStruct(pattern,slotsCheck,model,dico)
    SMatrix = full(model.S);
    patMatch = structfun(@(slot) regexp(string(slot), pattern, 'once'),...
                         slotsCheck, 'UniformOutput',false);
    posMatch = structfun(@(x) find(~cellfun(@isempty, x)), ...
                     patMatch, 'UniformOutput', false);

    if all(structfun(@length, posMatch) == 0)
        % this means that the string given is a gene ? 
        % can we find a match in the dico ? 
        matches = findInDico(dico, pattern);
        colname = getDicoColumnWithGeneIDsInModel(model, dico);
        if length(matches.rowIdx) ~= 0
            genesPattern = matches.rows.(colname);
            model.genes = regexprep(model.genes, '\.\d+$', '');
            rxnNames = findRxnsFromGenes(model,genesPattern);
            matched = string(fieldnames(rxnNames));
            rxnNames = struct2cell(structfun(@(x) x(:,1), rxnNames, 'UniformOutput', false));
            allNames = string(unique(vertcat(rxnNames{:})));
            [~,rxnIDs] = ismember(allNames,model.rxns);
            producingMet = repmat(0, 1,length(rxnIDs));
        else
            matched = [];
            rxnIDs = [];
            producingMet = [];
        end
    
    else
        [~,mostMatchSlot] = max(structfun(@(x) size(x,1),posMatch));
        metdimStatus = structfun(@(slot) size(slot,1) == size(slotsCheck.mets,1),slotsCheck);
        patternDefMets = metdimStatus(mostMatchSlot);
        fieldName = fieldnames(posMatch);
        fieldName = string(fieldName(mostMatchSlot));
    
        idxMatched = posMatch.(fieldName);
        matched = slotsCheck.(fieldName);
        matched = matched(idxMatched);
    
        % now we have the IDx of the matches, if the matched slot is in the
        % dimension of metabolites, the rxns have to be found from the
        % metabolite 
    
        if patternDefMets
            % find metablite names from the idx of the matches 
            metNames = slotsCheck.mets(idxMatched);
            rxnNames = findRxnsFromMets(model, metNames);
            [~,rxnIDs] = ismember(rxnNames, slotsCheck.rxns);
            producingMet = any(SMatrix(idxMatched,rxnIDs) == 1);
        else
            rxnIDs = idxMatched;
            producingMet = repmat(0, 1,length(rxnIDs));
        end

    end
    producingMet = producingMet';
end


function matches = findInDico(dico, query)
% FINDINDICO  Find a query string in any column of the dico table.
%   matches = findInDico(dico, query)
%
%   Returns a struct with:
%     matches.rows      - subtable of matching rows
%     matches.columns   - cell array of column names where match was found
%     matches.rowIdx    - row indices in original table

    colNames = dico.Properties.VariableNames; % {'ENTREZ','HGNC','ENSG','SYMBOL'}
    
    nCols = numel(colNames);
    matchMask = false(height(dico), nCols);
    
    for c = 1:nCols
        col = dico.(colNames{c});
        % Each column is a cell array of char vectors
        matchMask(:, c) = ~cellfun(@isempty, regexp(col, query, 'once'));
    end
    
    % Rows that matched in at least one column
    rowHits  = any(matchMask, 2);
    colHits  = colNames(any(matchMask, 1));
    
    matches.rows    = dico(rowHits, :);
    matches.columns = colHits;
    matches.rowIdx  = find(rowHits);
end

function colname = getDicoColumnWithGeneIDsInModel(model, dico)
        queryRaw = string(model.genes); % your vector

        queryStripped = regexprep(queryRaw, '\.\d+$', '');
        
        colNames = dico.Properties.VariableNames;
        overlapCount = zeros(1, numel(colNames));
        
        for c = 1:numel(colNames)
            col = dico.(colNames{c});
            overlapCount(c) = max(numel(intersect(queryRaw, col)), ...
                                 numel(intersect(queryStripped, col)));
        end
        
        [~, bestIdx] = max(overlapCount);
        colname = colNames{bestIdx};

end