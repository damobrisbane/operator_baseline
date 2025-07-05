
# Operator Baseline/Appliance Tooling

Shell script focused tooling for Openshift operator catalog mirroring. Useful for disconnected environments with a need to baseline operators on "minVersion" and consume the associated catalog indexes, independently of any upstream catalog updates.

Given an input pullspecs, output catalog operators, channels and versions. May optionally include operator bundle image references, or output an ImageSetConfiguration (ISC). For an ISC, accept json or yaml for both input and output (see Global parameters). An input pullspec is configured as a folder path that potentially contains pullspecs for redhat, certified and community operators.

A "pullspec" is a list of operators/catalog packages, where the only requirement is the package name. 

Optionally include a list of channels. The default channel will be determined from a grpc catalog query and included in the output, regardless of whether it was specified or not (hence an empty list of channels for a given package still produces a viable "defaultChannel" output. 

Other fields such as defaultChannelName or [channel] csvName can exist in the pullspec for a package, but these fields will be ignored. This behaviour guarrantees accuracy ie of channel versions and default channels against a baselined index over any on-disk specs that may lag a new mirroring operation (ie see [Pre-Work](#Pre-Work)).

## Requires

```
grpcurl
jq
yq: https://github.com/mikefarah/yq
podman or docker
```

# WorkFlow

## Pre-work

 CATALOG_NAMES = redhat certified community

 For each CATALOG_NAME in CATALOG_NAMES:

   a) pull and tag current upstream index for the new baseline <CATALOG_LOCATION>[/<CATALOG_NAME>:<VERSION>]

   b) push the <CATALOG_LOCATION>[/<CATALOG_NAME>:<VERSION>] into target registry [future out of scope activity on the baselined catalog].

_See also [pre-work.sh](./scripts/pre-work.sh)_

## Running

Run script on PULLSPEC_DIR, which expects _Pre-Work_ to have been completed:

```     
> D1=$(date +%Y%m%d)
> CATALOG_LOCATION=reg.dmz.lan/baseline/$D1
> cls;GEN_ISC=1 ./files/common/main.sh $D1 $CATALOG_LOCATION $PULLSPEC_DIR
```
where PULLSPEC_DIR is the root folder containing spec files for operator mirroring specs (yaml or json)

Where CATALOG_LOCATION is BOTH a grpc location and a destination registry location

_See also [main.sh](./scripts/main.sh)_

## Consuming

Consume the baseline ImageSetConfiguration, where its _CatalogName_ should align with <CATALOG_LOCATION>[/<CATALOG_NAME>:<VERSION>] of the pre-work. CATLOG_NAME Should correspond to the pullspec file name, refer code "\_CATALOG_NAME=${_FN_PULLSPEC%.*}".

## TBD

Versioning, see comment in [main.sh](./scripts/main.sh)

Incorporate the _additionalImages_ in a pullspec [and a generated ISC].

