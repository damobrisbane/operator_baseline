#!/bin/bash

_fsv_firsts() {
  #
  # Needed to preserve ordering on bash associative arrays
  #
  # mcg-operator@stable-4.15@stable-4.16 odf-operator@stable-4.15@stable-4.16 node-healthcheck-operator@4.12-eus@4.14-eus@4.16-eus@4.18-eus@candidate@stable kubevirt-hyperconverged@candidate@dev-preview@stable odf-csi-addons-operator@stable-4.15@stable-4.16
  # >>>
  # mcg-operator odf-operator node-healthcheck-operator kubevirt-hyperconverged odf-csi-addons-operator
  #

  local -n _L=$1
  local -n _L_FIRSTS=$2

  _L_FIRSTS=()
  for i in ${_L[@]}; do
    _L_FIRSTS+=( $(cut -d@ -f1 <<<$i) )
  done
}

_fsv_pullspec_json() {
  #
  # <PKG>@{@<CHANNEL>} <PKG>@{@<CHANNEL>}, ..
  #
  # Space delimited, @ field separated values, for shell script consumption
  #
  # ie
  #
  #  {
  #    "name": "kubevirt-hyperconverged",
  #    "defaultChannelName": "stable",
  #    "channels": [
  #      {
  #        "name": "candidate",
  #        "csvName": "kubevirt-hyperconverged-operator.v4.16.13"
  #      },
  #      {
  #        "name": "dev-preview",
  #        "csvName": "kubevirt-hyperconverged-operator.v4.99.0-0.1723448771"
  #      },
  #      {
  #        "name": "stable",
  #        "csvName": "kubevirt-hyperconverged-operator.v4.16.7"
  #      }
  #    ]
  #  }
  #  {
  #    "name": "odf-csi-addons-operator",
  #    "defaultChannelName": "stable-4.16",
  #    "channels": [
  #      {
  #        "name": "stable-4.15",
  #        "csvName": "odf-csi-addons-operator.v4.15.15-rhodf"
  #      },
  #      {
  #        "name": "stable-4.16",
  #        "csvName": "odf-csi-addons-operator.v4.16.11-rhodf"
  #      }
  #    ]
  #  }
  #
  #  >>>
  #
  #  kubevirt-hyperconverged@stable@candidate@dev-preview@stable odf-csi-addons-operator@stable-4.16@stable-4.15@stable-4.16
  #
  #
  
  local _FP_NDJSON=$1

  #_log 3 jq -rj "[.name,(.channels[].name)]|join(\"@\"),\" \"" $_FP_NDJSON
  #jq -rj "[.name,(.channels[].name)]|join(\"@\"),\" \"" $_FP_NDJSON

  # jq -rj '[.name,(.channels[]?|.name)]|join("@")," "'
  
  _log 3 jq -rj "[.name,(.channels[]?|.name)]|join(\"@\"),\" \"" $_FP_NDJSON
  jq -rj "[.name,(.channels[]?|.name)]|join(\"@\"),\" \"" $_FP_NDJSON
}

_fsv_pullspec_yaml() {

  # Globals:
  #
  # _YAML_XPATH
  # _YQ_BIN
  #
  
  local _FP_YAML=$1

  _log 3 jq -sjc '.[]|.name,"@",(select(.channels != null)|[.channels[]|.name]|join("@"))," "' \<\<\<\$\($_YQ_BIN '.oc_mirror_operators[0].packages[]' $_FP_YAML\)
  jq -sjc '.[]|.name,"@",(select(.channels != null)|[.channels[]|.name]|join("@"))," "' <<<$($_YQ_BIN --output-format json '.oc_mirror_operators[0].packages[]' $_FP_YAML)

}

_fsv_pullspec() {

  local _FP=$1

  _FN_PULLSPEC=$(basename $_FP)

  read _INDEX_NAME _TAG _EXT <<<$(_f_indexname_tag_ext $_FN_PULLSPEC)

  if [[ ( $_EXT == json ) || ( $_EXT == ndjson ) ]]; then

    _fsv_pullspec_json $_FP

  else

    _fsv_pullspec_yaml $_FP

  fi

}


_pkgname_pullspec() {
  local _FP_NDJSON=$1
  jq -rj '.name," "' $_FP_NDJSON
}

_a_fsv_pkg_ch() {

  # _a_fsv _L_PULLSPEC _L_FSV _A_FSV
  #

  local _ALL_PKGS_1999=$_ALL_PKGS

 _L_FSV_PKG=()

  if [[ -n $_ALL_PKGS ]]; then
    _L_FSV_PKG_CH=( ${_L_PKGS_PULLSPEC[@]} )
    _L_FSV_PKG=( ${_L_FSV_PKG_CH[@]} )
  else
    if [[ ( $_EXT == json ) || ( $_EXT == ndjson ) ]]; then
      _L_FSV_PKG_CH=$(_fsv_pullspec $_FP_PULLSPEC)
    else
      _L_FSV_PKG_CH=$(_fsv_pullspec_yaml $_FP_PULLSPEC)
    fi

    _fsv_firsts _L_FSV_PKG_CH _L_FSV_PKG

  fi

  _log 2 _L_FSV_PKG_CH: ${_L_FSV_PKG_CH[@]}
  _log 2 _L_FSV_PKG: ${_L_FSV_PKG[@]}

  local -n _L_FSV_PKG_CH_1999=$1
  local -n _A_FSV_1999=$2

  for _PKG_CH in ${_L_FSV_PKG_CH_1999[@]}; do
    # mcg-operator@stable-4.16@stable-4.15@stable-4.16
    
    IFS=$'@' read _PKG _L_CH <<<$_PKG_CH
    _A_FSV_1999[$_PKG]=$_L_CH

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

  IFS=$'\n'
  for k in $(jq -j '.packages_cut|to_entries[]|.key," ",(.value|join("@")),"\n"' <<<$_J_SPEC); do
    IFS=$' ' read _PKG _CHNLS <<<$k
    _A_PKGS_CUT_1999[$_PKG]=$_CHNLS
    _L_PKGS_CUT_1999+=( $_PKG )
  done

}

