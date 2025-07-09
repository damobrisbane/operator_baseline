#!/bin/bash
#
# Execution
#
# DATESTAMP=$(date +%Y%m%d)
#
# REG_LOCATION=reg.dmz.lan/baseline/$DATESTAMP
#
# cls;GEN_ISC=1 ./files/common/baseline.sh $DATESTAMP $REG_LOCATION $PULLSPEC_DIR
#
# where PULLSPEC_DIR is the root folder containing spec files for operator mirroring specs (yaml or json)
#
# REG_LOCATION does not include date part. ie actual catalog location becomes <REG_LOCATION>/<DATESTAMP>. This full catalog location becomes the first part of the image url used for the index container (for local gprc queries) and also makes up part of the _CatalogName_ of an ImageSetConfiguration.
#
#  <parameter>[default]
#
#  BUNDLE [not set]
#  GEN_ISC [not set]
#  ISC_FORMATS [json,yaml]
#  YQ_BIN [/usr/local/bin/yq]
#  REPORT_LOCATION [baseline] # [if not set, stdout] will create folder, <baseline>/<d1>/... generated imagesetconfigs go here...
#
#  GEN_ISC=1 will force unset BUNDLE
#
# Limitations, caveats
# 
# PULLSPEC_DIR manifests expect one file == one catalog (unlike ImageSetConfiguration, which allows one file == multiple catalogs).
# 
# Mapping of "csvName to Version" is naive. Needs deeper introspection to be accurate against the csv version naming in the wild wrt plus (+) and minus (-).
# 
# Internal processing logic is done in json via bash/jq, yaml may be used only on input, output.
#

######################################################################################################
### FUNCTIONS
######################################################################################################

_f_output_isc() {

  # Globals:
  #
  # _ISC_FORMATS
  # _REPORT_LOCATION
  #
  #  _f_output_isc _J_ISC $_DATESTAMP $_INDEX_NAME $_TAG
  #
 
  local -n _J_ISC_1999=$1
  local _DATESTAMP=$2
  local _INDEX_NAME=$3
  local _TAG=$4

  local _RPT_LOC=${_REPORT_LOCATION}/${_DATESTAMP}

  [[ ! -d $_RPT_LOC ]] && mkdir -p $_RPT_LOC

  local _L_ISC_FORMATS=( $( tr , ' ' <<<$_ISC_FORMATS) )

  for _FMT in ${_L_ISC_FORMATS[@]}; do

    local _FP_RPT=${_RPT_LOC}/isc-${_INDEX_NAME}-${_TAG}.${_FMT}

    if [[ ( $_FMT == json ) || ( $_FMT == ndjson ) ]]; then
      yq -o json . <<<$_J_ISC_1999 > ${_FP_RPT}
      yq -o json . <<<$_J_ISC_1999
    else
      yq -p json . <<<$_J_ISC_1999 > ${_FP_RPT}
      yq -p json . <<<$_J_ISC_1999
    fi

  done      
}

_f_output_api() {

  # Globals:
  #
  # _REPORT_LOCATION
  #
  #  _f_output_api _J_PKGS $_REG_LOCATION $_DATESTAMP $_INDEX_NAME $_TAG
  #
 
  local -n _J_PKGS_1999=$1
  local _DATESTAMP=$3

  local _RPT_LOC=${_REPORT_LOCATION}/${_DATESTAMP}

  [[ ! -d $_RPT_LOC ]] && mkdir -p $_RPT_LOC

  yq -o json . <<<$_J_PKGS_1999

}


_f_run() {
  
  _IMG=$1
  _GRPC_URL=$2

  if _f_grpc_running index $_GRPC_URL; then
    if [[ -z $_SKIP_POD_RM ]]; then
      _f_pod_rm $(_f_pod_id index)
      AUTHFILE=${_AUTHFILE} _f_pod_run index $_IMG
      if [[ $? -ne 0 ]]; then
        echo "No running pod (index) found. Are args correct, exiting.." && return 1
      else
        echo "Waiting for pod $_IMG to start.." 
        sleep 4
      fi
    fi
  else
    AUTHFILE=${_AUTHFILE} _f_pod_run index $_IMG && sleep 4
    if [[ $? -ne 0 ]]; then
      echo "No running pod (index) found. Are args correct, exiting.." && return 1
    else
      echo "Waiting for pod $_IMG to start.." 
      sleep 4
    fi
  fi

  local _COUNTER=1

  while : ; do
    if _f_grpc_running index $_GRPC_URL; then
      break
    else
      [[ $_COUNTER -gt 10 ]] && echo "No running pod (index) found. Are args correct, exiting.." && return 1
    fi
    _COUNTER=$(( $_COUNTER + 1 ))
    _sleep $_COUNTER
  done
  return 0
  
}

