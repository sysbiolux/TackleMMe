function [project, comparisonName] = modelsComparison(project, modelList, referenceModel, identifier, analyses)
% Compares multiple models on structural, functional, and sampling levels.
%
% This function runs a set of comparative analyses on the specified
% models. Three types of comparison are available: structural (presence
% or absence of reactions, metabolites, and genes), functional (FBA and
% FVA flux differences), and sampling (solution space comparison).
% Structural comparison is always run first as a prerequisite for the
% others.
%
% Arguments:
%   project (struct): Project structure with single model analyses
%       completed and active analyses set via chooseActiveAnalysis.
%   modelList (string): Names of the models to compare.
%   referenceModel (string): Reference model used to compute relative
%       reaction presence.
%   identifier (string): Postfix appended to the comparison name.
%       Default: current timestamp.
%   analyses (string): Analyses to perform. Valid values:
%       structuralComparison, functionalComparison, samplingComparison,
%       IDAREoutput. Default: structuralComparison.
%
% Returns:
%   project (struct): Project with a comparisons field containing all
%       results and plots.
%   comparisonName (string): Name of the created comparison.
%
% Examples:
%   ```matlab
%   % Run only the structural comparison (default)
%   [project, compName] = modelsComparison(project, ...
%       ["model1", "model2"], "model1");
%
%   % Run structural and functional comparisons
%   [project, compName] = modelsComparison(project, ...
%       ["model1", "model2"], "model1", "batchA", ...
%       ["structuralComparison", "functionalComparison"]);
%
%   % Run all three comparisons
%   [project, compName] = modelsComparison(project, ...
%       ["model1", "model2", "model3"], "model1", "fullRun", ...
%       ["structuralComparison", "functionalComparison", "samplingComparison"]);
%   ```
%
% Note:
%   The comparison name is built as model1_vs_model2_vs_...__identifier.
%   Models are ordered by their appearance in project.models. If a
%   comparison with the same name already exists and the structural
%   analysis was already run, only the newly requested analyses are
%   performed.
%
% Warning:
%   If a comparison with the same name exists but uses a different
%   reference model, the user is prompted to confirm overwriting.

arguments
    project        (1,1) struct
    modelList      (1,:) string
    referenceModel (1,1) string
    identifier     (1,1) string = string(datetime('now', 'Format', '_yyyyMMdd_HHmmss'))
    analyses       (1,:) string {mustBeMember(analyses, {'structuralComparison', 'functionalComparison', 'samplingComparison', 'IDAREoutput'})} = "structuralComparison"
end

%% Check project and models format for comparison

% Check first the reference model
checkProjectFormat(project, referenceModel)

% Check then models and analysis to compare
% active analysis of each model will be used for functionalComparison
checkProjectFormat(project, modelList, repmat({'active'}, 1, numel(modelList)))

%% Reorder models according to their order of appearance in project.models
order = string(fieldnames(project.models));
[~, idx] = ismember(modelList, order);
[~, sortIdx] = sort(idx);

modelListOrdered = modelList(sortIdx);

%% Give the comparison the name of all compared models associated with a given identifier
comparisonName = join(modelListOrdered, "_vs_") + "__" + identifier;

%% Create comparisons slot if not already existing
if ~isfield(project, 'comparisons')
    project.comparisons = struct();
elseif isfield(project, 'comparisons') && ~isstruct(project.comparisons)
    warning('project.comparisons exists but is not a struct (current class: %s).', ...
            class(project.comparisons));
    reply = '';
    while ~ismember(lower(strtrim(reply)), {'y', 'n', 'yes', 'no'})
        reply = input('Delete project.comparisons and reinitialize as an empty struct? [y/n] ', 's');
    end
    if startsWith(lower(strtrim(reply)), 'y')
        project.comparisons = struct();
        disp('project.comparisons reinitialized as an empty struct.');
    else
        error('Operation cancelled by user. project.comparisons left unchanged (class: %s).', ...
              class(project.comparisons));
    end
end

%% Comparison
% Structural comparison is needed for functional and sampling comparisons,
% therefore we check whether it was already run, to not run
% it again if it was already created

if isfield(project.comparisons, comparisonName)

    % TO ADD: checking of the format
    % If format correct, it means there is a field called
    % "referenceModel" which is part of project.comparisons

    if isequal(referenceModel, project.comparisons.(comparisonName).referenceModel)
        if isfield(project.comparisons.(comparisonName), 'structuralAnalysisStatus') && (project.comparisons.(comparisonName).structuralAnalysisStatus == 1)
            % Structural analysis already run
            disp("Structural comparison already run.");
            % Perform the other analyses if specified in analyses

            % Functional comparison
            if any(matches(analyses, "functionalComparison"))
                disp("Running functional comparison.");
                project.comparisons.(comparisonName).functionalComparison.plots = functionalComparison(project, comparisonName);
            end

            % Sampling comparison
            if any(matches(analyses, "samplingComparison"))
                disp("Running sampling comparison.");
                project = samplingComparison(project, comparisonName);
            end
        else
            % Structural analysis not run yet, mandatory
            project = runAllComparisons(project, modelListOrdered, referenceModel, comparisonName, analyses);
        end
    else
        % WARNING: field exists with a different referenceModel
        warning('Comparison "%s" already exists with referenceModel = "%s" (requested: "%s").', ...
                comparisonName, project.comparisons.(comparisonName).referenceModel, referenceModel);

        reply = '';
        while ~ismember(lower(strtrim(reply)), {'y', 'n', 'yes', 'no'})
            reply = input('Overwrite the existing comparison with the new reference model? [y/n] ', 's');
        end

        if startsWith(lower(strtrim(reply)), 'y')
            % YES: overwrite and rerun everything
            project = runAllComparisons(project, modelListOrdered, referenceModel, comparisonName, analyses);
        else
            % NO: stop, user must choose a new identifier
            error('Operation cancelled by user. Comparison "%s" keeps referenceModel = "%s".Choose a different identifier to create a new comparison.', ...
                  comparisonName, project.comparisons.(comparisonName).referenceModel);
        end
    end

else
    % Comparison does not exist yet: initialize and run everything
    project = runAllComparisons(project, modelListOrdered, referenceModel, comparisonName, analyses);
end

    % get the IDs for each of the analysis
    project.comparisons.(comparisonName).comparedAnalysisID = getActiveAnalysisIDTable(project,modelList);


end


function project = runAllComparisons(project, modelListOrdered, referenceModel, comparisonName, analyses)
    % RUNALLCOMPARISONS Initializes the comparison slot and runs structural,
    % functional, and sampling comparisons as requested.
    % Structural comparison is always run (prerequisite for the others).
    
    % Initialisation
    project.comparisons.(comparisonName) = struct();
    project.comparisons.(comparisonName).modelNames = modelListOrdered;
    project.comparisons.(comparisonName).referenceModel = referenceModel;
    
    % Running structural comparison
    disp("Running structural comparison.");
    project.comparisons.(comparisonName).structuralComparison = structuralComparison(project, modelListOrdered, referenceModel);
    project.comparisons.(comparisonName).structuralAnalysisStatus = 1;
    
    % Functional comparison
    if any(matches(analyses, "functionalComparison"))
        disp("Running functional comparison.");
        project = functionalComparison(project, comparisonName);
    end
    
    % Sampling comparison
    if any(matches(analyses, "samplingComparison"))
        disp("Running sampling comparison.");
        project = samplingComparison(project, comparisonName);
    end

end