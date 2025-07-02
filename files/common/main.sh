#!/bin/bash

process_catalog() {

  local _CATALOG_1999=$1
  local _FP_1999=$2

  _J0=$(BUNDLE=$_BUNDLE ./files/common/get_packages.sh $_FP_1999)

  if [[ -z $_GEN_ISC ]]; then
    jq . <<<$_J0
  else
    STORAGE_CONFIG_URL=$(_f_map_storage_config_url $IMG)/metadata/$(_f_map_target_name $IMG):latest-$_D1
    TARGET_NAME=$(_f_map_target_name $IMG)-$_D1
    FP_BASELINE=baseline/$_D1/$_CATALOG-$_TAG.ndjson
    _log 1 STORAGE_CONFIG_URL: $STORAGE_CONFIG_URL
    _log 1 TARGET_NAME: $TARGET_NAME
    _log 1 FP_BASELINE: $FP_BASELINE
    #./scripts/gen_isc.sh $STORAGE_CONFIG_URL $IMG $_J0
  fi
}

source $(dirname ${BASH_SOURCE})/lib/utility.sh
source $(dirname ${BASH_SOURCE})/lib/grpc.sh
source $(dirname ${BASH_SOURCE})/lib/filter.sh

_BUNDLE=${BUNDLE:-}
_GEN_ISC=${GEN_ISC:-}

_D1=$1
_IMG=$2
_DP_SPEC=${1:-}

for _FP in $(find $_DP_SPEC -type f -name "*.ndjson"); do

  read _CATALOG _EXT <<<$(tr . ' ' <<<$(basename $_FP))

  _log 1 Processing $_CATALOG

  process_catalog $_CATALOG $_FP

done

