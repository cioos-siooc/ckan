# Setup

These instructions are for CentOS 7. They have been modified from the original ['Installing CKAN with Docker Compose'](https://docs.ckan.org/en/2.8/maintaining/installing/install-from-docker-compose.html) instructions.

#### Install Docker

```bash
sudo yum install -y yum-utils device-mapper-persistent-data   lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
```

#### Install docker-compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo docker-compose --version
```

---

#### Download CKAN git repo and submodules

```bash
git clone -b cioos https://github.com/cioos-siooc/ckan.git
cd ckan
git checkout cioos
git submodule init
git submodule update
```

---

#### Create config files

Create environment file and populate with appropriate values

```bash
cd ~/ckan/contrib/docker/
cp .env.template .env
nano .env
```

If your CKAN installation will run at the root of your domain, use:

```
cd ~/ckan/contrib/docker/
cp production_root_url.ini production.ini
cp who_root_url.ini who.ini
```

**Or** Use this setup if your site will run at yourdomain.com **/ckan**

```bash
cd ~/ckan/contrib/docker/
cp production_non_root_url.ini production.ini
cp who_non_root_url.ini who.ini
```

copy pyCSW config file and update the database password. This is the same password entered in your .env file

```bash
cd ~/ckan/contrib/docker/pycsw
cp pycsw.cfg.template pycsw.cfg
nano pycsw.cfg
```

---

#### Build CKAN

Change to ckan docker config folder

```bash
  cd ~/ckan/contrib/docker
```

Build containers, this takes a while

```bash
  sudo docker-compose up -d --build
```

If you don't see any error messages, check http://localhost:5000 to see if the installation worked.

```bash
curl localhost:5000
```

If there was an error message, see Troubleshooting below.

Create ckan admin user

```bash
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini add admin
```

#### Configure admin settings

in the admin page of ckan set style to default and homepage to CIOOS to get the full affect of the cioos_theme extension

---

## Setup Harvesters

Add Organization
URL: `https://localhost/ckan/organization`

Add Harvester
URL: `https://localhost/ckan/harvest`

The settings for harvesters are fairly straightforward. The one exception is the configuration section. Some example configs are listed below.

#### CSW (geonetwork)

```json
{
  "default_tags": ["geonetwork"],
  "default_extras": {
    "encoding": "utf8",
    "h_source_id": "{harvest_source_id}",
    "h_source_url": "https://hecate.hakai.org/geonetwork/srv/eng/catalog.search#/metadata/",
    "h_source_title": "{harvest_source_title}",
    "h_job_id": "{harvest_job_id}",
    "h_object_id": "{harvest_object_id}"
  },
  "override_extras": true,
  "clean_tags": true,
  "harvest_iso_categories": true,
  "group_mapping": {
    "farming": "farming",
    "utilitiesCommunication": "boundaries",
    "transportation": "boundaries",
    "inlandWaters": "inlandwaters",
    "geoscientificInformation": "geoscientificinformation",
    "environment": "environment",
    "climatologyMeteorologyAtmosphere": "climatologymeteorologyatmosphere",
    "planningCadastre": "boundaries",
    "imageryBaseMapsEarthCover": "imagerybasemapsearthcover",
    "elevation": "elevation",
    "boundaries": "boundaries",
    "structure": "boundaries",
    "location": "boundaries",
    "economy": "economy",
    "society": "economy",
    "biota": "biota",
    "intelligenceMilitary": "boundaries",
    "oceans": "oceans",
    "health": "health"
  }
}
```

#### WAF (ERDDAP)

```json
{
  "default_tags": ["erddap"],
  "default_extras": {
    "encoding": "utf8",
    "guid_suffix": "_iso19115.xml",
    "h_source_id": "{harvest_source_id}",
    "h_source_url": "{harvest_source_url}",
    "h_source_title": "{harvest_source_title}",
    "h_job_id": "{harvest_job_id}",
    "h_object_id": "{harvest_object_id}"
  },
  "override_extras": false,
  "clean_tags": true,
  "validator_profiles": ["iso19139ngdc"],
  "harvest_iso_categories": true,
  "group_mapping": {
    "farming": "farming",
    "utilitiesCommunication": "boundaries",
    "transportation": "boundaries",
    "inlandWaters": "inlandwaters",
    "geoscientificInformation": "geoscientificinformation",
    "environment": "environment",
    "climatologyMeteorologyAtmosphere": "climatologymeteorologyatmosphere",
    "planningCadastre": "boundaries",
    "imageryBaseMapsEarthCover": "imagerybasemapsearthcover",
    "elevation": "elevation",
    "boundaries": "boundaries",
    "structure": "boundaries",
    "location": "boundaries",
    "economy": "economy",
    "society": "economy",
    "biota": "biota",
    "intelligenceMilitary": "boundaries",
    "oceans": "oceans",
    "health": "health"
  }
}
```

#### 19115-3 WAF (ERDDAP)

```json
{
  "default_tags": [],
  "default_extras": {
    "encoding": "utf8",
    "h_source_id": "{harvest_source_id}",
    "h_source_url": "{harvest_source_url}",
    "h_source_title": "{harvest_source_title}",
    "h_job_id": "{harvest_job_id}",
    "h_object_id": "{harvest_object_id}"
  },
  "override_extras": false,
  "clean_tags": true,
  "validator_profiles": ["iso19115"],
  "remote_orgs": "only_local",
  "harvest_iso_categories": false,
  "organization_mapping": {
    "Institute of Ocean Sciences, 9860 West Saanich Road, Sidney, B.C., Canada": "Fisheries and Oceans Canada"
  }
}
```

#### CKAN

```json
{
  "default_tags": [{ "name": "ckan" }, { "name": "production" }],
  "default_extras": {
    "encoding": "utf8",
    "h_source_id": "{harvest_source_id}",
    "h_source_url": "{harvest_source_url}",
    "h_source_title": "{harvest_source_title}",
    "h_job_id": "{harvest_job_id}",
    "h_object_id": "{harvest_object_id}"
  },
  "clean_tags": true,
  "use_default_schema": true,
  "force_package_type": "dataset",
  "groups_filter_include": ["cioos"],
  "spatial_crs": "4326",
  "spatial_filter_file": "./cioos-siooc-schema/pacific_RA.wkt",
  "spatial_filter": "POLYGON((-128.17701209 51.62096599, -127.92157996 51.62096599, -127.92157996 51.73507366, -128.17701209 51.73507366, -128.17701209 51.62096599))"
}
```
Note that `use_default_schema` and `force_package_type` are not needed and will cause validation errors if harvesting between two ckans using the same custom schema (the CIOOS setup). `spatial_filter_file`, if set, will take presidents over `spatial_filter`. Thus in the above example the `spatial_filter` paramiter will be ignored in favour of loading the spatial filter from an external file

### reindex Harvesters
it may become necessary to reindex harvesters, especially if they no longer report the correct number of harvested datasets. If modifying the harvester config you will also need to reindex to make the new config take affect

```bash
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckanext-harvest harvester reindex --config=/etc/ckan/production.ini
```
---

#### Finish setting up pyCSW

create pycsw database in existing pg container and install postgis

```bash
sudo docker exec -it db psql -U ckan
CREATE DATABASE pycsw OWNER ckan ENCODING 'utf-8';
\c pycsw
CREATE EXTENSION postgis;
\q
```

setup pycsw database tables.

```bash
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckanext-spatial ckan-pycsw setup -p /usr/lib/ckan/venv/src/pycsw/default.cfg
```

start pycsw container

```bash
sudo docker-compose up -d pycsw
```

#### test GetCapabilities

<https://localhost/ckan/csw/?service=CSW&version=2.0.2&request=GetCapabilities>

or

<https://localhost/csw/?service=CSW&version=2.0.2&request=GetCapabilities>

#### Useful pycsw commands

access pycsw-admin

```bash
sudo docker exec -ti pycsw pycsw-admin.py -h
```

Load the CKAN datasets into pycsw

```bash
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckanext-spatial ckan-pycsw load -p /usr/lib/ckan/venv/src/pycsw/default.cfg -u http://localhost:5000
```

ckan-pycsw commands

```bash
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckanext-spatial ckan-pycsw --help
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckanext-spatial ckan-pycsw setup -p /usr/lib/ckan/venv/src/pycsw/default.cfg
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckanext-spatial ckan-pycsw set_keywords -p /usr/lib/ckan/venv/src/pycsw/default.cfg -u http://localhost:5000
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckanext-spatial ckan-pycsw load -p /usr/lib/ckan/venv/src/pycsw/default.cfg -u http://localhost:5000
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckanext-spatial ckan-pycsw clear -p /usr/lib/ckan/venv/src/pycsw/default.cfg
```

errors while pycsw loading
if you get "Error:Cannot commit to repository" and "HINT: Values larger than 1/3 of a buffer page cannot be indexed." you are likely loading abstracts or other fields that are to big to be indexed in the database. You can either remove the index or switch to an index using the md5 encoded version of the value.

connect to db

```bash
sudo docker exec -i db psql -U ckan
\c pycsw
```

remove index

```sql
DROP INDEX ix_records_abstract;
```

add md5 index

```sql
CREATE INDEX ix_records_abstract ON records((md5(abstract)));
```

---

#### Setup Apache proxy

CKAN by default will install to localhost:5000. You can use Apache to forward requests from yourdomain.com or yourdomain.com/ckan to localhost:5000.

#### Install Apache

If proxying docker behind Apache (recommended) you will need to have that installed as well. nginx will also work but is not covered in this guide.

```bash
sudo yum install httpd mod_ssl
sudo systemctl enable httpd
sudo systemctl start httpd
```

add the following to your sites configs

```apache
    # CKAN
		<location /ckan>
  	    ProxyPass http://localhost:5000/
  	    ProxyPassReverse http://localhost:5000/
        # enable deflate
        SetOutputFilter DEFLATE
        SetEnvIfNoCase Request_URI "\.(?:gif|jpe?g|png)$" no-gzip
   	</location>

    # pycsw
     <location /ckan/csw>
         ProxyPass http://localhost:8000/pycsw/csw.js
         ProxyPassReverse http://localhost:8000/pycsw/csw.js
    </location>
```

or

```apache
    # CKAN
    <location />
        ProxyPass http://localhost:5000/
        ProxyPassReverse http://localhost:5000/
    </location>

    # pycsw
    <location /csw>
        ProxyPass http://localhost:8000/pycsw/csw.js
        ProxyPassReverse http://localhost:8000/pycsw/csw.js
    </location>

```

Redirect HTTP to HTTPS

```apache
<VirtualHost *:80>
   Redirect / https://yourdomain.org
</VirtualHost>
```

Allow Apache to make network connections:

```bash
sudo /usr/sbin/setsebool -P httpd_can_network_connect 1
```

Restart apache

```bash
  sudo apachectl restart
```

# Enable Compression in Apache
ubuntu https://rietta.com/blog/moddeflate-dramatic-website-speed/
centos7 https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-mod_deflate-on-centos-7
Enable mod_deflate in your Apache2 installation

```bash
sudo a2enmod deflate
```

Restart apache
```bash
  sudo apachectl restart
```

# Customize interface
Now that you have ckan running you can customize the interface via the admin config page. Go to http://localhost:5000/ckan-admin/config and configure some of the site options.

- Site_logo can be used to set the CIOOS logo that appears on every page.
- Homepage should be set to CIOOS for the CIOOS style home page layout
- Custom CSS can be used to change the colour pallet of the site as well as any of the other css items. An example css that sets the colour pallet is:

```CSS
#header-container #header .header-links>ul>li a:hover {
  color: #ffc857;
  background: #FFF
}
#header-container #header .header-links>ul>li.current-menu-item>a span {
  color: #ffc857;
}

#header-container #header .menu>li>a::after {
  background: #006e90;
}

#header-container #header #header-links .sub-menu {
  box-shadow: #115172 0 -4px 0 0px, rgba(0, 0, 0, 0.15) 1px 1px 2px 0;
}

#main-nav-check:checked~.mobile-nav ul.menu ul.subshow li a {
    line-height: 2.5em;
    border-width: 1px 0 0 0;
    transition: all .2s ease;
    height: auto;
    width: 100%
  }

#header-container #header .header-links>ul>li a {
    color: #58595b;
}

.homepage .box,
.homepage .wrapper {
  border: 1px solid #006e90;
  border-width: 0 0 0 4px;
}

#topmenu {
  background: #006e90;
}

.account-masthead {
  background-image: none;
  background: #006e90;
}

#footer {
  background: #006e90;
}

.account-masthead .account ul li a {
  color: rgb(255, 255, 255, .5);
}

.search-form .search-input-group button:hover i {
  color: #000000;
}

.toggle-menu label,
.mobile-nav {
  background: #006e90;
}

.mobile-nav ul.menu ul.sub-menu li {
  background: #00648c;
}

.mobile-nav ul.menu ul.shareicons {
  background: #006e90;
}

.mobile-nav ul.menu li a,
#main-nav-check:checked~.mobile-nav ul.menu li a {
  border-color: #187794;
}

#header-container #header .menu>li>a::after {
background:rgb(185, 214, 242);
}
```

# Enable Google Analytics
edit the production.ini file currently in the volume.
```bash
  export VOL_CKAN_CONFIG=`sudo docker volume inspect docker_ckan_config | jq -r -c '.[] | .Mountpoint'`
  sudo nano $VOL_CKAN_CONFIG/production.ini
```

uncomment the google analytics id config and update to your id

replace
```bash
  # googleanalytics.ids = UA-1234567890000-1
```
with
```bash
  googleanalytics.ids = [your Tracking IDs here seperated by spaces]
```

---

# Troubleshooting

Issues building/starting CKAN:

Try manually pulling the images first e.g.:

```bash
  sudo docker pull --disable-content-trust clementmouchet/datapusher
  sudo docker pull --disable-content-trust redis:latest
```

Sometimes the containers start in the wrong order. This often results in strange sql errors in the db logs. If this happens you can manually start the containers by first building then using docker-compose up

```bash
  sudo docker-compose build
  sudo docker-compose up -d db
  sudo docker-compose up -d solr redis
  sudo docker-compose up -d ckan
  sudo docker-compose up -d datapusher
  sudo docker-compose up -d ckan_gather_harvester ckan_fetch_harvester ckan_run_harvester
```

if you need to change the production.ini in the repo and rebuild then you may need to delete the volume first. volume does not update during dockerfile run if it already exists.

```bash
  sudo docker-compose down
  sudo docker volume rm docker_ckan_config
```

update ckan/contrib/docker/production.ini

```bash
  export VOL_CKAN_CONFIG=`sudo docker volume inspect docker_ckan_config | jq -r -c '.[] | .Mountpoint'`
  sudo nano $VOL_CKAN_CONFIG/production.ini
```

on windows edit the production.ini file and copy it to the volume
```bash
  docker cp production.ini ckan:/etc/ckan/
```

Is ckan running? Check container is running and view logs

```bash
  sudo docker ps | grep ckan
  sudo docker-compose logs -f ckan
```

if container isn’t running its probably because the db didn’t build in time. restart…

```bash
  sudo docker-compose restart ckan
```

Connect to container as root to debug

```bash
  sudo docker exec -u root -it ckan /bin/bash -c "export TERM=xterm; exec bash"
```

If you rebuilt the ckan container and no records are showing up, you need to reindex the records.

```bash
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan search-index rebuild --config=/etc/ckan/production.ini
```

you have done several builds of ckan and now you are running out of hard drive space? With ckan running you can clean up docker images, containers, volumes, cache etc.

```bash
  sudo docker system prune -a
  sudo docker volume prune
```

or remove only the images you want with

```bash
	sudo docker image ls
	sudo docker rmi [image name]
```

When building ckan, in windows, you get the error `standard_init_linux.go:207: exec user process caused "no such file or directory"`
  delete c:/user/[your username]/lock.gitconfig
Then change git line end characters to unix/linux style ones
  git config --global core.eol lf
  git config --global core.autocrlf input
Delete and re clone the ckan repo. You may want to backup config files first.

#### When changing harvester config it does not take affect

If you edit a harvester config and then reharvest the existing harvester will continue to use the in memory harvester config. To solve this you can either restart the harvester docker containers or reindex the harvesters

```bash
sudo docker-compose restart ckan_run_harvester ckan_fetch_harvester ckan_gather_harvester
```
or
```bash
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckanext-harvest harvester reindex --config=/etc/ckan/production.ini
```

#### When creating organizations or updating admin config settings you get a 500 Internal Server Error

This can be caused by ckan not having permissions to write to the internal storage of the ckan container. This should be setup during the build process. You can debug this by setting debug = true in the production.ini file. No error messages will be reported in the ckan logs for this issue without turning on debug.

To fix change the owner of the ckan storage folder and its children

```bash
  sudo docker exec -u root -it ckan /bin/bash -c "export TERM=xterm; exec bash"
  chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH
  exit
```

#### Build fails with 'Temporary failure resolving...' errors

Likely the issue is that docker is passing the wrong DNS lookup addresses to the
containers on build. See issue this issue on stack overflow https://stackoverflow.com/a/45644890
for a solution.

#### Saving the admin config via the gui causes an internal server errors

To diagnose issue turn on debugging in the production.ini file ad restart ckan. The problem is likely caused by file permissions or a missing upload directory. Change file permissions using chown or create folder as as needed. Exact paths will be reported in ckan error log.

- view ckan error log: `docker-compose logs -f --tail 100 ckan`
- create upload folder: `sudo mkdir $VOL_CKAN_STIRAGE/storage/upload`
- change file permissions: `sudo chown 900:900 -R $VOL_CKAN_HOME $VOL_CKAN_STORAGE`

### if while starting ckan you get the error "from osgeo import ogr ImportError: No module named osgeo"
This issue also applies to "ImportError: No module named urllib3.contrib" errors or any python module which you know is installed but is not found when starting ckan

You have re-build ckan after upgrading to a version that uses glad and ogr but have not recreated the docker_ckan_home volume. Delete the volume and restart ckan.

```bash
cd ~/ckan/contrib/docker
sudo docker-compose down
sudo docker volume rm docker_ckan_home
sudo docker-compose up -d
```

You may get a file permissions error after the new volume is created. reset permissions to resolve

```bash
cd ~/ckan/contrib/docker
sudo chown 900:900 -R $VOL_CKAN_HOME/venv/src/
sudo docker-compose up -d
```

---
# Update solr schema

This method uses dockers copy command to copy the new schema file into a running
solr container

```bash
cd ~/ckan
sudo docker cp ~/ckan/ckan/config/solr/schema.xml solr:/opt/solr/server/solr/ckan/conf
```

restart solr container

```bash
cd ~/ckan/contrib/docker
sudo docker-compose restart solr
```

rebuild search index

```bash
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan search-index rebuild --config=/etc/ckan/production.ini
```

# Update CKAN
If you need to update CKAN to a new version you can either remove the docker_ckan_home volume or update the volume with the new ckan core files. After which you need to rebuild the CKAN image and any docker containers based on that image. If you are working with a live / production system the preferred method is to update the volume and rebuild which will result in the least amount of down time.

update local repo
```bash
cd ~/ckan
git pull
```

Then copy updated ckan core files into the volume

```bash
cd ~/ckan
sudo cp -r . $VOL_CKAN_HOME/venv/src/ckan
```

update permissions (optional but recommended)

```bash
sudo chown 900:900 -R $VOL_CKAN_HOME/venv/src/
```
or on windows run the command directly in the ckan container

```bash
sudo docker exec -it ckan chown 900:900 -R $CKAN_HOME
```

Now rebuild the CKAN docker image

```bash
cd ~/ckan/contrib/docker
sudo docker-compose build ckan
```

update affected containers.

```bash
cd ~/ckan/contrib/docker
sudo docker-compose up -d
```

# Update CKAN extensions

enable volume environment variables to make accessing the volumes easier

```bash
export VOL_CKAN_HOME=`sudo docker volume inspect docker_ckan_home | jq -r -c '.[] | .Mountpoint'`
export VOL_CKAN_CONFIG=`sudo docker volume inspect docker_ckan_config | jq -r -c '.[] | .Mountpoint'`
export VOL_CKAN_STORAGE=`sudo docker volume inspect docker_ckan_storage | jq -r -c '.[] | .Mountpoint'`
echo $VOL_CKAN_HOME
echo $VOL_CKAN_CONFIG
echo $VOL_CKAN_STORAGE
```

update submodules

```bash
cd ~/ckan
git pull
git submodule init
git submodule sync
git submodule update
```

copy updated extension code to the volumes

```bash
cd ~/ckan/contrib/docker
sudo cp -r src/ckanext-cioos_theme/ $VOL_CKAN_HOME/venv/src/
sudo cp -R src/ckanext-googleanalyticsbasic $VOL_CKAN_HOME/venv/src/
sudo cp -r src/ckanext-cioos_harvest/ $VOL_CKAN_HOME/venv/src/
sudo cp -r src/ckanext-harvest/ $VOL_CKAN_HOME/venv/src/
sudo cp -r src/ckanext-spatial/ $VOL_CKAN_HOME/venv/src/
sudo cp -r src/pycsw/ $VOL_CKAN_HOME/venv/src/
sudo cp -r src/ckanext-scheming/ $VOL_CKAN_HOME/venv/src/
sudo cp -r src/ckanext-repeating/ $VOL_CKAN_HOME/venv/src/
sudo cp -r src/ckanext-composite/ $VOL_CKAN_HOME/venv/src/
sudo cp -r src/ckanext-fluent/ $VOL_CKAN_HOME/venv/src/
sudo cp -r src/ckanext-dcat/ $VOL_CKAN_HOME/venv/src/
sudo cp -r src/ckanext-geoview/ $VOL_CKAN_HOME/venv/src/
sudo cp src/cioos-siooc-schema/cioos-siooc_schema.json $VOL_CKAN_HOME/venv/src/ckanext-scheming/ckanext/scheming/cioos_siooc_schema.json
sudo cp src/cioos-siooc-schema/organization.json $VOL_CKAN_HOME/venv/src/ckanext-scheming/ckanext/scheming/organization.json
sudo cp src/cioos-siooc-schema/ckan_license.json $VOL_CKAN_HOME/venv/src/ckan/contrib/docker/src/cioos-siooc-schema/ckan_license.json
```

Exporting volumes on windows does not work so another option for copying files to the volumes is to use the `docker cp` command. You must know the path of the named volume in the container you are connecting to and the container must be running for this to work

```bash
cd ~/ckan/contrib/docker
docker cp -r src/ckanext-cioos_theme/ ckan:/usr/lib/ckan/venv/src/
docker cp -r src/ckanext-cioos_harvest/ ckan:/usr/lib/ckan/venv/src/
docker cp -r src/ckanext-harvest/ ckan:/usr/lib/ckan/venv/src/
docker cp -r src/ckanext-spatial/ ckan:/usr/lib/ckan/venv/src/
docker cp -r src/pycsw/ ckan:/usr/lib/ckan/venv/src/
docker cp -r src/ckanext-scheming/ ckan:/usr/lib/ckan/venv/src/
docker cp -r src/ckanext-repeating/ ckan:/usr/lib/ckan/venv/src/
docker cp -r src/ckanext-composite/ ckan:/usr/lib/ckan/venv/src/
docker cp -r src/ckanext-fluent/ ckan:/usr/lib/ckan/venv/src/
docker cp -r src/ckanext-dcat/ ckan:/usr/lib/ckan/venv/src/
docker cp -r src/ckanext-geoview/ ckan:/usr/lib/ckan/venv/src/
docker cp src/cioos-siooc-schema/cioos-siooc_schema.json ckan:/usr/lib/ckan/venv/src/ckanext-scheming/ckanext/scheming/cioos_siooc_schema.json
docker cp src/cioos-siooc-schema/organization.json ckan:/usr/lib/ckan/venv/src/ckanext-scheming/ckanext/scheming/organization.json
```

update permissions (optional)

```bash
sudo chown 900:900 -R $VOL_CKAN_HOME/venv/src/
```
or on windows run the command directly in the ckan container

```bash
docker exec -u root -it ckan chown 900:900 -R /usr/lib/ckan
```

restart the container affected by the change. If changing html files you may not need to restart anything

```bash
cd ~/ckan/contrib/docker
sudo docker-compose restart ckan
sudo docker-compose restart ckan_run_harvester ckan_fetch_harvester ckan_gather_harvester
```

# Other helpfull commands

### update a system file in a running container
The easiest way is with the docker copy command. For example to update the crontab of the ckan_run_harvester containers you first copy the file to the container:

```base
cd ~/ckan/contrib/docker
sudo docker cp ./crontab ckan_run_harvester:/etc/cron.d/crontab
```

Then update the crontab in the container by connecting to it's bash shell and running the crontab commands

```base
sudo docker exec -u root -it ckan_run_harvester /bin/bash -c "export TERM=xterm; exec bash"
chown root:root /etc/cron.d/crontab
chmod 0644 /etc/cron.d/crontab
/usr/bin/crontab /etc/cron.d/crontab
exit
```

In this example the entrypoint file for this container also copies the file over from the volume so you should update the file in the volume as well so that when the container is restarted the correct file contents is used.
```base
cd ~/ckan/contrib/docker
sudo cp -r ./crontab $VOL_CKAN_HOME/venv/src/ckan/contrib/docker/crontab
```

### Set timezone

timedatectl
ls -l /etc/localtime
timedatectl list-timezones
sudo timedatectl set-timezone UTC
sudo timedatectl set-timezone America/Vancouver


### flush email notifications
sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan post -c /etc/ckan/production.ini /api/action/send_email_notifications

### get public ip of server
```bash
curl ifconfig.me
```

### update language translation files

Build translation file
```bash
pip install babel
cd ~/ckan/contrib/docker/src/ckanext-cioos_theme
python setup.py compile_catalog --locale fr
```

Copy to volume
```bash
cd ~/ckan/contrib/docker
sudo cp -r src/ckanext-cioos_theme/ $VOL_CKAN_HOME/venv/src/
```

### add dhcp entries to docker container
edit docker-compose.xml
```bash
cd ~/ckan/contrib/docker
nano docker-compose.yml
```

add extra hosts entrie to any services. In this example we add a hosts entrie
for test.ckan.org to the ckan_gather_harvester container. this will map the
domain name to the local docker network.
```yml
services:
  ckan_gather_harvester:
    extra_hosts:
      - "test.ckan.org:172.17.0.1"
```

you can examine the hosts file in the container using
```bash
sudo docker exec -u root -it ckan_gather_harvester cat /etc/hosts
``



## build project using docker hub images

edit .env file and change compose file setting
```bash
COMPOSE_FILE=docker-cloud.yml
```

edit docker-cloud.yml to use correct image. If the CKAN_TAG variable is set in
the .env file then docker compose will use that setting by default. The default
setting for this variable is 'latest'. To change to a differente image tag you
can change the setting in your .env file or overwrite at continer launch using
a shell environment variable. For eample to use the PR37 tag of the cioos ckan
image you would use the following command
```bash
export CKAN_TAG=PR37; docker-compose up -d
or
sudo CKAN_TAG=PR37 docker-compose up -d
```

If changing in .env file then you can start the containers normally
```bash
sudo docker-compose up -d
```

### reindex if project was already installed / running

sudo docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan search-index rebuild --config=/etc/ckan/production.ini
sudo docker exec -it ckan /usr/local/bin/ckaext-harvest harvester reindex --config=/etc/ckan/production.ini


```
