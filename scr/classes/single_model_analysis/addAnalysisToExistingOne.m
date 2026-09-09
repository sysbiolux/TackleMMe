function project = addAnalysisToExistingOne(project, parameterTable, modelName, analyses, analysisId)
% Adds analyses to an already existing analysis run.
%
% This function adds one or more analyses to an existing analysis field
% identified by its analysis ID, without creating a new timestamped
% entry. It is useful for supplementing a previous run with additional
% analyses or re-running existing ones with updated parameters.
%
% Arguments:
%   project (struct): Project structure with an existing analysis field.
%   parameterTable (table): Parameter table containing settings for the
%       analyses to add.
%   modelName (char): Name of the model.
%   analyses (char): Analysis key(s) to add (e.g. 'FBA', 'sampling').
%       Can be a single string or a cell array of strings.
%   analysisId (char): Existing analysis ID to add to (e.g.
%       'analysis_20240815_1430').
%
% Returns:
%   project (struct): The input project with updated analysis results.
%
% Examples:
%   ```matlab
%   % Add gene deletion analyses to an existing run
%   project = addAnalysisToExistingOne(project, parameterTable, ...
%       'model1', {'singleGeneDeletion', 'doubleGeneDeletion'}, ...
%       'analysis_20240815_1430');
%
%   % Re-run FVA with updated parameters
%   project = addAnalysisToExistingOne(project, parameterTable, ...
%       'model1', 'FVA', 'analysis_20240815_1430');
%   ```
%
% Warning:
%   When re-running an existing analysis, results and the corresponding
%   rows in the stored parameters table are overwritten after user
%   confirmation. Parameters for other analyses are preserved.
%
arguments
    project struct
    parameterTable table
    modelName {mustBeText}
    analyses {mustBeText}
    analysisId {mustBeText}
end

if ischar(analyses)
    analyses = {analyses};
elseif isstring(analyses)
    analyses = cellstr(analyses);
end

