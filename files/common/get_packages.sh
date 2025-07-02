#!/bin/bash

source $(dirname ${BASH_SOURCE})/lib/utility.sh
source $(dirname ${BASH_SOURCE})/lib/grpc.sh
source $(dirname ${BASH_SOURCE})/lib/filter.sh

_BUNDLE=${BUNDLE:-}

_FP_FILTER=${1:-}

_L_PKGS=($(_list_pkgs))
_L_FSV=$(_fsv_filter $_FP_FILTER)

_L_PKGNAME=$(_pkgname_filter $_FP_FILTER)

_L_FILTER=($(_right_join _L_PKGS _L_PKGNAME))


_log 4 _L_PKGS: ${_L_PKGS[@]:0:3} ...
_log 4 _L_PKGNAME_FILTER: ${_L_PKGNAME[@]}
_log 4 _L_FSV: ${_L_FSV[@]}
_log 4 _L_FILTER: ${_L_FILTER[@]}

get_packages() {

  local -n _J0=$1

  declare -A _A_FSV
  _a_pkg_fsv _L_FSV _A_FSV

  _log 4 ${!_A_FSV[@]}
  _log 4 ${_A_FSV[@]}


  for _PKG in ${!_A_FSV[@]}; do

      _DEF_CH=$(cut -d@ -f1 <<<${_A_FSV[$_PKG]})
      _L_CHNLS_PULLSPEC=( $(tr @ ' ' <<<$(cut -d@ -f2- <<<${_A_FSV[$_PKG]})) )

      _log 3 _PKG: $_PKG _DEF_CH: $_DEF_CH _L_CHNLS_PULLSPEC: ${#_L_CHNLS_PULLSPEC[@]} ${_L_CHNLS_PULLSPEC[@]}

      _J_STOCK_PKG=$(grpcurl -plaintext -d "{\"name\":\"$_PKG\"}" localhost:50051 api.Registry/GetPackage)

      # _J_STOCK_PKG:
      #
      # {
      #  "name": "odf-csi-addons-operator",
      #  "channels": [
      #    {
      #      "name": "stable-4.15",
      #      "csvName": "odf-csi-addons-operator.v4.15.15-rhodf"
      #    },
      #    {
      #      "name": "stable-4.16",
      #      "csvName": "odf-csi-addons-operator.v4.16.11-rhodf" #    }
      #  ],
      #  "defaultChannelName": "stable-4.16"
      #

      _DEF_CH_NAME=$(jq -r ".defaultChannelName" <<<$_J_STOCK_PKG)

      declare -A _A_STOCK_CH_CSV
      local _L1=($(jq -rj ".channels[]|.name,\",\",.csvName,\"\n\"" <<<$_J_STOCK_PKG))
      for i in ${_L1[@]}; do
        IFS=$',' read _STOCK_CH _STOCK_CSV <<<$i
        _A_STOCK_CH_CSV[$_STOCK_CH]=$_STOCK_CSV
      done

      local _L_STOCK_CH=( ${!_A_STOCK_CH_CSV[@]} )
      _log 3 _A_STOCK_CH_CSV ${!_A_STOCK_CH_CSV[@]} ${_A_STOCK_CH_CSV[@]}
      _log 2 _L_STOCK_CH ${#_L_STOCK_CH[@]} ${_L_STOCK_CH[@]}
      _log 2 _L_CHNLS_PULLSPEC ${#_L_CHNLS_PULLSPEC[@]} ${_L_CHNLS_PULLSPEC[@]}
      _log 2 _DEF_CH_NAME ${_DEF_CH_NAME}

      declare -A _A_IN_SET=()

      local _J_PKG="{\"name\":\"$_PKG\",\"defaultChannelName\":\"$_DEF_CH_NAME\",\"channels\":[]}"

      unset _L_CHNLS
      _L_CHNLS=${_L_CHNLS_PULLSPEC[@]}
      _L_CHNLS+=( $_DEF_CH_NAME )

      _log 3 _L_CHNLS: ${_L_CHNLS[@]}

      for _STOCK_CH in ${_L_STOCK_CH[@]}; do

        for _CH in ${_L_CHNLS[@]}; do

          if [[ -z ${_A_IN_SET[$_CH]} ]]; then
            if [[ ( $_STOCK_CH == $_CH || $_STOCK_CH == $_DEF_CH_NAME ) && -z ${_A_IN_SET[$_CH]} ]]; then
              _J_CH=$(jq ".channels[]|select(.name==\"$_CH\")" <<<$_J_STOCK_PKG)
              if [[ -n $_BUNDLE ]]; then
                _log 3 _J_BUNDLE=\$\(_f_grpc_bundle $_PKG $_CH\)
                _J_BUNDLE=$(_f_grpc_bundle $_PKG $_CH)
                _J_CH=$(jq -s 'add' <<<"${_J_CH}${_J_BUNDLE}")
              fi
              _J_PKG=$(jq ".channels += [${_J_CH}]" <<<$_J_PKG)
              _A_IN_SET[$_CH]=1
            fi
          fi
        done

      done

  _J0+=$_J_PKG

  done

}

get_packages J_PKGS

jq . <<<$J_PKGS
