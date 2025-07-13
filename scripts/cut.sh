#!/bin/bash
#
# Execution
#
# DATESTAMP=$(date +%Y%m%d)
#
# REG_LOCATION=reg.dmz.lan/baseline/$DATESTAMP
#
# cls;GEN_ISC=1 ./files/common/baseline.sh $DATESTAMP $REG_LOCATION $PULLSPEC_DIR
#
# where PULLSPEC_DIR is the root folder containing spec files for operator mirroring specs (yaml or json)
#
# REG_LOCATION does not include date part. ie actual catalog location becomes <REG_LOCATION>/<DATESTAMP>. This full catalog location becomes the first part of the image url used for the index container (for local gprc queries) and also makes up part of the _CatalogName_ of an ImageSetConfiguration.
#
#  <parameter>[default]
#
#  BUNDLE [not set]
#  GEN_ISC [not set]
#  ISC_FORMATS [json,yaml]
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

_f_help_exit() {
  echo -ne "\n[DEBUG=<level>] [BUNDLE=] [ALL_PKGS=] [GEN_ISC=] [ISC_FORMATS=] [REPORT_LOCATION=] ./scripts/baseline.sh <DATESTAMP> <REG_LOCATION> <PULLSPEC FOLDER>||<STDIN>\n\n"
  exit
}

_f_output_isc() {

  # Globals:
  #
  # _ISC_FORMATS
  # _REPORT_LOCATION
  #
  #  _f_output_isc _J_ISC $_DATESTAMP $_INDEX_NAME $_TAG
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
  #  _f_output_api _J_PKGS_CUT $_DATESTAMP_1999 $_TARGET_INDEX_NAME $_TARGET_TAG
  #
 
  local -n _J_PKGS_CUT_1999=$1
  local _DATESTAMP=$2
  local TARGET_INDEX_NAME=$3
  local TARGET_TAG=$4

  local _RPT_LOC=${_REPORT_LOCATION}/${_DATESTAMP}

  local _FP_RPT=${_RPT_LOC}/pullspec-${_TARGET_INDEX_NAME}-${_TARGET_TAG}.json

  [[ ! -d $_RPT_LOC ]] && mkdir -p $_RPT_LOC

  #yq -o json . <<<$_J_PKGS_CUT_1999

  jq -c "{\"catalog_baseline\":\"$_CATALOG_BASELINE\",\"packages_cut\":.}" <<<$_J_PKGS_CUT_1999
  jq "{\"catalog_baseline\":\"$_CATALOG_BASELINE\",\"packages_cut\":.}" <<<$_J_PKGS_CUT_1999 > $_FP_RPT

}

_f_output_pullspec() {

  # Globals:
  #
  # _REPORT_LOCATION
  #
  #  _f_output_api _J_PKGS_CUT $_DATESTAMP $_INDEX_NAME $_TAG
  #
 
  local -n _J_PKGS_CUT_1999=$1
  local _DATESTAMP=$3

  local _RPT_LOC=${_REPORT_LOCATION}/${_DATESTAMP}

  [[ ! -d $_RPT_LOC ]] && mkdir -p $_RPT_LOC

  #yq -o json . <<<$_J_PKGS_CUT_1999
  jq -c <<<$_J_PKGS_CUT_1999

}


