
jq 'fromjson' <<<$(grpcurl -plaintext -d '{"pkgName":"advanced-cluster-management","channelName":"release-2.12"}' localhost:50067 api.Registry/GetBundleForChannel | jq .csvJson) > csvJson.json

jq -r '.spec|.relatedImages[].image' csvJson.json 
