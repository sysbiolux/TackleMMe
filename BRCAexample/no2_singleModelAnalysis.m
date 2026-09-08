%% Main script n°2: Single Model Analysis 
% This script is showing how to perform individual analysis on context-specific models stored in a TackleMMe project object.
% The first function, singleModelAnalysis.m, allows to perform on each model the following analysis:
%   - FBA
%   - FVA
%   - sampling
%   - looplessSampling (using cycleFreeFlux, from Desouki et al., 2015, COBRA version)
%   - FDR correction for sampling (https://doi.org/10.1016/j.jbi.2024.104597)
%   - singleGeneDeletion
%   - doubleGeneDeletion
% Parameter choice of each wanted analysis must be provided in a table
% format following the one given in our default table (defaultParametersAnalysis.csv).
% Both parameters and performed analyses are stored in the project object as well. A second
% function, writeAnalysisReport.m, generates a report based on the
% performed analysis, including tables with FBA/FVA/flux sum for exchangers
% or given metabolites, reactions, or pathways.
% Finally, an analysis can be integrated into an already existing analysis
% thanks to addAnalysisToExistingOne.m function.
% 
%% INITIALIZING THE ENVIRONNEMENT
initCobraToolbox();
changeCobraSolver('gurobi');
feature astheightlimit 2000;

%% define data folder path and add it to the path variable

dataPath = "/Users/leonie.thomas/Desktop/test_pipeline/analysisPipelineLVT/data";
addpath(genpath(dataPath))

%% LOADING PROJECT AND PARAMETERS FOR ANALYSIS
load('BRCAProjectNo1.mat');
defaultParametersAnalysis = readInParamTable('defaultParametersTable.csv');

%% PERFORMING ANALYSIS
% can take time depending on what's asked (especially (loopless) sampling))
wantedAnalyses = {'FBA', 'FVA'};
analyzedModels = {'Control', 'StageI', 'StageII', 'StageIV'};

% this is the most time consuming function in this script, depending on
% what you perform: FBA, FVA, sampling, + for how many models these are
% calculated
% for sampling, or loopless this can take hours (highly depending on how
% many samples are drawn) 
BRCAProject = singleModelAnalysis(BRCAProject, defaultParametersAnalysis, analyzedModels, wantedAnalyses, 1, 1);


save BRCAProjectNo2.mat BRCAProject

%% GENERATING A REPORT
% List of wanted pathways for the report
pathwaysOfInterest = {'Citric acid cycle', 'Pyruvate metabolism', 'Glutamate metabolism', 'Alanine and aspartate metabolism'};
% List of metabolites
metsOfInterest = {'glc_D', 'pyr', 'lac_L', 'lac_D', 'gln_L', 'glu_L', 'ala_L'};


writeAnalysisReport(BRCAProject, 'StageIV', 'analysis_20260902_1704', ...
    'pathwaysOfInterest', pathwaysOfInterest, 'metsOfInterest', metsOfInterest);
% choose a different analysis name in case you do not want to overwrite the previous pdf generated


%% ADDING AN ANALYSIS TO AN EXISTING ONE
BRCAProject = addAnalysisToExistingOne(BRCAProject, defaultParametersAnalysis, 'StageI', 'sampling', 'analysis_20260908_0118');
BRCAProject = addAnalysisToExistingOne(BRCAProject, defaultParametersAnalysis, 'StageII', 'sampling', 'analysis_20260908_0126');
BRCAProject = addAnalysisToExistingOne(BRCAProject, defaultParametersAnalysis, 'StageIV', 'sampling', 'analysis_20260908_0134');
BRCAProject = addAnalysisToExistingOne(BRCAProject, defaultParametersAnalysis, 'Control', 'sampling', 'analysis_20260908_0112');



