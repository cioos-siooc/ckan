#!/bin/bash

# CKAN utility functions and environment variables
# To get started, source this file and then run ckan_utils_list

CKAN_IMAGE_NAME="ckan"
DOCKER_CMD="docker" # or "sudo docker"
DOCKER_COMPOSE_CMD="docker compose" # or "sudo docker-compose"
EDIT_CMD="vim" # or nano
CKAN_PRODUCTION_INI="$CKAN_PRODUCTION_INI"
#CIOOS_NATIONAL_CATALOGUE="https://catalogue.cioos.ca"
CIOOS_NATIONAL_CATALOGUE="https://cioos-national-ckan.preprod.ogsl.ca" # dev

export CKAN_DOCKER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export CKAN_BASE=$(readlink -f ${CKAN_DOCKER}/../../)
export VOL_CKAN_HOME=`$DOCKER_CMD volume inspect docker_ckan_home | jq -r -c '.[] | .Mountpoint'`
export VOL_CKAN_CONFIG=`$DOCKER_CMD volume inspect docker_ckan_config | jq -r -c '.[] | .Mountpoint'`
export VOL_CKAN_STORAGE=`$DOCKER_CMD volume inspect docker_ckan_storage | jq -r -c '.[] | .Mountpoint'`



# List all the available ckan_ utility functions
ckan_utils_list() {
    compgen -A function ckan_
    echo "Run 'type <function name>' for function definition each utility listed above."
}

ckan_variables() {
    echo "CKAN_BASE $CKAN_BASE"
    echo "CKAN_DOCKER: $CKAN_DOCKER"
    echo "VOL_CKAN_HOME: $VOL_CKAN_HOME"
    echo "VOL_CKAN_CONFIG: $VOL_CKAN_CONFIG"
    echo "VOL_CKAN_STORAGE: $VOL_CKAN_STORAGE"
}

ckan_ps() {
    pushd $CKAN_DOCKER
    $DOCKER_COMPOSE_CMD ps
    popd
}

ckan_logs() {
    $DOCKER_CMD logs ckan
}

ckan_stop() {
    pushd $CKAN_DOCKER
    $DOCKER_COMPOSE_CMD stop ckan
    $DOCKER_COMPOSE_CMD stop ckan_gather_harvester
    $DOCKER_COMPOSE_CMD stop ckan_fetch_harvester
    $DOCKER_COMPOSE_CMD stop ckan_run_harvester
    popd
}

ckan_start() {
    pushd $CKAN_DOCKER
    $DOCKER_COMPOSE_CMD start ckan
    $DOCKER_COMPOSE_CMD start ckan_gather_harvester
    $DOCKER_COMPOSE_CMD start ckan_fetch_harvester
    $DOCKER_COMPOSE_CMD start ckan_run_harvester
    popd
}

ckan_restart() {
    pushd $CKAN_DOCKER
    $DOCKER_COMPOSE_CMD restart ckan
    popd    
}

ckan_down() {
    pushd $CKAN_DOCKER
    $DOCKER_COMPOSE_CMD down "$@"
    popd
}

ckan_up() {
    pushd $CKAN_DOCKER
    $DOCKER_COMPOSE_CMD up -d "$@"
    popd
}

ckan_perms() {
    sudo chown 900:900 -R $VOL_CKAN_HOME/venv/src/
}

ckan_reload() {
    bash $CKAN_BASE/ckan_reload_ckan.sh
}

# Run the CKAN command inside the container with arbitrary arguments
# Try ckan_ckan --help to get started
ckan_ckan() {
    $DOCKER_CMD exec -it $CKAN_IMAGE_NAME ckan -c $CKAN_PRODUCTION_INI "$@"
}

ckan_reindex() {
    $DOCKER_CMD exec -it $CKAN_IMAGE_NAME ckan -c $CKAN_PRODUCTION_INI search-index rebuild
}

ckan_create_admin() {
    $DOCKER_CMD exec -i $CKAN_IMAGE_NAME ckan -c $CKAN_PRODUCTION_INI sysadmin add admin
}

ckan_upgrade() {
    cd $CKAN_DOCKER
    $DOCKER_COMPOSE_CMD down
    # use down -v to remove all volumes in addition to containers
    git pull
    $DOCKER_COMPOSE_CMD pull
    $DOCKER_COMPOSE_CMD up -d --build
}

