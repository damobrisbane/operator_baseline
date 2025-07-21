#!/bin/bash

#
# Syntax for [baseline](./scripts/baseline.sh) and [cut](./scripts/cut.sh) is similar and when cutting a new baseline they should share the same _pullspec_ folder over the scripts execution.
# 
# ```
# 
# > # baseline.sh
# >
# > DATESTAMP=20250707
# > CATALOG_LOCATION=reg.dmz.lan/baseline
# >
# > POD_RUNNER=/usr/bin/docker ./scripts/baseline.sh $DATESTAMP $CATALOG_LOCATION pullspec/json1
# 
# Image reg.dmz.lan/baseline/20250707/redhat-operator-index:v4.16 already exists, not downloading again..
# Tagging reg.dmz.lan/baseline/20250707/redhat-operator-index:v4.16
#

######################################################################################################
### FUNCTIONS
######################################################################################################

_f_help_exit() {
  echo -ne "\n[DEBUG=<level>] ./scripts/baseline.sh <DATESTAMP> <REG_LOCATION> <CUTSPEC FOLDER>||<STDIN>\n\n"
  exit
}


######################################################################################################
### CODE
######################################################################################################

# GLOBAL PARAMETERS
#
_PODMAN_BIN=${PODMAN_BIN:-/usr/bin/podman}
_SKIP_IMAGE_PULL=${SKIP_IMAGE_PULL:-}
_SKIP_PUSH=${SKIP_PUSH:-}
_AUTHFILE=${AUTHFILE:-}
_YQ_BIN=${YQ_BIN:-/usr/local/bin/yq}       # https://github.com/mikefarah/yq

# LOCAL PARAMETERS
#
_ARGS=($@)

if [[ ${#_ARGS[@]} -ne 3 ]]; then
  echo -ne "\nIncorrect arguments, exiting. Need:\n\n"
  echo -ne "./bashline.sh <DATESTAMP> <REG_LOCATION> <PULLSPEC>\n\n"
  echo -ne "<PULLSPEC> can be a folder or stdin\n\n"
  exit
fi

_DATESTAMP=${_ARGS[0]}
_REG_LOCATION=${_ARGS[1]}
_CUTSPEC=${_ARGS[2]:-}


DEBUGID=$(dirname ${BASH_SOURCE})

source $(dirname ${BASH_SOURCE})/lib/utility.sh
source $(dirname ${BASH_SOURCE})/lib/container.sh
source $(dirname ${BASH_SOURCE})/lib/cutspec.sh

_f_ndjson_cutspecs _NDJSON_CUTSPEC $_CUTSPEC

if [[ ${#_NDJSON_CUTSPEC[@]} -eq 0 ]]; then
  echo -ne "\nNo cut specification has been generated, exiting..\n" && _f_help_exit
fi

_log 3 "(baseline.sh) _NDJSON_CUTSPEC: (${#_NDJSON_CUTSPEC[@]}) ${_NDJSON_CUTSPEC[@]}"

for _J_CUTSPEC in ${_NDJSON_CUTSPEC[@]}; do

  declare -A A1
  declare L1

  _f_catalog_baseline _J_CUTSPEC _CATALOG_UPSTREAM 

  # catalog_baseline: registry.redhat.io/redhat/redhat-operator-index:v4.18 
  # targetCatalog: reg.dmz.lan/baseline/20250709/redhat-operator-index:v4.18

  _NAMETAG=$(basename $_CATALOG_UPSTREAM)
  _CATALOG_TARGET=$_REG_LOCATION/$_DATESTAMP/${_NAMETAG}

  read _INDEX_LOCATION _INDEX_NAME _TAG <<<$(_f_indexname_tag $_CATALOG_UPSTREAM)
 
  _CATALOG_BASELINE=$_REG_LOCATION/$_DATESTAMP/${_NAMETAG}

  _log 2 "(baseline.sh) _CATALOG_BASELINE: $_CATALOG_BASELINE"

  _log 1 "(baseline.sh) _f_get_image $_INDEX_LOCATION $_TAG $_CATALOG_UPSTREAM"
  _f_get_image $_INDEX_LOCATION $_TAG $_CATALOG_UPSTREAM

  _f_pod_tag $_CATALOG_UPSTREAM $_CATALOG_BASELINE

  [[ -z $_SKIP_PUSH ]] && _f_pod_push $_CATALOG_BASELINE

done

echo
