#!/bin/bash
#
# Execution
#
# D1=$(date +%Y%m%d)
# CATALOG_LOCATION=reg.dmz.lan/baseline/$D1
#
# cls;GEN_ISC=1 ./files/common/baseline.sh $D1 $CATALOG_LOCATION $PULLSPEC_DIR
#
# where PULLSPEC_DIR is the root folder containing spec files for operator mirroring specs (yaml or json)
#
# CATALOG_LOCATION does not include date part. ie actual catalog location becomes <CATALOG_LOCATION>/<D1>. This full catalog location becomes the first part of the image url used for the index container (for local gprc queries) and also makes up part of the _CatalogName_ of an ImageSetConfiguration.
#
#  <parameter>[default]
#
#  BUNDLE [not set]
#  GEN_ISC [not set]
#  FORMATS [json,yaml]
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

_f_output() {

  # Globals:
  #
  # _FORMATS
  # _REPORT_LOCATION
  #
  #  _f_output _J_ISC $_D1 $_INDEX_NAME $_TAG
  #
 
  local -n _J_ISC_1999=$1
  local _D1=$2
  local _INDEX_NAME=$3
  local _TAG=$4

  if [[ -n $_REPORT_LOCATION ]]; then

    local _RPT_LOC=${_REPORT_LOCATION}/${_D1}

    [[ ! -d $_RPT_LOC ]] && mkdir -p $_RPT_LOC

  fi    

  local _L_FORMATS=( $( tr , ' ' <<<$_FORMATS) )

  for _FMT in ${_L_FORMATS[@]}; do

    if [[ -n $_REPORT_LOCATION ]]; then

      local _FP_RPT=${_RPT_LOC}/isc-${_INDEX_NAME}-${_TAG}.${_FMT}

      if [[ ( $_FMT == json ) || ( $_FMT == ndjson ) ]]; then
        yq -o json . <<<$_J_ISC_1999 > ${_FP_RPT}
      else
        yq -p json . <<<$_J_ISC_1999 > ${_FP_RPT}
      fi

    else

      if [[ $_FMT == json ]]; then
        yq -o json . <<<$_J_ISC_1999
      else
        yq -p json . <<<$_J_ISC_1999
      fi

    fi
  done      
}

xgenerate_baseline()   {

  #_J_BASELINE=$(generate_baseline _A_FSV _L_FSV $_D1 $_CATALOG_LOCATION $_CATALOG_NAME)

  local -n _A_FSV_PKG_CH_1999=$1
  local -n _L_FSV_1999=$2   # _L_FSV only required for preserving order on associatve array, _A_FSV
  local _D1=$3
  local _CATALOG_LOCATION=$4
  local _CATALOG_NAME_1999=$5

  local _J_PKGS=$(BUNDLE=$_BUNDLE get_packages _A_FSV_PKG_CH_1999 _L_FSV_1999)

  _log 2 _J_PKGS: $(jq -c . <<<$_J_PKGS)

  jq -c . <<<$_J_PKGS

}

