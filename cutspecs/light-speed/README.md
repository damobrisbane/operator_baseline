> GRPC_IMAGES=1 GEN_API=1 SKIP_POD_RM=1 ./scripts/cut.sh lightspeed reg.dmz.lan/baseline cutspecs/light-speed-v4.17

```
{
  "catalog": "registry.redhat.io/redhat/redhat-operator-index:v4.17",
  "packages": [
    {
      "name": "lightspeed-operator",
      "defaultChannelName": "stable",
      "channels": [
        {
          "name": "stable",
          "minVersion": "1.0.1",
          "bundlePath": "registry.redhat.io/openshift-lightspeed/lightspeed-operator-bundle@sha256:6d8f277d735816b0263202ea7213869a724d2e7400c82807927ddcefb236a72c",
          "relatedImages": [
            "registry.redhat.io/openshift-lightspeed/lightspeed-service-api-rhel9@sha256:2b9c0462a2453f85b3cc03339135a6dc77ceb417d89b7f671d1aac18582058ca",
            "registry.redhat.io/openshift-lightspeed/lightspeed-console-plugin-rhel9@sha256:854ce0b95b52f39fa396ece7304bc20c6427bcf9da89d14686e5eda578d14741",
            "registry.redhat.io/openshift-lightspeed/lightspeed-rhel9-operator@sha256:965d739b00a1f9b11163c5826228ca916e6e8dba228a39f03809437d88bf267e",
            "registry.redhat.io/openshift-lightspeed/lightspeed-operator-bundle@sha256:6d8f277d735816b0263202ea7213869a724d2e7400c82807927ddcefb236a72c"
          ]
        }
      ]
    }
  ]
}
```

> podman pull registry.redhat.io/openshift-lightspeed/lightspeed-service-api-rhel9@sha256:2b9c0462a2453f85b3cc03339135a6dc77ceb417d89b7f671d1aac18582058ca

```
Trying to pull registry.redhat.io/openshift-lightspeed/lightspeed-service-api-rhel9@sha256:2b9c0462a2453f85b3cc03339135a6dc77ceb417d89b7f671d1aac18582058ca...
Getting image source signatures
Copying blob 9e0c739abd58 skipped: already exists  
Copying blob 1ec5864c3611 skipped: already exists  
Copying config fa4a2026ed done   | 
Writing manifest to image destination
fa4a2026ed4c7ea2fd39a3ddfcbc0800242900d2de118f60ed2a06c86affb107
> 
```

> podman tag registry.redhat.io/openshift-lightspeed/lightspeed-service-api-rhel9@sha256:2b9c0462a2453f85b3cc03339135a6dc77ceb417d89b7f671d1aac18582058ca reg.dmz.lan/openshift-lightspeed/lightspeed-service-api-rhel9
> 

> podman push reg.dmz.lan/openshift-lightspeed/lightspeed-service-api-rhel9

```
> podman push reg.dmz.lan/openshift-lightspeed/lightspeed-service-api-rhel9
Getting image source signatures
Copying blob 1ec5864c3611 skipped: already exists  
Copying blob 9e0c739abd58 skipped: already exists  
Copying config fa4a2026ed done   | 
Writing manifest to image destination
> 

```

> operator_baseline]$ find baseline -mmin -1

```
baseline
baseline/20250709/api-redhat-operator-index-v4.17-cut.json
```


![ref](./cut-operator_baseline.png)
