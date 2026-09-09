function [figs] = visDiffMetSetUsageSampling(project, compName, rxnSets, rxnSetLabels, referenceModel)
% Generates a heatmap showing how much each metabolite participating in
% the defined reaction sets is used, based on sampling solutions. An
% average is computed over all samples to produce one value per reaction
% set in the heatmap. Usage is defined as the flux sum of all reactions
% that consume the metabolite within each reaction set.
%
% Arguments:
%   project (struct): Project object from singleModelAnalysis and
%       modelComparison. Both must have been run before calling this
%       function.
%   compName (string): Name of the comparison to visualize. Available
%       comparisons can be listed with project.comparisons.
%   rxnSets (cell): Sets of reaction indices to visualize, typically
%       obtained via getRxnIDs.
%   rxnSetLabels (string): Labels for each reaction set, displayed in
%       the figure. Must be the same length as rxnSets.
%   referenceModel (string): Name of the reference model. Must match
%       the reference model used in the specified comparison and when
%       retrieving reaction IDs with getRxnIDs.
%
% Returns:
%   figs (figure): Figure object generated and displayed by the
%       function.
%
% Examples:
%   ```matlab
%   % Retrieve reactions for two sets, then visualize
%   [rxnsMetId, producingMet, matched] = getRxnIDs(project, ...
%       referenceModel, ["Pentose.* & g6p.*"; "Glycolysis.*"]);
%   figs = visDiffMetSetUsageSampling(project, compName, rxnsMetId, ...
%       ["Pentose.* & g6p.*"; "Glycolysis.*"], referenceModel);
%   ```
%
% Warning:
%   The reference model must be the same one used when calling
%   getRxnIDs to retrieve the reaction indices. Using a different
%   reference model will cause index misalignment.

arguments
    project 
    compName (1,1) string
    rxnSets (1,:) cell
    rxnSetLabels (1,:) string
    referenceModel (1,1) string
end

if ~isfield(project, 'comparisons')
    error('Project object does not contain a comparison object. After running the singleModels analysis you still have to run modelsComparison before beeing able to use this function!')
end
if ~isfield(project.comparisons, compName)
    error('The comparison name you gave as an input is not available in the object. Check your spelling!')
end
if ~isfield(project.comparisons.(compName),'samplingComparison')
    error('The comparison object you specified does not entail a samplingComparison. Run modelsComparison(project, modelsToCompare, referenceModel, compID, ["samplingComparison"]).')
end
if ~isfield(project.comparisons.(compName).samplingComparison, 'orderedSamples')
    error('The comparisons object does not entail a valid samplingComparison object rerun the functionalComparison: modelsComparison(project, modelsToCompare, referenceModel, compID, ["samplingComparison"])')
end

% rxnSets and rxSetLabels need to be the same length
if length(rxnSets) ~= length(rxnSetLabels)
    error('The rxnSets and the rxnSetLabels you specified do not have the same length, you need to give as many Lables as rxnID sets. ')
end


% check that the reference model used when retrieving the rxnIDs is the
% same as in the comparison, otherwise the ids are wrongly assigned

if project.comparisons.(compName).referenceModel ~= referenceModel
    error('The reference Model you gave as input (%s) is not the same reference Model defined in the specified comparison object (%s). Check the spelling! The reference model when retrieving the rxnIDS with getRxnIDs needs to be the same as the one specified here! Otherwise the idx are misaligned.  "%s" keeps referenceModel = "%s".Choose a different identifier to create a new comparison.', ...
          referenceModel, project.comparisons.(compName).referenceModel);
end

%

[~,figs] = visualizeFluxsum(project, compName,[],rxnSets,rxnSetLabels,"heatmap",...
                                       false,false,"orderedSamples","outgoing",referenceModel,'on')

end