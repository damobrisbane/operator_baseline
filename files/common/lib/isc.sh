#!/bin/bash

# Generate ImageSetConfiguration
#
# ./scripts/gent_isp.sh $CATALOG $FP_BASELINE
#

_DP_SCRIPT=$(dirname ${BASH_SOURCE[0]})
_FP_TMPL=$_DP_SCRIPT/../template/isc-operator.json

gen_isc() {

  local -n _J0_BASELINE_1998=$1
  export CATALOG=$2
  export STORAGE_CONFIG_URL=$3
  export TARGET_NAME=$4
  export TARGET_TAG=$5

  #jq . <<<$_J0_BASELINE_1998
  #exit
  export PKG_CHANNELS=$(jq . <<<$_J0_BASELINE_1998)

  envsubst <<<$(cat $_FP_TMPL)
  #jq . <<<$(envsubst <<<$(cat $_FP_TMPL))

}
