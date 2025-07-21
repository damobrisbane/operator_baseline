#!/bin/bash

# Generate ImageSetConfiguration
#
# ./scripts/gen_isc.sh $CATALOG $FP_BASELINE
#

_DP_SCRIPT=$(dirname ${BASH_SOURCE[0]})
_FP_TMPL=$_DP_SCRIPT/../template/isc-operator.json

gen_isc() {
  #
  # gen_isc _J_ISC _J_PKGS_CUT _J_PLATFORM_PASSTHROUGH _J_ADDITIONAL_IMG_PASSTHROUGH _J_HELM_PASSTHROUGH $_DATESTAMP_1999 $_CATALOG_BASELINE $_CATALOG_TARGET $_TAG
  # ie,
  # gen_isc _J_PKGS_CUT _J_PLATFORM_PASSTHROUGH _J_ADDITIONAL_IMG_PASSTHROUGH _J_HELM_PASSTHROUGH reg.dmz.lan/baseline/20250705/original/certified-operator-index:v4.16 reg.dmz.lan/baseline/20250705/certified-operator-index:v4.16-cut v4:16-cut
  # Globals:
  #
  # _TEMPLATE
  #

  local -n _J_ISC_1998=$1
  local -n _J_PKGS_CUT_1998=$2
  local -n _J_PLATFORM_PASSTHROUGH_1999=$3
  local -n _J_ADDITIONAL_IMG_PASSTHROUGH_1999=$4
  local -n _J_HELM_PASSTHROUGH_1999=$5
  local _DATESTAMP=$6
  export CATALOG=$7
  local _TARGET_CATALOG=$8
  export TARGET_TAG=$9      # ISC v1 only

  read _INDEX_LOCATION _INDEX_NAME _TAG <<<$(_f_indexname_tag $_TARGET_CATALOG)
  export TARGET_CATALOG=${_INDEX_LOCATION}

  export STORAGE_CONFIG_URL=$(_f_map_storage_config_url $TARGET_CATALOG)/metadata/$_DATESTAMP/$(_f_map_target_name $TARGET_CATALOG):$TARGET_TAG

  local _DP_SCRIPT=$(dirname ${BASH_SOURCE[0]})
  local _FP_TMPL=$_DP_SCRIPT/../template/${_TEMPLATE}
  export PLATFORM_PASSTHROUGH=$(jq -c . <<<$_J_PLATFORM_PASSTHROUGH_1999)
  export PKG_CHANNELS=$(jq -c . <<<$_J_PKGS_CUT_1998)
  export ADDITIONAL_IMG_PASSTHROUGH=$(jq -c . <<<$_J_ADDITIONAL_IMG_PASSTHROUGH_1999)
  export HELM_PASSTHROUGH=$(jq -c . <<<$_J_HELM_PASSTHROUGH_1999)

  _J_ISC_1998=$(jq -c . <<<$(envsubst <<<$(cat $_FP_TMPL)))

}

_f_output_isc() {

  # Globals:
  #
  # _ISC_FORMATS
  # _REPORT_LOCATION
  #
  #  _f_output_isc _J_ISC $_DATESTAMP_1999 $_INDEX_NAME $_TAG
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
  #  _f_output_api _J_PKGS_CUT $_DATESTAMP_1999 $_INDEX_NAME $_TAG
  #
 
  local -n _J_PKGS_CUT_1999=$1
  local _DATESTAMP=$2
  local INDEX_NAME=$3
  local TARGET_TAG=$4

  local _RPT_LOC=${_REPORT_LOCATION}/${_DATESTAMP}

  local _FP_RPT=${_RPT_LOC}/api-${_INDEX_NAME}-${_TAG}.json

  [[ ! -d $_RPT_LOC ]] && mkdir -p $_RPT_LOC

  #jq -c "{\"catalog_baseline\":\"$_CATALOG_BASELINE\",\"packages_cut\":.}" <<<$_J_PKGS_CUT_1999
  #jq "{\"catalog_baseline\":\"$_CATALOG_BASELINE\",\"packages_cut\":.}" <<<$_J_PKGS_CUT_1999 > $_FP_RPT

  jq -s ". as \$A|{\"catalog\":\"$_CATALOG_BASELINE\",\"packages\":\$A}" <<<$_J_PKGS_CUT_API
  jq -s ". as \$A|{\"catalog\":\"$_CATALOG_BASELINE\",\"packages\":\$A}" <<<$_J_PKGS_CUT_API > $_FP_RPT
}


