---
title       : Knowledge Transfer
subtitle    : R libraries for alpenv
author      : Johannes Brenner
job         : EURAC, Institute for Alpine Environment
framework   : io2012        # {io2012, html5slides, shower, dzslides, ...}
highlighter : highlight.js  # {highlight.js, prettify, highlight}
hitheme     : tomorrow      # 
widgets     : []            # {mathjax, quiz, bootstrap}
ext_widgets : {rCharts: [libraries/nvd3, libraries/leaflet]}
mode        : selfcontained # {standalone, draft}
knit        : slidify::knit2slides
logo        : logo.png
license     : by-nc-sa
github      : {user: JBrenn, repo: KnowledgeTransferEURAC}
---

## Content

all following R libraries are hosted on my GitHub account: [https://github.com/JBrenn](https://github.com/JBrenn)

> 1. **[DataBaseAlpEnvEURAC](https://github.com/JBrenn/DataBaseAlpEnvEURAC)** - reading, formating, writing Mazia LTER data; post-process WISKI .rzx files
> 2. **[SMCcalibration](https://github.com/JBrenn/SMCcalibration)** - shiny app for calibrting SMC sensors
> 3. **[SpatialInterpol](https://github.com/JBrenn/SpatialInterpol)** - spatial interpolation using local ordinary kriging and inverse distance weighting
> 4. **[AnalyseGEOtop](https://github.com/JBrenn/AnalyseGEOtop)** - GEOtop simulation analysis
> 5. **[TopoSUB](https://github.com/JBrenn/TopoSUB)** - landscape k-means clustering & land-surface modelling with GEOtop

---

## Intro R & GitHub

+ version control
+ branching
+ R packages in GitHub can be installed with __devtools::install_github__:


```r
library(devtools)
# install master branch
install_github("JBrenn/DataBaseAlpEnvEURAC")
# install different branch
install_github("JBrenn/SMCcalibration@download")
```

+ place to gather alpenv scripts?

---

## DataBaseAlpEnvEURAC - get data 1

+ base function is **dB_readStationData**

+ **dB_updatedb**: writing, updating SQlite database for specific variables or total data set (multiple stations and .csv output supported) - preperation for LTER database with fixed headers

+ **dB_getMETEO**: get meteo data  
+ **dB_getGEOtop**: get meteo data and convert to standard GEOtop meteo file format (multiple stations supported)
+ **dB_getSWC**: get soil moisture data
+ **dB_getSoilTemp**: get soil temperature data 
+ **dB_getSWP**: get soil water pressure (B2)

--- bg:#EEE

## DataBaseAlpEnvEURAC - get data 2


```r
# load library
library(DataBaseAlpEnvEURAC); library(dygraphs); library(zoo)
# easy data access, e.g. SWC data station P2
path2files <- ".../HiResAlp/06_Workspace/BrJ/02_data/Station_data_Mazia/P/P2"
header.file <- ".../HiResAlp/06_Workspace/BrJ/02_data/Station_data_Mazia/P/header_P2.txt"
P2 <- dB_getSWC(path2files = path2files, header.file = header.file, station = "P", 
                station_nr = 2, aggregation = "h", minVALUE = 0, maxVALUE = 1,
                write.csv = FALSE, path2write = "./")
# use calibration function
data(calibration); View(calibration)
P2_cal <- dB_getSWC(path2files = path2files, header.file = header.file, station = "P", 
                    station_nr = 2, aggregation = "h", minVALUE = 0, maxVALUE = 1,
                    calibrate=T)
# compare
P2_merge <- merge(P2[,1], P2_cal[,1])
time(P2_merge) <- as.POSIXct(time(P2_merge))
dygraphs(P2_merge)
```

---



<iframe src="./assets/widgets/dygraph1.html" width=100% height=100% allowtransparency="true"> </iframe>

--- bg:#EEE

## DataBaseAlpEnvEURAC - update database


```r
# creating .sqlite database for specific variables or total data
# for SWC .sqlite database is copied in data folder of SMCcalibrate package
# this is needed for downloading data with the clibration shiny app

P <- dB_updatedb(stations = c("P1","P2","P3"), variables = "SWC", 
                 inCloud = "/home/jbre/Schreibtisch/", 
                 write_csv = F, return_data = T)
```

+ **variables**: "TOTAL", "METEO", "SWC", "TSoil"
+ multiple stations and variables supported
+ possibility to write .csv for each station
+ handle .sqlite with R package *RSQlite* or specific software (e.g. [Sqliteman](https://sourceforge.net/projects/sqliteman/))

--- bg:#EEE

## SMCcalibration


```r
# load libraries
library(SMCcalibration)
library(shiny)

# easy data access
data("SensorVSample")

# data description
?SensorVSample

# reduce data
data <- unique(data[,-8])

# run shiny app
shinyApp(ui, server)
```

--- bg:#EEE

## DataBaseAlpEnvEURAC - postprocess .zrx 

+ **dB_readZRX** - read ZRX data file, working for single variable and multiple variables in .zrx file
+ used by **dB_readZRX2station** - process ZRX data files, return .csv file for each station containing available variables.


```r
files <- dir("/home/jbre/Schreibtisch/zrx/Mazia0480", full.names = T)
mazia <- dB_readZRX2station(files = files, write_csv = T, output_path = getwd(), 
                            multivar = TRUE)
plot(mazai$st0480)

files <- dir("/home/jbre/Schreibtisch/zrx/SouthTyrol", full.names = T)
data <- dB_readZRX2station(files = files, write_csv = F, output_path = getwd(), 
                           multivar = FALSE)
```

---

## Intro Rmarkdown

+ **.Rmd files** - An R Markdown (.Rmd) file is a record of your research. It contains the code that a scientist needs to reproduce your work along with the narration that a reader needs to understand your work.

+ **Reproducible Research** - At the click of a button you can rerun the code in an R Markdown file to reproduce your work and export the results as a finished report.

+ **Dynamic Docs** - You can choose to export the finished report as a html, pdf, MS Word, ODT, RTF, or markdown document; or as a html or pdf based slide show.

Example: 
+ Download or clone Git repository DataBaseAlpEnvEURAC
+ In the folder *Rmd* find the file **01_data_preparation_climate_quality.rmd**
+ open/run in RStudio

--- bg:#EEE

## SpatialInterpol


```r
library(SpatialInterpol)
ordkrig100 <- OrdKrig(datafolder = "master")
#ordkrig20  <- OrdKrig(datafolder = "master", npix = 20)
idw     <- OrdKrig(datafolder = "master", inverseDistWeigths = TRUE)
plot(ordkrig100$AdigeVenosta$vario, ordkrig100$AdigeVenosta$vario_fit)
```

![plot of chunk SpatialInterpol1](assets/fig/SpatialInterpol1-1.png)

---

### SpatialInterpol results

<iframe src="./assets/widgets/leaflet1.html" width=100% height=100% allowtransparency="true"> </iframe>

---


## include a source, e.g. ref

<div class='source'>
  Source: <a href='http://www.subtlepatterns.com'>Background from SubtlePatterns</a>
</div>


<style>
em {
  font-style: italic
}
strong {
  font-weight: bold;
}
</style>