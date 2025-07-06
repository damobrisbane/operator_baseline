#!/bin/bash

_f_grpc_bundle() {
  #grpcurl -plaintext -d '{"name":"percona-xtradb-cluster-operator-certified","channelName":"stable"}' localhost:50051 api.Registry/GetBundleForChannel | jq .
  local _OP=$1
  local _CH=$2

  local _GRPC_URL=${3:-localhost:50051}

  read channelName csvName bundlePath <<<$(grpcurl -plaintext -d "{\"pkgName\":\"${_OP}\",\"channelName\":\"${_CH}\"}" $_GRPC_URL api.Registry/GetBundleForChannel | jq -rj ".channelName,\" \",.csvName,\" \",.bundlePath")

  echo "{\"version\":\"$(_map_csv_version $csvName)\",\"bundlePath\":\"$bundlePath\"}"

}

_grpc_list_pkgs() {

  local _GRPC_URL=${1:-localhost:50051}

  grpcurl -plaintext $_GRPC_URL api.Registry/ListPackages | jq -r -s -S '.|sort[].name'
}

get_packages() {

  # Globals:
  #
  # _BUNDLE
  # _ALL_PKGS
  # _GEN_ISC [when NOT set, include defaultChannelName in output]
  #
 
  # _L_FSV only required for preserving order on associatve array, _A_FSV
  #
  local -n _A_FSV_PKG_CH_1998=$1
  local -n _L_FSV_1998=$2
  
  local _J0

  _log 3 \!_A_FSV_PKG_CH_1998: ${!_A_FSV_PKG_CH_1998[@]}
  _log 3 _A_FSV_PKG_CH_1998: ${_A_FSV_PKG_CH_1998[@]}

  for _PKG in ${_L_FSV_1998[@]}; do

      _L_CHNLS_PULLSPEC=( $(tr @ ' ' <<<${_A_FSV_PKG_CH_1998[$_PKG]}))

      _log 4 _PKG: $_PKG _DEF_CH: $_DEF_CH _L_CHNLS_PULLSPEC: ${#_L_CHNLS_PULLSPEC[@]} ${_L_CHNLS_PULLSPEC[@]}

      _J_STOCK_PKG=$(grpcurl -plaintext -d "{\"name\":\"$_PKG\"}" localhost:50051 api.Registry/GetPackage)

      _log 5 _J_STOCK_PKG: $(jq -c . <<<$_J_STOCK_PKG)

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

      unset _A_STOCK_CH_CSV
      declare -A _A_STOCK_CH_CSV
      local _L1=($(jq -rj ".channels[]|.name,\",\",.csvName,\"\n\"" <<<$_J_STOCK_PKG))
      for i in ${_L1[@]}; do
        IFS=$',' read _STOCK_CH _STOCK_CSV <<<$i
        _A_STOCK_CH_CSV[$_STOCK_CH]=$_STOCK_CSV
      done

      local _L_STOCK_CH=( ${!_A_STOCK_CH_CSV[@]} )
      _log 4 _A_STOCK_CH_CSV ${!_A_STOCK_CH_CSV[@]} ${_A_STOCK_CH_CSV[@]}
      _log 3 _L_STOCK_CH ${#_L_STOCK_CH[@]} ${_L_STOCK_CH[@]}
      _log 3 _L_CHNLS_PULLSPEC ${#_L_CHNLS_PULLSPEC[@]} ${_L_CHNLS_PULLSPEC[@]}
      _log 3 _DEF_CH_NAME ${_DEF_CH_NAME}

      declare -A _A_IN_SET=()

      if [[ -n $_GEN_ISC ]]; then
        local _J_PKG="{\"name\":\"$_PKG\",\"channels\":[]}"
      else
        local _J_PKG="{\"name\":\"$_PKG\",\"defaultChannelName\":\"$_DEF_CH_NAME\",\"channels\":[]}"
      fi

      #unset _L_CHNLS
      #_L_CHNLS=${_L_CHNLS_PULLSPEC[@]}
      #_L_CHNLS+=( $_DEF_CH_NAME )

      _log 4 _L_CHNLS: ${_L_CHNLS[@]}

      for _STOCK_CH in ${_L_STOCK_CH[@]}; do

        unset _L_CHNLS
        if [[ -n $_ALL_PKGS ]]; then
          _L_CHNLS=( $_STOCK_CH )
        else
          _L_CHNLS=${_L_CHNLS_PULLSPEC[@]}
          _L_CHNLS+=( $_DEF_CH_NAME )
        fi

        for _CH in ${_L_CHNLS[@]}; do

          if [[ -z ${_A_IN_SET[$_CH]} ]]; then

            if [[ ( $_STOCK_CH == $_CH || $_STOCK_CH == $_DEF_CH_NAME ) && -z ${_A_IN_SET[$_CH]} ]]; then

              if [[ -n $_BUNDLE ]]; then

                _J_BUNDLE=$(_f_grpc_bundle $_PKG $_CH)

                _J_CH_1999=$(jq ".channels[]|select(.name==\"$_CH\")" <<<$_J_STOCK_PKG)

                _J_CH=$(jq -s 'add' <<<"${_J_CH_1999}${_J_BUNDLE}")

              else

                _S_CH_CSV=$(jq -rj ".channels[]|(select(.name==\"$_CH\")|.name,\" \",.csvName)" <<<$_J_STOCK_PKG)                

                read name csvName <<<$_S_CH_CSV
                
                _J_CH="{\"name\":\"$name\",\"minVersion\":\"$(_map_csv_version $csvName)\"}"

              fi

              _J_PKG=$(jq ".channels += [${_J_CH}]" <<<$_J_PKG)
              _A_IN_SET[$_CH]=1

            fi
          fi
        done

      done

  _J0+=$_J_PKG

  done

  jq -sc . <<<$_J0
}

