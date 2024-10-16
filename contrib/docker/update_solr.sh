# if updating the schema you must build the image first. once the container starts there 
# is no way to update the managed schema other then via thesolr api
# sudo docker-compose pull solr OR sudo docker-compose build solr
sudo docker-compose rm -f -s solr
sudo docker volume rm docker_solr_data
sudo docker-compose up -d ckan
sleep 5
sudo docker exec -it ckan ckan --config=/srv/app/ckan.ini search-index rebuild -r