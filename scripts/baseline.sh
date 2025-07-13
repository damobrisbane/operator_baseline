#!/bin/bash

#
# Syntax for [baseline](./scripts/baseline.sh) and [cut](./scripts/cut.sh) is similar and when cutting a new baseline they should share the same _pullspec_ folder over the scripts execution.
# 
# ```
# 
# > # baseline.sh
# >
# > DATESTAMP=20250707
# > CATALOG_LOCATION=reg.dmz.lan/baseline
# >
# > POD_RUNNER=/usr/bin/docker ./scripts/baseline.sh $DATESTAMP $CATALOG_LOCATION pullspec/json1
# 
# Image reg.dmz.lan/baseline/20250707/redhat-operator-index:v4.16 already exists, not downloading again..
# Tagging reg.dmz.lan/baseline/20250707/redhat-operator-index:v4.16
#


# GLOBAL PARAMETERS
#
_PODMAN_BIN=${PODMAN_BIN:-/usr/bin/podman}
_PUSH=${PUSH:-}
_AUTHFILE=${AUTHFILE:-}

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
source $(dirname ${BASH_SOURCE})/lib/cutspec.sh

_L_CUTSPEC=( $(_f_parse_input $_PULLSPEC) )

_log 3 "(baseline.sh) _L_CUTSPEC: (${#_L_CUTSPEC[@]}) ${_L_CUTSPEC[@]}"

for _J_CUTSPEC in ${_L_CUTSPEC[@]}; do

  declare -A A1
  declare L1

  _f_baseline_cut $_J_CUTSPEC _CATALOG_BASELINE A1 L1

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
