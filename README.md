# ECMWF Download

The script ecmwf_ra_download.R gives an explicit example of using the package ecmwfr to access the climate data store (cds) of the ecmwf to download the ERA5-Land and Pressure level reanalysis data for a given area.

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