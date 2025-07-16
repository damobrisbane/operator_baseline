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
  #{
  #  "catalog_baseline": "registry.redhat.io/redhat/redhat-operator-index:v4.16",
  #  "packages_cut": [
  #    {
  #      "name": "3scale-operator",
  #      "defaultChannelName": "threescale-2.15",
  #      "channels": [
  #        {
  #          "name": "threescale-mas",
  #          "minVersion": "0.11.8-mas"
  #        },
  #        {
  #          "name": "threescale-2.15",
  #          "minVersion": "0.12.3"
  #        },
  #        {
  #          "name": "threescale-2.13",
  #          "minVersion": "0.10.5"
  #        }
  #      ]
  #    },
  #    {
  #      "name": "advanced-cluster-management",
  #      "defaultChannelName": "release-2.13",
  #      "channels": [
  #        {
  #          "name": "release-2.12",
  #          "minVersion": "2.12.3"
  #        },
  #        {
  #          "name": "release-2.13",
  #          "minVersion": "2.13.3"
  #        }
  #      ]
  #    }
  #  ]
  #}
  #
  #  >>>
  #
  #  kubevirt-hyperconverged@stable@candidate@dev-preview@stable odf-csi-addons-operator@stable-4.16@stable-4.15@stable-4.16
  #
  #
  
  local _SEP=${_SEP:-" "}

  local _J_CUTSPEC=$1

  #_log 3 "(cutspec.sh) jq -rj \".packages_cut|to_entries[]|.key,\"@\",(.value|join(\"@\")),\" \"\" <<< \$_J_CUTSPEC"
  #jq -rj ".packages_cut|to_entries[]|.key,\"@\",(.value|join(\"@\")),\" \"" <<< $_J_CUTSPEC

  #for k in $(jq -j '.packages_cut[]|.name," ",([.channels[]?|.name]|join("@")),"\n"' <<<$_J_SPEC); do
  jq -rj ".packages_cut[]|.name,\"@\",([.channels[]?|.name]|join(\"@\")),\" \"" <<< $_J_CUTSPEC
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

  local -n _J_CUTSPEC_1998=$1
  local -n _L_PKGS_1998=$2
  local -n _A_PKGS_CH_1998=$3

  _log 2 "(grpc.sh:_f_grpc_get_packages)"

  _L_PKGS_1998=( $( jq -r '.packages_cut[].name' <<<$_J_CUTSPEC_1998 ) )

  for _PKG in ${_L_PKGS_1998[@]}; do
    
    _J_PKG=$(jq ".packages_cut[]|select(.name==\"$_PKG\")" <<<$_J_CUTSPEC_1998)

    _S_CH=$(jq -r 'if has("channels") then ([.channels[]|.name]|join("@")) else "" end' <<<$_J_PKG)

    _A_PKGS_CH_1998[$_PKG]=$_S_CH

  done

}

_fsv_pullspec_yaml() {

  # Globals:
  #
  # _YAML_XPATH
  # _YQ_BIN
  #
  
  local _FP_YAML=$1

  _log 3 jq -sjc '.[]|.name,"@",(select(.channels != null)|[.channels[]|.name]|join("@"))," "' \<\<\<\$\($_YQ_BIN '.oc_mirror_operators[0].packages[]' $_FP_YAML\)

  $_YQ_BIN --output-format json '.oc_mirror_operators[0]|{"catalog_baseline":.catalog,"packages_cut":.packages}' $_FP_YAML

}

_f_ndjson_cutspecs() {
  if [[ -d $1 ]]; then
    local _J=
    for _FI in $(find $1 -type f); do

      local _EXT=${_FI##*.}

      if [[ ( $_EXT == json ) || ( $_EXT == ndjson ) ]]; then
        if jq . $_FI >/dev/null 2>&1; then
          _J+=$(jq -c . $_FI)
        else
          echo "Unable to parse pullspec file $_FI"
          break
        fi
      else          
        _J+=$(_fsv_pullspec_yaml $_FI)
      fi
    done        
    jq -c <<<$_J
  else
    jq -cj '.," "' <<<$@
  fi
}

_f_parse_cutspec() {

  local _J_SPEC=$1
  local -n _CATALOG_BASELINE_1999=$2
  local -n _A_PKGS_CUT_1999=$3
  local -n _L_PKGS_CUT_1999=$4

  _CATALOG_BASELINE_1999=$(jq -r '.catalog_baseline' <<<$_J_SPEC)

  oIFS=$IFS IFS=$'\n'

  _log 3 "(cutspec.sh:_f_parse_cutspec) _J_SPEC: $_J_SPEC"
  _log 3 "(cutspec.sh:_f_parse_cutspec) for k in \$(jq -j '.packages_cut|to_entries[]|.key,\" \",(.value|join(\"@\")),\"\n\"' <<< \$_J_SPEC); do"

  #for k in $(jq -j '.packages_cut|to_entries[]|.key," ",(.value|join("@")),"\n"' <<<$_J_SPEC); do
  for k in $(jq -j '.packages_cut[]|.name," ",([.channels[]?|.name]|join("@")),"\n"' <<<$_J_SPEC); do
    IFS=$' ' read _PKG _CHNLS <<<$k
    _A_PKGS_CUT_1999[$_PKG]=$_CHNLS
    _L_PKGS_CUT_1999+=( $_PKG )
  done

  IFS=$oIFS

}

