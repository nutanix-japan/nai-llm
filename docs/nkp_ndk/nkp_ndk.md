# Preparing NDK

In this section we will use just one Prism Central (PC)/Prism Element (PE)/K8s cluster to test the data recovery capabilities of NDK.

## Prerequisites
- NDK ``2.0.0`` or later deployed on a Nutanix cluster
- Nutanix Kubernetes Platform (NKP) cluster ``v2.16.1`` [or later] deployed, accessible via `kubectl`. See [NKP Deployment](../infra/infra_nkp.md) for NKP install instructions.
  
- Internal Harbor container registry
  
    * See [Harbor Installation](../infra/harbor.md)
    * Direct download from Docker.io is also possible [See inline notes in the lab]

- Nutanix CSI driver installed for storage integration. [pre-configured with NKP install]
- Networking configured to allow communication between the Kubernetes cluster, PC and PE.
- Traefik Ingress controller installed for external access. [pre-configured with NKP install]
- K8s Load Balancer installed to facilitate replication workflows. [ Metallb pre-configured with NKP install]
- Linux Tools VM or equivalent environment with `kubectl`, `helm`, `curl`, `docker` and `jq` installed. See [Jumphost VM](../infra/workstation.md) for details.
- PC, PE and NKP access credentials


## High-Level Process

!!! warning

    NKP supports NDK ``v2.0.0`` at the time of writing this lab with CSI version ``3.3.8``.

    We will use NDK ``v2.0.0`` with NKP ``v2.16.1`` for this lab.

    CSI version ``3.3.8`` is necessary for Nutanix Files replication and protection. 

