#!/bin/bash
#
# Execution
#
# DATESTAMP=$(date +%Y%m%d)
#
# REG_LOCATION=reg.dmz.lan/baseline/$DATESTAMP
#
# cls;GEN_ISC=1 ./files/common/baseline.sh $DATESTAMP $REG_LOCATION $CUTSPEC_DIR
#
# where CUTSPEC_DIR is the root folder containing spec files for operator mirroring specs (yaml or json)
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
# CUTSPEC_DIR manifests expect one file == one catalog (unlike ImageSetConfiguration, which allows one file == multiple catalogs).
# 
# Mapping of "csvName to Version" is naive. Needs deeper introspection to be accurate against the csv version naming in the wild wrt plus (+) and minus (-).
# 
# Internal processing logic is done in json via bash/jq, yaml may be used only on input, output.
#

######################################################################################################
### FUNCTIONS
######################################################################################################

_f_help_exit() {
  echo -ne "\n[DEBUG=<level>] [BUNDLE=] [ALL_PKGS=] [GEN_ISC=] [ISC_FORMATS=] [REPORT_LOCATION=] ./scripts/cut.sh <DATESTAMP> <REG_LOCATION> <CUTSPEC FOLDER>||<STDIN>\n\n"
  exit
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

  local _FP_RPT=${_RPT_LOC}/pullspec-${_INDEX_NAME}-${_TAG}.json

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


f2() {
  echo f2
  exit
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
  local _CATALOG_BASELINE=$3
  local _CATALOG_TARGET=$4

  read _INDEX_LOCATION _INDEX_NAME _TAG <<<$(_f_indexname_tag $_CATALOG_TARGET)
  read _POD_LABEL _POD_NAME _PPROF_PORT _GRPC_PORT <<<$(_f_run_metadata $_CATALOG_TARGET)

  [[ -n $_GEN_ISC ]] && unset _BUNDLE

  local _GRPC_URL=$_GRPC_HOST:$_GRPC_PORT

  _log 2 "(cut.sh:f_main) if _f_run $_CATALOG_BASELINE $_POD_NAME $_POD_LABEL $_PPROF_PORT $_GRPC_PORT $_GRPC_URL; then"

  if _f_run $_CATALOG_BASELINE $_POD_NAME $_POD_LABEL $_PPROF_PORT $_GRPC_PORT $_GRPC_URL; then

     declare -A _A_PKGS_CH

    _L_BASELINE_PKGS=( $(_grpc_list_pkgs $_GRPC_URL) )

    if [[ -n $_ALL_PKGS ]]; then
      _L_PKGS=${_L_BASELINE_PKGS[@]}
      _L_PKGS_OUTER=()
      for i in ${_L_BASELINE_PKGS[@]}; do
        _A_PKGS_CH[$i]=
      done
    else
      _a_fsv_cut_pkg_ch _J_CUTSPEC_1999 _L_PKGS_INITIAL _A_PKGS_CH
      _intersection _L_PKGS_INITIAL _L_BASELINE_PKGS _L_PKGS _L_PKGS_OUTER
    fi

    _log 4 "_L_PKGS ${_L_PKGS[@]}"
    _log 4 "_L_PKGS_OUTER ${_L_PKGS_OUTER[@]}"

    _f_grpc_get_packages $_GRPC_URL _L_PKGS _A_PKGS_CH _J_PKGS_CUT

    _log 4 "_A_PKGS_CH ${!_A_PKGS_CH[@]}"
    _log 4 "_A_PKGS_CH ${_A_PKGS_CH[@]}"
      
#jq . <<<$_J_PKGS_CUT 1>&2

    if [[ -n $_GEN_ISC ]]; then

      _log 1 "(cut.sh:f_main) gen_isc _J_PKGS_CUT $_CATALOG_BASELINE $_CATALOG_TARGET"

      gen_isc _J_PKGS_CUT _J_ISC $_DATESTAMP_1999 $_CATALOG_BASELINE $_CATALOG_TARGET $_TAG

      _log 1 "(cut.sh:f_main) _f_output_isc _J_ISC $_DATESTAMP_1999 $_INDEX_NAME $_TAG"

      _f_output_isc _J_ISC $_DATESTAMP_1999 $_INDEX_NAME $_TAG

    else      

      _log 2 "(cut.sh:f_main) _f_output_api _J_PKGS_CUT $_DATESTAMP_1999 $_INDEX_NAME $_TAG"
      _f_output_api _J_PKGS_CUT $_DATESTAMP_1999 $_INDEX_NAME $_TAG

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
_TARGET_AS_BASELINE=${TARGET_AS_BASELINE:-}
_YQ_BIN=${YQ_BIN:-/usr/local/bin/yq}       # https://github.com/mikefarah/yq
_TEMPLATE=${TEMPLATE:-isc-operator-v2.json}
_SKIP_POD_RM=${SKIP_POD_RM:-}
_REPORT_LOCATION=${REPORT_LOCATION:-baseline}
_AUTHFILE=${AUTHFILE:-}
_GRPC_HOST=${GRPC_HOST:-localhost}
DEBUG=${DEBUG:-0}

#_YAML_XPATH=${YAML_XPATH:-".oc_mirror_operators[0].packages[]"}

# LOCAL PARAMETERS

_DATESTAMP=$1
_REG_LOCATION=$2
_CUTSPEC=${3:-}

if [[ $1 == -h ]]; then
  f_help && exit
fi

source $(dirname ${BASH_SOURCE})/lib/utility.sh
source $(dirname ${BASH_SOURCE})/lib/grpc.sh
source $(dirname ${BASH_SOURCE})/lib/container.sh
source $(dirname ${BASH_SOURCE})/lib/cutspec.sh
source $(dirname ${BASH_SOURCE})/lib/isc.sh

_NDJSON_CUTSPEC=( $(_f_ndjson_cutspecs $_CUTSPEC) )

if [[ ${#_NDJSON_CUTSPEC[@]} -eq 0 ]]; then
  echo -ne "\nNo cut specification has been generated, exiting..\n" && _f_help_exit
fi

_log 3 "(cut.sh) _NDJSON_CUTSPEC: (${#_NDJSON_CUTSPEC[@]}) ${_NDJSON_CUTSPEC[@]}"

for _J_CUTSPEC in ${_NDJSON_CUTSPEC[@]}; do

  declare -A A1
  declare L1

  _f_parse_cutspec $_J_CUTSPEC _CATALOG_BASELINE A1 L1

  # catalog_baseline: registry.redhat.io/redhat/redhat-operator-index:v4.18 
  # baselineCatalog: reg.dmz.lan/baseline/20250709/redhat-operator-index:v4.18
  # targetCatalog: reg.dmz.lan/baseline/20250709/redhat-operator-index:v4.18-cut

  _NAMETAG=$(basename $_CATALOG_BASELINE)

  [[ -n $_TARGET_AS_BASELINE ]] && _CATALOG_BASELINE=$_REG_LOCATION/$_DATESTAMP/${_NAMETAG}

  _CATALOG_TARGET=$_REG_LOCATION/$_DATESTAMP/${_NAMETAG}-cut

  _log 2 "(cut.sh) _CATALOG_BASELINE: $_CATALOG_BASELINE"
  _log 2 "(cut.sh) _CATALOG_TARGET: $_CATALOG_TARGET"

  _log 1 "(cut.sh) _f_main \$_J_CUTSPEC $_DATESTAMP $_CATALOG_BASELINE $_CATALOG_TARGET"
  _f_main $_J_CUTSPEC $_DATESTAMP $_CATALOG_BASELINE $_CATALOG_TARGET

done
