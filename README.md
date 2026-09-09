# Metabolic Models Exploration

**TackleMMe**, is a pipeline developed in MATLAB and developed for tackling Metabolic Models exploration. It is based on the creation of a unique MATLAB object, called `project`. A `project` is made to store everything, from model building, to model analysis and model comparison.

## 3 steps of the pipeline
  1. **Model building and Project Initialization**
  2. **Single Model Analysis**
  3. **Model Comparison**

A documentation, including installation requirements, project layout description and functions documentation is available on our [website](https://sysbiolux.github.io/TackleMMe/). 


## Storage of the data

Everything is stored in a structure named `project`. The architecture looks like the below tree.
A complete `project` can be downloaded from our [zenodo folder](https://zenodo.org/records/22209352?preview=1&token=eyJhbGciOiJIUzUxMiJ9.eyJpZCI6IjRjYzNkNDQ5LTQxNjUtNGI0Yy05NTUwLTBkMWVmYWMzNTQ0ZSIsImRhdGEiOnt9LCJyYW5kb20iOiJjMjE1ZmEyMTAwODRlNWMyNzBkYjZhNTU2NGUwYzVhNiJ9.puAZhYmsSncp1HasCN-igfMabHyGzJJW3ZAlou2d76_lICZ5vHo3wJmytpqy0bRFITK441eD9SaHTr2lZEgq5g). The object shows how a project looks like after running the entire pipeline. This one specifically corresponds to the tutorial example on Breast Cancer data.

## Running an example

A running example is available in the BRCAexample folder. Associated data are provided in the data folder (to download the data correctly it needs to be pulled using git pull, zip download will not work). Associated workspaces and intermediate projects after each step of the pipeline can be downloaded from our [zenodo folder](https://zenodo.org/records/22209352?preview=1&token=eyJhbGciOiJIUzUxMiJ9.eyJpZCI6IjRjYzNkNDQ5LTQxNjUtNGI0Yy05NTUwLTBkMWVmYWMzNTQ0ZSIsImRhdGEiOnt9LCJyYW5kb20iOiJjMjE1ZmEyMTAwODRlNWMyNzBkYjZhNTU2NGUwYzVhNiJ9.puAZhYmsSncp1HasCN-igfMabHyGzJJW3ZAlou2d76_lICZ5vHo3wJmytpqy0bRFITK441eD9SaHTr2lZEgq5g) as well.