_f_main() {
  #
  #  _f_main $_J_CUTSPEC $_DATESTAMP $_CATALOG_BASELINE $_CATALOG_TARGET
  #
  #  _f_main {"catalog_baseline":"registry.redhat.io/redhat/redhat-operator-index:v4.18","packages_cut":{"advanced-cluster-management":["stable"],"xxxx":[],"yyy":["s1","s2"]}} 20250705
  #
  # _TAG wont be used on default ImagetSetConfiguration (v2) template
  #
  # Globals:
  #
  # _ALL_PKGS
  #
  #

  local _J_CUTSPEC_1999=$1
  local _DATESTAMP_1999=$2

  read _TARGET_INDEX_NAME _TARGET_TAG _POD_LABEL _POD_NAME _PPROF_PORT _GRPC_PORT <<<$(_f_indexname_tag $_CATALOG_TARGET)

  [[ -n $_GEN_ISC ]] && unset _BUNDLE

  local _GRPC_URL=$_GRPC_HOST:$_GRPC_PORT

  # Run up index image
  #_log 2 "(cut.sh) _f_run $_CATALOG_BASELINE $_GRPC_URL"

  _log 2 "(cut.sh:f_main) if _f_run $_CATALOG_BASELINE $_POD_NAME $_POD_LABEL $_PPROF_PORT $_GRPC_PORT $_GRPC_URL; then"

  if _f_run $_CATALOG_BASELINE $_POD_NAME $_POD_LABEL $_PPROF_PORT $_GRPC_PORT $_GRPC_URL; then

    _log 2 "(cut.sh:f_main) _L_BASELINE_PKGS=( $(_grpc_list_pkgs $_GRPC_URL) )"

    _L_BASELINE_PKGS=( $(_grpc_list_pkgs $_GRPC_URL) )

    _log 3 "(cut.sh:f_main) _L_BASELINE_PKGS: ${_L_BASELINE_PKGS[@]:0:3} ..."

    declare -A _A_FSV_CUT_PKG_CH
    local _L_FSV_CUT_PKG=()
    local _L_FSV_CUT_PKG_ERROR=()

    _log 2 "(cut.sh:f_main) _ALL_PKGS=$_ALL_PKGS _a_fsv_cut_pkg_ch _L_BASELINE_PKGS _A_FSV_CUT_PKG_CH _L_FSV_CUT_PKG _L_FSV_CUT_PKG_ERROR \$_J_CUTSPEC_1999"

    _ALL_PKGS=$_ALL_PKGS _a_fsv_cut_pkg_ch _L_BASELINE_PKGS _A_FSV_CUT_PKG_CH _L_FSV_CUT_PKG _L_FSV_CUT_PKG_ERROR $_J_CUTSPEC_1999 

    _log 4 "(cut.sh:f_main) _A_FSV_CUT_PKG_CH: ${#_A_FSV_CUT_PKG_CH[@]}"
    _log 4 "(cut.sh:f_main) _A_FSV_CUT_PKG_CH: ${!_A_FSV_CUT_PKG_CH[@]}"
    _log 4 "(cut.sh:f_main) _A_FSV_CUT_PKG_CH: ${_A_FSV_CUT_PKG_CH[@]}"

    _log 3 "(cut.sh:f_main) _L_FSV_CUT_PKG: ${_L_FSV_CUT_PKG[@]}"

    _log 3 "(cut.sh:f_main) _L_FSV_CUT_PKG_ERROR: ${_L_FSV_CUT_PKG_ERROR[@]}"

    _log 2 "(cut.sh:f_main) _J_PKGS_CUT=\$(_BUNDLE=$_BUNDLE _ALL_PKGS=$_ALL_PKGS _f_grpc_get_packages $_GRPC_URL _A_FSV_CUT_PKG_CH _L_FSV_CUT_PKG)"

    _J_PKGS_CUT=$(_BUNDLE=$_BUNDLE _ALL_PKGS=$_ALL_PKGS _f_grpc_get_packages $_GRPC_URL _A_FSV_CUT_PKG_CH _L_FSV_CUT_PKG)

    _log 2 "(cut.sh:f_main) _J_PKGS_CUT: $(jq -c . <<<$_J_PKGS_CUT)"

    if [[ -n $_GEN_ISC ]]; then

      _log 1 "(cut.sh:f_main) gen_isc _J_PKGS_CUT $_CATALOG_BASELINE $_CATALOG_TARGET"

      local _J_ISC=$(gen_isc _J_PKGS_CUT $_DATESTAMP_1999 $_CATALOG_BASELINE $_CATALOG_TARGET $_TARGET_TAG)

      _log 1 "(cut.sh:f_main) _f_output_isc _J_ISC $_DATESTAMP_1999 $_TARGET_INDEX_NAME $_TARGET_TAG"

      _f_output_isc _J_ISC $_DATESTAMP_1999 $_TARGET_INDEX_NAME $_TARGET_TAG

    else      

      _log 2 "(cut.sh:f_main) _f_output_api _J_PKGS_CUT $_DATESTAMP_1999 $_TARGET_INDEX_NAME $_TARGET_TAG"
      _f_output_api _J_PKGS_CUT $_DATESTAMP_1999 $_TARGET_INDEX_NAME $_TARGET_TAG

    fi

  else
    echo "Issue running $_CATALOG_BASELINE $_POD_NAME $_POD_LABEL $_PPROF_PORT $_GRPC_URL; skipping.."
  fi
}

