add `ckan.cache_expires = 604800` and `ckan.cache_enabled = True` to ckan.ini  file

ckan use is now 92 rather then 900. you will need to chanke log folders to be owned by user 92 so it will work with alpine image
eg `sudo chown -R 92:92 /var/log/ckan/`

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
