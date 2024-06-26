library(lubridate)
library(dplyr)
library(ncdf4)
library(reshape2)
library(sf)
library(openair)
library(tmap)
library(birk)
library(worldmet)
#remotes::install_github("skgrange/threadr")
library(threadr)

##define coordinate systems
latlong = "+init=epsg:4326"
rdnew = "+init=epsg:28992" ## metres coordinate system - Dutch

variables <- c("surface_solar_radiation_downwards", "2m_temperature", "10m_u_component_of_wind",
               "10m_v_component_of_wind", "total_precipitation", "total_sky_direct_solar_radiation_at_surface")
##output path as previously defined
path_out <- "downloads"

## TO GET time series for a single location from the file

yrz <- c("2022")

## take Bristol Airport as a location
bristol_airport <- getMeta(site = "bristol")

## extract lat and lon for site - can be amended to custom site coordinates
site_lat <- bristol_airport$latitude
site_lon <- bristol_airport$longitude

## import data for bristol airport to compare
noaa_dat <- importNOAA(bristol_airport$code, year = as.numeric(yrz))

## get ECMWF variables downloaded with previous script
all_varz <- list()
for (v in variables){
  ## loop through each month and year
  dat_list <- list()
  for (y in yrz){
  
  monthz <- sprintf("%02d", 1:12)
  
    for (m in monthz){
      
      ## open the file
      ECMWF <- nc_open(paste0("downloads/", v, "_",y, m, ".nc"))
      
      ## get variable name
      var <- names(ECMWF$var)
      
      ##get latitude and longitude range from file
      lons <- ncvar_get(ECMWF, "longitude")
      lats <- ncvar_get(ECMWF, "latitude")
      ## find netcdf id that matches the lon and lat coords
      n_lon <- which.closest(lons, site_lon)
      n_lat <- which.closest(lats, site_lat)
      
      ##import time stamps from netcdf
      thyme <- ncvar_get(ECMWF, "time")
      
      ##convert to POSIX - info given here https://confluence.ecmwf.int/display/CKB/ERA5%3A+data+documentation#ERA5:datadocumentation-Dateandtimespecification
      d8 <- lubridate::ymd("1900-01-01") + lubridate::hours(thyme)
      
      ## import all coordinates for country area
      var_dat <- ncvar_get(ECMWF, var, start = c(n_lon, n_lat, 1), count = c(1,1, NROW(d8)))
      
      ##create data frame of dates
      df <- data.frame(date = d8,
                       ecmwf_dat = var_dat)
      
      ## assign correct variable name to column
      names(df) <- c("date", var)
      
      ## generate unique character for the list name
      nam <- paste0(y,m)
      
      ## write to list
      dat_list[[nam]] <- df
      ## show progress
      print(paste(v,nam))
    }
  
  }
  ## write full date period for the variable
  all_varz[[v]] <- do.call(rbind, dat_list)
 
}
## left join all variables in list to give a data frame with row for each hour for all variables
ecmwf_all <- purrr::reduce(all_varz, left_join, by = "date") %>% 
  mutate(date2 = with_tz(date, tzone = "GMT"))

## define function to calculate wind direction in degrees from u and v
windDir <- function(u,v){
  (270-atan2(u,v)*180/pi)%%360
}

## convert raw outputs to standard units
ecmwf_units <- ecmwf_all %>% 
  transmute(date,
            ws_ms = sqrt(u10^2+v10^2),
            wd_deg = windDir(u = u10, v = v10),
            t_deg = t2m - 273.15,
            fdir_wm2 = fdir/3600)

## ssrd data is cumulative so for the daily total we only need the value at the end of the day 23:00
ecmwf_cum <- ecmwf_all %>%
  mutate(colsplit(date, " ", c("day", "hour")),
         row_d8 = seq(1:NROW(date))) %>% 
  mutate(ssrd = c(ssrd[-1],0), tp = c(tp[-1],0))

## loop through each day to avoid including total for previous day in difference calc
d <- unique(ecmwf_cum$day)[2]
day_vals <- list()
for (d in unique(ecmwf_cum$day)){
  
  ## calculate value for each hour and convert ssrd to watts per m2
  cum_df <- ecmwf_cum %>% 
    filter(day == d) %>% 
    transmute(date, ssrd_wm2 = c(ssrd[1], diff(ssrd))/3600, tp = c(tp[1],diff(tp)))
  
  day_vals[[d]] <- cum_df
  
}

## cumulative data normalised
ecmwf_out <- do.call(rbind,day_vals)

## join all ecmwf data to noaa
noaa_ecmwf <- noaa_dat %>% 
  left_join(ecmwf_units, by = "date") %>% 
  left_join(ecmwf_out, by = "date")

## plot observed and modelled temperature
temp_mod_obs <- noaa_ecmwf %>% 
  transmute(date, obs = air_temp, mod = t_deg)

## show full years time series together
p1 <- timePlot(temp_mod_obs, c("obs", "mod"))    

## interactive version
threadr::time_dygraph(temp_mod_obs, c("obs", "mod"))

## rearrange for time variation plot
temp_mod_obs_down <- melt(temp_mod_obs, 'date')

## plot summary periods
p2 <- timeVariation(temp_mod_obs_down, "value", group = "variable")  

## compare observed and modelled wind speed
ws_mod_obs <- noaa_ecmwf %>% 
  transmute(date, obs = ws, mod = ws_ms) %>% 
  melt('date')

## plot summary periods
p3 <- timeVariation(ws_mod_obs, 'value', group = 'variable')

## rearrange for time variation plot
wd_mod_obs <- noaa_ecmwf %>% 
  transmute(date, obs = wd, mod = wd_deg) %>% 
  melt('date')

p4 <- timeVariation(wd_mod_obs, 'value', group = 'variable')

## compile data for wind rose plot
wswd_obs <- noaa_ecmwf %>% 
  select(date, ws,wd) %>% 
  mutate(variable = "obs")

wswd_mod <- noaa_ecmwf %>% 
  select(date, ws = ws_ms, wd =wd_deg) %>% 
  mutate(variable = "mod")

wswd_mod_obs <- rbind(wswd_obs, wswd_mod)  

## show wind rose for modelled and observed
p5 <- windRose(wswd_mod_obs, type = 'variable')
