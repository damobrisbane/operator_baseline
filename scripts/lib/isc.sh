#!/bin/bash

# Generate ImageSetConfiguration
#
# ./scripts/gen_isc.sh $CATALOG $FP_BASELINE
#

_DP_SCRIPT=$(dirname ${BASH_SOURCE[0]})
_FP_TMPL=$_DP_SCRIPT/../template/isc-operator.json

gen_isc() {
  #
  # gen_isc _J0_BASELINE_1999 $_CATALOG_NAME $_TARGET_CATALOG
  #
  # gen_isc _J0_BASELINE_1999 reg.dmz.lan/baseline/20250705/original/certified-operator-index:v4.16 reg.dmz.lan/baseline/20250705/certified-operator-index:v4.16
  #
  # Globals:
  #
  # _TEMPLATE
  #

  local -n _J0_BASELINE_1998=$1
  export CATALOG=$2
  export TARGET_CATALOG=$3
  export TARGET_TAG=$4      # ISC v1 only

  export STORAGE_CONFIG_URL=$(_f_map_storage_config_url $_TARGET_CATALOG)/metadata/$(_f_map_target_name $_TARGET_CATALOG):$TARGET_TAG-cut

  local _DP_SCRIPT=$(dirname ${BASH_SOURCE[0]})
  local _FP_TMPL=$_DP_SCRIPT/../template/${_TEMPLATE}

  export PKG_CHANNELS=$(jq -c . <<<$_J0_BASELINE_1998)

  jq -c . <<<$(envsubst <<<$(cat $_FP_TMPL))

}
