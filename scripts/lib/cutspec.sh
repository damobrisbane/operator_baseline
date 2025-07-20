#!/bin/bash

_f_parse_cutspec() {

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

_f_passthrough() {

  local -n _J_CUTSPEC_1998=$1
  local -n _J_PLATFORM_PASSTHROUGH_1999=$2
  local -n _J_ADDITIONAL_IMG_PASSTHROUGH_1999=$3
  local -n _J_HELM_PASSTHROUGH_1999=$4
 
  _J_PLATFORM_PASSTHROUGH_1999=$(jq -cr 'if has("platform") then (.platform) else {} end' <<<$_J_CUTSPEC_1998)
  _J_ADDITIONAL_IMG_PASSTHROUGH_1999=$(jq -cr 'if has("additionalImages") then (.platform) else {} end' <<<$_J_CUTSPEC_1998)
  _J_HELM_PASSTHROUGH_1999=$(jq -cr 'if has("platform") then (.helm) else {} end' <<<$_J_CUTSPEC_1998)

}

_fsv_pullspec_yaml() {

  # Globals:
  #
  # _YAML_XPATH
  # _YQ_BIN
  #
  
  local -n _J1_1999=$1
  local _FP_YAML=$2

  _log 3 jq -sjc '.[]|.name,"@",(select(.channels != null)|[.channels[]|.name]|join("@"))," "' \<\<\<\$\($_YQ_BIN '.oc_mirror_operators[].packages[]' $_FP_YAML\)

  _J1_1999+=$(jq -c <<<$($_YQ_BIN --output-format json '.oc_mirror_operators[]|{"catalog_baseline":.catalog,"packages_cut":.packages}' $_FP_YAML))

}

_f_ndjson_cutspecs() {
  local -n _NDJSON_CUTSPECS_1999=$1
  local _FP=$2

  if [[ -d $_FP ]]; then
    local _J=
    for _FI in $(find $_FP -type f); do

      local _EXT=${_FI##*.}

      if [[ ( $_EXT == json ) || ( $_EXT == ndjson ) ]]; then

        if jq . $_FI >/dev/null 2>&1; then
          _J+=$(jq -c . $_FI)
        else
          echo "Unable to parse pullspec file $_FI"
          break
        fi

      elif [[ ( $_EXT == yml ) || ( $_EXT == yaml ) ]]; then
      
        _fsv_pullspec_yaml _J $_FI 

      fi
    done        
    _NDJSON_CUTSPECS_1999=($(jq -c <<<$_J))
  else
    _NDJSON_CUTSPECS_1999=$(jq -cj '.," "' <<<$@)
  fi
}

_f_catalog_baseline() {

  local _J_SPEC=$1
  local -n _CATALOG_BASELINE_1999=$2

  _CATALOG_BASELINE_1999=$(jq -r '.catalog_baseline' <<<$_J_SPEC)

}

