# See CKAN docs on installation from Docker Compose on usage
#------------------------------------------------------------------------------#
# FROM debian:buster as prebase
# #------------------------------------------------------------------------------#
# MAINTAINER Open Knowledge

# # Install required system packages
# RUN apt-get -q -y update \
#     && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
#     && DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
#     python-dev \
#     python-pip \
#     python-virtualenv \
#     python-wheel \
#     python-lxml \
#     python-owslib \
#     python-gdal \
#     python3 \
#     python3-dev \
#     python3-pip \
#     python3-virtualenv \
#     python3-venv \
#     python3-wheel \
#     python3-owslib \
#     python3-gdal \
#     libpq-dev \
#     libxml2-dev \
#     libxslt-dev \
#     libgeos-dev \
#     libssl-dev \
#     libffi-dev \
#     postgresql-client \
#     build-essential \
#     gdal-bin \
#     libgdal-dev\
#     git-core \
#     vim \
#     wget \
#     python-factory-boy \
#     python-mock \
#     supervisor \
#     cron \
#     wait-for-it \
#     curl \
#     && DEBIAN_FRONTEND=noninteractive apt-get -q clean \
#     && rm -rf /var/lib/apt/lists/*

# remove curl for prodution image.

#------------------------------------------------------------------------------#
FROM ckan/ckan-base:2.9 as base
#------------------------------------------------------------------------------#

# RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal
# RUN export C_INCLUDE_PATH=/usr/include/gdal
RUN apk add --no-cache geos geos-dev gdal gdal-dev proj proj-dev proj-util musl-dev py3-gdal

# ENV PROJ_DIR=/usr

# Define environment variables
# ENV CKAN_HOME /srv/app/src
# ENV CKAN_VENV $CKAN_HOME/venv
# ENV CKAN_CONFIG /etc/ckan
# ENV CKAN_STORAGE_PATH=/var/lib/ckan

ENV APP_DIR=/srv/app
ENV SRC_DIR=/srv/app/src
ENV CKAN_INI=${APP_DIR}/ckan.ini
ENV PIP_SRC=${SRC_DIR}
ENV CKAN_STORAGE_PATH=/var/lib/ckan


# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# Create ckan user
#RUN useradd -r -u 900 -m -c "ckan account" -d $CKAN_HOME -s /bin/false ckan

# Setup virtual environment for CKAN
RUN ln -s SRC_DIR/ckan/bin/ckan /usr/local/bin/ckan

# Setup CKAN
# ADD ./bin/ $SRC_DIR/ckan/bin/
# ADD ./ckan/ $SRC_DIR/ckan/ckan/
# ADD ./ckanext/ $SRC_DIR/ckan/ckanext/
# ADD ./scripts/ $SRC_DIR/ckan/scripts/
#COPY ./*.py ./*.txt ./*.ini ./*.rst $SRC_DIR/ckan/
ADD ./contrib/docker/who.ini $APP_DIR/who.ini

RUN pip3 install wheel
# RUN ln -s $SRC_DIR/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini
# pip3 install pip==22.3.1 && \
#     pip3 install --upgrade --no-cache-dir -r $SRC_DIR/ckan/requirement-setuptools.txt && \
#     # pip3 install --upgrade --no-cache-dir -r $SRC_DIR/ckan/requirements-py2.txt && \
#     pip3 install --upgrade --no-cache-dir -r $SRC_DIR/ckan/requirements.txt && \
#     pip3 install -e $SRC_DIR/ckan/ && \


# Install needed libraries
RUN pip3 install factory_boy
RUN pip3 install mock
RUN pip3 install "urllib3>=1.26.14"
RUN pip3 install gdal==3.4.3 --no-cache-dir
RUN pip3 install ckanapi
RUN pip3 install -U requests[security] --no-cache

# for debugging
RUN pip3 install flask_debugtoolbar

# Copy files to container
ADD ./contrib/docker/production.ini $CKAN_INI
# ADD ./contrib/docker/ckan-entrypoint.sh /ckan-entrypoint.sh
# ADD ./contrib/docker/ckan-harvester-entrypoint.sh /ckan-harvester-entrypoint.sh
# ADD ./contrib/docker/ckan-run-harvester-entrypoint.sh /ckan-run-harvester-entrypoint.sh
ADD ./contrib/docker/crontab $SRC_DIR/ckan/contrib/docker/crontab
ADD ./contrib/docker/wait-for-postgres.sh /wait-for-postgres.sh