generate_isc() {
  #
  #  generate_isc _J_BASELINE 20250705 reg.dmz.lan/baseline certified-operator-index v4.16
  #

  local -n _J0_BASELINE_1999=$1
  local _D1=$2
  local _CATALOG_LOCATION=$3
  local _CATALOG_NAME=$4
  local _TAG=$5

  TARGET_NAME=$_CATALOG_LOCATION/$_D1/$_CATALOG_NAME:$_TAG
  #FP_BASELINE=baseline/$_D1/$_CATALOG_NAME-$_TAG.ndjson
  _log 2 STORAGE_CONFIG_URL: $STORAGE_CONFIG_URL
  _log 2 TARGET_NAME: $TARGET_NAME
  #_log 2 FP_BASELINE: $FP_BASELINE

  _CATALOG=$_CATALOG_LOCATION
  echo gen_isc _J0_BASELINE_1999 \$_CATALOG_LOCATION \$STORAGE_CONFIG_URL \$TARGET_NAME \$TARGET_TAG 1>&2
  echo gen_isc _J0_BASELINE_1999 $_CATALOG_LOCATION $STORAGE_CONFIG_URL $TARGET_NAME $TARGET_TAG 1>&2
  #gen_isc _J0_BASELINE_1999 $_CATALOG_LOCATION $STORAGE_CONFIG_URL $TARGET_NAME $TARGET_TAG

  local -n _J0_BASELINE_1998=$1
  export CATALOG=$2
  export STORAGE_CONFIG_URL=$3
  export TARGET_NAME=$4
  export TARGET_TAG=$5


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
 
  local _D1=$1
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

  #_J_BASELINE=$(generate_baseline _A_FSV_PKG_CH _L_FSV_PKG $_D1 $_CATALOG_LOCATION $_INDEX_NAME)

  _J_PKGS=$(BUNDLE=$_BUNDLE get_packages _A_FSV_PKG_CH _L_FSV_PKG)

  _log 2 _J_PKGS: $(jq -c . <<<$_J_PKGS)

  if [[ -n $_GEN_ISC ]]; then

    _CATALOG=$_CATALOG_LOCATION/$_D1/$_INDEX_NAME:$_TAG
    _TARGET_CATALOG=$_CATALOG_LOCATION/$_D1/$_INDEX_NAME:$_TAG-cut

    _log 2 gen_isc _J_PKGS $_CATALOG $_TARGET_CATALOG $_TAG

    local _J_ISC=$(gen_isc _J_PKGS $_CATALOG $_TARGET_CATALOG $_TAG)

    _f_output _J_ISC $_D1 $_INDEX_NAME $_TAG

  else      
    #jq . <<<$_J_BASELINE
    _f_output $_CATALOG_NAME $_J_BASELINE
  fi
}

######################################################################################################
### CODE
######################################################################################################

# GLOBAL PARAMETERS

_BUNDLE=${BUNDLE:-}
_ALL_PKGS=${ALL_PKGS:-}
_GEN_ISC=${GEN_ISC:-}
_FORMATS=${FORMATS:-yaml}
_YQ_BIN=${YQ_BIN:-/usr/local/bin/yq}       # https://github.com/mikefarah/yq
_REPORT_LOCATION=${REPORT_LOCATION:-}
_TEMPLATE=${TEMPLATE:-isc-operator.json}

#_YAML_XPATH=${YAML_XPATH:-".oc_mirror_operators[0].packages[]"}

# LOCAL PARAMETERS

_D1=$1
_CATALOG_LOCATION=$2
_DP_PULLSPEC=${3:-}

if [[ $1 == -h ]]; then
  echo "[DEBUG=<level>] [BUNDLE=] [ALL_PKGS=] [GEN_ISC=] [FORMATS=] [REPORT_LOCATION=] ./scripts/baseline.sh <DATE> <CATALOG_LOCATION> <PULLSPEC FOLDER" && exit
fi

source $(dirname ${BASH_SOURCE})/lib/utility.sh
source $(dirname ${BASH_SOURCE})/lib/grpc.sh
source $(dirname ${BASH_SOURCE})/lib/pullspec.sh
source $(dirname ${BASH_SOURCE})/lib/isc.sh

# Run up idex image
_L_PKGS_PULLSPEC=($(_grpc_list_pkgs))
_log 2 _L_PKGS_PULLSPEC: ${_L_PKGS[@]:0:3} ...

for _FP_PULLSPEC in $(find $_DP_PULLSPEC -type f); do

  _FN_PULLSPEC=$(basename $_FP_PULLSPEC)

  _log 2 "read _INDEX_NAME _TAG _EXT <<<\$(_f_indexname_tag_ext $_FN_PULLSPEC)"

  read _INDEX_NAME _TAG _EXT <<<$(_f_indexname_tag_ext $_FN_PULLSPEC)

  # [n/a] catalog_upstream: registry.redhat.io/redhat/certified-operator-index:v4.16
  # catalog: reg.dmz.lan/baseline/20250705/certified-operator-index:v4.16
  # targetCatalog: reg.dmz.lan/baseline/20250705/certified-operator-index:v4.16-cut
 
  _CATALOG=$_CATALOG_LOCATION/$_D1/$_INDEX_NAME:$_TAG
  _TARGET_CATALOG=$_CATALOG_LOCATION/$_D1/$_INDEX_NAME:$_TAG-cut

  _f_main $_D1 $_INDEX_NAME $_TAG

done
