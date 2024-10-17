## Pull new github repo
```
cd ckan
git pull
git submodule update
cd contrib/docker
```

## Copy ckan.ini to new location and backup
```
export VOL_CKAN_HOME=`sudo docker volume inspect docker_ckan_home | jq -r -c '.[] | .Mountpoint'`
export VOL_CKAN_CONFIG=`sudo docker volume inspect docker_ckan_config | jq -r -c '.[] | .Mountpoint'`

sudo cp $VOL_CKAN_CONFIG/production.ini $VOL_CKAN_HOME/ckan.ini
sudo cp $VOL_CKAN_CONFIG/production.ini  ./ckan.ini
```

## Backup the database, just in case
### Admin config and harvesters
```
sudo docker exec  -it db  pg_dump --column-inserts --data-only --table=public.system_info -U ckan -d ckan > ~/ckan/contrib/docker/ckan_admin_config.sql
sudo docker exec  -it db  pg_dump --column-inserts --data-only --table=public.harvest_source -U ckan -d ckan > ~/ckan/contrib/docker/ckan_harvest_source.sql
```

### Do a full db dump because we are that kind of developer
```
sudo docker exec -u root -ti db /bin/bash -c "export TERM=xterm; exec bash"
pg_dump -U ckan --format=custom -d ckan > /tmp/ckan.dump
exit
sudo docker cp db:/tmp/ckan.dump ckan.dump
```

#### To restore from the full backup, if needed
```
sudo docker cp ckan.dump db:/tmp/ckan.dump
sudo docker exec -u root -ti db /bin/bash -c "export TERM=xterm; exec bash"
pg_restore -U ckan --clean --if-exists -d ckan < /tmp/ckan.dump 
exit
```

#### Or to update just the admin config and harvester
```
sudo docker exec  -it db psql -U ckan -d ckan < ~/ckan/contrib/docker/ckan_admin_config.sql
sudo docker exec  -it db psql -U ckan -d ckan < ~/ckan/contrib/docker/ckan_harvest_source.sql
```


## Setup .env file
run commands in env.template to update secrets in .env. Manually review .env file to ensure it has the correct settings


## Pull down new ckan image
```
sudo docker-compose pull ckan
```

You might need to upgrade docker-compose to v2
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-centos-7
https://github.com/docker/compose/releases/tag/v2.17.3
```
sudo curl -L "https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo docker-compose --version
```

## Recreate CKAN container
```
sudo docker kill datapusher
./clean_reload_ckan.sh
sudo docker volume rm docker_ckan_storage
sudo docker-compose up -d ckan
```

## Update permissions
CKAN user is now 92 (www-data) rather then 900. you will need to change the log folder owner to 92 so it will work with alpine image
```
sudo chown -R 92:92 /var/log/ckan/
```

may need to change permission on some internal files after web assets are built during initial ckan container start
eg
```
export VOL_CKAN_HOME=`sudo docker volume inspect docker_ckan_home | jq -r -c '.[] | .Mountpoint'`
export VOL_CKAN_STORAGE=`sudo docker volume inspect docker_ckan_storage | jq -r -c '.[] | .Mountpoint'`
sudo chown -R 92:92 $VOL_CKAN_HOME $VOL_CKAN_STORAGE
```

## Finally 
Once everything is running, update robots.txt with your sitemap details
```
sudo docker exec -u root -it ckan  /bin/bash -c 'sed -i "s@Sitemap: /sitemap/sitemap.xml@Sitemap: $CKAN_SITE_URL/sitemap/sitemap.xml@" src/ckanext-cioos_theme/ckanext/cioos_theme/public/robots.txt'
```

## Other notes
### If building from source
You can now use a cache for pip packages. if using docker-compose < 2 you will need to add environment variables to enable buildkit
eg
```
COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build ckan
```

### long api calls
If getting proxy errors due to timeous and errors about HARAKIRI in the logs then you are hitting the harakiri timeout.
https://github.com/ckan/ckan/blob/ff9afc5a3cff5ca7a2ba96bd73bf2371ea13afe0/ckan-uwsgi.ini#L11
consider increasing it temporarily by changing the environment variable in the compose file. The default timeout is 50. for 2 min timeout set to 120

Setting in docker-compose environment section of the ckan container
```
UWSGI_HARAKIRI=120
```

