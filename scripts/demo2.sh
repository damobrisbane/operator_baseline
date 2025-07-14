#!/bin/bash

export PODMAN_IGNORE_CGROUPSV1_WARNING=1

source $(dirname ${BASH_SOURCE})/lib/utility.sh


_NOREAD=1 _demo_prompt '# Run and compare multiple baselines'

_demo_prompt 'cat cutspecs/minimal_specs_20250709/*'

_NOREAD=1 _demo_prompt '# Run cut.sh. NB: ALL_PKGS flag takes longer to run..'

_demo_prompt SKIP_POD_RM=1 GEN_ISC=1 ALL_PKGS=1 DEBUG=1 ./scripts/cut.sh demo2-20250709 reg.dmz.lan/baseline cutspecs/minimal_specs_20250709

_demo_prompt 'find baseline/demo2-20250709/'

_demo_prompt '# We will now compare baseline over three minor version indexes'

