function project = createProject(params)
% Creates a project structure ready for the analysis pipeline.
%
% This function initializes a project object containing one or more models,
% each defined by a set of parameters. The project can then be used as input
% for single model analysis and model comparison functions.
%
% Arguments:
%   params (cell): 1-by-N cell array. One struct per model. See the Project Initialization
%       page for the full list of available fields. Required fields:
%       modelName, contextSpecificModel.
%
% Returns:
%   project (struct): Initialized project with a models field.
%
% Examples:
%   ```matlab
%   params = {struct('modelName', 'model1', 'contextSpecificModel', model)};
%   project = createProject(params);
%
%   params = {struct(...), struct(...)};
%   project = createProject(params);
%   ```
%
% Note:
%   Fields marked as (rFastcormics) in the source code are specific to
%   models built with rFASTCORMICS and are optional for other COBRA models.
%   Only `modelName` and `contextSpecificModel` are required. Field
%   validation is performed by `validateParamsForPipeline`.

arguments
    params (1,:) cell
end

% Initialize project
project = struct();
project.models = struct();

% Loop through models
for i = 1:numel(params)
    paramsForModel = params{i};
    
    % Validate each struct's fields
    paramsForModel = validateParamsForPipeline(paramsForModel);
    
    % Initiate a struct per model
    project.models.(paramsForModel.modelName) = formatParamsForModel(paramsForModel);
end

end
