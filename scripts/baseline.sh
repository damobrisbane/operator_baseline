#!/bin/bash

# GLOBAL PARAMETERS
#
_POD_BIN=${POD_BIN:-/usr/bin/podman}
_PUSH=${PUSH:-}

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
_PULLSPEC=${_ARGS[2]:-}

DEBUGID=$(dirname ${BASH_SOURCE})

source $(dirname ${BASH_SOURCE})/lib/utility.sh
source $(dirname ${BASH_SOURCE})/lib/container.sh
source $(dirname ${BASH_SOURCE})/lib/pullspec.sh

_L_SPECS_CUT=( $(_f_parse_input $_PULLSPEC) )

_log 3 "(baseline.sh) _L_SPECS_CUT: (${#_L_SPECS_CUT[@]}) ${_L_SPECS_CUT[@]}"

for _J_SPEC_CUT in ${_L_SPECS_CUT[@]}; do

  declare -A A1
  declare L1

  _f_baseline_cut $_J_SPEC_CUT _CATALOG_BASELINE A1 L1

  # catalog_upstream: registry.redhat.io/redhat/redhat-operator-index:v4.18 
  # targetCatalog: reg.dmz.lan/baseline/20250709/redhat-operator-index:v4.18-cut
 
  _NAMETAG=$(basename $_CATALOG_BASELINE)

  _CATALOG_TARGET=$_REG_LOCATION/$_DATESTAMP/${_NAMETAG}-cut

  _log 2 "(baseline.sh:010) _CATALOG_BASELINE: $_CATALOG_BASELINE"
  _log 2 "(baseline.sh:010) _CATALOG_TARGET: $_CATALOG_TARGET"

  _f_image_exists $_CATALOG_BASELINE

  _f_pod_tag $_CATALOG_BASELINE $_CATALOG_TARGET

  [[ -n $_PUSH ]] && _f_pod_push $_CATALOG_TARGET

done

echo
