#!/bin/bash

_f_grpc_bundle() {
  #grpcurl -plaintext -d '{"name":"percona-xtradb-cluster-operator-certified","channelName":"stable"}' localhost:50051 api.Registry/GetBundleForChannel | jq .
  local _GRPC_URL=$1
  local _OP=$2
  local _CH=$3

  read channelName csvName bundlePath version <<<$(grpcurl -plaintext -d "{\"pkgName\":\"${_OP}\",\"channelName\":\"${_CH}\"}" $_GRPC_URL api.Registry/GetBundleForChannel | jq -rj ".channelName,\" \",.csvName,\" \",.bundlePath,\" \",.version")

  printf '%s' "{\"version\":\"${version}\",\"bundlePath\":\"${bundlePath}\"}"

}

_f_grpc_running() {
  #
  # Globals:
  #
  # _GRPC_HOST
  #
 
  local _GRPC_URL=$1

  read _GRPC_HOST _GRPC_PORT <<< $(tr : ' ' <<<$_GRPC_URL)

  if grpcurl -plaintext $_GRPC_URL describe >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

_grpc_list_pkgs() {
  #
  # Globals:
  #
  # _GRPC_HOST
  #
 
  local _GRPC_URL=$1

  grpcurl -plaintext $_GRPC_URL api.Registry/ListPackages | jq -r -s -S '.|sort[].name'
}

_f_grpc_get_packages() {

  local _GRPC_URL=$1
  local -n _L_PKGS_1999=$2
  local -n _A_PKGS_CH_1999=$3
  local -n _J_PKGS_CUT_1999=$4

  local _J0=

  _log 2 "(grpc.sh:_f_grpc_get_packages)"

  for _PKG in ${_L_PKGS_1999[@]}; do


      _L_CHNLS_PULLSPEC=( $(tr @ ' ' <<<${_A_PKGS_CH_1999[$_PKG]}))

      _log 4 "$_PKG: _L_CHNLS_PULLSPEC: ${_L_CHNLS_PULLSPEC[@]}"

      _J_STOCK_PKG=$(grpcurl -plaintext -d "{\"name\":\"$_PKG\"}" $_GRPC_URL api.Registry/GetPackage)

      _log 5 "(grpc.sh:_f_grpc_get_packages) _J_STOCK_PKG: $(jq -c . <<<$_J_STOCK_PKG)"

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

      _log 4 "(grpc.sh:_f_grpc_get_packages) _A_STOCK_CH_CSV ${!_A_STOCK_CH_CSV[@]} ${_A_STOCK_CH_CSV[@]}"
      _log 3 "(grpc.sh:_f_grpc_get_packages) _L_STOCK_CH ${#_L_STOCK_CH[@]} ${_L_STOCK_CH[@]}"
      _log 3 "(grpc.sh:_f_grpc_get_packages) _DEF_CH_NAME ${_DEF_CH_NAME}"

      declare -A _A_IN_SET=()

      if [[ -n $_GEN_ISC ]]; then
        local _J_PKG="{\"name\":\"$_PKG\",\"channels\":[]}"
      else
        local _J_PKG="{\"name\":\"$_PKG\",\"defaultChannelName\":\"$_DEF_CH_NAME\",\"channels\":[]}"
      fi


      for _STOCK_CH in ${_L_STOCK_CH[@]}; do

        unset _L_CHNLS
        if [[ -n $_ALL_PKGS ]]; then
          _L_CHNLS=( $_STOCK_CH )
        else
          _L_CHNLS=${_L_CHNLS_PULLSPEC[@]}
          _L_CHNLS+=( $_DEF_CH_NAME )
        fi

        _log 4 "(grpc.sh:_f_grpc_get_packages) _L_CHNLS: ${_L_CHNLS[@]}"

        for _CH in ${_L_CHNLS[@]}; do

          if [[ -z ${_A_IN_SET[$_CH]} ]]; then

            if [[ ( $_CH == $_STOCK_CH || $_CH == $_DEF_CH_NAME ) && -z ${_A_IN_SET[$_CH]} ]]; then

              #if [[ -n $_BUNDLE ]]; then

                #_J_BUNDLE=$(_f_grpc_bundle $_GRPC_URL $_PKG $_CH)
                #_J_CH_1999=$(jq ".channels[]|select(.name==\"$_CH\")" <<<$_J_STOCK_PKG)
                #_J_CH=$(jq -s 'add' <<<"${_J_CH_1999}${_J_BUNDLE}")

                _J_BUNDLE=$(_f_grpc_bundle $_GRPC_URL $_PKG $_CH)
                local _VERSION=$(jq -r .version <<<$_J_BUNDLE)

                #_J_CH_1999=$(jq ".channels[]|select(.name==\"$_CH\")" <<<$_J_STOCK_PKG)

                #_J_CH=$(jq -s 'add' <<<"${_J_CH_1999}${_J_BUNDLE}")


              #else

                _S_CH_CSV=$(jq -rj ".channels[]|(select(.name==\"$_CH\")|.name,\" \",.csvName)" <<<$_J_STOCK_PKG)

                read name csvName <<<$_S_CH_CSV

                #_J_CH="{\"name\":\"$name\",\"minVersion\":\"$(_map_csv_version $csvName)\"}"
                _J_CH="{\"name\":\"$name\",\"minVersion\":\"${_VERSION}\"}"

              #fi

              _J_PKG=$(jq ".channels += [${_J_CH}]" <<<$_J_PKG)
              _A_IN_SET[$_CH]=1

            fi
          fi
        done

      done

  _J0+=$_J_PKG

  done

  _J_PKGS_CUT_1999=$(jq -s <<<$_J0)
}

