#!/bin/bash

_f_pod_run() {

  local _CONTAINER_NAME=$1
  local _IMG=$2

  local _POD_RUNNER=${POD_RUNNER:-/usr/bin/podman}
  local _PORT=50051

  _log 2 "_f_pod_run ($_IMG)"

  if [[ $_POD_RUNNER =~ podman ]]; then
    $_POD_RUNNER run --authfile=$AUTHFILE -d -t --rm --label index= --name $_CONTAINER_NAME --net=host -p $_PORT:50051 $_IMG
  else
    $_POD_RUNNER run -d -t --rm --label index= --name $_CONTAINER_NAME --net=host -p $_PORT:50051 -t $_IMG
  fi

}

_f_grpc_running() {
  
  local _CONTAINER_NAME=$1
  local _GRPC_URL=$2

  IFS=$':' read _GRPC_HOST _GRPC_PORT <<<$_GRPC_URL

  if nc -z $_GRPC_HOST $_GRPC_PORT; then
    return 0
  else
    return 1
  fi
}

_f_pod_id() {
  
  local _CONTAINER_NAME=$1
  local _POD_RUNNER=${POD_RUNNER:-/usr/bin/podman}


  echo $($_POD_RUNNER ps -a --filter label=$_CONTAINER_NAME | grep -v CONTAINER | tr -s ' ' | cut -d' ' -f1)

}

_f_pod_rm() {

  local _CONTAINER_NAME=$1

  local _POD_RUNNER=${POD_RUNNER:-/usr/bin/podman}

  $_POD_RUNNER rm -f $_CONTAINER_NAME >/dev/null 2>&1

  sleep 2
}

_f_image_exists() {

  local _DATESTAMP=$1
  local _INDEX_NAME=$2
  local _TAG=$3

  local _POD_RUNNER=${POD_RUNNER:-/usr/bin/podman}

  local _RESP=$($_POD_RUNNER images | grep "$_DATESTAMP.*$_INDEX_NAME.*$_TAG" | wc -l )

  if [[ $_RESP -eq 1 ]]; then
    return 0
  else
    return 1
  fi

}
