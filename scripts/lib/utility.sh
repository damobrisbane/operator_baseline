#!/bin/bash

_log() {

  local _LVL=$1 && shift

  case $_LVL in
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
  _log 2 "Sleeping $_DELAY secs.."
  sleep $_DELAY
}

d1() {
  date +%Y%m%d
}

_f_indexname_tag() {
  # ie redhat-operators:v4.16 
  # >>>
  # redhat-operators v4.16

  sed -E 's/(.*)-(v[[:alnum:]]+.[[:alnum:]]+).[[:alnum:]]+$/\1 \2/' <<<$1
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

_right_join() {
  # not currently used
  local -n L1=$1
  local -n L2=$2

  local _L_JOIN=()

  for _m in ${L2[@]}; do
    for _n in ${L1[@]}; do
      [[ $_m == $_n ]] && _L_JOIN+=( $_m )
    done
  done

  echo -ne ${L2[@]}
}


