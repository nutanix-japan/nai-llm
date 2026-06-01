
# Preparing Air-gap NDK

## High-Level Process

!!! warning

    NKP supports NDK ``v2.0.0`` at the time of writing this lab with CSI version ``3.3.8``.

    We will use NDK ``v2.0.0`` with NKP ``v2.16.1`` for this lab.

    CSI version ``3.3.8`` is necessary for Nutanix Files replication and protection. 

1. Download NDK ``v2.0.0`` binaries that are available in Nutanix Support [Nutanix Portal](https://portal.nutanix.com/page/downloads?product=nkp)
2. Upload NDK containers to an internal Harbor registry
3. Enable NDK to trust internal Harbor registry. See [here](../appendix/nkp_cert_ds.md)
4. Install NDK ``v2.0.0``


## Setup Harbor Internal Registry 

> Follow instructions in [Harbor Installation](../infra/harbor.md) to setup internal Harbor registry for storing NDK ``v2.0.0`` containers.

1. Login to Harbor
2. Create a project called ``nkp`` in Harbor

### Prepare for NDK Installation

#### Download NDK Binaries

1. Login to [Nutanix Portal](https://portal.nutanix.com/page/downloads?product=ndk) using your credentials

2. Go to **Downloads** > **Nutanix Data Services for Kubernetes (NDK)** 

3. Scroll and choose **Nutanix Data Services for Kubernetes ( Version: 2.0.0 )**

4. Open new `VSCode` window on your jumphost VM

5.  In `VSCode` Explorer pane, click on existing ``$HOME`` folder

6.  Click on **New Folder** :material-folder-plus-outline: name it: ``ndk``

7.  On `VSCode` Explorer plane, click the ``$HOME/ndk`` folder

8.  On `VSCode` menu, select ``Terminal`` > ``New Terminal``

9.  Browse to ``ndk`` directory

    === ":octicons-command-palette-16: Command"
    
         ```bash
         cd $HOME/ndk
         ```
   
10.   Download the NDK binaries bundle from the link you copied earlier
    
    === ":octicons-command-palette-16: Command"

        ```text title="Paste the download URL within double quotes"
        curl -o ndk-2.0.0.tar "_paste_download_URL_here"
        ```

    === ":octicons-command-palette-16:  Sample Command"
        
        ```{ .text .no-copy }
        $HOME/ndk $ curl -o ndk-2.0.0.tar "https://download.nutanix.com/downloads/ndk/2.0.0/ndk-2.0.0.tar?Expires=XXXXXXXXX__"
        ```

5.  Extract the NDK binaries
    
    === ":octicons-command-palette-16: Command"

        ```text 
        tar -xvf ndk-${NDK_VERSION}.tar
        cd ndk-${NDK_VERSION}
        ```

    === ":octicons-command-palette-16:  Sample Command"
        
        ```{ .text .no-copy }
    
        tar -xvf ndk-2.0.0.tar
        cd ndk-2.0.0
        ```
    
    ??? Info "NDK Binaries Directory Contents"

        ```{ .text .no-copy }
        ~/ndk/ndk-2.0.0$ tree
        
        ├── ndk-2.0.0
        │   ├── chart
        │   │   ├── Chart.yaml                                      # NDK chart

        │   │   ├── crds
        │   │   │   └── scheduler.nutanix.com_jobschedulers.yaml    # NDK CRDs

        │   │   ├── templates

                │   │   └── values.yaml                             # NDK chart values

        │   └── ndk-2.0.0.tar                                       # NDK container images
        ```


8. Source the ``.env`` file to import environment variables
   
    === ":octicons-command-palette-16: Command"
    
         ```bash
         source $HOME/ndk/.env
         ```

9. Load NDK container images to local Docker instance

    === ":octicons-command-palette-16: Command"

        ```bash
        docker load -i ndk-${NDK_VERSION}.tar
        ```

    === ":octicons-command-palette-16: Command output"
        
        ```{ .text .no-copy }
        Loaded image: ndk/manager:2.0.0
        Loaded image: ndk/infra-manager:2.0.0
        Loaded image: ndk/job-scheduler:2.0.0
        Loaded image: ndk/kube-rbac-proxy:v0.19.0
        Loaded image: ndk/kubectl:1.32.3
        ```

10. In ``VSC``, under the newly created ``ndk`` folder, click on **New File** :material-file-plus-outline: and create file with the following name:
   
    === ":octicons-file-code-16: File"
    
         ```bash
         .env
         ```

11. Add (append) the following environment variables and save it
   
    === ":octicons-file-code-16: Template .env"

        ```bash
        export NDK_VERSION=_your_ndk_version # (1)! 
        export KUBE_RBAC_PROXY_VERSION=_your_kube_kube_rbac_proxy_version # (2)! 
        export KUBECTL_VERSION=_your_kubectl_version # (3)! 
        export IMAGE_REGISTRY=_your_harbor_registy_url/nkp
        ```
        
        1. Get ``NDK`` tag version information from ``docker load -i ndk-${NDK_VERSION}.tar`` command output
        2. Get ``KUBE_RBAC_PROXY_VERSION`` tag version information from ``docker load -i ndk-${NDK_VERSION}.tar`` command output
        3. Get ``KUBECTL_VERSION`` tag version information from ``docker load -i ndk-${NDK_VERSION}.tar`` command output
    
    === ":octicons-file-code-16: Sample .env"
        
        ```text
        export NDK_VERSION=2.0.0
        export KUBE_RBAC_PROXY_VERSION=v0.19.0
        export KUBECTL_VERSION=1.32.3
        export IMAGE_REGISTRY=harbor.apj-cxrules.win/nkp
        ```

12. Load NDK container images and upload to internal Harbor registry

    === ":octicons-command-palette-16: Command"

        ```bash
        docker login ${IMAGE_REGISTRY} 

        for img in ndk/manager:${NDK_VERSION} \
        ndk/infra-manager:${NDK_VERSION} \
        ndk/job-scheduler:${NDK_VERSION} \
        ndk/kube-rbac-proxy:${KUBE_RBAC_PROXY_VERSION} 
        ndk/kubectl:${KUBECTL_VERSION}; \
        do docker tag $img ${IMAGE_REGISTRY}/${img}; \
        docker push ${IMAGE_REGISTRY}/${img}; \
        done
        ```

    === ":octicons-command-palette-16:  Sample Command"
        
        ```{ .text .no-copy }
        docker login harbor.example.com/nkp

        for img in ndk/manager:2.0.0 ndk/infra-manager:2.0.0 ndk/job-scheduler:2.0.0 ndk/kube-rbac-proxy:v0.17.0 ndk/bitnami-kubectl:1.30.3; do docker tag ndk/bitnami-kubectl:1.30.3 harbor.example.com/nkp/ndk/bitnami-kubectl:1.30.3; docker push harbor.example.com/nkp/ndk/bitnami-kubectl:1.30.3;done
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
         helm upgrade -n ntnx-system --install ndk chart/ \
         --set manager.repository="harbor.example.com/nkp/ndk/manager" \
         --set manager.tag=2.0.0 \
         --set infraManager.repository="harbor.example.com/nkp/ndk/infra-manager" \
         --set infraManager.tag=2.0.0 \
         --set kubeRbacProxy.repository="harbor.example.com/nkp/ndk/kube-rbac-proxy" \
         --set kubeRbacProxy.tag=v0.17.0 \
         --set bitnamiKubectl.repository="harbor.example.com/nkp/ndk/bitnami-kubectl" \
         --set bitnamiKubectl.tag=1.30.3 \
         --set jobScheduler.repository="harbor.example.com/nkp/ndk/job-scheduler" \
         --set jobScheduler.tag=2.0.0 \
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

NDK in air-gap enviroment is now install. 

> Proceed to the configuring NDK [here](nkp_ndk.md#configure-ndk).