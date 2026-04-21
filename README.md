# SouthRiceNorthWheat_2010and2014

This repository contains the replication code and analysis data for the empirical study on the North-South divide in physical activity participation among Chinese residents.

The analysis uses data derived from the China Family Panel Studies (CFPS). The original CFPS files can be obtained from the official CFPS website: https://cfpsdata.pku.edu.cn/#/home.

## Directory

### code

* `1_analysis`: Stata do-file for the empirical analysis.
* `2_visualization`: R scripts used to generate visualization files.

### data

* `raw`: analysis data file used by the Stata and R scripts.

## Files

* `code/1_analysis/analysis.do`: main Stata replication script.
* `code/2_visualization/Regional_Heterogeneity.R`: visualization script for regional heterogeneity.
* `code/2_visualization/Income_Heterogeneity.R`: visualization script for income heterogeneity.
* `data/raw/SouthRiceNorthWheat_2010and2014.dta`: analysis dataset.

## System Requirements

The empirical analysis was prepared for Stata 17. The Stata script uses the following user-written commands:

* `estout`
* `winsor2`
* `psmatch2`
* `fairlie`
* `khb`
* `asdoc`

The visualization scripts use R and the following packages:

* `tidyverse`
* `scales`
* `showtext`

## Data Source

The data are based on CFPS public-use data. Users who wish to reproduce the analysis from the original source files should obtain the CFPS data directly from the official CFPS platform:

https://cfpsdata.pku.edu.cn/#/home

## Contributor

This repository is maintained by Cai Minghan as the only contributor.

## License

This project is available under the MIT License.
