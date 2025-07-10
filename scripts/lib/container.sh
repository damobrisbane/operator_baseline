#!/bin/bash

_f_pod_run() {

  local _POD_BIN=${POD_BIN:-/usr/bin/podman}

  local _CONTAINER_NAME=$1
  local _IMG=$2

  local _PORT=50051

  _log 2 "(container.sh) _f_pod_run ($_IMG)"

  if [[ $_POD_BIN =~ podman ]]; then
    $_POD_BIN run --authfile=$AUTHFILE -d -t --rm --label index= --name $_CONTAINER_NAME --net=host -p $_PORT:50051 $_IMG
  else
    $_POD_BIN run -d -t --rm --label index= --name $_CONTAINER_NAME --net=host -p $_PORT:50051 -t $_IMG
  fi

  if [[ $? -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

_f_grpc_running() {
  
  local _CONTAINER_NAME=$1
  local _GRPC_URL=$2

  IFS=$':' read _GRPC_HOST _GRPC_PORT <<<$_GRPC_URL

  _log 3 "(container.sh) if nc -z $_GRPC_HOST $_GRPC_PORT; then"
  if nc -z $_GRPC_HOST $_GRPC_PORT; then
    return 0
  else
    return 1
  fi
}

_f_pod_id() {
  
  local _POD_BIN=${POD_BIN:-/usr/bin/podman}

  local _CONTAINER_NAME=$1

  echo $($_POD_BIN ps -a --filter label=$_CONTAINER_NAME | grep -v CONTAINER | tr -s ' ' | cut -d' ' -f1)

}

_f_pod_rm() {

  local _CONTAINER_NAME=$1

  local _POD_BIN=${POD_BIN:-/usr/bin/podman}

  $_POD_BIN rm -f $_CONTAINER_NAME >/dev/null 2>&1

  sleep 2
}

_f_image_exists() {

  local _POD_BIN=${POD_BIN:-/usr/bin/podman}

  local _IMG=$1

  IFS=$' ' read _INDEX_NAME _TAG <<<$(_f_indexname_tag $_IMG)

  local _RESP=$($_POD_BIN images | grep "${_INDEX_NAME}.*${_TAG}" | wc -l )

  if [[ $_RESP -eq 1 ]]; then
    echo "Image $_CATALOG_BASELINE already exists, not downloading again.."
  else
    echo "Downloading $_CATALOG_BASELINE.."
    $_POD_BIN pull $_CATALOG_BASELINE
  fi

}

_f_pod_tag() {

  local _POD_BIN=${POD_BIN:-/usr/bin/podman}

  local _CATALOG_BASELINE=$1
  local _CATALOG_TARGET=$2

  echo Tagging $_CATALOG_BASELINE $_CATALOG_TARGET
  $_POD_BIN tag $_CATALOG_BASELINE $_CATALOG_TARGET
}

_f_pod_push() {

  local _CATALOG_TARGET=$1

  local _POD_BIN=${POD_BIN:-/usr/bin/podman}

  if [[ $_POD_BIN =~ podman ]]; then
    $_POD_BIN push --remove-signatures $_CATALOG_TARGET
  else
    $_POD_BIN push $_CATALOG_TARGET
  fi

  echo Pushed $_CATALOG_TARGET
}
