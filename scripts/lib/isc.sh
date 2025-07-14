#!/bin/bash

# Generate ImageSetConfiguration
#
# ./scripts/gen_isc.sh $CATALOG $FP_BASELINE
#

_DP_SCRIPT=$(dirname ${BASH_SOURCE[0]})
_FP_TMPL=$_DP_SCRIPT/../template/isc-operator.json

gen_isc() {
  #
  # gen_isc _J_PKGS_CUT $_CATALOG_BASELINE $_CATALOG_TARGET $_TARGET_TAG 1>&2
  #
  # gen_isc _J_PKGS_CUT reg.dmz.lan/baseline/20250705/original/certified-operator-index:v4.16 reg.dmz.lan/baseline/20250705/certified-operator-index:v4.16-cut v4:16-cut
  #
  # Globals:
  #
  # _TEMPLATE
  #

  local -n _J_PKGS_CUT_1998=$1
  local _DATESTAMP=$2
  export CATALOG=$3
  local _TARGET_CATALOG=$4
  export TARGET_TAG=$5      # ISC v1 only

  read _INDEX_LOCATION _INDEX_NAME _TAG <<<$(_f_indexname_tag $_TARGET_CATALOG)
  export TARGET_CATALOG=${_INDEX_LOCATION}

  export STORAGE_CONFIG_URL=$(_f_map_storage_config_url $TARGET_CATALOG)/metadata/$_DATESTAMP/$(_f_map_target_name $TARGET_CATALOG):$TARGET_TAG

  local _DP_SCRIPT=$(dirname ${BASH_SOURCE[0]})
  local _FP_TMPL=$_DP_SCRIPT/../template/${_TEMPLATE}

  export PKG_CHANNELS=$(jq -c . <<<$_J_PKGS_CUT_1998)

  jq -c . <<<$(envsubst <<<$(cat $_FP_TMPL))

}
