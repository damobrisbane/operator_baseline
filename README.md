
# Operator Baseline/Appliance Tooling

Shell script focused tooling for Openshift operator catalog mirroring. Useful for disconnected environments with a need to baseline operators on "minVersion" and consume the associated catalog indexes, independently of any upstream catalog updates. See [Creating the image set configuration](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/mirroring-in-disconnected-environments#oc-mirror-building-image-set-config-v2_about-installing-oc-mirror-v2).

Given an input pullspecs, output catalog operators, channels and versions. May optionally include operator bundle image references, or output an ImageSetConfiguration (ISC). A "pullspec" is a list of operators/catalog packages, where the only requirement is the package name. 

For an ISC, accept json or yaml for both input and output (see Global parameters). An input pullspec is configured as a folder path that potentially contains pullspecs for redhat, certified and community operators. Optionally include a list of channels. The default channel will be determined from a grpc catalog query and included in the output, regardless of whether it was specified or not (hence an empty list of channels for a given package still produces a viable "defaultChannel" output. 

Other fields such as defaultChannelName or [channel] csvName can exist in the pullspec for a package, but these fields will be ignored. This behaviour guarrantees accuracy ie of channel versions and default channels against a baselined index over any on-disk specs that may lag a new mirroring operation (ie see [Pre-Work](#Pre-Work)).

## Requires

sed  
[grpcurl](https://github.com/fullstorydev/grpcurl)  
jq  
[yq](https://github.com/mikefarah/yq)  
podman or docker

# WorkFlow

## Pre-work

 CATALOG_NAMES = redhat certified community

 For each CATALOG_NAME in CATALOG_NAMES:

   a) pull and tag current upstream index for the new baseline <CATALOG_LOCATION>[/<CATALOG_NAME>:<VERSION>]

   b) push the <CATALOG_LOCATION>[/<CATALOG_NAME>:<VERSION>] into target registry <sup>1</sup>

<sup>1</sup> Any future consumption activity on the catalog is out of scope for [operator_baseline](https://github.com/damobrisbane/operator_baseline).

_See also [pre-work.sh](./scripts/pre-work.sh)_

## Running

Run script on PULLSPEC_DIR, which expects _Pre-Work_ to have been completed:

```     
> D1=$(date +%Y%m%d)
> CATALOG_LOCATION=reg.dmz.lan/baseline/$D1
> cls;GEN_ISC=1 ./files/common/baseline.sh $D1 $CATALOG_LOCATION $PULLSPEC_DIR
```
where PULLSPEC_DIR is the root folder containing spec files for operator mirroring specs (yaml or json)

Where CATALOG_LOCATION is BOTH a grpc location and a destination registry location

_See also [baseline.sh](./scripts/baseline.sh)_

## Consuming

Consume the baseline ImageSetConfiguration, where its _CatalogName_ should align with <CATALOG_LOCATION>[/<CATALOG_NAME>:<VERSION>] of the pre-work. CATLOG_NAME should correspond to the pullspec file name, refer code:

```
_CATALOG_NAME=${_FN_PULLSPEC%.*}
```

## Container Images to script execution, to registry location mapping


Given an image name:

```
> podman ps:
> reg.dmz.lan/baseline/20250701/certified-operator-index   v4.16     c85077a313ec   9 hours ago     1.5GB
```

And the script execution ( baseline.sh \<D1\> \<CATALOG_LOCATION\> \<PULLSEC_DIR\> ):

```
baseline.sh 20250704 reg.dmz.lan/baseline pullspecs/test1
```

Where pullspecs/test1 folder contains the pullspec file _redhat-operator-index-v4.16.json_

Generate an ISC CatalogName of _reg.dmz.lan/baseline/20250704/redat-operator-indexo:v4.16_

The name of the pullspec file is implicitly used as catalog index name and tag in the code. ie _redhat-operator-index-v4.16_ becomes [catalog name] _redhat-operator-index_ and [tag] _v4.16_. This mapping needs to align with the image name shown in the _podman ps_ command, above.

## BUNDLE parameter

Running with BUNDLE=1 gives bundle image in the output:

```
> BUNDLE=1 FORMATS=json ./scripts/baseline.sh $D1 $CATALOG_LOCATION pullspec/json1

...


[
  {
    "name": "advanced-cluster-management",
    "defaultChannelName": "release-2.13",
    "channels": [
      {
        "name": "release-2.13",
        "csvName": "advanced-cluster-management.v2.13.3",
        "version": "2.13.3",
        "bundlePath": "registry.redhat.io/rhacm2/acm-operator-bundle@sha256:be468395c00c323b013c14f535472f5d7f49b9ed36fba2645ff102eaf99b197e"
      }
    ]
  },
  {
    "name": "ansible-automation-platform-operator",
    "defaultChannelName": "stable-2.5",
    "channels": [
      {
        "name": "stable-2.5",
        "csvName": "aap-operator.v2.5.0-0.1750901111",
        "version": "2.5.0-0.1750901111",
        "bundlePath": "registry.redhat.io/ansible-automation-platform/platform-operator-bundle@sha256:bcd18a86b1ca2f62177bb66a72ec2a4fcd58b49411635e3b725c4b934e59ee2e"
      }
    ]
  },
  {
...

```

## Generating a new baseline

Can imagine other approaches available for this (TBD link(s)), however you could also [after pre-work] do below, and then tweak the generated files:

```
> mkdir tmp; touch tmp/{redhat,certified,community}-operator-index-v4.16.ndjson

> REPORT_LOCATION=pullspec/MYNEWSPEC ALL_PKGS=1 FORMATS=json ./scripts/baseline.sh $D1 $CATALOG_LOCATION tmp

> find pullspec/MYNEWSPEC/
pullspec/MYNEWSPEC/
pullspec/MYNEWSPEC/20250705
pullspec/MYNEWSPEC/20250705/certified-operator-index.isc-json
pullspec/MYNEWSPEC/20250705/community-operator-index.isc-json
pullspec/MYNEWSPEC/20250705/redhat-operator-index.isc-json

> head pullspec/MYNEWSPEC/20250705/redhat-operator-index.isc-json
[
  {
    "name": "3scale-operator",
    "channels": [
      {
        "name": "threescale-mas",
        "minVersion": "0.12.1-mas"
      },
      {
        "name": "threescale-2.15",


```


## TBD

Versioning, see comment in [baseline.sh](./scripts/baseline.sh)

Incorporate the _additionalImages_ in a pullspec [and a generated ISC].