validModels = checkStructureForSingleModelAnalysis(project, {modelName});
if isequal(char(validModels(1)), modelName)
    if isfield(project.models.(modelName), 'analysis')
        if isfield(project.models.(modelName).analysis, analysisId)
            if isstruct(project.models.(modelName).analysis.(analysisId))
                for i = 1:numel(analyses)
                    test = char(analyses(i));
                    % Filter parameterTable to only keep rows for the current test
                    testRows = strcmp(parameterTable.Analysis, test);
                    testParams = parameterTable(testRows, :);
                    if isempty(testParams)
                        error('No parameters corresponding to %s were found in the parameterTable', test);
                    else
                        if isfield(project.models.(modelName).analysis.(analysisId), test)
                            % check par rapport à table
                            if isfield(project.models.(modelName).analysis.(analysisId), 'parameters')                            
                                % Also filter existing parameters for the same test
                                existingParams = project.models.(modelName).analysis.(analysisId).parameters;
                                existingTestRows = strcmp(existingParams.Analysis, test);
                                existingTestParams = existingParams(existingTestRows, :);
                                
                                % If no existing params for this test, just add them
                                if isempty(existingTestParams)
                                    answer = input(sprintf('Analysis "%s" already exists without given parameters. Overwrite existing analysis and store new parameters? (y/n): ', analysisId), 's');
                                    if ~strcmpi(answer, 'y')
                                        error('Analysis adding cancelled by user.');
                                    else
                                        project.models.(modelName).analysis.(analysisId).parameters = [existingParams; testParams];
                                        project = performAnalysis(project, parameterTable, modelName, {test}, analysisId);
                                    end
                                
                                elseif isequal(existingTestParams, testParams)
                                    dispValue = evalc('disp(testParams)');
                                    answer = input(sprintf('Analysis "%s" already exists with identical parameters:\n%s\nOverwrite? (y/n): ', test, dispValue), 's');
                                    if ~strcmpi(answer, 'y')
                                        error('Analysis adding cancelled by user.');
                                    else
                                        project = performAnalysis(project, parameterTable, modelName, {test}, analysisId);
                                    end
                                
                                else
                                    % Parameters differ — show differences
                                    commonParams = intersect(existingTestParams.Parameter, testParams.Parameter);
                                    differingParams = {};
                                
                                    for i = 1:numel(commonParams)
                                        param = commonParams{i};
                                        oldVal = existingTestParams.Value{strcmp(existingTestParams.Parameter, param)};
                                        newVal = testParams.Value{strcmp(testParams.Parameter, param)};
                                        if ~strcmp(oldVal, newVal)
                                            differingParams{end+1} = param;
                                        end
                                    end
                                
                                    fprintf('The following parameters differ between the existing and new analysis "%s":\n', analysisId);
                                    fprintf('  %-25s  %-25s  %-25s ', 'Parameter', 'Existing Value', 'New Value');
                                    fprintf('\n  %s\n', repmat('-', 1, 77));
                                    fprintf('');
                                    for i = 1:numel(differingParams)
                                        param = differingParams{i};
                                        oldVal = existingTestParams.Value{strcmp(existingTestParams.Parameter, param)};
                                        newVal = testParams.Value{strcmp(testParams.Parameter, param)};
                                        fprintf('  %-25s  %-25s  %-25s ', param, oldVal, newVal);
                                    end
                                    fprintf('');
                                
                                    answer = input('\nOverwrite existing analysis with new parameters? (y/n): ', 's');
                                    if ~strcmpi(answer, 'y')
                                        error('Analysis adding cancelled by user.');
                                    else
                                        % Overwrite only the test-related rows in the parameters table
                                        otherRows = ~strcmp(existingParams.Analysis, test);
                                        otherParams = existingParams(otherRows, :);
                                        project.models.(modelName).analysis.(analysisId).parameters = [otherParams; testParams];
                                
                                        % Re-run and add analysis
                                        project = performAnalysis(project, parameterTable, modelName, {test}, analysisId);
                                    end
                                end
                            else
                                warning('No parameters table found. Continuing and storing given parameters.')
                                project = performAnalysis(project, parameterTable, modelName, {test}, analysisId);
                                project.models.(modelName).analysis.(analysisId).parameters = testParams;
                            end
                        else
                            fprintf('Analysis "%s" does not exist yet. It will be run and stored with its corresponding parameters.\n', test);
                            
                            if isfield(project.models.(modelName).analysis.(analysisId), 'parameters')                            
                                % Also filter existing parameters for the same test
                                existingParams = project.models.(modelName).analysis.(analysisId).parameters;
                                existingTestRows = strcmp(existingParams.Analysis, test);
                                existingTestParams = existingParams(existingTestRows, :);
                                
                                % If no existing params for this test, just add them
                                if isempty(existingTestParams)
                                    project = performAnalysis(project, parameterTable, modelName, {test}, analysisId);
                                    project.models.(modelName).analysis.(analysisId).parameters = [existingParams; testParams];
                                
                                elseif isequal(existingTestParams, testParams)
                                    project = performAnalysis(project, parameterTable, modelName, {test}, analysisId);
                                
                                else
                                    % Parameters differ
                                    % Overwrite only the test-related rows in the parameters table
                                    otherRows = ~strcmp(existingParams.Analysis, test);
                                    otherParams = existingParams(otherRows, :);
                                    project.models.(modelName).analysis.(analysisId).parameters = [otherParams; testParams];
                                
                                    % Re-run and add analysis
                                    project = performAnalysis(project, parameterTable, modelName, {test}, analysisId);

                                end
                            else
                                warning('No parameters table found. Continuing and storing given parameters.')
                                project = performAnalysis(project, parameterTable, modelName, {test}, analysisId);
                                project.models.(modelName).analysis.(analysisId).parameters = testParams;
                            end
                        end
                    end
                end
            else
                error('project.models.%s.analysis.%s must be a structure.', modelName, analysisId);
            end
        else
            error('project.models.%s.analysis.%s does not exist. Please choose an existing analysis or run singleModelAnalysis.', modelName, analysisId)
        end
    else
        error('There is no analysis field for project.models.%s. Please run singleModelAnalysis first.', modelName)
    end
else
    warning('project.models.%s was not found.', modelName);
end
    
% checking that project.models.(modelName).analysis.analysisId existe et
% que c'est bien une struct
% si oui, boucler sur les news analyses demandées, et regarder s'il y a
% déjà un champ au nom des analyses demandées
% si oui, regarder si parametres changent entre l'ancienne table et la
% nouvelle
% si oui, demander confirmation avant d'overwrite (display anciens params versus nouveaux), remplacer anciens params
% par nouveaux dans ceux stockés si confirmation, sinon abort.
% Si pas d'ancienne analysis correspondante, on update les infos params
% dans la table (on enlève anciennement stockées car pas utilisées, on met les nouvelles), et on run l'analyse, on stocke les results. 

% Think about checking if parameterTable isequal to the one present. If
% yes, ask for confirmation (displaying changes) before overwriting.

end