######################################################################################################
### CODE
######################################################################################################

# GLOBAL PARAMETERS

_PODMAN_BIN=${PODMAN_BIN:-/usr/bin/podman}
_BUNDLE=${BUNDLE:-}
_ALL_PKGS=${ALL_PKGS:-}
_GEN_ISC=${GEN_ISC:-}
_GEN_CUTSPEC=${GEN_CUTSPEC:-}
_ISC_FORMATS=${ISC_FORMATS:-yaml}
_YQ_BIN=${YQ_BIN:-/usr/local/bin/yq}       # https://github.com/mikefarah/yq
_TEMPLATE=${TEMPLATE:-isc-operator.json}
_SKIP_POD_RM=${SKIP_POD_RM:-}
_REPORT_LOCATION=${REPORT_LOCATION:-baseline}
_AUTHFILE=${AUTHFILE:-}
_GRPC_HOST=${GRPC_HOST:-localhost}
DEBUG=${DEBUG:-0}

#_YAML_XPATH=${YAML_XPATH:-".oc_mirror_operators[0].packages[]"}

# LOCAL PARAMETERS

_DATESTAMP=$1
_REG_LOCATION=$2
_PULLSPEC=${3:-}

if [[ $1 == -h ]]; then
  f_help && exit
fi

source $(dirname ${BASH_SOURCE})/lib/utility.sh
source $(dirname ${BASH_SOURCE})/lib/grpc.sh
source $(dirname ${BASH_SOURCE})/lib/container.sh
source $(dirname ${BASH_SOURCE})/lib/cutspec.sh
source $(dirname ${BASH_SOURCE})/lib/isc.sh

_L_CUTSPEC=( $(_f_parse_input $_PULLSPEC) )

if [[ ${#_L_CUTSPEC[@]} -eq 0 ]]; then
  echo -ne "\nNo cut specification has been generated, exiting..\n" && _f_help_exit
fi

_log 3 "(cut.sh) _L_CUTSPEC: (${#_L_CUTSPEC[@]}) ${_L_CUTSPEC[@]}"

for _J_CUTSPEC in ${_L_CUTSPEC[@]}; do

  declare -A A1
  declare L1

  _f_baseline_cut $_J_CUTSPEC _CATALOG_BASELINE A1 L1

  # catalog_upstream: registry.redhat.io/redhat/redhat-operator-index:v4.18 
  # baselineCatalog: reg.dmz.lan/baseline/20250709/redhat-operator-index:v4.18
  # targetCatalog: reg.dmz.lan/baseline/20250709/redhat-operator-index:v4.18-cut
 
  _NAMETAG=$(basename $_CATALOG_BASELINE)

  _CATALOG_TARGET=$_REG_LOCATION/$_DATESTAMP/${_NAMETAG}-cut

  _log 2 "(cut.sh) _CATALOG_BASELINE: $_CATALOG_BASELINE"
  _log 2 "(cut.sh) _CATALOG_TARGET: $_CATALOG_TARGET"

  _log 2 "(cut.sh) _f_main $_J_CUTSPEC $_DATESTAMP $_CATALOG_BASELINE $_CATALOG_TARGET"
  _f_main $_J_CUTSPEC $_DATESTAMP $_CATALOG_BASELINE $_CATALOG_TARGET

done
