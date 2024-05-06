## script for downloading the free ECMWF reanalysis (ra) data. There are two variations shown below, downloading the 'land' (9km2) and the 'single layer' (30km2)

library(dplyr)
library(sf)
library(ncdf4)
library(ecmwfr)
library(osmdata)

## import some coordinates
place <- osmdata::getbb("Bristol")

## find extent
min_lon <- place[1]
max_lon <- place[3]
min_lat <- place[2]
max_lat <- place[4]


##define the minimum and maximum latitude and longitude, or define manually
# lon_min <- -5.2
# lon_max <- -5.6
# lat_min <- 50.1
# lat_max <- 50.8
# 
# ## convert to ecmwf friendly numbers
#   min_lon <- floor(lon_min)
#   max_lon <- ceiling(lon_max)
#   
#   min_lat <- floor(lat_min)
#   max_lat <- ceiling(lat_max)

 ##define the max and min domain for the ecmwf request
  ecmwf_land_area <- paste0(min_lat, "/", min_lon, "/", max_lat, "/", max_lon)
  
  ##output path, don't put a / at the end or will return an error
  path_out <- "./"
  
  ##input ecmwf user id
  user = "" ## ecmwf username
  
  wf_set_key(user = "", ## user id
             key = "", ## key
             service = "cds") ##service (cds = 'climate data store')
  
  ##define variables to download. list is available here: https://confluence.ecmwf.int/display/CKB/ERA5-Land%3A+data+documentation#ERA5Land:datadocumentation-parameterlistingParameterlistings
  variables <- c("surface_net_solar_radiation",
                 "surface_solar_radiation_downwards", "2m_temperature", "10m_u_component_of_wind",
                 "10m_v_component_of_wind", "total_precipitation")

  yrz <- c("2018", "2019", "2020", "2021", "2022")
  
  ## recent update to climate data store means some datasets (e.g. reanalysis land) have a 1000 line limit. To avoid files of different time periods
  ## which can cause headaches down the line, best to split into months
  monthz <- 1:12
  
  ##downloads to a directory 'data' at the same level as the script is saved
  
  ##ECMWF data
    for(v in unique(variables)){
      
      for (y in yrz){
        
        for (m in monthz){
        
          m_nam <- sprintf("%02d", m)
      
      request_BLD <- list(dataset_short_name = "reanalysis-era5-land",
                          product_type   = "reanalysis",
                          variable       = v,
                          year = y,
                          month = m,
                          day = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"),
                          time = c("00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"),
                          area           = ecmwf_land_area,
                          format         = "netcdf",
                          target         = paste0(v, "_", y,m_nam, ".nc"))
      
      
      nc_BLD <- wf_request(user = "59954",
                           request = request_BLD,
                           transfer = TRUE,
                           path = path_out,
                           verbose = TRUE)
      
        }
      
    }

    }
  ##ERA variable (0.25 degree)
  
  ecmwf_main_area <- paste0(min_lat, "/", min_lon, "/", max_lat, "/", max_lon)

  ##for list of variables visit https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=form create a query and click
  ## 'show API request' next to the variable with the the variable text to paste into the list of strings below
  variables_main <- c("total_sky_direct_solar_radiation_at_surface", "surface_solar_radiation_downwards")
  
  ##ECMWF data
  
  for(v in unique(variables_main)){
    
    for (y in yrz){
      
      for (m in monthz){
        
        ## convert month name to 2 digit for file name
        m_nam <- sprintf("%02d", m)
    
    request_BLD <- list(dataset_short_name = "reanalysis-era5-single-levels",
                        product_type   = "reanalysis",
                        variable       = v,
                        year = y,
                        month = m,
                        day = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"),
                        time = c("00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"),
                        area           = ecmwf_main_area,
                        format         = "netcdf",
                        target         = paste0(v, "_", y,m_nam, ".nc"))
    
    
    nc_BLD <- wf_request(user = "59954",
                         request = request_BLD,
                         transfer = TRUE,
                         path = path_out,
                         verbose = TRUE)
    
      }
    
  }
  }
 