# Set file permissions
RUN chmod +x /wait-for-postgres.sh
# chmod +x /ckan-entrypoint.sh && \
#     chmod +x /ckan-harvester-entrypoint.sh && \
#     chmod +x /ckan-run-harvester-entrypoint.sh && \


# Copy extensions into container and Install
RUN  chown -R ckan:ckan $APP_DIR $CKAN_STORAGE_PATH

COPY ./contrib/docker/src/ckanext-dcat/requirements.txt $SRC_DIR/ckanext-dcat/requirements.txt
RUN /bin/bash -c "cd $SRC_DIR && pip3 install -r ckanext-dcat/requirements.txt"

COPY ./contrib/docker/src/ckanext-harvest/requirements.txt $SRC_DIR/ckanext-harvest/requirements.txt
RUN /bin/bash -c "cd $SRC_DIR && pip3 install -r ckanext-harvest/requirements.txt"

COPY ./contrib/docker/src/ckanext-spatial/requirements.txt $SRC_DIR/ckanext-spatial/requirements.txt
RUN /bin/bash -c "cd $SRC_DIR && pip3 install -r ckanext-spatial/requirements.txt"

# COPY ./contrib/docker/src/ckanext-scheming/requirements.txt $SRC_DIR/ckanext-scheming/requirements.txt
# RUN /bin/bash -c "cd $SRC_DIR && pip3 install -r ckanext-scheming/requirements.txt"

COPY ./contrib/docker/src/ckanext-cioos_theme/dev-requirements.txt $SRC_DIR/ckanext-cioos_theme/dev-requirements.txt
COPY ./contrib/docker/src/ckanext-cioos_theme/requirements.txt $SRC_DIR/ckanext-cioos_theme/requirements.txt
RUN /bin/bash -c "cd $SRC_DIR && pip3 install -r ckanext-cioos_theme/requirements.txt"
RUN /bin/bash -c "cd $SRC_DIR && pip3 install -r ckanext-cioos_theme/dev-requirements.txt"

#------------------------------------------------------------------------------#
FROM base as extensions1
#------------------------------------------------------------------------------#
WORKDIR $SRC_DIR

COPY ./contrib/docker/src/ckanext-geoview $SRC_DIR/ckanext-geoview
RUN /bin/bash -c "cd $SRC_DIR/ckanext-geoview && python3 setup.py install && python3 setup.py develop"

COPY ./contrib/docker/src/ckanext-dcat $SRC_DIR/ckanext-dcat
RUN /bin/bash -c "cd $SRC_DIR/ckanext-dcat && python3 setup.py install && python3 setup.py develop"

WORKDIR $SRC_DIR
RUN /bin/bash -c "rm -R ./ckan"

WORKDIR /usr/lib/python3.9/site-packages/
RUN /bin/bash -c "find . -maxdepth 1 ! -name 'ckanext*' ! -name '..' ! -name '.' ! -name 'easy-install.pth' | xargs rm -R; mv easy-install.pth easy-install-A.pth"

#------------------------------------------------------------------------------#
FROM base as extensions2
#------------------------------------------------------------------------------#
WORKDIR $SRC_DIR

COPY ./contrib/docker/src/ckanext-scheming $SRC_DIR/ckanext-scheming
RUN /bin/bash -c "cd $SRC_DIR/ckanext-scheming && python3 setup.py install && python3 setup.py develop"

COPY ./contrib/docker/src/ckanext-fluent $SRC_DIR/ckanext-fluent
RUN /bin/bash -c "cd $SRC_DIR/ckanext-fluent && python3 setup.py install && python3 setup.py develop"

COPY ./contrib/docker/src/cioos-siooc-schema/cioos-siooc_schema.json  $SRC_DIR/ckanext-scheming/ckanext/scheming/cioos_siooc_schema.json
COPY ./contrib/docker/src/cioos-siooc-schema/organization.json $SRC_DIR/ckanext-scheming/ckanext/scheming/
COPY ./contrib/docker/src/cioos-siooc-schema/ckan_license.json $SRC_DIR/ckanext-scheming/ckanext/scheming/
COPY ./contrib/docker/src/cioos-siooc-schema/group.json $SRC_DIR/ckanext-scheming/ckanext/scheming/