_f_main() {
  #
  #  _f_main 20250707 redhat-operator-index v4.16
  #
  # _TAG wont be used on default ImagetSetConfiguration (v2) template
  #
  # Globals:
  #
  # _ALL_PKGS
  #
 
  local _DATESTAMP=$1
  local _INDEX_NAME=$2
  local _TAG=$3

  _log 1 Processing $_INDEX_NAME

  declare -A _A_FSV_PKG_CH

  _L_FSV_PKG=()
  if [[ -n $_ALL_PKGS ]]; then
    _L_FSV_PKG_CH=( ${_L_PKGS_PULLSPEC[@]} )
    _L_FSV_PKG=( ${_L_FSV_PKG_CH[@]} )
  else
    if [[ ( $_EXT == json ) || ( $_EXT == ndjson ) ]]; then
      _L_FSV_PKG_CH=$(_fsv_pullspec $_FP_PULLSPEC)
    else
      _L_FSV_PKG_CH=$(_fsv_pullspec_yaml $_FP_PULLSPEC)
    fi

    _fsv_firsts _L_FSV_PKG_CH _L_FSV_PKG

  fi

  _log 2 _L_FSV_PKG_CH: ${_L_FSV_PKG_CH[@]}
  _log 2 _L_FSV_PKG: ${_L_FSV_PKG[@]}

  _a_fsv_pkg_ch _L_FSV_PKG_CH _A_FSV_PKG_CH 

  _log 2 _A_FSV_PKG_CH: ${!_A_FSV_PKG_CH[@]}

  [[ -n $_GEN_ISC ]] && unset _BUNDLE

  #_J_BASELINE=$(generate_baseline _A_FSV_PKG_CH _L_FSV_PKG $_DATESTAMP $_REG_LOCATION $_INDEX_NAME)

  _J_PKGS=$(BUNDLE=$_BUNDLE get_packages _A_FSV_PKG_CH _L_FSV_PKG)

  _log 2 _J_PKGS: $(jq -c . <<<$_J_PKGS)

  if [[ -n $_GEN_ISC ]]; then

    _CATALOG=$_REG_LOCATION/$_DATESTAMP/$_INDEX_NAME:$_TAG
    _TARGET_CATALOG=$_REG_LOCATION/$_DATESTAMP/$_INDEX_NAME
    _TARGET_TAG=$_TAG-cut

    _log 2 gen_isc _J_PKGS $_CATALOG $_TARGET_CATALOG $_TARGET_TAG

    local _J_ISC=$(gen_isc _J_PKGS $_CATALOG $_TARGET_CATALOG $_TARGET_TAG)

    _f_output_isc _J_ISC $_DATESTAMP $_INDEX_NAME $_TAG

  else      
    _f_output_api _J_PKGS $_REG_LOCATION $_DATESTAMP $_INDEX_NAME $_TAG
  fi
}

######################################################################################################
### CODE
######################################################################################################

# GLOBAL PARAMETERS

_BUNDLE=${BUNDLE:-}
_ALL_PKGS=${ALL_PKGS:-}
_GEN_ISC=${GEN_ISC:-}
_ISC_FORMATS=${ISC_FORMATS:-yaml}
_YQ_BIN=${YQ_BIN:-/usr/local/bin/yq}       # https://github.com/mikefarah/yq
_TEMPLATE=${TEMPLATE:-isc-operator.json}
_SKIP_POD_RM=${SKIP_POD_RM:-}
_REPORT_LOCATION=${REPORT_LOCATION:-baseline}
_GRPC_URL=${GRPC_URL:-localhost:50051}

#_YAML_XPATH=${YAML_XPATH:-".oc_mirror_operators[0].packages[]"}

# LOCAL PARAMETERS

_DATESTAMP=$1
_REG_LOCATION=$2
_DP_PULLSPEC=${3:-}



if [[ $1 == -h ]]; then
  echo "[DEBUG=<level>] [BUNDLE=] [ALL_PKGS=] [GEN_ISC=] [ISC_FORMATS=] [REPORT_LOCATION=] ./scripts/baseline.sh <DATE> <REG_LOCATION> <PULLSPEC FOLDER" && exit
fi

source $(dirname ${BASH_SOURCE})/lib/utility.sh
source $(dirname ${BASH_SOURCE})/lib/grpc.sh
source $(dirname ${BASH_SOURCE})/lib/container.sh
source $(dirname ${BASH_SOURCE})/lib/pullspec.sh
source $(dirname ${BASH_SOURCE})/lib/isc.sh

for _FP_PULLSPEC in $(find $_DP_PULLSPEC -type f); do

  _FN_PULLSPEC=$(basename $_FP_PULLSPEC)

  _log 2 "read _INDEX_NAME _TAG _EXT <<<\$(_f_indexname_tag_ext $_FN_PULLSPEC)"

  read _INDEX_NAME _TAG _EXT <<<$(_f_indexname_tag_ext $_FN_PULLSPEC)

  # [n/a] catalog_upstream: registry.redhat.io/redhat/certified-operator-index:v4.16
  # catalog: reg.dmz.lan/baseline/20250705/certified-operator-index:v4.16
  # targetCatalog: reg.dmz.lan/baseline/20250705/certified-operator-index:v4.16-cut
 
  _CATALOG=$_REG_LOCATION/$_DATESTAMP/$_INDEX_NAME:$_TAG
  _TARGET_CATALOG=$_REG_LOCATION/$_DATESTAMP/$_INDEX_NAME:$_TAG-cut

  # Run up index image
  _f_run $_CATALOG $_GRPC_URL

  if [[ $? -eq 0 ]]; then

    _L_PKGS_PULLSPEC=($(_grpc_list_pkgs))
    _log 2 _L_PKGS_PULLSPEC: ${_L_PKGS[@]:0:3} ...

    _f_main $_DATESTAMP $_INDEX_NAME $_TAG

  fi
done
