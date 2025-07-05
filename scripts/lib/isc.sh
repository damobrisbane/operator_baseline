#!/bin/bash

# Generate ImageSetConfiguration
#
# ./scripts/gen_isc.sh $CATALOG $FP_BASELINE
#

_DP_SCRIPT=$(dirname ${BASH_SOURCE[0]})
_FP_TMPL=$_DP_SCRIPT/../template/isc-operator.json

gen_isc() {

  local -n _J0_BASELINE_1998=$1
  export CATALOG=$2
  export STORAGE_CONFIG_URL=$3
  export TARGET_NAME=$4
  export TARGET_TAG=$5

  export PKG_CHANNELS=$(jq . <<<$_J0_BASELINE_1998)

  jq -c . <<<$(envsubst <<<$(cat $_FP_TMPL))

}