WORKDIR $SRC_DIR
RUN /bin/bash -c "rm -R ./ckan"

WORKDIR /usr/lib/python3.9/site-packages/
RUN /bin/bash -c "find . -maxdepth 1 ! -name 'ckanext*' ! -name '..' ! -name '.' ! -name 'easy-install.pth' | xargs rm -R; mv easy-install.pth easy-install-B.pth"

#------------------------------------------------------------------------------#
FROM base as harvest_extensions
#------------------------------------------------------------------------------#
WORKDIR $SRC_DIR

COPY ./contrib/docker/src/ckanext-harvest $SRC_DIR/ckanext-harvest
RUN /bin/bash -c "cd $SRC_DIR/ckanext-harvest && python3 setup.py install && python3 setup.py develop"

COPY ./contrib/docker/src/ckanext-spatial $SRC_DIR/ckanext-spatial
RUN /bin/bash -c "cd $SRC_DIR/ckanext-spatial && python3 setup.py install && python3 setup.py develop"

WORKDIR $SRC_DIR
RUN /bin/bash -c "rm -R ./ckan"

WORKDIR /usr/lib/python3.9/site-packages/
RUN /bin/bash -c "find . -maxdepth 1 ! -name 'ckanext*' ! -name '..' ! -name '.' ! -name 'easy-install.pth' | xargs rm -R; mv easy-install.pth easy-install-C.pth"

#------------------------------------------------------------------------------#
FROM base as cioos_extensions
#------------------------------------------------------------------------------#
WORKDIR $SRC_DIR
COPY ./contrib/docker/src/ckanext-cioos_harvest $SRC_DIR/ckanext-cioos_harvest
RUN /bin/bash -c "cd $SRC_DIR/ckanext-cioos_harvest && python3 setup.py install && python3 setup.py develop"

COPY ./contrib/docker/src/ckanext-cioos_theme $SRC_DIR/ckanext-cioos_theme
RUN /bin/bash -c "cd $SRC_DIR/ckanext-cioos_theme  && python3 setup.py --help-commands  && python3 setup.py compile_catalog --locale fr && python3 setup.py install && python3 setup.py develop"

WORKDIR $SRC_DIR
RUN /bin/bash -c "rm -R ./ckan"

WORKDIR /usr/lib/python3.9/site-packages/
RUN /bin/bash -c "find . -maxdepth 1 ! -name 'ckanext*' ! -name '..' ! -name '.' ! -name 'easy-install.pth' | xargs rm -R; mv easy-install.pth easy-install-D.pth"

#------------------------------------------------------------------------------#
FROM base
#------------------------------------------------------------------------------#
COPY --from=extensions1 $SRC_DIR/ $SRC_DIR/
COPY --from=extensions1 /usr/lib/python3.9/site-packages/ /usr/lib/python3.9/site-packages/

COPY --from=extensions2 $SRC_DIR/ $SRC_DIR/
COPY --from=extensions2 /usr/lib/python3.9/site-packages/ /usr/lib/python3.9/site-packages/

COPY --from=harvest_extensions $SRC_DIR/ $SRC_DIR/
COPY --from=harvest_extensions /usr/lib/python3.9/site-packages/ /usr/lib/python3.9/site-packages/

COPY --from=cioos_extensions $SRC_DIR/ $SRC_DIR/
COPY --from=cioos_extensions /usr/lib/python3.9/site-packages/ /usr/lib/python3.9/site-packages/

RUN /bin/bash -c "sort -u /usr/lib/python3.9/site-packages/easy-install-[ABCD].pth > /usr/lib/python3.9/site-packages/easy-install.pth"

RUN mkdir -p $APP_DIR/logs
RUN touch "$APP_DIR/logs/ckan_access.log"
RUN touch "$APP_DIR/logs/ckan_default.log"

RUN chown -R 92:92 $APP_DIR $CKAN_STORAGE_PATH

WORKDIR $APP_DIR

# ENTRYPOINT ["/ckan-entrypoint.sh"]

USER ckan
EXPOSE 5000

HEALTHCHECK --interval=60s --timeout=5s --retries=5 CMD curl --fail http://localhost:5000/api/3/action/status_show || exit 1

# CMD ["/srv/app/start_ckan.sh"]

CMD ["bash", "/wait-for-postgres.sh", "db", "ckan", "-c", "/srv/app/ckan.ini", "run", "--host", "0.0.0.0"]