1. Download NDK ``v2.0.0`` binaries that are available in Nutanix Support [Nutanix Portal](https://portal.nutanix.com/page/downloads?product=nkp)
2. Get NDK container download credentials
3. Install NDK helm charts
4. Install NDK ``v2.0.0``

## Setup source NKP in Primary PC/PE/K8s

Make sure to name your NKP cluster appropriately so it is easy to identify

For the purposes of this lab, we will call the source NKP cluster as ``nkpprimary``

> Follow instructions in [NKP Deployment](../infra/infra_nkp.md) to setup source/primary NKP K8s cluster.

## Prepare for NDK Installation

??? tip "Are you installing in an air-gap environment?"

    > Follow instructions in [NDK Air-Gap Deployment](airgap_nkp_ndk.md) to setup source/primary NKP K8s cluster.


### Download NDK Binaries

1. Open new `VSCode` window on your jumphost VM

2.  In `VSCode` Explorer pane, click on existing ``$HOME`` folder

2.  Click on **New Folder** :material-folder-plus-outline: name it: ``ndk``

3.  On `VSCode` Explorer plane, click the ``$HOME/ndk`` folder

7.  Login to [Nutanix Portal](https://portal.nutanix.com/page/downloads?product=ndk) using your credentials

8.  Go to **Downloads** > **Nutanix Data Services for Kubernetes (NDK)** 
9.  On top of the download page, get the Docker registry download credentials under **Manage Access Token**
    
      * Username 
      * Access Token (password)
   
    We will use these values in the ``.env`` file
    
10. In ``VSC``, under the newly created ``ndk`` folder, click on **New File** :material-file-plus-outline: and create file with the following name:
   
    === ":octicons-file-code-16: File"
    
         ```bash
         .env
         ```

11. Add (append) the following environment variables and save it
   
    === ":octicons-file-code-16: Template .env"

        ```bash
        export NDK_VERSION=_your_ndk_version
        export DOCKER_USERNAME=_NDK_GA_release_docker_username  # (1)!
        export DOCKER_PASSWORD=_NDK_GA_release_docker_password  # (2)!
        ```

        1.  Username from **Manage Access Token** section.
        2.  Access Token (password) from **Manage Access Token** section.
    
    === ":octicons-file-code-16: Sample .env"
        
        ```text
        export NDK_VERSION=2.0.0
        export DOCKER_USERNAME=nutanixndk
        export DOCKER_PASSWORD=dckr_pat_xxxxxxxxxxxxxxxxxxxxx
        ```

12. Source the ``.env`` file to import environment variables
   
    === ":octicons-command-palette-16: Command"
    
         ```bash
         source $HOME/ndk/.env
         ```

13. Scroll and choose **Nutanix Data Services for Kubernetes ( Version: 2.0.0 )**


13.  Download the NDK binaries bundle from the link you copied earlier
    
    === ":octicons-command-palette-16: Command"

        ```text title="Paste the download URL within double quotes"
        curl -o ndk-1.2.0.tar "_paste_download_URL_here"
        ```

    === ":octicons-command-palette-16:  Sample Command"
        
        ```{ .text .no-copy }
        $HOME/ndk $ curl -o ndk-1.2.0.tar "https://download.nutanix.com/downloads/ndk/1.2.0/ndk-1.2.0.tar?Expires=XXXXXXXXX__"
        ```

7.  Extract the NDK binaries
    
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

### Install NDK on Primary NKP Cluster
    

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

         ```bash
         helm repo add ntnx-charts https://nutanix.github.io/helm-releases/ && helm repo update ntnx-charts
         ```
         ```bash
         helm install ndk -n ntnx-system ntnx-charts/ndk \
         --version 2.0.0 \
         --set imageCredentials.credentials.username=$DOCKER_USERNAME \
         --set imageCredentials.credentials.password=$DOCKER_PASSWORD \
         --set config.secret.name=nutanix-csi-credentials \
         --set tls.server.enable=false
         ```

    === ":octicons-command-palette-16:  Sample Command"
        
         ```{ .text .no-copy }
         helm repo add ntnx-charts https://nutanix.github.io/helm-releases/ && helm repo update ntnx-charts
         ```
         ```{ .text .no-copy }
         helm install ndk -n ntnx-system ntnx-charts/ndk \
         --version 2.0.0 \
         --set imageCredentials.credentials.username=nutanixndk \
         --set imageCredentials.credentials.password=dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxx \
         --set config.secret.name=nutanix-csi-credentials \
         --set tls.server.enable=false
         ```

    === ":octicons-command-palette-16: Command output"
    
         ```{ .text .no-copy }
         Release "ndk" does not exist. Installing it now.
         NAME: ndk
         LAST DEPLOYED: Mon Jul  7 06:33:28 2025
         NAMESPACE: ntnx-system
         STATUS: deployed
         REVISION: 1
         TEST SUITE: None
         ```

5. Check if all NDK custom resources are running (4 of 4 containers should be running inside the ``ndk-controller-manger`` pod)
   
    === ":octicons-command-palette-16: Command"

         ```bash
         kubens ntnx-system
         k get all -l app.kubernetes.io/name=ndk
         ```

    === ":octicons-command-palette-16:  Command output"
        
         ```text hl_lines="6 15 18"
         Active namespace is "ntnx-system".
 
         $ k get all -l app.kubernetes.io/name=ndk
 
         NAME                                          READY   STATUS    RESTARTS   AGE
         pod/ndk-controller-manager-754bcbf7d4-8wn55   4/4     Running   0          77m
         
         NAME                                             TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE
         service/ndk-controller-manager-metrics-service   ClusterIP      10.96.236.12    <none>         8443/TCP         77m
         service/ndk-intercom-service                     LoadBalancer   10.102.58.136   10.x.x.216     2021:30215/TCP   77m
         service/ndk-scheduler-webhook-service            ClusterIP      10.111.99.86    <none>         9444/TCP         77m
         service/ndk-webhook-service                      ClusterIP      10.106.40.106   <none>         443/TCP          77m
         
         NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
         deployment.apps/ndk-controller-manager   1/1     1            1           77m
         
         NAME                                                DESIRED   CURRENT   READY   AGE
         replicaset.apps/ndk-controller-manager-754bcbf7d4   1         1         1       77m
         ```

## NDK Custom Resources for K8s

To begin protecting applications with NDK, it is good to become familiar with the NDK custom resources and how they are used to manage data protection. The following table provides a brief overview of the NDK custom resources and their purposes.

For more information about the NDK custom resources, see the [NDK Custom Resources](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Data-Services-for-Kubernetes:top-terminology-k8s-r.html) section of the NDK
documentation.

!!! tip

    We will be using NDK custom resources throughout the lab for accomplising data protection tasks and show the relationship between these custom resources as well.

| Custom Resource          | Purpose                                           |
|--------------------------|---------------------------------------------------|
| ``StorageCluster``           | Defines the Nutanix storage fabric and UUIDs for PE and PC. |
| ``Application``              | Defines a logical group of K8s resources for data protection. |
| ``ApplicationSnapshotContent`` | Stores infrastructure-level data of an application snapshot. |
| ``ApplicationSnapshot``      | Takes a snapshot of an application and its volumes. |
| ``ApplicationSnapshotRestore`` | Restores an application snapshot. |
| ``Remote``                   | Defines a target Kubernetes cluster for replication. |
| ``ReplicationTarget``        | Specifies where to replicate an application snapshot. |
| ``ApplicationSnapshotReplication`` | Triggers snapshot replication to another cluster. |
| ``JobScheduler``             | Defines schedules for data protection jobs. |
| ``ProtectionPlan``           | Defines snapshot and replication rules and retention. |
| ``AppProtectionPlan``        | Applies one or more ProtectionPlans to an application. |

## Configure NDK

The first component we would configure in NDK is ``StorageCluster``. This is used to represent the Nutanix Cluster components including the following:

- Prism Central (PC)
- Prism Element (PE)

By configuring ``StorageCluster`` custom resource with NDK, we are providing Nutanix infrastructure information to NDK.


1. Logon to Jumphost VM Terminal in ``VSCode``

    === ":octicons-command-palette-16: Command"
    
         ```bash
         cd $HOME/ndk
         ```

2. Get uuid of PC and PE using the following command

    === ":octicons-command-palette-16:  Template Command"

        ```bash
        kubectl get node _any_nkp_node_name -o jsonpath='{.metadata.labels}' | grep -o 'csi\.nutanix\.com/[^,]*' 
        ```
    
    === ":octicons-command-palette-16:  Sample .command"
        
        ```text
        kubectl get node nkprimary-md-0-vd5kr-ff8r8-hq764 -o jsonpath='{.metadata.labels}' | grep -o 'csi\.nutanix\.com/[^,]*' 
        ```
    === ":octicons-command-palette-16:  Command output"
        
        ```text hl_lines="3 4"
        $ kubectl get node nkprimary-md-0-vd5kr-ff8r8-hq764 -o jsonpath='{.metadata.labels}' | grep -o 'csi\.nutanix\.com/[^,]*' 

        csi.nutanix.com/prism-central-uuid":"d0f1eb56-9ee6-4469-b21f-xxxxxxxxxxxx"
        csi.nutanix.com/prism-element-uuid":"00062f20-b2e0-fa8e-4b04-xxxxxxxxxxxx"
        ```

3. Add (append) the following environment variables ``$HOME/ndk/.env`` and save it
   
    === ":octicons-file-code-16: Template .env"

        ```text
        export PRISM_CENTRAL_UUID=_pc_uuid_from_previous_commands
        export PRISM_ELEMENT_UUID=_pe_uuid_from_previous_commands
        export SC_NAME=_storage_cluster_name
        export KUBECONFIG=$HOME/nkp/_nkp_primary_cluster_name.conf
        ```
    
    === ":octicons-file-code-16: Sample .env"
        
        ```text
        export PRISM_CENTRAL_UUID=ad0f1eb56-9ee6-4469-b21f-xxxxxxxxxx
        export PRISM_ELEMENT_UUID=00062f20-b2e0-fa8e-4b04-xxxxxxxxxx
        export SC_NAME=primary-storage-cluster
        export KUBECONFIG=$HOME/nkp/nkpprimary.conf
        ```

6. Note and export the external  IP assigned to the NDK intercom service on the Primary Cluster

    ```bash
    export PRIMARY_NDK_IP=$(k get svc -n ntnx-system ndk-intercom-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo $PRIMARY_NDK_IP
    ```

3. Add (append) the following environment variables file ``$HOME/ndk/.env`` and save it
   
    === ":octicons-file-code-16: Template .env"

        ```text
        export PRIMARY_NDK_PORT=2021
        export PRIMARY_NDK_IP=$(k get svc -n ntnx-system ndk-intercom-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        ```

4. Source the ``$HOME/ndk/.env`` file
    
    === ":octicons-command-palette-16: Command"
    
         ```bash
         source $HOME/ndk/.env
         ```

5. Create the StorageCluster custom resource
   
    === ":octicons-command-palette-16: Command"

         ```bash
         kubectl apply -f -<<EOF
         apiVersion: dataservices.nutanix.com/v1alpha1
         kind: StorageCluster
         metadata:
          name: $SC_NAME
         spec:
          storageServerUuid: $PRISM_ELEMENT_UUID
          managementServerUuid: $PRISM_CENTRAL_UUID
         EOF
         ```

    === ":octicons-command-palette-16: Command Output"

         ```bash
         storagecluster.dataservices.nutanix.com/primary-storage-cluster created
         ```
        
    
Now we are ready to create local cluster snapshots and snapshot restores using the following NDK custom resources:

-  ``ApplicationSnapshot`` and
-  ``ApplicationSnapshotRestore``