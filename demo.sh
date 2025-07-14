#!/bin/bash

f1() {
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

_NOREAD=1 f1 '> # There is a selection of example cut specs'

f1 find cutspecs -type f

_NOREAD=1 f1 '> # Pull and tag images for a baseline'

_NOREAD=1 f1 '> # First, check current images'

f1 'podman images'

_NOREAD=1 f1 '> # Can see we already have index images. Good idea to tag them though'

_NOREAD=1 f1 '> # We can use baseline.sh and the minimal_specs for this, ie'

f1 'cat cutspecs/minimal_specs/*'

_NOREAD=1 f1 '> # In these cases, "catalog_baseline" will serve for the upstream indexes'

_NOREAD=1 f1 '> # Run ./scripts/baseline.sh. We will specify a DATESTAMP of "20250709" and REGISTRY_LOCATION of "reg.dmz.lan/baseline" and run baseline.sh with the cutspec directory as the last argument'

f1 ./scripts/baseline.sh 20250709 reg.dmz.lan/baseline cutspecs/minimal_specs 

_NOREAD=1 f1 '> # Run podman ps again, not the (DATESTAMP/REGISTRY LOCATION) tagged "baseline" indexes'

f1 'podman images --noheading | sort'

_NOREAD=1 f1 '\n*******************\nNow lets run through some cut scenarios, using the cutspecs we listed before'

_NOREAD=1 f1 '> # Test Cut Specs with real and bogus data'

f1 'cat cutspecs/real_and_bogus*|jq'

_NOREAD=1 f1 '> # Run cut.sh on the above folder and generate an ImageSetConfiguration, using same DATESTAMP and REGISTRY_LOCATION used in the baseline'

GEN_ISC=1 ./scripts/cut.sh 20250709 reg.dmz.lan/baseline cutspecs/real_and_bogus

exit

_NOREAD=1 f1 '> # Minimal Cut Specs'

f1 'cat cutspecs/minimal_specs/json0/*|jq'

exit

_NOREAD=1 f1 '> # Test Cut with real and bogus data'



exit
cls;DEBUG=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json1
vim scripts/cut.sh scripts/lib/container.sh  scripts/lib/grpc.sh scripts/lib/cutspec.sh  scripts/lib/utility.sh
vim README.md
cls;SKIP_POD_RM=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json1
vim scripts/cut.sh scripts/lib/container.sh  scripts/lib/grpc.sh scripts/lib/cutspec.sh  scripts/lib/utility.sh
grep -r "_log 1" .
cls;DEBUG=1 SKIP_POD_RM=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json1
cls
DEBUG=1 SKIP_POD_RM=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json1
podman images|grep index
/usr/bin/podman run -d -t --rm --label index=6077_50068 --name index_6077_50068 -p 6077:6060 -p 50068:50051 registry.redhat.io/redhat/redhat-operator-index:v4.17
podman ps -a
podman rm 3e703281763d c5f2577b9d7e 9155481bf3b3
podman rm -f 3e703281763d c5f2577b9d7e 9155481bf3b3
cls;DEBUG=1 SKIP_POD_RM=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json1
cls;SKIP_POD_RM=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json1
cls;DEBUG=1 SKIP_POD_RM=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json1
cls;SKIP_POD_RM=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json1
find baseline -mmin -1
vim -O -d baseline/20250709/*
rm baseline/20250709/*
cls;SKIP_POD_RM=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json1
vim -O -d baseline/20250709/*
cls;ALL_PKGS=1 SKIP_POD_RM=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json1
vim -O -d baseline/20250709/*
cat cut/v2-json0/*
cat cut/v2-json1/redhat-operator-indexes.json 
cat cut/v2-json2/*
cls;SKIP_POD_RM=1 GEN_ISC=1 ./scripts/cut.sh $D1 reg.dmz.lan/baseline cut/v2-json2

