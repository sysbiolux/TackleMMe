# Installation

This page describes the software requirements and installation steps for the TackleMMe analysis pipeline.

## MATLAB version

The pipeline requires **MATLAB R2024a or R2024b**.

!!! warning "MATLAB R2025 is not compatible"
    The UMAP toolbox used by this pipeline relies on Java access to MATLAB figures, which is removed in MATLAB R2025. Use R2024b or earlier.

Check your MATLAB version in the command window:

```matlab
ver
```

## Required toolboxes

The following MathWorks toolboxes must be installed. Install them via **Home > Add-Ons > Get Add-Ons** in MATLAB, or through your institution's license portal.

| Toolbox | Required for | Minimum version |
|---|---|---|
| Statistics and Machine Learning Toolbox | UMAP, statistical analysis | R2024a |
| MATLAB Report Generator | Automated report generation | R2024a |
| Cobra Toolbox | Uses cobra model structure + functions | 2024 |

Verify that all toolboxes are installed:

```matlab
ver
```

The output should list both `Statistics and Machine Learning Toolbox` and `MATLAB Report Generator`.

## UMAP toolbox installation

The pipeline uses the MATLAB UMAP implementation by Meehan et al. [[File Exchange #71902](https://www.mathworks.com/matlabcentral/fileexchange/71902-uniform-manifold-approximation-and-projection-umap){: target="_blank" rel="noopener noreferrer" }].

!!! note "Dependencies"
    The UMAP toolbox requires the **Statistics and Machine Learning Toolbox** and the **Financial Toolbox**. Check with `ver` if you encounter missing function errors.

### Step 1 — Download

Download the toolbox from [MATLAB File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/71902-uniform-manifold-approximation-and-projection-umap){: target="_blank" rel="noopener noreferrer" }.

Alternatively, open it directly in MATLAB Online by clicking **Open in MATLAB Online** on the File Exchange page.

### Step 2 — Add to MATLAB path

Unzip the downloaded archive to a permanent location (e.g. `C:\Tools\umap`), then add it to your MATLAB path:

```matlab
addpath(genpath('C:\Tools\umap'));
savepath;
```

!!! tip "Save the path"
    Run `savepath` after `addpath` so the UMAP toolbox is available in future MATLAB sessions without re-adding it manually.


### Step 3 — Verify installation

```matlab
% Should run without errors and produce a 2D scatter plot
X = rand(100, 10);
Y = run_umap(X, 'n_components', 2);
scatter(Y(:,1), Y(:,2));
```
!!! note "MathWorks File Exchange restrictions"
    A window asking whether you want to download UMAP accelerants may appear. Select **"Download all our UMAP accelerants directly"** and confirm your choice.

## Report generation

The pipeline generates automated analysis reports using the **MATLAB Report Generator** toolbox. Reports are produced by the `writeAnalysisReport` function.

### How it works

The report generator uses the Report API and Document Object Model (DOM) API to programmatically build documents from your analysis results. The pipeline captures tables, and text output from the single model analysis step and compiles them into a structured PDF report. The report file is saved to the working directory.

## Verification checklist

After completing all installation steps, verify your setup with the following commands in the MATLAB command window:

```matlab
% 1. Check MATLAB version (should be R2024a or R2024b)
ver('matlab')

% 2. Check required toolboxes
ver('stats')      % Statistics and Machine Learning Toolbox
ver('rptgen')     % MATLAB Report Generator

% 3. Check UMAP installation
which run_umap    % Should return the path to run_umap.m

% 4. Test UMAP
Y = run_umap(rand(50, 5), 'n_components', 2);
disp(size(Y))     % Should be [50, 2]
```

If all commands execute without errors, your environment is ready for the pipeline.

## Installing the COBRA Toolbox 

The COnstraint-Based Reconstruction and Analysis Toolbox is a MATLAB software to create & analyze constrained based metabolic models. All the models stored & worked with in TackleMMe are stored in COBRA format and functions of the COBRA Toolbox are used. Therefore the toolbox must be installed ([see the github page](https://github.com/opencobra/cobratoolbox){: target="_blank" rel="noopener noreferrer" } as well as the [documentation webpage](https://opencobra.github.io/cobratoolbox/stable/index.html#){: target="_blank" rel="noopener noreferrer" }). 

+ clone the github repository from the [github page](https://github.com/opencobra/cobratoolbox){: target="_blank" rel="noopener noreferrer" } (```git clone https://github.com/opencobra/cobratoolbox.git```)
+ follow the installation instructions from the [cobratoolbox github README.md](https://github.com/opencobra/cobratoolbox){: target="_blank" rel="noopener noreferrer" }

Make sure to add the toolbox to your matlab path:
```matlab
addpath(genpath('path/to/toolbox/on/your/local/machine'));
savepath;
```
## Install TackleMMe Pipeline 

Clone the repository to your local machine. The zip download may not work due to the high size of some datasets. Therefore, we recommend to clone the repository instead.

```{bash}
git clone https://github.com/sysbiolux/TackleMMe.git
```

## Building models with rFastcormics

rFASTCORMICS will be integrated into the next release of the COBRA Toolbox. In the meantime, in case you want to build context-specific models using rFASTCORMICS before comparing them with TackleMMe, follow the installation instructions on the [rFASTCORMICS GitHub page](https://github.com/sysbiolux/rFASTCORMICS/tree/master/rFASTCORMICS%20for%20RNA-seq%20data/rFASTCORMICS_v2){: target="_blank" rel="noopener noreferrer" }.

In TackleMMe, a extra `rFastcormicsPipeline.m` script is provided in the [`scr/` folder](https://github.com/sysbiolux/TackleMMe/tree/main/scr){: target="_blank" rel="noopener noreferrer" }. This new version of the original `rFastcormics.m` function has been designed to directly fit with TackleMMe by building context-specific models as done originally but providing at the same time an output called `params`  that can be passed directly to `createProject.m`. `params` is a structure that serve as the main input to the TackleMMe pipeline, containing all the information required to initialize and build a *project*. See more explanation about `params` format in [Project Initialization](project_init.md). 

For a usage example, see `no1_modelBuildingAndProjectInit.m` in the [`BRCAexample` folder](https://github.com/sysbiolux/TackleMMe/tree/main/BRCAexample){: target="_blank" rel="noopener noreferrer" }.

