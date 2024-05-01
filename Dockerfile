#------------------------------------------------------------------------------#
FROM ckan/ckan-base:2.9 as base
#------------------------------------------------------------------------------#

ARG PROJ_VERSION=9.0.0

RUN --mount=type=cache,target=/root/.cache/pip apk add --no-cache .build-deps libc-dev geos geos-dev gdal gdal-dev \
    proj proj-util proj-dev gcc g++ libffi-dev musl-dev py3-gdal python3-dev \
    libstdc++ build-base \
    # Setup build env for PROJ
    wget curl unzip make libtool autoconf automake pkgconfig g++ sqlite sqlite-dev \
    # For PROJ and GDAL
    linux-headers curl-dev tiff-dev zlib-dev zstd-dev lz4-dev libarchive-dev \
    libjpeg-turbo-dev libpng-dev libwebp-dev expat-dev postgresql-dev openjpeg-dev \
    # For cryptography
    gcc musl-dev python3-dev libffi-dev openssl-dev cargo pkgconfig py3-urllib3 py3-cryptography \
    && pip install cryptography \
    # Build PROJ
    && mkdir proj \
    && apk add --no-cache cmake \
    && wget -q https://github.com/OSGeo/PROJ/archive/${PROJ_VERSION}.tar.gz -O - \
    | tar xz -C proj --strip-components=1 \
    && cd proj \
    && cmake . \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DENABLE_IPO=ON \
    -DBUILD_TESTING=OFF \
    && make -j$(nproc) \
    && make install \
    && make install DESTDIR="/build_proj" \
    && cd .. \
    && rm -rf proj \
    && for i in /build_proj/usr/lib/*; do strip -s $i 2>/dev/null || /bin/true; done \
    && for i in /build_proj/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done \
    && apk del cmake \
    && pip3 install pyproj==3.6.1 --no-cache-dir \
    && pip3 install gdal==3.4.3 --no-cache-dir \
    && pip3 install ckanapi --no-cache-dir \
    && pip3 install -U requests[security] --no-cache-dir \
    # for debugging
    && pip3 install 'flask<=2.3.3' \
    && pip3 install flask_debugtoolbar --no-cache-dir \
    # clean up
    && apk del .build-deps

# Define environment variables
ENV APP_DIR=/srv/app
ENV SRC_DIR=/srv/app/src
ENV CKAN_INI=${APP_DIR}/ckan.ini
ENV PIP_SRC=${SRC_DIR}
ENV CKAN_STORAGE_PATH=/var/lib/ckan


# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# Setup virtual environment for CKAN
RUN ln -s SRC_DIR/ckan/bin/ckan /usr/local/bin/ckan

# Setup CKAN
ADD ./contrib/docker/who.ini $APP_DIR/who.ini

# Copy files to container
ADD ./contrib/docker/production.ini $CKAN_INI
ADD ./contrib/docker/crontab $SRC_DIR/ckan/contrib/docker/crontab
ADD ./contrib/docker/wait-for-postgres.sh /wait-for-postgres.sh

# Set file permissions
RUN chmod +x /wait-for-postgres.sh

# Copy extensions into container and Install
RUN  chown -R ckan:ckan $APP_DIR $CKAN_STORAGE_PATH

COPY ./contrib/docker/src/ckanext-dcat/requirements.txt $SRC_DIR/ckanext-dcat/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip cd $SRC_DIR && pip3 install -r ckanext-dcat/requirements.txt

COPY ./contrib/docker/src/ckanext-harvest/requirements.txt $SRC_DIR/ckanext-harvest/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip cd $SRC_DIR && pip3 install -r ckanext-harvest/requirements.txt

COPY ./contrib/docker/src/ckanext-spatial/requirements.txt $SRC_DIR/ckanext-spatial/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip cd $SRC_DIR && pip3 install -r ckanext-spatial/requirements.txt

COPY ./contrib/docker/src/ckanext-cioos_harvest/requirements.txt $SRC_DIR/ckanext-cioos_harvest/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip cd $SRC_DIR && pip3 install -r ckanext-cioos_harvest/requirements.txt

COPY ./contrib/docker/src/ckanext-cioos_theme/requirements.txt $SRC_DIR/ckanext-cioos_theme/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip cd $SRC_DIR && pip3 install -r ckanext-cioos_theme/requirements.txt


#------------------------------------------------------------------------------#
FROM base as extensions1
#------------------------------------------------------------------------------#
WORKDIR $SRC_DIR

COPY ./contrib/docker/src/ckanext-geoview $SRC_DIR/ckanext-geoview
RUN cd $SRC_DIR/ckanext-geoview && python3 setup.py install && python3 setup.py develop

COPY ./contrib/docker/src/ckanext-dcat $SRC_DIR/ckanext-dcat
RUN cd $SRC_DIR/ckanext-dcat && python3 setup.py install && python3 setup.py develop

# included in base image
RUN cd $SRC_DIR/ckanext-envvars && python3 setup.py install && python3 setup.py develop

WORKDIR $SRC_DIR
RUN rm -R ./ckan

WORKDIR /usr/lib/python3.9/site-packages/
RUN find . -maxdepth 1 ! -name 'ckanext*' ! -name '..' ! -name '.' ! -name 'easy-install.pth' | xargs rm -R; mv easy-install.pth easy-install-A.pth

#------------------------------------------------------------------------------#
FROM base as extensions2
#------------------------------------------------------------------------------#
WORKDIR $SRC_DIR

COPY ./contrib/docker/src/ckanext-scheming $SRC_DIR/ckanext-scheming
RUN cd $SRC_DIR/ckanext-scheming && python3 setup.py install && python3 setup.py develop

COPY ./contrib/docker/src/ckanext-fluent $SRC_DIR/ckanext-fluent
RUN cd $SRC_DIR/ckanext-fluent && python3 setup.py install && python3 setup.py develop

COPY ./contrib/docker/src/cioos-siooc-schema/cioos-siooc_schema.json  $SRC_DIR/ckanext-scheming/ckanext/scheming/cioos_siooc_schema.json
COPY ./contrib/docker/src/cioos-siooc-schema/organization.json $SRC_DIR/ckanext-scheming/ckanext/scheming/
COPY ./contrib/docker/src/cioos-siooc-schema/ckan_license.json $SRC_DIR/ckanext-scheming/ckanext/scheming/
COPY ./contrib/docker/src/cioos-siooc-schema/group.json $SRC_DIR/ckanext-scheming/ckanext/scheming/

WORKDIR $SRC_DIR
RUN rm -R ./ckan

WORKDIR /usr/lib/python3.9/site-packages/
RUN find . -maxdepth 1 ! -name 'ckanext*' ! -name '..' ! -name '.' ! -name 'easy-install.pth' | xargs rm -R; mv easy-install.pth easy-install-B.pth

#------------------------------------------------------------------------------#
FROM base as harvest_extensions
#------------------------------------------------------------------------------#
WORKDIR $SRC_DIR

COPY ./contrib/docker/src/ckanext-harvest $SRC_DIR/ckanext-harvest
RUN cd $SRC_DIR/ckanext-harvest && python3 setup.py install && python3 setup.py develop

COPY ./contrib/docker/src/ckanext-spatial $SRC_DIR/ckanext-spatial
RUN cd $SRC_DIR/ckanext-spatial && python3 setup.py install && python3 setup.py develop

WORKDIR $SRC_DIR
RUN rm -R ./ckan

WORKDIR /usr/lib/python3.9/site-packages/
RUN find . -maxdepth 1 ! -name 'ckanext*' ! -name '..' ! -name '.' ! -name 'easy-install.pth' | xargs rm -R; mv easy-install.pth easy-install-C.pth

#------------------------------------------------------------------------------#
FROM base as cioos_extensions
#------------------------------------------------------------------------------#
WORKDIR $SRC_DIR
COPY ./contrib/docker/src/ckanext-cioos_harvest $SRC_DIR/ckanext-cioos_harvest
RUN cd $SRC_DIR/ckanext-cioos_harvest && python3 setup.py install && python3 setup.py develop

COPY ./contrib/docker/src/ckanext-cioos_theme $SRC_DIR/ckanext-cioos_theme
RUN cd $SRC_DIR/ckanext-cioos_theme  && python3 setup.py --help-commands  && python3 setup.py compile_catalog --locale fr && python3 setup.py install && python3 setup.py develop

WORKDIR $SRC_DIR
RUN rm -R ./ckan

WORKDIR /usr/lib/python3.9/site-packages/
RUN find . -maxdepth 1 ! -name 'ckanext*' ! -name '..' ! -name '.' ! -name 'easy-install.pth' | xargs rm -R; mv easy-install.pth easy-install-D.pth

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

RUN sort -u /usr/lib/python3.9/site-packages/easy-install-[ABCD].pth > /usr/lib/python3.9/site-packages/easy-install.pth

RUN mkdir -p $APP_DIR/logs
RUN touch "$APP_DIR/logs/ckan_access.log"
RUN touch "$APP_DIR/logs/ckan_default.log"

RUN chown -R 92:92 $APP_DIR $CKAN_STORAGE_PATH

WORKDIR $APP_DIR

# ENTRYPOINT ["/ckan-entrypoint.sh"]

USER ckan
EXPOSE 5000

CMD ["bash", "/wait-for-postgres.sh", "db", "ckan", "-c", "/srv/app/ckan.ini", "run", "--host", "0.0.0.0"]
