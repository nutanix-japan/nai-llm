

# Preparing NDK

In this section we will use just one Prism Central (PC)/Prism Element (PE)/K8s cluster to test the data recovery capabilities of NDK.

## Prerequisites
- NDK ``v1.2`` or later deployed on a Nutanix cluster
- Nutanix Kubernetes Platform (NKP) cluster ``v1.15`` or later deployed, accessible via `kubectl`. See [NKP Deployment](../infra/infra_nkp.md) for NKP install instructions.
- Internal Harbor container registry. See [Harbor Installation](../infra/harbor.md)
- Nutanix CSI driver installed for storage integration. [pre-configured with NKP install]
- Networking configured to allow communication between the Kubernetes cluster, PC and PE.
- Traefik Ingress controller installed for external access. [pre-configured with NKP install]
- K8s Load Balancer installed to facilitate replication workflows. [ Metallb pre-configured with NKP install]
- Linux Tools VM or equivalent environment with `kubectl`, `helm`, `curl`, `docker` and `jq` installed. See [Jumphost VM](../infra/workstation.md) for details.
- PC, PE and NKP access credentials


## High-Level Process

!!! warning

    NKP only supports NDK ``v1.2`` at the time of writing this lab.

    We will use NDK ``v1.2`` with NKP ``v2.15`` for this lab.

    This lab will be updated as NKP supports NDK ``v1.3`` in the near future.

