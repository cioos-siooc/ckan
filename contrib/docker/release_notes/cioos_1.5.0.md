# Release cioos 1.5.0 
To update from cioos ckan 1.4 to this release a few configuration changes are required. You will also 
need to sign up for a free stadia account and create an api key so that we can continue using the same 
basemap tiles. see https://stadiamaps.com/stamen/onboarding/create-account/

We have added a RA polygon layer to the search maps. if you would like to display this layer you must give 
a path to a geojson file in the config.

production.ini
```
ckanext.spatial.common_map.stadia.API_key = [YOUR KEY HERE]
ckan.cioos.ra_json_file = ./ckanext-cioos_theme/ckanext/cioos_theme/public/base/layers/pacific_RA.json (or similar json file for your ra)
```

We are now making groups from responsible organizations during harvest. if you would like to 
turn this off, not recommended, you need to set the configure the system to not harvest 
responsible organizations either in the production.ini or in the config of a given harvester.
This value defaults to True if not set.

production.ini
```
ckan.harvest_responsible_organizations = True 
```

Or harvester config
```
"harvest_responsible_organizations”: True
```

It is also possible to set a 'quality level' per harvester. This is used when harvesting from external catalogues and will display a quality notice on any dataset pulled from this harvester if given a value of 'unknown' or 'external'.

harvester config
```
"harvest_source_quality_level": "unknown",
```

If using a harvester that utilizes amazon translate you will need to set the AWS keys in your .env file
```.env
# to use amazone translate you must have the following AWS keys set
AWS_DEFAULT_REGION=us-east-1
AWS_ACCESS_KEY_ID=[YOUR_KEY_ID]
AWS_SECRET_ACCESS_KEY=(YOUR_ACCESS_KEY)
```


### Once you have the above config set correctly you can update to the latest release by

Update ckan
```
cd ~/ckan/contrib/docker
sudo docker-compose pull ckan
./clean_reload_ckan.sh
sudo docker-compose up -d
```

Update solr 
```
cd ~/ckan/contrib/docker
sudo docker-compose pull solr
./update_solr.sh
```