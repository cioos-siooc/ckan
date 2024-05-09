copy ckan.ini to new location and backup
```
export VOL_CKAN_HOME=`sudo docker volume inspect docker_ckan_home | jq -r -c '.[] | .Mountpoint'`
export VOL_CKAN_CONFIG=`sudo docker volume inspect docker_ckan_config | jq -r -c '.[] | .Mountpoint'`

sudo cp $VOL_CKAN_CONFIG/production.ini $VOL_CKAN_HOME/ckan.ini
sudo cp $VOL_CKAN_CONFIG/production.ini  ./ckan.ini
```

run commands in env.template to update secrets in .env. Manually review .env file to ensure it has the correct settings

<!-- add `ckan.cache_expires = 604800` and `ckan.cache_enabled = True` to ckan.ini  file -->

pull down new ckan image
```
sudo docker-compose pull ckan
```

You might need to upgrade docker-compose to v2
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-centos-7
https://github.com/docker/compose/releases/tag/v2.6.1


ckan use is now 92 rather then 900. you will need to change log folders to be owned by user 92 so it will work with alpine image
eg `sudo chown -R 92:92 /var/log/ckan/`

recreate ckan container
```
./clean_reload_ckan.sh
sudo docker-compose up -d ckan
```

may need to change permission on some internal files after webassets get built
eg
```
export VOL_CKAN_HOME=`sudo docker volume inspect docker_ckan_home | jq -r -c '.[] | .Mountpoint'`
export VOL_CKAN_STORAGE=`sudo docker volume inspect docker_ckan_storage | jq -r -c '.[] | .Mountpoint'`
sudo chown -R 92:92 $VOL_CKAN_HOME $VOL_CKAN_STORAGE
```

you can now use a cache for pip packages. if using docker-compose < 2 you will need to add enviroment variables to enable buildkit
eg
```
COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build ckan
```


update robots.txt with your sitemap details
```
sudo docker exec -u root -it ckan  /bin/bash -c 'sed -i "s@Sitemap: /sitemap/sitemap.xml@Sitemap: $CKAN_SITE_URL/sitemap/sitemap.xml@" src/ckanext-cioos_theme/ckanext/cioos_theme/public/robots.txt'
```