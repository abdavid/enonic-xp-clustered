# Enonic XP Basic Cluster example k8s

### Getting this example up and running
Since we are using k8s configmaps to store configuration for each node type, we are required to build our own image off of 
Enonics base image. See the `Dockerfile` for more information about that. 

1. Build a Docker image from the supplied `Dockerfile` - name it (and push if necessary) and reference the image name in the deployments.
2. Change pv-*.yaml files in the storage folder to match your setup. 
3. `kubectl apply -k infrastructure`

```
infrastructure
├── 00-namespace.yaml
├── config
│   ├── config-backend.yaml
│   ├── config-frontend.yaml
│   └── config-master.yaml
├── deployments
│   ├── deployment-backend.yaml
│   ├── deployment-frontend.yaml
│   └── deployment-master.yaml
├── kustomization.yaml
├── services
│   ├── elastic.yaml
│   ├── hazelcast.yaml
│   ├── http.yaml
│   └── monitoring.yaml
└── storage
    ├── pv-blob.yaml
    ├── pv-data.yaml
    ├── pv-snapshots.yaml
    ├── pvc-blob.yaml
    ├── pvc-data.yaml
    └── pvc-snapshots.yaml

4 directories, 18 files
```
