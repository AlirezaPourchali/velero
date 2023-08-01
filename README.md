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

1 . If your k8s cluster support `csi` you can get `volumesnapshots` which by its name you can guess what it is.     
* One Important to consider is that the content of the snapshots (the actual data) is not backed up in minio or s3 storage providers    
    
2 . If you dont have that , you will have to use `file system backup`. this way uses open-source backup tools `restic` and `kopia`.    
    this wont work with `hostPath` volumes.

3. or enable `csi` like [here](https://github.com/AlirezaPourchali/velero/edit/main/README.md#csi)

*Important* : file system backup doesnt work in `minikube` for some [reason](https://github.com/vmware-tanzu/velero/issues/5018#issuecomment-1158966805) . in minikube you can only backup other object 
or enable csi for minikube and backup with snapshots.




# installation

You can follow the [official](https://velero.io/docs/v1.11/basic-install/) installation on `velero-cli`.    
I will install the velero server with the chart    

* first you have to [install](https://helm.sh/docs/intro/install/) `helm` before deploying the chart
```
git clone https://github.com/AlirezaPourchali/velero.git

cd velero

helm install velero --namespace velero vmware-tanzu/velero --values values/new.yml --version 4.1.3
```
* you might need to create `velero` namespace before installing the chart.

There is also a helmfile which you have to install as well and deploy it with the following command instead

```
helmfile apply
```


# deploy minio
* For minio apply the yaml file like bellow

```
kubectl apply -f examples/minio/00-minio-deployment.yaml
```

* now in `velero` namespace you have minio and velero pods


# File System Backup

* lets deploy a test pod and backup pvc

```
kubectl apply -f nginx-velero-pvc.yml
kubectl apply -f nginx-velero.yml
```

* lets put some data in there.

```
kubectl exec -it nginx-test sh
```

* create a random file around 10mb inside the pod  

```
$ dd if=/dev/urandom of=/usr/share/nginx/html/test-file3.txt count=10000 bs=1024

$ ls -laSh /usr/share/nginx/html/
```
* for the backup to work , the node agent will check the annotation of a pod and the name of the volume you set

* there are 3 ways opt-in , opt-out stated [here](https://velero.io/docs/v1.11/file-system-backup/)
* another way to go around this , in the velero chart set
the following parameter to backup by restic by default.

```
defaultVolumesToFsBackup: false
```

* we use opt-in 

```
kubectl  annotate pod nginx-test3 backup.velero.io/backup-volumes=mystorage 
# mystorage is the name of the volume , see the pod manifest.
```

* now to backup 

```
velero backup create test-pv-100  --include-namespaces velero  --include-resources  persistentvolumeclaims,persistentvolumes.pods --selector app=nginx --wait -v=5
```

* for this to work , you need permissions to a lot of objects and resources

* you can debug it with `velero backup describe` or `velero backup logs` commands 

* you can check your minio to see if the backup is done successfully or not.

* if you get something like "minio.svc" cannot be resolved , do next step (port-forward) before backingup.

* install [minio-client](https://min.io/docs/minio/linux/reference/minio-mc.html)

* change to velero namespace

```
kubectl port-forward <minio-pod> 9000:9000

```

* in another shell

```
mc ls local/velero/backups/restic/velero
```
* in this directory you should see a `data` subdirectory    
it contains **the data from the volume you annotated**.

* inside `data` directory subdirectories will be made (i think the names are the first 2 characters of the hashed backup name) 

* there should be a file arount 10mb there.

# restoring 

* delete the pod and pvc and pv , and run the following 
```
velero restore create --from-backup test-pv-100 
```
* it will create your pvc , pv , pod.

* if you check the pod you will see that an `init container` is used to get the data from minio to the volume.

* it uses the `velero-restore-helper` image , which can be modified by a [configmap](https://velero.io/docs/v1.11/file-system-backup/#customize-restore-helper-container).   

note: could get the configmap to work yet


# csi 

For enabling csi in the cluster , 'minikube' in this matter , follow [these](https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/docs/deploy-1.17-and-later.md) steps.     

some of the manifest that you need to apply might have an image that you cannot download (403).    

i have stored the images on dockerhub for easier access and you can apply my modified manifest (or edit the deployments and statefullsets images registry to `docker.iranrepo.ir/salehborhani`)

replaced [manifests](./csi-manifest/)    
* Snapshotcrd's
* Snapshot controller
* manifest.deploy --> changed the images that are deployed within csi-hostpathplugin-0 while running the deploy.sh [script](https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/deploy/kubernetes-1.24) (an example)


# volumesnapshot  
