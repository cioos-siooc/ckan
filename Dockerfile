# See CKAN docs on installation from Docker Compose on usage
FROM debian:stretch
MAINTAINER Open Knowledge

# Install required system packages
RUN apt-get -q -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
    && apt-get -q -y install \
        python-dev \
        python-pip \
        python-virtualenv \
        python-wheel \
        python-lxml \
        python-owslib \
        libpq-dev \
        zlib1g-dev \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        postgresql-client \
        build-essential \
        git-core \
        vim \
        wget \
        python-factory-boy \
        python-mock \
        supervisor \
        cron \
        libsaxonb-java \
        gdal-bin \
        libgdal-dev\
        python3-gdal \
        python-gdal \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal
RUN export C_INCLUDE_PATH=/usr/include/gdal

# Define environment variables
ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_VENV $CKAN_HOME/venv
ENV CKAN_CONFIG /etc/ckan
ENV CKAN_STORAGE_PATH=/var/lib/ckan

# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# Create ckan user
RUN useradd -r -u 900 -m -c "ckan account" -d $CKAN_HOME -s /bin/false ckan

# Setup virtual environment for CKAN
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH && \
    virtualenv $CKAN_VENV && \
    ln -s $CKAN_VENV/bin/pip /usr/local/bin/ckan-pip &&\
    ln -s $CKAN_VENV/bin/paster /usr/local/bin/ckan-paster

# Setup CKAN
ADD . $CKAN_VENV/src/ckan/
COPY ./contrib/docker/production.ini $CKAN_CONFIG/production.ini
COPY ./contrib/docker/who.ini $CKAN_VENV/src/ckan/ckan/config/who.ini
RUN ckan-pip install -U pip && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirement-setuptools.txt && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirements.txt && \
    ckan-pip install -e $CKAN_VENV/src/ckan/ && \
    ln -s $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/ckan-entrypoint.sh /ckan-entrypoint.sh && \
    chmod +x /ckan-entrypoint.sh && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/ckan-harvester-entrypoint.sh /ckan-harvester-entrypoint.sh && \
    chmod +x /ckan-harvester-entrypoint.sh && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/ckan-run-harvester-entrypoint.sh /ckan-run-harvester-entrypoint.sh && \
    chmod +x /ckan-run-harvester-entrypoint.sh && \
    chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH

# Install needed libraries
RUN ckan-pip install factory_boy
RUN ckan-pip install mock
RUN ckan-pip install urllib3
RUN ckan-pip install --global-option=build_ext --global-option="-I/usr/include/gdal" GDAL==2.1.0

# for debugging
RUN ckan-pip install flask_debugtoolbar

# Copy extensions into container
WORKDIR $CKAN_VENV/src
COPY ./contrib/docker/src/pycsw $CKAN_VENV/src/pycsw
COPY ./contrib/docker/pycsw/pycsw.cfg $CKAN_VENV/src/pycsw/default.cfg
COPY ./contrib/docker/src/ckanext-harvest $CKAN_VENV/src/ckanext-harvest
COPY ./contrib/docker/src/ckanext-spatial $CKAN_VENV/src/ckanext-spatial
COPY ./contrib/docker/src/ckanext-cioos_theme $CKAN_VENV/src/ckanext-cioos_theme
COPY ./contrib/docker/src/ckanext-cioos_harvest $CKAN_VENV/src/ckanext-cioos_harvest
COPY ./contrib/docker/src/ckanext-scheming $CKAN_VENV/src/ckanext-scheming
COPY ./contrib/docker/src/ckanext-composite $CKAN_VENV/src/ckanext-composite
COPY ./contrib/docker/src/ckanext-repeating $CKAN_VENV/src/ckanext-repeating
COPY ./contrib/docker/src/ckanext-fluent $CKAN_VENV/src/ckanext-fluent
COPY ./contrib/docker/src/ckanext-googleanalyticsbasic $CKAN_VENV/src/ckanext-googleanalyticsbasic
COPY ./contrib/docker/src/ckanext-dcat $CKAN_VENV/src/ckanext-dcat
COPY ./contrib/docker/src/cioos-siooc-schema/cioos-siooc_schema.json $CKAN_VENV/src/ckanext-scheming/ckanext/scheming/cioos_siooc_schema.json
COPY ./contrib/docker/src/cioos-siooc-schema/organization.json $CKAN_VENV/src/ckanext-scheming/ckanext/scheming/organization.json
RUN  chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH

# Install Extensions
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src && ckan-pip install -e pycsw"
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src && ckan-pip install -r pycsw/requirements.txt"
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/pycsw && python setup.py build && python setup.py install && python setup.py develop"

RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src && ckan-pip install -r ckanext-harvest/pip-requirements.txt"
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-harvest && python setup.py install && python setup.py develop"

RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src && ckan-pip install -r ckanext-spatial/pip-requirements.txt"
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-spatial && python setup.py install && python setup.py develop"

# add simlink so ckan spatial can find pycsw
RUN ln -s $CKAN_VENV/src/pycsw/pycsw $CKAN_VENV/src/ckanext-spatial/pycsw

RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-cioos_theme && python setup.py install && python setup.py develop"
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-cioos_harvest && python setup.py install && python setup.py develop"
#RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-doi && python setup.py install && python setup.py develop"

RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src && ckan-pip install -r ckanext-scheming/requirements.txt"
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-scheming && python setup.py install && python setup.py develop"
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-repeating && python setup.py install && python setup.py develop"
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-composite && python setup.py install && python setup.py develop"
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-fluent && python setup.py install && python setup.py develop"

RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-googleanalyticsbasic && python setup.py install && python setup.py develop"

RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src && ckan-pip install -r ckanext-dcat/requirements.txt"
RUN /bin/bash -c "source $CKAN_VENV/bin/activate && cd $CKAN_VENV/src/ckanext-dcat && python setup.py install&& python setup.py develop"

RUN  chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH

ENTRYPOINT ["/ckan-entrypoint.sh"]

USER ckan
EXPOSE 5000

CMD ["ckan-paster","serve","/etc/ckan/production.ini"]
