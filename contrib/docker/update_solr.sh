sudo docker-compose rm -f -s solr
sudo docker volume rm docker_solr
sudo docker-compose up -d solr
sudo docker exec -it ckan ckan --config=/etc/ckan/production.ini search-index rebuild -r
