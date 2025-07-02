#!/bin/bash


_f_grpc_bundle() {
  #grpcurl -plaintext -d '{"name":"percona-xtradb-cluster-operator-certified","channelName":"stable"}' localhost:50051 api.Registry/GetBundleForChannel | jq .
  local _OP=$1
  local _CH=$2

  local _GRPC_URL=${3:-localhost:50051}

  read channelName csvName bundlePath <<<$(grpcurl -plaintext -d "{\"pkgName\":\"${_OP}\",\"channelName\":\"${_CH}\"}" $_GRPC_URL api.Registry/GetBundleForChannel | jq -rj ".channelName,\" \",.csvName,\" \",.bundlePath")


  echo csvName $csvName 1>&2
  echo version $(_map_csv_version $csvName) 1>&2

  echo "{\"version\":\"$(_map_csv_version $csvName)\",\"bundlePath\":\"$bundlePath\"}"

}

_list_pkgs() {

  local _GRPC_URL=${1:-localhost:50051}

  grpcurl -plaintext $_GRPC_URL api.Registry/ListPackages | jq -r -s -S '.|sort[].name'
}



