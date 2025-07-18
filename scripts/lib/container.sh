#!/bin/bash

# Globals:
#
# _AUTHFILE
# _PODMAN_BIN
#
# 2>/dev/null indicates TLDR
# 2>&1 doubles down
#


_f_pod_exists() {
  
  local _POD_LABEL=$1

  local _L=( $($_PODMAN_BIN ps -a -q --filter label=$_POD_LABEL 2>/dev/null ))

  if [[ ${#_L[@]} -eq 0 ]]; then
    return 1
  else
    return 0
  fi
}

_f_pod_rm() {

  local _POD_LABEL=$1
  local _POD_NAME=$2

  if _f_pod_exists $_POD_LABEL; then
    _log 2 "(container.sh:_f_pod_rm) $_PODMAN_BIN rm -f $_POD_NAME"
    $_PODMAN_BIN rm -f $_POD_NAME 
  fi
  sleep 2
}

_f_get_image() {

  # Globals:
  #
  # _SKIP_IMAGE_RM
  #

  local _INDEX_LOCATION=$1
  local _TAG=$2
  local _IMG=$3

  local _RESP=$($_PODMAN_BIN images --noheading | grep "${_INDEX_LOCATION}.*${_TAG}" | wc -l )

  if [[ $_RESP -eq 1 && -n $_SKIP_IMAGE_RM ]]; then
    echo "Image $_IMG already exists, not downloading again.."
  else
    echo "Downloading $_IMG.."
    $_PODMAN_BIN pull $_IMG
  fi

}

_f_pod_tag() {

  local _CATALOG_BASELINE=$1
  local _CATALOG_TARGET=$2

  echo Tagging $_CATALOG_BASELINE $_CATALOG_TARGET
  $_PODMAN_BIN tag $_CATALOG_BASELINE $_CATALOG_TARGET
}

_f_pod_push() {

  local _CATALOG_TARGET=$1

  $_PODMAN_BIN push --remove-signatures $_CATALOG_TARGET

  echo Pushed $_CATALOG_TARGET
}

_f_pod_run() {
  #
  # _f_pod_run $_IMG $_POD_NAME $_POD_LABEL $_PPROF_PORT $_GRPC_PORT
  #

  local _IMG=$1
  local _POD_NAME=$2
  local _POD_LABEL=$3
  local _PPROF_PORT=$4
  local _GRPC_PORT=$5
  
  _log 1 "(container.sh:_f_pod_run) $_PODMAN_BIN run -d -t --rm --label $_POD_LABEL --name $_POD_NAME -p $_PPROF_PORT:6060 -p $_GRPC_PORT:50051 $_IMG"
  $_PODMAN_BIN run -d -t --rm --label $_POD_LABEL --name $_POD_NAME -p $_PPROF_PORT:6060 -p $_GRPC_PORT:50051 $_IMG >/dev/null 2>&1

}

_f_run() {
  #
  # Globals:
  #
  # _SKIP_POD_RM
  #
  # _f_run $_CATALOG_BASELINE $_POD_NAME $_POD_LABEL $_PPROF_PORT $_GRPC_PORT; then
  #

  IFS=$' ' read _IMG _POD_NAME _POD_LABEL _PPROF_PORT _GRPC_PORT _GRPC_URL <<<$@

  if [[ -z $_SKIP_POD_RM ]]; then
    _f_pod_rm $_POD_LABEL $_POD_NAME
    _f_pod_run $_IMG $_POD_NAME $_POD_LABEL $_PPROF_PORT $_GRPC_PORT
  else
    if ! _f_pod_exists $_POD_LABEL; then
      _f_pod_run $_IMG $_POD_NAME $_POD_LABEL $_PPROF_PORT $_GRPC_PORT
    fi

  fi

  local _COUNTER=1

  while : ; do
    if _f_grpc_running $_GRPC_URL; then
      return 0
    else
      if [[ $_COUNTER -gt 10 ]]; then
        _log 0 "(cut.sh:_f_run) No running pod (index) found. Are args correct, return 1.."
        return 1
      fi
    fi
    _COUNTER=$(( $_COUNTER + 1 ))
    _sleep $_COUNTER
  done

}


