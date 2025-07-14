#!/bin/bash

export PODMAN_IGNORE_CGROUPSV1_WARNING=1

source $(dirname ${BASH_SOURCE})/lib/utility.sh

export _SKIP_POD_RM=${SKIP_POD_RM:-}

_NOREAD=1 _demo_prompt '# Pull and tag images for a baseline'

_NOREAD=1 _demo_prompt '# View current images'

_demo_prompt 'podman images|grep index'

_NOREAD=1 _demo_prompt '# Use baseline.sh to tag a long-lived baseline index, based on same cutspecs used to generate the ImageSetConfiguration'

_demo_prompt 'cat cutspecs/select_rh_operators/*'

_demo_prompt 'SKIP_PUSH=1 ./scripts/baseline.sh demo-20250715 reg.dmz.lan/baseline cutspecs/select_rh_operators'

_NOREAD=1 _demo_prompt '# Run podman ps again, note the (DATESTAMP/REGISTRY LOCATION) tagged "baseline" indexes'

_demo_prompt 'podman images --noheading | sort'

_NOREAD=1 _demo_prompt '\n*******************\nRun cut.sh on the same cutspec folder'

_demo_prompt GEN_ISC=1 ./scripts/cut.sh demo-20250715 reg.dmz.lan/baseline cutspecs/select_rh_operators

_demo_prompt 'find baseline/demo-20250715'




