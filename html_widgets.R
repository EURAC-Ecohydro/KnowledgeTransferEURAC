

library(htmlwidgets)

## @knitr dygraph1

# load library
library(DataBaseAlpEnvEURAC); library(dygraphs); library(zoo)
# easy data access, e.g. SWC data station P2
path2files <- "/media/alpenv/Projekte/HiResAlp/06_Workspace/BrJ/02_data/Station_data_Mazia/P/P2"
header.file <- "/media/alpenv/Projekte/HiResAlp/06_Workspace/BrJ/02_data/Station_data_Mazia/P/header_P2.txt"
P2 <- dB_getSWC(path2files = path2files, header.file = header.file, station = "P", 
                station_nr = 2, aggregation = "h", minVALUE = 0, maxVALUE = 1,
                write.csv = FALSE, path2write = "./")
# use calibration function
data(calibration); View(calibration)
P2_cal <- dB_getSWC(path2files = path2files, header.file = header.file, station = "P", 
                    station_nr = 2, aggregation = "h", minVALUE = 0, maxVALUE = 1,
                    calibrate=T)
# compare
P2_merge <- merge(uncalibrated = P2[,1], calibrated= P2_cal[,1])
time(P2_merge) <- as.POSIXct(time(P2_merge))
dy <- dygraph(P2_merge) %>%
  dyRangeSelector() %>%
  dyRoller()

saveWidget(dy, 'dygraph1.html')

## @knitr leaflet1
library(raster)
library(leaflet)
r_kp <- raster("/home/jbre/R/OrdKrig/Humus____/maps/AdigeVenosta_Humus_____100_predict_sp_krige.tif")
r_kp_20 <- raster("/home/jbre/R/OrdKrig/Humus____/maps/AdigeVenosta_Humus_____20_predict_sp_krige.tif")
r_idw <- raster("/home/jbre/R/OrdKrig/Humus____/maps/AdigeVenosta_Humus_____100_predict_sp_idw.tif")

pal <- colorNumeric(c("#0C2C84", "#41B6C4", "#FFFFCC"), values(r)[values(r)<=15], na.color = "transparent")
m <- leaflet() %>%
  addTiles(group = "OSM (default)") %>%
#  addProviderTiles("Acetate.terrain", group = "Terrain")  %>% 
  addRasterImage(r_kp_20, colors = pal, opacity = 0.8, group = "krige 20m") %>%
  addRasterImage(r_kp, colors = pal, opacity = 0.8, group = "krige 100m") %>%
  addRasterImage(r_idw, colors = pal, opacity = 0.8, group = "idw 100m") %>%
  addLegend(pal = pal, values = values(r), title = "Humus fraction in %")  %>% 
  addLayersControl(
    overlayGroups = c("krige 20m", "krige 100m", "idw 100m"),
    options = layersControlOptions(collapsed = FALSE)
  )

saveWidget(m, 'leaflet1.html')
