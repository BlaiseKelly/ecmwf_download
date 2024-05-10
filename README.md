# ECMWF Download

The script 01_ecmwf_ra_download.R gives an explicit example of using the package ecmwfr to access the climate data store (cds) of the ecmwf to download the ERA5-Land and Pressure level reanalysis data for a given area.

API key and account (free for anyone) is needed to access. 

Create an account here: https://cds.climate.copernicus.eu/#!/home

Once created go to user page: https://cds.climate.copernicus.eu/user/{user_id}

and copy the 6 digit UID to the 'user' and the API key to 'key'. 

```
 ##input ecmwf user id
  user = "" ## ecmwf username (email address)
  
  wf_set_key(user = "", ## user id 6 digit UID
             key = "", ## API key
             service = "cds") ##service (cds = 'climate data store')
```

To see the status of request made by the script go to https://cds.climate.copernicus.eu/cdsapp#!/yourrequests

The reanalysis-era5-land is a higher resolution dataset only available over land. Not as many parameters are available as the reanalysis-era5-single-levels, so examples of both are given.

ECMWF Land
The first loop downloads variables from the ECMWF land datastore, which is the highest resolution available (~7km) but only over land. To get a full list of variable names go to: https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-land?tab=overview

ECMWF ERA5
The ERA5 database covers the entire globe, sea and land and is approximately 30km resolution.
Full list of variable names: https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-pressure-levels?tab=overview

The script downloads the files for the defined period by months (month is chosen as the server has a limit of 1000 hours) and saves in a folder called 'downloads' as netcdf files.

Script 02_extract_from_ecmwf.R shows a method for extracting the data from the downloaded files for a specific lat lon coordinate. It uses the worldmet R package to access the NOAA observation database and shows a few examples of how the modelled data can be compared to this data.

Bristol has been used as the demonstration area so Bristol airport is taken as the 