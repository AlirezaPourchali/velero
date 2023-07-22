# velero
velero for kubernetes backup     

# overview
Velero (formerly Heptio Ark) gives you tools to back up and restore your Kubernetes cluster resources and persistent volumes. You can run Velero with a `cloud provider` or `on-premises`. Velero lets you:

* Take backups of your cluster and restore in case of loss.
* Migrate cluster resources to other clusters.
* Replicate your production cluster to development and testing clusters.     

Velero consists of:

* A server that runs on your cluster , deployed either by the cli or the chart
* A command-line client that runs locally (veleri-cli)

![image](./resources/image.png)
# before installation
* In this document i will deploy velero server with the official chart.    
velero backs up data to a cloud provider , s3-compatible storage services can work as well. 
I want `on-premise` backup so `minio` will be used for that case.

* Another thing to mention is the way k8s `pvc` or `pv` backups work in velero    

1. If your k8s cluster support `csi` you can get `volumesnapshots` which by its name you can guess what it is.     
2. If you dont have that , you will have to use `file system backup`. this way uses open-source backup tools `restic` and `kopia`.    
this wont work with `hostPath` volumes.

*Important* : file system backup doesnt work in `minikube` for some [reason](https://github.com/vmware-tanzu/velero/issues/5018#issuecomment-1158966805) . in minikube you can only backup other object     

* 


# installation

You can follow the [official](https://velero.io/docs/v1.11/basic-install/) installation on `velero-cli`.    
I will install the velero server with the chart    

* first you have to [install](https://helm.sh/docs/intro/install/) `helm` before deploying the chart
```
git clone https://github.com/AlirezaPourchali/velero.git

cd velero

helm install velero --namespace velero vmware-tanzu/velero --values values.yml --version 4.1.3
```
* you might need to create `velero` namespace before installing the chart.

There is also a helmfile which you have to install as well and deploy it with the following command instead

```
helmfile apply
```
* Or use the script to install with velero-cli 
```
./velero.sh
```

# deploy minio
* For minio apply the yaml file like bellow
```
kubectl apply -f examples/minio/00-minio-deployment.yaml
```
* now in `velero` namespace you have minio and velero pods


 