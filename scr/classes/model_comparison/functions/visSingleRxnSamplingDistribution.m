function [fluxSet, figs] = visSingleRxnSamplingDistribution(project, compName, rxnSet, rxnSetLabel, referenceModel, addKLDValues)
% Generates violin plots showing the distribution of flux values across
% all sampling solutions for each reaction in the defined set. One
% violin plot is produced per reaction index in rxnSet.
%
% Arguments:
%   project (struct): Project object from singleModelAnalysis and
%       modelComparison. Both must have been run before calling this
%       function.
%   compName (string): Name of the comparison to visualize. Available
%       comparisons can be listed with project.comparisons.
%   rxnSet (cell): Set of reaction indices to visualize, typically
%       obtained via getRxnIDs.
%   rxnSetLabel (string): Label displayed for this reaction set in the
%       figure.
%   referenceModel (string): Name of the reference model. Must match
%       the reference model used in the specified comparison and when
%       retrieving reaction IDs with getRxnIDs.
%   addKLDValues (logical): If true, display the Kullback-Leibler
%       divergence significance between sampling distributions on the
%       violin plots. Default: false.
%
% Returns:
%   fluxSet (struct): Flux data used to generate the violin plots.
%   figs (figure): Figure object generated and displayed by the
%       function.
%
% Examples:
%   ```matlab
%   % Visualize sampling distribution for a set of reactions
%   [rxnsMetId, producingMet, matched] = getRxnIDs(project, ...
%       referenceModel, "Glycolysis.*");
%   [fluxSet, figs] = visSingleRxnSamplingDistribution(project, ...
%       compName, rxnsMetId, "Glycolysis", referenceModel);
%
%   % Include KLD significance values
%   [fluxSet, figs] = visSingleRxnSamplingDistribution(project, ...
%       compName, rxnsMetId, "Glycolysis", referenceModel, true);
%   ```
%
% Warning:
%   The reference model must be the same one used when calling
%   getRxnIDs to retrieve the reaction indices. Using a different
%   reference model will cause index misalignment.

arguments
    project 
    compName (1,1) string
    rxnSet (1,:) cell
    rxnSetLabel (1,:) string
    referenceModel (1,1) string
    addKLDValues (1,1) logical = false
end

% check project format: 

if ~isfield(project, 'comparisons')
    error('Project object does not contain a comparison object. After running the singleModels analysis you still have to run modelsComparison before beeing able to use this function!')
end
if ~isfield(project.comparisons, compName)
    error('The comparison name you gave as an input is not available in the object. Check your spelling!')
end
if ~isfield(project.comparisons.(compName), 'samplingComparison')
    error('The comparison object you specified does not entail a samplingComparison. Run modelsComparison(project, modelsToCompare, referenceModel, compID, ["samplingComparison"]).')
end
if ~isfield(project.comparisons.(compName).samplingComparison, 'orderedSamples')
    error('The comparisons object does not entail a valid samplingComparison object rerun the functionalComparison: modelsComparison(project, modelsToCompare, referenceModel, compID, ["samplingComparison"])')
end

% check that the reference model used when retrieving the rxnIDs is the
% same as in the comparison, otherwise the ids are wrongly assigned

if project.comparisons.(compName).referenceModel ~= referenceModel
    error('The reference Model you gave as input (%s) is not the same reference Model defined in the specified comparison object (%s). Check the spelling! The reference model when retrieving the rxnIDS with getRxnIDs needs to be the same as the one specified here! Otherwise the idx are misaligned.  "%s" keeps referenceModel = "%s".Choose a different identifier to create a new comparison.', ...
          referenceModel, project.comparisons.(compName).referenceModel);
end

%

%
rxnLabel    = matlab.lang.makeValidName(rxnSetLabel);  % used as field name

[fluxSet, figs] = visualizeFlux(project, compName, rxnSet, rxnLabel, "orderedSamples", "all", 'on', addKLDValues)

end