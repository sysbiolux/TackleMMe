function project = addModelsToProject(project, params)
% Adds one or more models to an already existing project.
%
% This function extends an existing project by adding new models. Each
% model is validated and formatted before being added. If a model with
% the same name already exists, the user is prompted to confirm
% overwriting.
%
% Arguments:
%   project (struct): Existing project structure created by createProject.
%   params (cell): 1-by-N cell array, one struct per model to add. See
%       the Project Initialization page for the full list of available
%       fields. Required fields: modelName, contextSpecificModel.
%
% Returns:
%   project (struct): The input project with new models added.
%
% Examples:
%   ```matlab
%   project = addModelsToProject(project, ...
%       {struct('modelName', 'model2', 'contextSpecificModel', model2)});
%
%   % Add multiple models
%   project = addModelsToProject(project, {struct(...), struct(...)});
%   ```
%
% Note:
%   The project format is validated with checkProjectFormat before
%   adding any model. Fields specific to rFASTCORMICS are optional.

arguments
    project
    params (1,:) cell
end

% Check whether the project is in the correct format
fprintf("Checking project format before adding model. \n")
checkProjectFormat(project);

% Add extra models one by one
for i = 1:numel(params)
    paramsForModel = params{i};
    
    % Validate each struct's fields
    paramsForModel = validateParamsForPipeline(paramsForModel);

    % Initiate a struct per model
    if isfield(project.models, paramsForModel.modelName)
        answer = input("Model '" + paramsForModel.modelName + "' already exists. Overwrite? [y/n]: ", 's');
        if ~strcmpi(answer, 'y')
            fprintf("Model '" + paramsForModel.modelName + "' skipped.")
            continue
        end
    end

    project.models.(paramsForModel.modelName) = formatParamsForModel(paramsForModel);

end

end

