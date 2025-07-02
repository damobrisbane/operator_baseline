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

_right_join() {
  local -n L1=$1
  local -n L2=$2

  local L3=()

  for _m in ${L2[@]}; do
    for _n in ${L1[@]}; do
      if [[ $_m == $_n ]]; then
        L3+=( $_m )
      fi
    done
  done

  echo -ne ${L2[@]}
}

_map_csv_version() {
  # ie quay-operator.v3.13.6 >>> 3.13.6
  sed -E 's/^[v](.*)/\1/' <<<$(cut -d. -f2- <<<$1)
}

_f_map_image_tag() {
  # reg.int.lan/baseline/20250701/redhat-operator-index:v4.16
  # >>> 4.16

  grep "v[[:digit:]]\+\.[[:digit:]]\+$" <<<$(cut -d: -f2 <<<$(basename $1))
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
