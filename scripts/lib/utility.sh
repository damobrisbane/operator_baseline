#!/bin/bash

_log() {

  local _LVL=$1 && shift

  case $_LVL in
      0)
          echo $@ 1>&2
      ;;
      1)
          [[ $DEBUG -gt 0 ]] && echo $@ 1>&2
      ;;
      2)
          [[ $DEBUG -gt 1 ]] && echo $@ 1>&2
      ;;
      3)
          [[ $DEBUG -gt 2 ]] && echo $@ 1>&2
      ;;
      4)
          [[ $DEBUG -gt 3 ]] && echo $@ 1>&2
      ;;
      5)
          [[ $DEBUG -gt 3 ]] && echo $@ 1>&2
      ;;
      6)
          [[ $DEBUG -gt 3 ]] && echo $@ 1>&2
      ;;
      *)
          :
      ;;
  esac;
}

_sleep() {
  local _DELAY=$1
  _log 2 "(utility.sh) Sleeping $_DELAY secs.."
  sleep $_DELAY
}

d1() {
  date +%Y%m%d
}

_f_port_map() {
  # 4.16 >> (6060+16) (50051+16),
  # 4.17 >> (6060+17) (50051+17),
  # 4.18 >> (6060+18) (50051+18),..
  #

  local _TAG_1999=$1
  local _INDEX_NAME_1999=$2

  local _n_MINOR=$(cut -d. -f2 <<<$_TAG_1999)     # ie v4.16 >>> 16

  local _OFFSET=0                           # hacky way to distinguish between redhat, certified, community

  case $_INDEX_NAME_1999 in
    community*)  _OFFSET=1
                ;;
    certified*)  _OFFSET=2
                ;;
    redhat*)  _OFFSET=3
                ;;
    *)          _OFFSET=0
                ;;
  esac

  printf '%s %s' $(( 6060 + $_OFFSET + $_n_MINOR )) $(( 50051 + $_OFFSET + $_n_MINOR ))
  
}

_f_indexname_tag() {
  #
  # Globals:
  #
  #
  # ie reg.dmz.lan:5000/redhat-operators:v4.16; or
  #    redhat-operators:v4.16-cut; or 
  #    redhat-operators:v4.16 
  #   >>>
  #    redhat-operators v4.16
  #

  local _IMG=$1

  local _SEP=${_SEP:-" "}
  local _INDEX_LOCATION
  local _INDEX_NAME
  local _TAG

  read _INDEX_LOCATION _TAG <<< $(sed -E "s/(.*):(v[[:alnum:]\.-]+$)/\1${_SEP}\2/" <<<$_IMG)

  _INDEX_NAME=$(basename $_INDEX_LOCATION)
  printf '%s %s %s' $_INDEX_LOCATION $_INDEX_NAME $_TAG
}

_f_run_metadata() {

  local _IMG=$1

  local _PPROF_PORT
  local _GRPC_PORT
  local _POD_LABEL
  local _POD_NAME

  read _INDEX_LOCATION _INDEX_NAME _TAG <<<$(_f_indexname_tag $_IMG)

  read _PPROF_PORT _GRPC_PORT <<< $(_f_port_map $_TAG $_INDEX_NAME)

  _POD_LABEL="index=${_INDEX_NAME}_${_PPROF_PORT}_${_GRPC_PORT}"
  _POD_NAME="${_INDEX_NAME}_${_PPROF_PORT}_${_GRPC_PORT}"
 
  printf '%s %s %s %s' $_POD_LABEL $_POD_NAME $_PPROF_PORT $_GRPC_PORT 

}

_f_indexname_tag_ext() {

  local _FP_PULLSPEC=$1

  local _EXT=${_FN_PULLSPEC##*.}

  read _INDEX_NAME _TAG <<<$(_f_indexname_tag $_FN_PULLSPEC)

  echo -ne $_INDEX_NAME $_TAG $_EXT

}

map_csv_version() {
  # ie quay-operator.v3.13.6 >>> 3.13.6
  sed -E 's/^[v](.*)/\1/' <<<$(cut -d. -f2- <<<$1)
}

_f_map_target_name() {
  # reg.int.lan:5000/baseline/20250701/redhat-operator-index:v4.16
  # >>> redhat-operator-index

  cut -d : -f1 <<<$(basename $1)
}

_f_map_storage_config_url() {
  # reg.int.lan:5000/baseline/20250701/redhat-operator-index:v4.16
  # >>> reg.int.lan:5000
  
  cut -d/ -f1 <<<$1
}

_map_csv_version() {
  # ie quay-operator.v3.13.6 >>> 3.13.6

  sed -E 's/^[v](.*)/\1/' <<<$(cut -d. -f2- <<<$1)
}

_intersection() {
  local -n S1=$1
  local -n S2=$2
  local -n _S_INTERSECT=$3
  local -n _S_OUTER=$4

  declare -A _OUTER_SET=()
  for i1 in ${S1[@]}; do
    _OUTER_SET[$i1]=1
  done

  for i1 in ${S1[@]}; do
    for i2 in ${S2[@]}; do
      if [[ $i1 == $i2 ]]; then 
        _S_INTERSECT+=( $i1 )
        unset _OUTER_SET[$i1]
      fi
    done
  done
  _S_OUTER=${!_OUTER_SET[@]}
}

_demo_prompt() {
  if [[ -n $_NOREAD ]]; then
    echo -ne "$@\n"
  else
    echo -ne "\n$@ "
    read 
    echo
    eval $@
    echo
  fi
}


