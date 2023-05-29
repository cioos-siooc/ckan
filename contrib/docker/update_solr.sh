sudo docker-compose pull solr
sudo docker-compose rm -f -s solr
sudo docker volume rm docker_solr_data
sudo docker-compose up -d
sudo docker exec -it ckan ckan --config=/etc/ckan/production.ini search-index rebuild -r