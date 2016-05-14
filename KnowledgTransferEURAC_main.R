# script for knowledge transfer presentation - 2016-05-19
# Johannes Brenner, alpenv, EURAC

#1 -----
#  install R libraries from GitHub

  library(devtools)

# install master branch of DataBaseAlpEnvEURAC 
  install_github("JBrenn/DataBaseAlpEnvEURAC")
  
# install download branch of SMCcalibration
  install_github("JBrenn/SMCcalbration@download")
  
# install TopoSUB and build vignettes
  install_github("JBrenn/TopoSUB", build_vignettes = TRUE)
  
#2 -----
#  load LTER data with DataBaseAlpEnvEURAC
  library(DataBaseAlpEnvEURAC)
  library(dygraphs)
  
# easy data access, e.g. SWC data station P2, with the possibility to write .csv files, range selection for variables and aggregation
  path2data <- "/media/alpenv/Projekte/HiResAlp/06_Workspace/BrJ/02_data/Station_data_Mazia"
  
# output object is a zoo time series (easy to plot see below)  
  P2 <- dB_getSWC(path2data = path2data, station = "P2", aggregation = "h", 
                  minVALUE = 0, maxVALUE = 1, write.csv = FALSE, path2write = "./")
  str(P2)
  
# use calibration function, calibration function parameters are inbeded in libraries 
  data("calibration")
  View(calibration)
  P2_cal <- dB_getSWC(path2data = path2data, station = "P2", aggregation = "h", 
                      minVALUE = 0, maxVALUE = 1, calibrate=T)
  
# compare calibrated vs. uncalibrated
  # merge two time series 
  P2_merge <- merge(P2[,1], P2_cal[,1])
  # change chron datetime to POSIXct convention
  time(P2_merge) <- as.POSIXct(time(P2_merge))
  # interactive time series plot with dygraph
  dygraph(P2_merge) %>%
    dyRangeSelector() %>% 
    dyRoller()
  
# creating .sqlite database for specific variables or total data
# for SWC .sqlite database is copied in data folder of SMCcalibrate library if available
# this is needed for downloading data with the calibration shiny app
  
# all LTER stations
  stations <- c(paste("B",1:3,sep=""), paste("P",1:3,sep=""), "I1", "I3", 
                paste("M",1:7,sep=""), "S2", "S4", "S5", "XS1", "XS6")
  
  all_st_swc <- dB_updatedb(path2data = path2data, stations = station, variables = "SWC", 
                            inCloud = "/home/jbre/Schreibtisch/", write_csv = F, return_data = T)
  
#3 -----
#  interactive shiny app for soil moisture sensor calibration and data download if "download" branch installed
  
# load libraries
  library(SMCcalibration)
  library(shiny)
  
# easy data access
  data("SensorVSample")
  
# data description
  ?SensorVSample
  View(SensorVSample)
  
# reduce data
  data <- unique(data[,-8])
  
# run shiny app
  shinyApp(ui, server)  
  

#4 -----
#  DataBaseAlpEnvEURAC - postprocess .zrx from batch WISKI download (Province Meteo Database)
  library(zoo)
  
# read data from two .zrx files containing different variables (multivar = FALSE)
  files <- dir("/home/jbre/Schreibtisch/zrx/SouthTyrol", full.names = T)
  data <- dB_readZRX2station(files = files, write_csv = F, 
                             multivar = FALSE)
  str(data$st0480)
  plot(data$st0480)

# read data from single .zrx file containing multiple variables (multivar = TRUE)
# files are written in output_path directory, data file for each station and meta data file  
  path <- "/home/jbre/Schreibtisch/zrx/Mazia0480"
  files <- dir(path, full.names = T)
  mazia <- dB_readZRX2station(files = files, write_csv = T, output_path = path, 
                              multivar = TRUE)
  plot(mazia$st0480)
  
# show data.table of written data
  library(DT); library(readr)
  matschdata <- read_csv(file.path(path,"st0480_1440.csv"))
  datatable(matschdata)
  
  
#5 -----
#  Spatial interpolation
# local ordinary kriging and inverse distance weighting
# fokrigin and idw function to minimize are implemented in order to allow model parameter calibration
# with "optim" or "hydroPSO"  
  
  install_github("JBrenn/SpatialInterpol")
  library(SpatialInterpol)
  
# ordinary kriging, resolution of output is resolution of raster mask  
  ordkrig100 <- OrdKrig(datafolder = "master", variable = "Humus____")
# resample utput resolution to 20m  
  ordkrig20  <- OrdKrig(datafolder = "master", variable = "Humus____", npix = 20)
# inverse distance weighting  
  idw     <- OrdKrig(datafolder = "master", variable = "Humus____", inverseDistWeigths = TRUE)
# plot sample variogram and fitted variagram   
  plot(ordkrig100$AdigeVenosta$vario, ordkrig100$AdigeVenosta$vario_fit)
  
# visualize output maps with leaflet
  library(raster)
  library(leaflet)
# load raster maps from output directory  
  r_kp <- raster("/home/jbre/R/OrdKrig/Humus____/maps/AdigeVenosta_Humus_____100_predict_sp_krige.tif")
  r_kp_20 <- raster("/home/jbre/R/OrdKrig/Humus____/maps/AdigeVenosta_Humus_____20_predict_sp_krige.tif")
  r_idw <- raster("/home/jbre/R/OrdKrig/Humus____/maps/AdigeVenosta_Humus_____100_predict_sp_idw.tif")
# define map colors  
  pal <- colorNumeric(c("#0C2C84", "#41B6C4", "#FFFFCC"), values(r_kp)[values(r_kp)<=15], na.color = "transparent")
# leaflet map
  leaflet() %>%
    addTiles(group = "OSM (default)") %>%
    addRasterImage(r_kp_20, colors = pal, opacity = 0.8, group = "krige 20m") %>%
    addRasterImage(r_kp, colors = pal, opacity = 0.8, group = "krige 100m") %>%
    addRasterImage(r_idw, colors = pal, opacity = 0.8, group = "idw 100m") %>%
    addLegend(pal = pal, values = values(r_kp), title = "Humus fraction in %")  %>% 
    addLayersControl(
      overlayGroups = c("krige 20m", "krige 100m", "idw 100m"),
      options = layersControlOptions(collapsed = FALSE)
    )
  
#6 -----
#  get TopoSUB vignettes
  browseVignettes("TopoSUB")
  
  