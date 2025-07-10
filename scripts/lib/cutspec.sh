#!/bin/bash

_fsv_splice0() {
  #
  # Needed to preserve ordering on bash associative arrays
  #
  # mcg-operator@stable-4.15@stable-4.16 odf-operator@stable-4.15@stable-4.16 node-healthcheck-operator@4.12-eus@4.14-eus@4.16-eus@4.18-eus@candidate@stable kubevirt-hyperconverged@candidate@dev-preview@stable odf-csi-addons-operator@stable-4.15@stable-4.16
  # >>>
  # mcg-operator odf-operator node-healthcheck-operator kubevirt-hyperconverged odf-csi-addons-operator
  #

  local -n _L=$1

  _L_FIRST_ELEMENTS=()
  for i in ${_L[@]}; do
    _L_FIRST_ELEMENTS+=( $(cut -d@ -f1 <<<$i) )
  done
  echo -ne ${_L_FIRST_ELEMENTS[@]}
}

_fsv_cut_json() {
  #
  # <PKG>@{@<CHANNEL>} <PKG>@{@<CHANNEL>}, ..
  #
  # Space delimited, @ field separated values, for shell script consumption
  #
  # ie
  #
  #
  #  {
  #    "catalog_baseline": "registry.redhat.io/redhat/redhat-operator-index:v4.18",
  #    "packages_cut": {
  #      "advanced-cluster-management": [
  #        "stable"
  #      ],
  #      "xxxx": [],
  #      "yyy": [
  #        "s1",
  #        "s2"
  #      ]
  #    }
  #  }
  #
  #  >>>
  #
  #  kubevirt-hyperconverged@stable@candidate@dev-preview@stable odf-csi-addons-operator@stable-4.16@stable-4.15@stable-4.16
  #
  #
  
  local _SEP=${_SEP:-" "}

  local _J_CUTSPEC=$1

  _log 3 "(cutspec.sh) jq -rj \".packages_cut|to_entries[]|.key,\"@\",(.value|join(\"@\")),\" \"\" <<< \$_J_CUTSPEC"

  jq -rj ".packages_cut|to_entries[]|.key,\"@\",(.value|join(\"@\")),\" \"" <<< $_J_CUTSPEC
}

_fsv_cut_yaml() {

  # Globals:
  #
  # _YAML_XPATH
  # _YQ_BIN
  #
  
  local _FP_YAML=$1

  jq -sjc '.[]|.name,"@",(select(.channels != null)|[.channels[]|.name]|join("@"))," "' <<<$($_YQ_BIN --output-format json '.oc_mirror_operators[0].packages[]' $_FP_YAML)

}

_pkgname_cutspec() {
  local _FP_NDJSON=$1
  jq -rj '.name," "' $_FP_NDJSON
}

_in_set() {
  local _PKG=$1
  local -n _L_PKGS=$2

  for _DEF_PKG in ${_L_PKGS[@]}; do
    if [[ $_DEF_PKG == $_PKG ]]; then
      return 0
    fi
  done
  return 1
}


_fsv_validate() {
  #
  # _fsv_validate _L_BASELINE_PKGS_1999 _L_FSV_CUT_PKG_CH_1999 _L_FSV_CUT_PKG_1999 _L_FSV_CUT_PKG_ERROR_1999
  #

  local -n _L_BASELINE_PKGS_1998=$1 
  local -n _L_FSV_CUT_PKG_CH_1998=$2 
  local -n _L_FSV_CUT_PKG_1998=$3
  local -n _L_FSV_CUT_PKG_ERROR_1998=$4

  local _L_PKG_CH_VALIDATED=()
  for _PKG_CH in ${_L_FSV_CUT_PKG_CH_1998[@]}; do

    IFS=$'@' read _PKG _L_CH <<<$_PKG_CH
    if _in_set $_PKG _L_BASELINE_PKGS_1998; then
      _L_FSV_CUT_PKG_1998+=( $_PKG )
      _L_PKG_CH_VALIDATED+=( $_PKG_CH )
    else
      _L_FSV_CUT_PKG_ERROR_1998+=( $_PKG )
    fi        

  done
  _L_FSV_CUT_PKG_CH_1998=${_L_PKG_CH_VALIDATED[@]}
}


_a_fsv_cut_pkg_ch() {

  # _ALL_PKGS=$_ALL_PKGS _a_fsv_cut_pkg_ch _L_BASELINE_PKGS _A_FSV_CUT_PKG_CH _L_FSV_CUT_PKG _L_CUT_PKG_ERROR $_J_CUTSPEC_1999 
  #

  local -n _L_BASELINE_PKGS_1999=$1
  local -n _A_FSV_CUT_PKG_CH_1999=$2
  local -n _L_FSV_CUT_PKG_1999=$3
  local -n _L_FSV_CUT_PKG_ERROR_1999=$4
  local _J_CUTSPEC_1999=$5

  if [[ -n $_ALL_PKGS ]]; then
    _L_FSV_CUT_PKG_CH_1999=( ${_L_BASELINE_PKGS_1999[@]} )
  else
    _L_FSV_CUT_PKG_CH_1999=$(_fsv_cut_json $_J_CUTSPEC_1999)
  fi


  _fsv_validate _L_BASELINE_PKGS_1999 _L_FSV_CUT_PKG_CH_1999 _L_FSV_CUT_PKG_1999 _L_FSV_CUT_PKG_ERROR_1999

  _log 2 "(cutspec.sh) _L_FSV_CUT_PKG_1999: ${_L_FSV_CUT_PKG_1999[@]}"
  _log 2 "(cutspec.sh) _L_FSV_CUT_PKG_ERROR_1999: ${_L_FSV_CUT_PKG_ERROR_1999[@]}"

  _log 2 "(cutspec.sh) _L_FSV_CUT_PKG_CH_1999: ${_L_FSV_CUT_PKG_CH_1999[@]}"

  for _CUT_PKG_CH in ${_L_FSV_CUT_PKG_CH_1999[@]}; do
    # mcg-operator@stable-4.16@stable-4.15@stable-4.16
    
    IFS=$'@' read _PKG _L_CH <<<$_PKG_CH

    if _in_set _PKG _L_BASELINE_PKGS_1999; then
      _A_FSV_CUT_PKG_CH_1999[$_PKG]=$_L_CH
    else
      _L_CUT_PKG_ERROR_1999+=( $_PKG )
    fi        
  done

}

_f_parse_input() {
  if [[ -d $1 ]]; then
    echo !arg
  else  
    jq -c -j '.," "' <<<$@
  fi
}

_f_baseline_cut() {

  local _J_SPEC=$1
  local -n _CATALOG_BASELINE_1999=$2
  local -n _A_PKGS_CUT_1999=$3
  local -n _L_PKGS_CUT_1999=$4

  _CATALOG_BASELINE_1999=$(jq -r '.catalog_baseline' <<<$_J_SPEC)

  oIFS=$IFS IFS=$'\n'

  for k in $(jq -j '.packages_cut|to_entries[]|.key," ",(.value|join("@")),"\n"' <<<$_J_SPEC); do
    IFS=$' ' read _PKG _CHNLS <<<$k
    _A_PKGS_CUT_1999[$_PKG]=$_CHNLS
    _L_PKGS_CUT_1999+=( $_PKG )
  done

  IFS=$oIFS

}

