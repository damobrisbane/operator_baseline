#!/bin/bash

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

