#!/bin/bash

# GLOBAL PARAMETERS
#
_POD_RUNNER=${POD_RUNNER:-/usr/bin/docker}
_L_CATALOGS=( $(tr , ' ' <<<${L_CATALOGS:-redhat,certified,community} ) )
_TAG=${TAG:-v4.16}

# LOCAL PARAMETERS
#
_D1=$1
_CATALOG_LOCATION=$2

for _CAT in ${_L_CATALOGS[@]}; do

  _CAT_UPSTREAM=registry.redhat.io/redhat/$_CAT-operator-index:$_TAG
  _CAT_TARGET=$_CATALOG_LOCATION/$_D1/$_CAT-operator-index:$_TAG

  #echo Downloading $_CAT_UPSTREAM.. 
  $_POD_RUNNER pull $_CAT_UPSTREAM 2>/dev/null 1>&2

  $_POD_RUNNER tag $_CAT_UPSTREAM $_CAT_TARGET 2>/dev/null 1>&2

  $_POD_RUNNER push $_CAT_TARGET 2>/dev/null 1>&2
  echo Pushed $_CAT_TARGET

done
