#!/bin/bash

generate_baseline() {

  local _D1=$2
  local _IMG=$3
  local _CATALOG_1999=$4

  #_J0=$(BUNDLE=$_BUNDLE ./files/common/get_packages.sh $_FP_1999)

  local -n _A_FSV_1999=$1
  
  local _J_PKGS=$(BUNDLE=$_BUNDLE get_packages _A_FSV_1999)

  _log 2 _J_PKGS: $(jq -c . <<<$_J_PKGS)

  jq -c . <<<$_J_PKGS
}

generate_isc() {

  local -n _J0_BASELINE_1999=$1
  local _D1=$2
  local _CATALOG=$3
  local _IMG=$4

  STORAGE_CONFIG_URL=$(_f_map_storage_config_url $_IMG)/metadata/$(_f_map_target_name $_IMG):latest-$_D1
  TARGET_NAME=$(_f_map_target_name $_IMG)-$_D1
  TARGET_TAG=$(_f_map_image_tag $_IMG)
  FP_BASELINE=baseline/$_D1/$_CATALOG-$_TAG.ndjson
  _log 2 STORAGE_CONFIG_URL: $STORAGE_CONFIG_URL
  _log 2 TARGET_NAME: $TARGET_NAME
  _log 2 TARGET_TAG: $TARGET_NAME
  _log 2 FP_BASELINE: $FP_BASELINE

  gen_isc _J0_BASELINE_1999 $_IMG $STORAGE_CONFIG_URL $TARGET_NAME $TARGET_TAG
}

source $(dirname ${BASH_SOURCE})/lib/utility.sh
source $(dirname ${BASH_SOURCE})/lib/grpc.sh
source $(dirname ${BASH_SOURCE})/lib/pullspec.sh
source $(dirname ${BASH_SOURCE})/lib/isc.sh

_BUNDLE=${BUNDLE:-}
_GEN_ISC=${GEN_ISC:-}

_D1=$1
_IMG=$2
_DP_PULLSPEC=${3:-}

# Run up idex image
_L_PKGS_PULLSPEC=($(_grpc_list_pkgs))
_log 2 _L_PKGS_PULLSPEC: ${_L_PKGS[@]:0:3} ...

for _FP_FILTER in $(find $_DP_PULLSPEC -type f); do

  _FN=$(basename $_FP_FILTER)
  _CATALOG=${_FN%.*}
  _EXT=${_FN##*.}

  _log 1 Processing $_CATALOG

  if [[ $_EXT == ndjson ]]; then
    _L_FSV=$(_fsv_filter $_FP_FILTER)
  else
    _L_FSV=$(_fsv_filter_yaml $_FP_FILTER)
  fi

  declare -A _A_FSV
  _a_pkg_fsv _L_FSV _A_FSV

  _log 2 _L_FSV: ${_L_FSV[@]}
  _log 2 _A_FSV: ${!_A_FSV[@]}

  [[ -n $_GEN_ISC ]] && unset _BUNDLE

  _J_BASELINE=$(generate_baseline _A_FSV $_D1 $_IMG $_CATALOG)

  if [[ -n $_GEN_ISC ]]; then
    jq . <<<$(generate_isc _J_BASELINE $_D1 $_CATALOG $_IMG)
  else      
    jq . <<<$_J_BASELINE
  fi

done

