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

_fsv_filter() {
  #
  # <PKG>@<DEF_CHANNEL>{@<CHANNEL>},<PKG>@<DEF_CHANNEL>{@<CHANNEL>}, ..
  #
  # Space delimited, @ field separated values
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

  _log 3 jq -rj "[.name,(.channels[].name)]|join(\"@\"),\" \"" $_FP_NDJSON

  jq -rj "[.name,(.channels[].name)]|join(\"@\"),\" \"" $_FP_NDJSON

}

_fsv_filter_yaml() {

  local _FP_YAML=$1

  _log 3 jq -sjc '.[]|.name,"@",(select(.channels != null)|[.channels[]|.name]|join("@"))," "' \<\<\<\$\(yq '.oc_mirror_operators[0].packages[]' $_FP_YAML\)

  jq -sjc '.[]|.name,"@",(select(.channels != null)|[.channels[]|.name]|join("@"))," "' <<<$(yq --output-format json '.oc_mirror_operators[0].packages[]' $_FP_YAML)

}

_pkgname_filter() {
  local _FP_NDJSON=$1
  jq -rj '.name," "' $_FP_NDJSON
}

_a_fsv_pkg_ch() {

  # _a_fsv _L_FILTER _L_FSV _A_FSV
  #
  local -n _A_FSV_1999=$1

  for i in ${!_A_FSV_1999[@]}; do
    # mcg-operator@stable-4.16@stable-4.15@stable-4.16
    
    IFS=$'@' read _PKG _L_CH <<<$i
    _A_FSV_1999[$_PKG]=$_L_CH

  done
}
