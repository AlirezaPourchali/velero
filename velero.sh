#!/bin/bash

velero install \
    --namespace velero \
    --provider aws \
    --plugins docker.iranrepo.ir/velero/velero-plugin-for-aws \
    --bucket velero2 \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=true \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000 \
    --image docker.iranrepo.ir/velero/velero \
    --snapshot-location-config region="default" \
    --use-node-agent   --wait 

    #kubectl -n test-nginx  annotate pod/nginx-test backup.velero.io/backup-volumes=mystorage
    #velero backup create test-pv-100  --include-namespaces test-nginx  --include-resources  persistentvolumeclaims,persistentvolumes --wait
    #dd if=/dev/urandom of=/usr/share/nginx/html/test-file3.txt count=512000 bs=1024
    #ls -laSh /usr/share/nginx/html/
