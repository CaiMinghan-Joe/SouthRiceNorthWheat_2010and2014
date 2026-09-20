# SouthRiceNorthWheat_2010and2014

This repository contains replication code, documentation, and non-restricted aggregate outputs for the empirical study on the North-South divide in physical activity participation among Chinese residents.

The analysis uses data derived from the China Family Panel Studies (CFPS). The original CFPS files can be obtained from the official CFPS website: https://cfpsdata.pku.edu.cn/#/home.

## Directory

### code

* `1_analysis`: Stata do-file for the empirical analysis.
* `2_visualization`: R scripts used to generate visualization files.

### data

* `raw`: data-access documentation only; restricted CFPS-derived analysis data are not distributed through this repository.
* `Revision_1`: Revision 1 replication code, documentation, aggregate output tables, and the non-microdata historical province workbook.

## Files

* `code/1_analysis/analysis.do`: main Stata replication script.
* `code/2_visualization/Regional_Heterogeneity.R`: visualization script for regional heterogeneity.
* `code/2_visualization/Income_Heterogeneity.R`: visualization script for income heterogeneity.
* `data/raw/README_DATA_ACCESS.md`: instructions for obtaining the restricted source data.
* `Revision_1/README.md`: Revision 1 replication instructions and data restrictions.

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

The individual-level analysis data are derived from CFPS data and are not distributed in this public repository. The previously tracked `data/raw/SouthRiceNorthWheat_2010and2014.dta` was removed because it contains CFPS-derived individual-level records. Authorized users who wish to reproduce the analysis should obtain CFPS data directly from the official CFPS platform:

https://cfpsdata.pku.edu.cn/#/home

For Revision 1, `HSSC_analysis_data_final.dta` is the corresponding analysis dataset. After obtaining and preparing the authorized CFPS data, place that file locally at `Revision_1/data/HSSC_analysis_data_final.dta`. Do not upload it to this repository or another unauthorized third-party platform. See `Revision_1/data/README_DATA_RESTRICTIONS.md` for details.

## Contributor

This repository is maintained by Cai Minghan as the only contributor.

## License

This project is available under the MIT License.
