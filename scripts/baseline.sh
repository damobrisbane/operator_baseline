#!/bin/bash

# GLOBAL PARAMETERS
#
_POD_RUNNER=${POD_RUNNER:-/usr/bin/podman}
_L_CATALOGS=( $(tr , ' ' <<<${L_CATALOGS:-redhat,certified,community} ) )
_TAG=${TAG:-v4.16}
_PUSH=${PUSH:-}

# LOCAL PARAMETERS
#
_DATESTAMP=$1
_CATALOG_LOCATION=$2
_DP_PULLSPEC=${3:-}

DEBUGID=$(dirname ${BASH_SOURCE})

source $(dirname ${BASH_SOURCE})/lib/utility.sh
source $(dirname ${BASH_SOURCE})/lib/container.sh

for _FP_PULLSPEC in $(find $_DP_PULLSPEC -type f); do

  _FN_PULLSPEC=$(basename $_FP_PULLSPEC)

  _log 2 "read _INDEX_NAME _TAG _EXT <<<\$(_f_indexname_tag_ext $_FN_PULLSPEC)"

  read _INDEX_NAME _TAG _EXT <<<$(_f_indexname_tag_ext $_FN_PULLSPEC)

  # catalog_upstream: registry.redhat.io/redhat/certified-operator-index:v4.16
  # catalog: reg.dmz.lan/baseline/20250705/certified-operator-index:v4.16
  # [n/a] targetCatalog: reg.dmz.lan/baseline/20250705/certified-operator-index:v4.16-cut
 
  _CATALOG_UPSTREAM=registry.redhat.io/redhat/$_INDEX_NAME:$_TAG
  _CATALOG=$_CATALOG_LOCATION/$_DATESTAMP/$_INDEX_NAME:$_TAG

  _log 2 "($DEBUGID:010) _CATALOG: $_CATALOG"

  if _f_image_exists $_DATESTAMP $_INDEX_NAME $_TAG; then
    echo "Image $_CATALOG already exists, not downloading again.."
  else
    echo "Downloading $_CATALOG_UPSTREAM.."
    $_POD_RUNNER pull $_CATALOG_UPSTREAM
  fi

  echo Tagging $_CATALOG
  $_POD_RUNNER tag $_CATALOG_UPSTREAM $_CATALOG

  if [[ -n $_PUSH ]]; then
    $_POD_RUNNER push --remove-signatures $_CATALOG
    echo Pushed $_CATALOG
  fi

done
