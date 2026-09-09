function [project, activeAnalysisTable] = chooseActiveAnalysis(project, modelList, analysisIDs, overwriteActive)
% Designates which analysis run to use for model comparison.
%
% This function must be run before modelComparison. Since multiple
% analysis runs can coexist on the same model, this function selects which
% one to use by copying it into an 'active' slot. This allows downstream
% comparison functions to access results without specifying the exact
% analysis ID for each model.
%
% Arguments:
%   project (struct): Project structure with completed single model
%       analyses.
%   modelList (cell): Names of the models to define an active analysis
%       for.
%   analysisIDs (cell): Analysis ID to set as active for each model, in
%       the same order as modelList. If empty, the most recent analysis
%       (by timestamp) is automatically selected for each model.
%   overwriteActive (cell): Fields to overwrite in the existing active
%       slot. Use {'all'} (default) for full replacement, or specify
%       individual fields (e.g. {'FBA'}) to selectively overwrite while
%       preserving other results.
%
% Returns:
%   project (struct): Project with an active analysis defined for each
%       model.
%   activeAnalysisTable (table): Summary of the active analysis IDs used
%       per model.
%
% Examples:
%   ```matlab
%   % Use the most recent analysis for each model
%   [project, activeTable] = chooseActiveAnalysis(project, ...
%       {'model1', 'model2'});
%
%   % Specify explicit analysis IDs
%   [project, activeTable] = chooseActiveAnalysis(project, ...
%       {'model1', 'model2'}, ...
%       {'analysis_20240815_1430', 'analysis_20240816_0900'});
%
%   % Selectively overwrite only FBA in the active slot
%   [project, activeTable] = chooseActiveAnalysis(project, ...
%       {'model1'}, {'analysis_20240815_1430'}, {'FBA'});
%   ```
%
% Note:
%   When overwriteActive is set to a specific field (e.g. {'FBA'}), the
%   parameters table is automatically merged: rows corresponding to the
%   overwritten analyses are replaced, while rows for other analyses are
%   preserved.

    arguments
        project
        modelList (1,:) cell
        analysisIDs (1,:) cell = {}
        overwriteActive (1,:) cell = {'all'}
    end

    % Convert inputs to string arrays for internal use
    modelList = string(modelList);
    overwriteActive = string(overwriteActive);
    if isempty(analysisIDs)
        analysisIDs = strings(1,0);
    else
        analysisIDs = string(analysisIDs);
    end

    % Validate overwriteActive
    if ismember("all", overwriteActive) && numel(overwriteActive) > 1
        error("overwriteActive cannot contain 'all' together with other field names.");
    end

    %% Check format of models/analysisIDs and defining active analyses
    if isempty(analysisIDs)
        checkProjectFormat(project, modelList)

        % Defining the most recent analysis as active in case no
        % analysisIDs were provided
        for m = 1:numel(modelList)
            modelShortcut = project.models.(modelList(m));

            if isfield(modelShortcut, 'analysis')
                analysisFields = string(fieldnames(modelShortcut.analysis));

                % Check that analysisFields is not empty
                if isempty(analysisFields)
                    error("There is no analysis entry for this model: '" + modelList(m) + "'. Run singleModelAnalysis function in order to create an analysis field for the specified models.");
                end

                % Search for slots created by singleModelAnalysis
                isA = startsWith(analysisFields, "analysis_");

                % Check that there is at least one analysis_ field
                if ~any(isA)
                    error("There is no analysis_ entry for this model: '" + modelList(m) + "'. Run singleModelAnalysis function in order to create an analysis field for the specified models.");
                end

                % Validate date format for analysis_ fields
                analysisFieldsA = analysisFields(isA);
                dateStrs = extractAfter(analysisFieldsA, "analysis_");
                isValidDate = false(size(dateStrs));

                for k = 1:numel(dateStrs)
                    try
                        datetime(dateStrs(k), 'InputFormat', 'yyyyMMdd_HHmm');
                        isValidDate(k) = true;
                    catch
                        % not a valid date — will be reported below
                    end
                end

                % Report invalid IDs
                if any(~isValidDate)
                    invalidIds = analysisFieldsA(~isValidDate);
                    fprintf("Warning: The following analysis IDs in model '%s' are not valid dates (yyyyMMdd_HHmm) and will be ignored: %s", ...
                        modelList(m), strjoin(invalidIds, ", "));
                end

                % Check that there is at least one valid date
                if ~any(isValidDate)
                    error("There is no valid analysis_ entry (yyyyMMdd_HHmm) for this model: '" + modelList(m) + "'. Run singleModelAnalysis function in order to create an analysis field for the specified models.");
                end

                % compute time difference between now and the time the
                % analysis were created (only for valid dates)
                timeDiff = NaN(size(analysisFields));
                validIdx = find(isA);
                validIdx = validIdx(isValidDate);
                timeDiff(validIdx) = minutes(datetime("now") - ...
                    datetime(dateStrs(isValidDate), 'InputFormat', 'yyyyMMdd_HHmm'));
                [~, idx] = min(timeDiff); % choose the most recently performed one

                analysisIDs(m) = analysisFields(idx);

            else
                error("There is no analysis field for this model: '" + modelList(m) + "'. Run singleModelAnalysis function in order to create an analysis field for the specified models.");
            end
        end

    else
        checkProjectFormat(project, modelList, analysisIDs)
    end

    %% Creating/updating active field
    for m = 1:numel(modelList)
        modelShortcut = project.models.(modelList(m));
        srcAnalysis = modelShortcut.analysis.(analysisIDs(m));
        srcFields = fieldnames(srcAnalysis);

        if ~isfield(modelShortcut.analysis, 'active') || isequal(overwriteActive, "all")
            % (Re)initializing active field — full replacement
            modelShortcut.analysis.active = struct();

            % Copy all fields from the selected analysis into active
            for k = 1:numel(srcFields)
                fieldName = srcFields{k};
                modelShortcut.analysis.active.(fieldName) = srcAnalysis.(fieldName);
                % Add analysisId to structs and tables only
                if isstruct(modelShortcut.analysis.active.(fieldName))
                    modelShortcut.analysis.active.(fieldName).analysisId = analysisIDs(m);
                end
            end

        else
            % Selective replacement — only overwrite specified fields
            for i = 1:numel(overwriteActive)
                fieldName = overwriteActive(i);

                % Check that the field exists in the source analysis
                if ~isfield(srcAnalysis, fieldName)
                    error("Field '%s' does not exist in analysis '%s' for model '%s'. Cannot overwrite.", ...
                        fieldName, analysisIDs(m), modelList(m));
                end

                % Report whether it's a new field or an overwrite
                if ~isfield(modelShortcut.analysis.active, fieldName)
                    warning("Field '%s' does not exist in active analysis for model '%s'. It will be added from analysis '%s'.", ...
                        fieldName, modelList(m), analysisIDs(m));
                else
                    fprintf("Overwriting '%s' in active analysis for model '%s' with analysis '%s'.", ...
                        fieldName, modelList(m), analysisIDs(m));
                end

                % Copy the field
                modelShortcut.analysis.active.(fieldName) = srcAnalysis.(fieldName);
                % Add analysisId to structs and tables only
                if isstruct(modelShortcut.analysis.active.(fieldName)) 
                    modelShortcut.analysis.active.(fieldName).analysisId = analysisIDs(m);
                end
            end

            % Merge parameters (if parameters was not explicitly overwritten)
            if ~ismember("parameters", overwriteActive)
                if isfield(srcAnalysis, 'parameters') && ...
                   isfield(modelShortcut.analysis.active, 'parameters')
                    % Determine which analyses are being replaced
                    parametersReplace = setdiff(overwriteActive, "parameters");
                    if ~isempty(parametersReplace)
                        oldParams = modelShortcut.analysis.active.parameters;
                        newParams = srcAnalysis.parameters;

                        % Keep rows from oldParams that are NOT being replaced
                        idxKeep = ~ismember(string(oldParams.Analysis), parametersReplace);
                        oldParams = oldParams(idxKeep, :);

                        % Take rows from newParams that ARE being replaced
                        idxAdd = ismember(string(newParams.Analysis), parametersReplace);
                        newParamsToAdd = newParams(idxAdd, :);

                        % Combine
                        modelShortcut.analysis.active.parameters = [oldParams; newParamsToAdd];
                    end
                end
            end
        end

        % Write back to project (MATLAB structs are pass-by-value)
        project.models.(modelList(m)) = modelShortcut;
    end
    
    activeAnalysisTable = getActiveAnalysisIDTable(project,modelList);
      
end