1. Download NDK ``v1.2`` binaries that are available in Nutanix Support [Nutanix Portal](https://portal.nutanix.com/page/downloads?product=nkp)
2. Upload NDK containers to an internal Harbor registry
3. Enable NDK to trust internal Harbor registry. See [here](../appendix/nkp_cert_ds.md)
4. Install NDK ``v1.2``
   
## Setup source NKP in Primary PC/PE/K8s

Make sure to name your NKP cluster appropriately so it is easy to identify

For the purposes of this lab, we will call the source NKP cluster as ``nkpprimary``

> Follow instructions in [NKP Deployment](../infra/infra_nkp.md) to setup source/primary NKP K8s cluster.

## Setup Harbor Internal Registry 

> Follow instructions in [Harbor Installation](../infra/harbor.md) to setup internal Harbor registry for storing NDK ``v1.2`` containers.

1. Login to Harbor
2. Create a project called ``nkp`` in Harbor

## Prepare for NDK Installation

### Download NDK Binaries

1. Open new `VSCode` window on your jumphost VM

2.  In `VSCode` Explorer pane, click on existing ``$HOME`` folder

2.  Click on **New Folder** :material-folder-plus-outline: name it: ``ndk``

3.  On `VSCode` Explorer plane, click the ``$HOME/ndk`` folder

4.  On `VSCode` menu, select ``Terminal`` > ``New Terminal``

5.  Browse to ``ndk`` directory

    === ":octicons-command-palette-16: Command"
    
         ```bash
         cd $HOME/ndk
         ```

7. In ``VSC``, under the newly created ``ndk`` folder, click on **New File** :material-file-plus-outline: and create file with the following name:
   
    === ":octicons-command-palette-16: Command"
    
         ```bash
         .env
         ```

8. Add (append) the following environment variables and save it
   
    === ":octicons-file-code-16: Template .env"

        ```bash
        export NDK_VERSION=_your_ndk_version
        export JUMPBOX=_your_jumpboxvm_ip
        export SSH_USER=ubuntu
        export KUBE_RBAC_PROXY_VERSION=_vX.XX.X
        export KUBECTL_VERSION=_X.XX.X
        export IMAGE_REGISTRY=_your_harbor_registy_url/nkp
        ```
    
    === ":octicons-file-code-16: Sample .env"
        
        ```text
        export NDK_VERSION=1.2.0
        export JUMPBOX=10.x.x.124
        export SSH_USER=ubuntu
        export KUBE_RBAC_PROXY_VERSION=v0.17.0
        export KUBECTL_VERSION=1.30.3
        export IMAGE_REGISTRY=harbor.example.com/nkp
        ```

9. Source the ``.env`` file to import environment variables
   
    === ":octicons-command-palette-16: Command"
    
         ```bash
         source $HOME/ndk/.env
         ```

10. Login to [Nutanix Portal](https://portal.nutanix.com/page/downloads?product=ndk) using your credentials

11. Go to **Downloads** > **Nutanix Data Services for Kubernetes (NDK)** 
12. Scroll and choose **Nutanix Data Services for Kubernetes ( Version: 1.2.0 )**


13.  Download the NDK binaries bundle from the link you copied earlier
    
    === ":octicons-command-palette-16: Command"

        ```text title="Paste the download URL within double quotes"
        curl -o ndk-1.2.0.tar "_paste_download_URL_here"
        ```

    === ":octicons-command-palette-16:  Sample Command"
        
        ```{ .text .no-copy }
        $HOME/ndk $ curl -o ndk-1.2.0.tar "https://download.nutanix.com/downloads/ndk/1.2.0/ndk-1.2.0.tar?Expires=XXXXXXXXX__"
        ```

14. Extract the NDK binaries
    
    === ":octicons-command-palette-16: Command"

        ```text 
        tar -xvf ndk-${NDK_VERSION}.tar
        cd ndk-${NDK_VERSION}
        ```

    === ":octicons-command-palette-16:  Sample Command"
        
        ```{ .text .no-copy }
    
        tar -xvf ndk-1.2.0.tar
        cd ndk-1.2.0
        ```
    
    ??? Info "NDK Binaries Directory Contents"

        ```{ .text .no-copy }
        ~/ndk/ndk-1.2.0$ tree
        
        ├── ndk-1.2.0
        │   ├── chart
        │   │   ├── Chart.yaml                                      # NDK chart

        │   │   ├── crds
        │   │   │   └── scheduler.nutanix.com_jobschedulers.yaml    # NDK CRDs

        │   │   ├── templates

                │   │   └── values.yaml                             # NDK chart values

        │   └── ndk-1.2.0.tar                                       # NDK container images
        ```

### Upload NDK Binaries to Internal Registry

1. Load NDK container images and upload to internal Harbor registry

    === ":octicons-command-palette-16: Command"

        ```bash
        docker load -i ndk-${NDK_VERSION}.tar
        docker login ${IMAGE_REGISTRY} 

        for img in ndk/manager:${NDK_VERSION} ndk/infra-manager:${NDK_VERSION} ndk/job-scheduler:${NDK_VERSION} ndk/kube-rbac-proxy:${KUBE_RBAC_PROXY_VERSION} ndk/bitnami-kubectl:${KUBECTL_VERSION}; do docker tag $img ${IMAGE_REGISTRY}/${img}; docker push ${IMAGE_REGISTRY}/${img};done
        ```

    === ":octicons-command-palette-16:  Sample Command"
        
        ```{ .text .no-copy }
        docker load -i ndk-1.2.0.tar
        docker login harbor.example.com/nkp

        for img in ndk/manager:1.2.0 ndk/infra-manager:1.2.0 ndk/job-scheduler:1.2.0 ndk/kube-rbac-proxy:v0.17.0 ndk/bitnami-kubectl:1.30.3; do docker tag ndk/bitnami-kubectl:1.30.3 harbor.example.com/nkp/ndk/bitnami-kubectl:1.30.3; docker push harbor.example.com/nkp/ndk/bitnami-kubectl:1.30.3;done
        ```

## Install NDK ``v1.2.0``
    

1. Login to VSCode Terminal
2. Set you NKP cluster KUBECONFIG

    === ":octicons-command-palette-16: Command"
    
         ```bash
         export KUBECONFIG=$HOME/nkp/_nkp_primary_cluster_name.conf
         ```
 
    === ":octicons-command-palette-16: Sample Command"
 
         ```bash
         export KUBECONFIG=$HOME/nkp/nkpprimary.conf
         ```

3. Test connection to ``nkpprimary`` cluster 
   
    === ":octicons-command-palette-16: Command"
    
         ```bash
         kubectl get nodes -owide
         ```
 
    === ":octicons-command-palette-16: Sample Command"
 
         ```bash
         $ kubectl get nodes

         NAME                                STATUS   ROLES           AGE    VERSION
         nkpprimary-md-0-vd5kr-ff8r8-hq764   Ready    <none>          3d4h   v1.32.3
         nkpprimary-md-0-vd5kr-ff8r8-jjpvx   Ready    <none>          3d4h   v1.32.3
         nkpprimary-md-0-vd5kr-ff8r8-md28h   Ready    <none>          3d4h   v1.32.3
         nkpprimary-md-0-vd5kr-ff8r8-xvmf6   Ready    <none>          3d4h   v1.32.3
         nkpprimary-xnnk5-6pnr8              Ready    control-plane   3d4h   v1.32.3
         nkpprimary-xnnk5-87slh              Ready    control-plane   3d4h   v1.32.3
         nkpprimary-xnnk5-fjdd4              Ready    control-plane   3d4h   v1.32.3
         ```

4. Install NDK

    === ":octicons-command-palette-16: Command"

        ```text
        helm upgrade -n ntnx-system --install ndk chart/ \
        --set manager.repository="$IMAGE_REGISTRY/ndk/manager" \
        --set manager.tag=${NDK_VERSION} \
        --set infraManager.repository="$IMAGE_REGISTRY/ndk/infra-manager" \
        --set infraManager.tag=${NDK_VERSION} \
        --set kubeRbacProxy.repository="$IMAGE_REGISTRY/ndk/kube-rbac-proxy" \
        --set kubeRbacProxy.tag=${KUBE_RBAC_PROXY_VERSION} \
        --set bitnamiKubectl.repository="$IMAGE_REGISTRY/ndk/bitnami-kubectl" \
        --set bitnamiKubectl.tag=${KUBECTL_VERSION} \
        --set jobScheduler.repository="$IMAGE_REGISTRY/ndk/job-scheduler" \
        --set jobScheduler.tag=${NDK_VERSION} \
        --set config.secret.name=nutanix-csi-credentials \
        --set tls.server.enable=false
        ```

    === ":octicons-command-palette-16:  Sample Command"
        
        ```{ .text .no-copy }
        helm upgrade -n ntnx-system --install ndk chart/         
        --set manager.repository=harbor.example.com/nkp/ndk/manager         
        --set manager.tag=1.2.0         
        --set infraManager.repository=harbor.example.com/nkp/ndk/infra-manager         
        --set infraManager.tag=1.2.0         
        --set kubeRbacProxy.repository=harbor.example.com/nkp/ndk/kube-rbac-proxy         
        --set kubeRbacProxy.tag=v0.17.0         
        --set bitnamiKubectl.repository=harbor.example.com/nkp/ndk/bitnami-kubectl         
        --set bitnamiKubectl.tag=1.30.3         
        --set jobScheduler.repository=harbor.example.com/nkp/ndk/job-scheduler         
        --set jobScheduler.tag=1.2.0         
        --set config.secret.name=nutanix-csi-credentials         
        --set tls.server.enable=false
        ```

    === "Output"

        ```{ .text .no-copy }
        Release "ndk" does not exist. Installing it now.
        NAME: ndk
        LAST DEPLOYED: Mon Jul  7 06:33:28 2025
        NAMESPACE: ntnx-system
        STATUS: deployed
        REVISION: 1
        TEST SUITE: None
        ```

5. Check if all NDK resources are running (4 of 4 containers should be running inside the ``ndk-controller-manger`` pod)
   
    === ":octicons-command-palette-16: Command"

         ```bash
         kubens ntnx-system
         k get all -l app.kubernetes.io/name=ndk
         ```

    === ":octicons-command-palette-16:  Sample Command"
        
         ```text hl_lines="6 15 18"
         Active namespace is "ntnx-system".
 
         $ k get all -l app.kubernetes.io/name=ndk
 
         NAME                                          READY   STATUS    RESTARTS   AGE
         pod/ndk-controller-manager-57fd7fc56b-gg5nl   4/4     Running   0          19m
 
         NAME                                             TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)          AGE
         service/ndk-controller-manager-metrics-service   ClusterIP      10.109.134.126   <none>         8443/TCP         19m
         service/ndk-intercom-service                     LoadBalancer   10.99.216.62     10.122.7.212   2021:30258/TCP   19m
         service/ndk-scheduler-webhook-service            ClusterIP      10.96.174.148    <none>         9444/TCP         19m
         service/ndk-webhook-service                      ClusterIP      10.107.189.171   <none>         443/TCP          19m
 
         NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
         deployment.apps/ndk-controller-manager   1/1     1            1           19m
 
         NAME                                                DESIRED   CURRENT   READY   AGE
         replicaset.apps/ndk-controller-manager-57fd7fc56b   1         1         1       19m
         ```

## Configure NDK

The first component we would configure in NDK is ``StorageCluster``. This is used to represent the Nutanix Cluster components including the following:

- Prism Central (PC)
- Prism Element (PE)

By configuring ``StorageCluster`` resource with NDK, we are providing Nutanix infrastructure information to NDK.

1. Logon to PC
 
    === ":octicons-command-palette-16: Command"
    
         ```bash 
         ssh -l nutanix pc.example.com
         ```

2. Find PC UUID
   
    === ":octicons-command-palette-16: Command"
         
         ```bash 
         ncli cluster info
         ```

    === ":octicons-command-palette-16: Command Output"

        ```bash hl_lines="4"
        admin@NTNX-10-x-x-x-A-PCVM:~$ ncli cluster info

            Cluster Id                : d0f1eb56-9ee6-4469-b21f-xxxxxxxxxx::3611790923605874030
            Cluster Uuid              : d0f1eb56-9ee6-4469-b21f-xxxxxxxxxx
            Cluster Name              : PC_10.x.x.x
        ```

1. Logon to PE
 
    === ":octicons-command-palette-16: Command"
    
         ```bash 
         ssh -l nutanix pe.example.com
         ```

2. Find PE UUID
   
    === ":octicons-command-palette-16: Command"
         
         ```bash 
         ncli cluster info
         ```

    === ":octicons-command-palette-16: Command Output"

        ```bash hl_lines="4"
        admin@NTNX-10-x-x-x-A-PCVM:~$ ncli cluster info

            Cluster Id                : 00062f20-b2e0-fa8e-4b04-xxxxxxxxxx::5405509758989007242
            Cluster Uuid              : 00062f20-b2e0-fa8e-4b04-xxxxxxxxxx
            Cluster Name              : PE_10.x.x.x
        ```

3. Logon to Jumphost VM Terminal in ``VSCode``

    === ":octicons-command-palette-16: Command"
    
         ```bash
         cd $HOME/ndk
         ```

4. Add (append) the following environment variables and save it
   
    === ":octicons-file-code-16: Template .env"

        ```bash
        export PRISM_UUID=_pc_uuid_from_previous_commands
        export ELEMENT_UUID=_pe_uuid_from_previous_commands
        export SC_NAME=_storage_cluster_name
        export KUBECONFIG=$HOME/nkp/_nkp_primary_cluster_name.conf
        ```
    
    === ":octicons-file-code-16: Sample .env"
        
        ```text
        export PRISM_UUID=ad0f1eb56-9ee6-4469-b21f-xxxxxxxxxx
        export ELEMENT_UUID=00062f20-b2e0-fa8e-4b04-xxxxxxxxxx
        export SC_NAME=primary-storage-cluster
        export KUBECONFIG=$HOME/nkp/nkpprimary.conf
        ```
 
5. Source the ``.env`` file
    
    === ":octicons-command-palette-16: Command"
    
         ```bash
         source $HOME/ndk/.env
         ```

6. Create the StorageCluster resource
   
    === ":octicons-command-palette-16: Command"

         ```bash
         kubectl apply -f -<<EOF
         apiVersion: dataservices.nutanix.com/v1alpha1
         kind: StorageCluster
         metadata:
          name: $SC_NAME
         spec:
          storageServerUuid: $ELEMENT_UUID
          managementServerUuid: $PRISM_UUID
         EOF
         ```

    === ":octicons-command-palette-16: Command Output"

         ```bash
         storagecluster.dataservices.nutanix.com/primary-storage-cluster created
         ```

Now we are ready to create local cluster snapshots and snapshot restores using the following NDK resources:

-  ``ApplicationSnapshot`` and
-  ``ApplicationSnapshotRestore``