ckan_compile_css() {
    cd $CKAN_DOCKER/src/ckanext-cioos_theme/ckanext/cioos_theme/public/
    sass --update --style=compressed cioos_atlantic.scss:cioos_atlantic.css cioos_theme.scss:cioos_theme.css
    cd $CKAN_DOCKER
}

ckan_generate_config() {
    $DOCKER_CMD exec -it $CKAN_IMAGE_NAME ckan -c $CKAN_PRODUCTION_INI generate config /etc/ckan/production.gen.ini
    prod_gen=$CKAN_DOCKER/production.gen.ini
    sudo cp $VOL_CKAN_CONFIG/production.gen.ini $prod_gen
    sudo chown $USER:$USER $prod_gen
    printf "Generated production.gen.ini in two locations:\n$CKAN_DOCKER/production.gen.ini\n$prod_gen\n"
    printf "Key values to pull into main production.ini before down/up:\n"
    grep "beaker.session.secret" $prod_gen
    grep "app_instance_uuid" $prod_gen
    grep "api_token.jwt.encode.secret" $prod_gen
    grep "api_token.jwt.decode.secret" $prod_gen
}

ckan_edit_production_ini() {
    sudo $EDIT_CMD $VOL_CKAN_CONFIG/production.ini
}

# install miniconda
# https://docs.conda.io/en/latest/miniconda.html
# create conda environment for ckanapi install, e.g.:
# $ conda create --name ckanapi -c conda-forge python=3 ckanapi
# $ conda activate ckanapi
ckan_api_setup() {
    echo "Setting up the URL, API_KEY, and conda environment for use with the CKAN API."
    echo "For more information, see:"
    echo "https://github.com/ckan/ckanapi"
    echo "https://docs.ckan.org/en/latest/api/index.html"
    echo ""
    if ! command -v conda &> /dev/null; then
        echo "The conda command is not in the current PATH"
        echo "Typically found at $HOME/miniconda3/etc/profile.d/conda.sh"
        # echo "Please enter the full path to your conda.sh"
        read -p "Please enter the full path to your conda.sh " CONDA_SH
        export CONDA_SH=$CONDA_SH
    else
        condaexe=`which conda`
        condabin=`dirname $condaexe`
        echo $condaexe
        echo $condabin
        pushd $condabin 
        cd ../etc/profile.d/
        CONDA_SH=`pwd`/conda.sh
        if [ -e $CONDA_SH ]; then
            export CONDA_SH=$CONDA_SH
        else
            echo "Error: could not determine location of conda.sh"
        fi
        popd
    fi
    if ! command -v ckanapi &> /dev/null; then
        echo "The ckanapi command is not in the current PATH"
        # echo "Which conda environment enables the ckanapi command?"
        read -p "Which conda environment enables the ckanapi command? " CONDA_ENV
    fi
    if [ -z $CKAN_URL ]; then
        # echo "What is the CKAN URL?"
        read -p "What is the CKAN URL? " CKAN_URL
        export CKAN_URL=$CKAN_URL
    fi
    if [ -z $CKAN_API_KEY ]; then
        # echo "What is the API key to use?"
        read -p "What is the API key to use? " CKAN_API_KEY
        export CKAN_API_KEY=$CKAN_API_KEY
    fi
}

ckan_api() {
    if [[ -z $CONDA_SH ]] || [[ -z $CONDA_ENV ]] || [[ -z $CKAN_URL ]] || [[ -z $CKAN_API_KEY ]]; then
        echo "A required environment variable for the CKAN API setup is not set."
        echo "Run the ckan_api_setup command to set these first."
    else
        source $CONDA_SH
        conda activate $CONDA_ENV
        ckanapi "$@" -r $CKAN_URL -a $CKAN_API_KEY 
    fi
}

# Download the given (ECCC) organization from national catalogue
ckan_dump_national_org() {
    if [ -z $1 ]; then
        echo "Error - usage: ckan_dump_national_org <organization short name>"
    else
        org_name=$1
        source $CONDA_SH
        conda activate $CONDA_ENV
        ckanapi dump organizations $org_name -O /tmp/${org_name}.jsonl -r $CIOOS_NATIONAL_CATALOGUE
        echo "Dumped national organization $org_name to /tmp/${org_name}.jsonl."
    fi
}

# Upload an organization .jsonl file to a CKAN you have API access to
ckan_load_organization() {
    if [ -z $1 ]; then
        echo "Error - usage: ckan_load_organization <path to organization jsonl file>"
    else
        org_file=$1
        ckan_api load organizations -I $org_file
    fi
}
