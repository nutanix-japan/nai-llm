---

title: "Deploy NKP Cluster with Flow CNI"
description: ""

---

In this section we will prepare the NKP Cluster with Flow CNI.

# Deploy NKP Clusters

This section will take you through install NKP(Kubernetes) on Nutanix cluster as we will be deploying Flow CNI on these kubernetes clusters and testing networking between containers and VMs.

## NKP High Level Cluster Design

The ``nkpflow`` cluster will be hosting the Flow CNI and the testing application stack. 

### Management Cluster

Management Cluster called ``nkpmanage`` will be essential to deploying a workload ``nkpflow`` cluster. 

| Role   | No. of Nodes (VM) | vCPU | RAM   | Storage |
| ------ | ----------------- | ---- | ----- | ------- |
| Master | 1                 | 12    | 16 GB | 200 GB  |
| Worker | 2                 | 12    | 16 GB  | 200 GB  |

### Flow Workload Cluster

For ``nkpflow``, we will deploy an NKP Cluster of with the following resources to be able to deploy Flow CNI.

| Role   | No. of Nodes (VM) | vCPU | RAM   | Storage |
| ------ | ----------------- | ---- | ----- | ------- |
| Master | 1                 | 12    | 16 GB | 200 GB  |
| Worker | 2                 | 12    | 16 GB  | 200 GB  |


## Create Externel Subnet

We will create a external subnet to deploy the NKP cluster nodes. This has to be a separate network to the one that VM and contianers will be sharing to communicate.

!!! note
    
    The IP address schemes are for illustrative purposes. Choose your own subnet details.

    Make sure to have enough IP (at least 3) addresses for nkpflow workload NKP cluster. See [here](../appendix/infra_nkp_hard_way.md#reserve-control-plane-and-metallb-endpoint-ips) for IP address requirement details for workload cluster.

1. Go to **Prism Central** > **Networking** > **Subnets**
2. Click on **Create Subnet** and fill the following details
   
    -  **Name**: ``NKP``
    -  **Type**: VLAN
    -  **Virtual Switch**: ``vs0``
    -  **VLAN ID**: ``203``
    -  **Exretnal connectivity for VPC** - Toggle to ``Yes`` and select ``NAT``
    -  **IP Address Management**: Nutanix IPAM
    -  **Network IP Address / Profile**: ``10.24.160.0/22``
    -  **Gateway IP Address**: ``10.24.160.1``
    -  **IP Pool**
        - **Start Address**: ``10.24.163.45``
        - **End Address**: ``10.24.163.60``
3. Click on **Create**

## Create a Jumphost VM

- See instructions [here](../infra/workstation.md) to prepare your workstation (Mac/PC) with Tools
- See instructions [here](../infra/infra_jumphost_tofu.md) to create a Jumphost VM

## Deploy NKP Management Cluster

- Follow instructions [here](../appendix/infra_nkp_hard_way.md) to deploy a management cluster.

- Ensure to license the Management cluster with at least NKP Pro License
  
- Follow instructions [here](../appendix/infra_nkp_hard_way.md#license-management-cluster) to generate and license the NKP Management cluster.

## Create Rocky Linux Base Image


1. Connect to the Jumphost VM using ``VSCode``
   
2. In `VSCode` Explorer pane, click on existing ``$HOME`` folder

3. Click on **New Folder** :material-folder-plus-outline: name it: ``flow``

4. On `VSCode` Explorer plane, click the ``$HOME/flow`` folder

5. On `VSCode` menu, select ``Terminal`` > ``New Terminal``

6. Browse to ``nkp`` directory

    === ":octicons-command-palette-16: Command"
    
        ```bash
        cd $HOME/flow
        ```

5. Create and the following values inside the ``.env`` file for the workload ``nkpflow`` cluster
   
    === ":octicons-file-code-16: Template ``.env``"

        ```text
        export NUTANIX_USER=_your_nutanix_username
        export NUTANIX_PASSWORD=_your_nutanix_password
        export NUTANIX_ENDPOINT=_your_prism_central_fqdn
        export NUTANIX_CLUSTER=_your_prism_element_cluster_name
        export NUTANIX_SUBNET_NAME=_your_ahv_ipam_network_name
        export STORAGE_CONTAINER=_your_storage_container_nmae
        export SSH_PUBLIC_KEY=_path_to_ssh_pub_key_on_jumphost_vm
        export NKP_CLUSTER_NAME=_your_nkp_cluster_name
        export CONTROLPLANE_VIP=_your_nkp_cluster_controlplane_ip
        export LB_IP_RANGE=_your_range_of_two_ips
        export DOCKER_USERNAME=_your_docker_username
        export DOCKER_PASSWORD=_your_docker_password_pat
        export CONTROL_PLANE_REPLICAS=_no_of_control_plane_replicas
        export CONTROL_PLANE_VCPUS=_no_of_control_plane_vcpus
        export CONTROL_PLANE_CORES_PER_VCPU=_no_of_control_plane_cores_per_vcpu
        export CONTROL_PLANE_MEMORY_GIB=_no_of_control_plane_memory_gib
        export WORKER_REPLICAS=_no_of_worker_replicas
        export WORKER_VCPUS=_no_of_worker_vcpus
        export WORKER_CORES_PER_VCPU=_no_of_worker_cores_per_vcpu
        export WORKER_MEMORY_GIB=_no_of_worker_memory_gib
        export CSI_FILESYSTEM=_preferred_filesystem_ext4/xfs
        export CSI_HYPERVISOR_ATTACHED=_true/false
        ```

    === ":octicons-file-code-16: Sample ``.env``"

        ```text
        export NUTANIX_USER=admin
        export NUTANIX_PASSWORD=xxxxxxxx
        export NUTANIX_ENDPOINT=pc.example.com
        export NUTANIX_CLUSTER=pe
        export NUTANIX_SUBNET_NAME=NKP
        export STORAGE_CONTAINER=default
        export SSH_PUBLIC_KEY=$HOME/.ssh/id_rsa.pub
        export NKP_CLUSTER_NAME=nkpflow
        export CONTROLPLANE_VIP=10.x.x.220
        export LB_IP_RANGE=10.x.x.221-10.x.x.222
        export DOCKER_USERNAME=_your_docker_username
        export DOCKER_PASSWORD=_your_docker_password_pat
        export CONTROL_PLANE_REPLICAS=1
        export CONTROL_PLANE_VCPUS=12
        export CONTROL_PLANE_CORES_PER_VCPU=1
        export CONTROL_PLANE_MEMORY_GIB=16
        export WORKER_REPLICAS=2
        export WORKER_VCPUS=12
        export WORKER_CORES_PER_VCPU=1
        export WORKER_MEMORY_GIB=16
        export CSI_FILESYSTEM=ext4
        export CSI_HYPERVISOR_ATTACHED=true
        ```

6. Ensure to use the ``rocky-9.6`` as the image version in the base image command

    === ":octicons-command-palette-16: Command"
    
        ```bash
        nkp create image nutanix rocky-9.6 \
          --endpoint ${NUTANIX_ENDPOINT} --cluster ${NUTANIX_CLUSTER} \
          --subnet ${NUTANIX_SUBNET_NAME} --insecure
        ```
    === ":octicons-command-palette-16: Command output"
    
        ```text hl_lines="6 7"
        ---> 100%
        Build 'nutanix.kib_image' finished after 4 minutes 55 seconds.
        ==> Wait completed after 4 minutes 55 seconds
    
        ==> Builds finished. The artifacts of successful builds are:
        --> nutanix.kib_image: export NKP_IMAGE=nkp-rocky-9.6-1.34.3-20260609005954
        --> nutanix.kib_image: export NKP_IMAGE=nkp-rocky-9.6-1.34.3-20260609005954
        ```

7.  Populate the ``.env`` file with the NKP image name by adding (appending) the following environment variables and save it

    === "Template .env"

        ```text
        export NKP_IMAGE=nkp-image-name
        ```

    === "Sample .env"

        ```text
        export NKP_IMAGE=nkp-ubuntu-24.04-1.34.3-20260328040605
        ```

We are now ready to install the workload ``nkpflow`` cluster

## Deploy NKP Workload Cluster

We will create the workload cluster's cluster definition manifest first, modify values and proceed to deploy the workload cluster.

6. Using VSC Terminal, load the environment variables and its values

    ```bash
    source $HOME/flow/.env
    ```

7. Open ``nkpmanage`` management clusters context

    
    === ":octicons-command-palette-16: Command"
    
        ```bash
        export KUBECONFIG=nkpmanage.conf
        ```

8. Create the cluster configuration file for workload ``nkpflow`` cluster
   
    === ":octicons-command-palette-16: Command"
    
        ```text
        nkp create cluster nutanix -c ${NKP_CLUSTER_NAME} \
          --control-plane-endpoint-ip ${CONTROLPLANE_VIP} \
          --control-plane-prism-element-cluster ${NUTANIX_CLUSTER} \
          --control-plane-subnets ${NUTANIX_SUBNET_NAME} \
          --control-plane-vm-image ${NKP_IMAGE} \
          --csi-storage-container ${STORAGE_CONTAINER} \
          --endpoint https://${NUTANIX_ENDPOINT}:9440 \
          --worker-prism-element-cluster ${NUTANIX_CLUSTER} \
          --worker-subnets ${NUTANIX_SUBNET_NAME} \
          --worker-vm-image ${NKP_IMAGE} \
          --ssh-public-key-file ${SSH_PUBLIC_KEY} \
          --kubernetes-service-load-balancer-ip-range ${LB_IP_RANGE} \
          --control-plane-disk-size 200 \
          --control-plane-memory ${CONTROL_PLANE_MEMORY_GIB} \
          --control-plane-vcpus ${CONTROL_PLANE_VCPUS} \
          --control-plane-cores-per-vcpu ${CONTROL_PLANE_CORES_PER_VCPU} \
          --worker-disk-size 200 \
          --worker-memory ${WORKER_MEMORY_GIB} \
          --worker-vcpus ${WORKER_VCPUS} \
          --worker-cores-per-vcpu ${WORKER_CORES_PER_VCPU} \
          --csi-file-system ${CSI_FILESYSTEM} \
          --csi-hypervisor-attached-volumes=${CSI_HYPERVISOR_ATTACHED} \
          --registry-mirror-url "https://registry-1.docker.io" \
          --registry-mirror-username ${DOCKER_USERNAME} \
          --registry-mirror-password ${DOCKER_PASSWORD} \
          --kubernetes-pod-network-cidr 192.168.0.0/16     
          --kubernetes-service-cidr 10.96.0.0/12     
          --insecure 
          --dry-run     
          --output=yaml > cluster-nkpflow-install.yaml
        ```
    
    === ":octicons-command-palette-16: Sample command"

        ```text
        nkp create cluster nutanix -c nkpflow \
          --control-plane-endpoint-ip 10.x.x.220 \
          --control-plane-prism-element-cluster pe \
          --control-plane-subnets NKP \
          --control-plane-vm-image \
          --csi-storage-container default \
          --endpoint https://pc.example.com:9440 \
          --worker-prism-element-cluster pe \
          --worker-subnets NKP \
          --worker-vm-image nkp-rocky-9.6-1.34.3-20260609005954 \
          --ssh-public-key-file ~/.ssh/id_rsa.pub \
          --kubernetes-service-load-balancer-ip-range 10.x.x.221-10.x.x.222 \
          --control-plane-disk-size 200 \
          --control-plane-memory 16 \
          --control-plane-vcpus 12 \
          --control-plane-cores-per-vcpu 1 \
          --worker-disk-size 200 \
          --worker-memory 16 \
          --worker-vcpus 12 \
          --worker-cores-per-vcpu 1 \
          --csi-file-system ext4 \
          --csi-hypervisor-attached-volumes=true \
          --registry-mirror-url "https://registry-1.docker.io" \
          --registry-mirror-username _your_docker_username \
          --registry-mirror-password _your_docker_password \
          --kubernetes-pod-network-cidr 192.168.0.0/16     
          --kubernetes-service-cidr 10.96.0.0/12     
          --insecure 
          --dry-run     
          --output=yaml > cluster-nkpflow-install.yaml
        ```

9. Download the pull secret for Flow CNI contianer images from **Nutanix Portal** > **Downloads** > [**Flow Networking and Security**](https://portal.nutanix.com/page/downloads?product=flowNetworkSecurity)
   
10. Choose **Flow CNI** form the drop-down menu > Click on **Manage Access Tokens**
    
11. Copy any username and password and append to the ``.env`` file
    
    === ":octicons-file-code-16: Template ``.env``"
    
        ```bash
        export FLOW_DOCKER_USERNAME=_your_docker_username
        export FLOW_DOCKER_PASSWORD=_your_docker_password_pat
        ```
    
    === ":octicons-file-code-16: Sample ``.env``"
    
        ```bash
        export FLOW_DOCKER_USERNAME=svcpubflowcni
        export FLOW_DOCKER_PASSWORD=xXXXXXXXXXXXXXXXXXXXXXXXX
        ```

12. Create base64 value for the download secret
    
    === ":octicons-command-palette-16: Command"
    
        ```bash
        export FLOW_SECRET=$(echo '${FLOW_DOCKER_USERNAME}:${FLOW_DOCKER_USERNAME}' | base64)
        ```
    
    === ":octicons-command-palette-16: Sample command"
    
        ```bash
        export FLOW_SECRET=$(echo -n  'svcpubflowcni:xXXXXXXXXXXXXXXXXXXXXXXXXxXXXXXXXXXXXXXXXXXXXXXXXX'| base64)
        ```
    

13. Create the ``HelmChartProxy`` manifest to append to the ``cluster-nkpflow-install.yaml`` manifest file 
    
    === ":octicons-command-palette-16: Command"
    
        ```bash
        cat <<EOF >> cluster-nkpflow-install.yaml

        ---
        apiVersion: addons.cluster.x-k8s.io/v1alpha1
        kind: HelmChartProxy
        metadata:
          name: flow-cni
          namespace: <namespace-cluster>
        spec:
          clusterSelector:
            matchLabels:
              cluster.x-k8s.io/cluster-name: ${NKP_CLUSTER_NAME}
          repoURL: https://nutanix.github.io/helm-releases/
          chartName: nutanix-flow-cni
          version: 1.0.0
          namespace: flow-cni-system
          options:
            waitForJobs: true
            wait: true
            timeout: 30m
            install:
              createNamespace: true
          valuesTemplate: |
            nutanix-core-flow-ovn-kubernetes:
              k8sAPIServer: "https://${CONTROLPLANE_VIP}:6443" 
              podNetwork: "192.168.0.0/16/24" 
              serviceNetwork: "10.96.0.0/12"
            global:
              dockerConfigSecret:
                registry: docker.io
                auth: ${FLOW_SECRET}
                create: true
              imagePullSecretName: "flow-cni-secret"
            imagePullSecrets:
              - name: flow-cni-secret
        EOF
        ```
    
    === ":octicons-file-code-16: Command output file"
    
        ```{ .yaml .no-copy }
        < SNIPPED FOR BREVITY>
        < Contents of cluster-nkpflow-install.yaml file>

                    imagePullSecrets:
              - name: flow-cni-Secret
        ---
        apiVersion: addons.cluster.x-k8s.io/v1alpha1
        kind: HelmChartProxy
        metadata:
          name: flow-cni
          namespace: <namespace-cluster>
        spec:
          clusterSelector:
            matchLabels:
              cluster.x-k8s.io/cluster-name: nkpflow
          repoURL: https://nutanix.github.io/helm-releases/
          chartName: nutanix-flow-cni
          version: 1.0.0
          namespace: flow-cni-system
          options:
            waitForJobs: true
            wait: true
            timeout: 30m
            install:
              createNamespace: true
          valuesTemplate: |
            nutanix-core-flow-ovn-kubernetes:
              k8sAPIServer: "https://10.x.x.220:6443" 
              podNetwork: "192.168.0.0/16/24" 
              serviceNetwork: "10.96.0.0/12"
            global:
              dockerConfigSecret:
                registry: docker.io
                auth: xXXXXXXXXXXXXXXXXXXXXXXXXxXXXXXXXXXXXXXXXXXXXXXXXX=
                create: true
              imagePullSecretName: "flow-cni-secret"
            imagePullSecrets:
              - name: flow-cni-secret
        ```

14. Remove the default Cilium definition from the cluster-nkpflow-install.yaml file as we will be installing Flow CNI
    
    === ":octicons-command-palette-16: Command"
    
        ```bash
        yq eval -i 'select(.kind == "Cluster").spec.topology.variables[] | select(.name == "addons").value.cni del' cluster-${NKP_CLUSTER_NAME}-install.yaml
        ```
    
    === ":octicons-command-palette-16: Sample command"
    
        ```bash
        yq eval -i 'select(.kind == "Cluster").spec.topology.variables[] | select(.name == "addons").value.cni del' cluster-nkpflow-install.yaml
        ```

16. Open ``cluster-nkpflow-install.yaml`` file and visually inspect for any formatting issues or incorrect values

17. Create the nkpflow workload cluster with Flow CNI
    
    !!! warning
        
        The following workload cluster creation must be done in the management ``nkpmanage`` cluster's context. 

        Ensure the context for ``nkpmanage`` before proceeding. 
    
    === ":octicons-command-palette-16: Command"
    
        ```bash
        export KUBECONFIG=nkpmanage.conf
        kubectl apply -f cluster-nkpflow-install.yaml
        ```
    
    === ":octicons-command-palette-16: Command"
    
        ```{ .text .no-copy }
        $ kubectl apply -f cluster-nkpflow-install.yaml
        #
        secret/flow-pc-credentials created
        secret/flow-pc-credentials-for-csi created
        secret/flow-pc-credentials-for-konnector-agent created
        secret/flow-image-registry-credentials created
        cluster.cluster.x-k8s.io/flow created
        helmchartproxy.addons.cluster.x-k8s.io/flow-cni created
        ```

18. Monitor the progress of the ``nkpflow`` cluster creation and wait until all conditions are ``True``
    
    !!! note 
        This will take about 5 minutes.
    
    === ":octicons-command-palette-16: Command"
    
        ```bash
        while test true;do nkp describe cluster -c flow -n kommander-default-workspace; sleep 5;clear;done
        ```
    
    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        Cluster/flow                                                                True                     76s
        ├─ClusterInfrastructure - NutanixCluster/flow-gp7rc
        ├─ControlPlane - KubeadmControlPlane/flow-zfck9                             True                     76s
        │ └─Machine/flow-zfck9-57vxk                                                True                     2m12s
        │   └─MachineInfrastructure - NutanixMachine/flow-zfck9-57vxk
        └─Workers
          └─MachineDeployment/flow-md-0-4v9w6                                       True                     20s
            ├─Machine/flow-md-0-4v9w6-b26pn-8qgq6                                   True                     70s
            │ └─MachineInfrastructure - NutanixMachine/flow-md-0-4v9w6-b26pn-8qgq6
            └─Machine/flow-md-0-4v9w6-b26pn-vbqwv                                   True                     67s
              └─MachineInfrastructure - NutanixMachine/flow-md-0-4v9w6-b26pn-vbqwv
        ```

19. Once the cluster creation is finished, get the kubeconfig file for the ``nkpflow`` cluster (if it is not already present in the directory)
    
    === ":octicons-command-palette-16: Command"
    
        ```bash title="Use the workspace namespace where the nkpflow cluster was deployed"
        export KUBECONFIG=nkpmanage.conf
        nkp get kubeconfig -c nkpflow -n _namespace_ > nkpflow.conf
        ```
    
    === ":octicons-command-palette-16: Sample command"
    
        ```{ .text .no-copy }
        export KUBECONFIG=nkpmanage.conf
        nkp get kubeconfig -c nkpflow -n kommander-default-workspace > nkpflow.conf
        ```

20. Change context to nkpflow cluster and check status

    === ":octicons-command-palette-16: Command"
    
        ```bash
        export KUBECONFIG=nkpflow.conf
        kubectl get nodes
        ```
        ```bash
        kubectl get all -n ovn-kubernetes
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        $ kubectl get nodes
        #
        NAME                          STATUS   ROLES           AGE   VERSION
        flow-md-0-4v9w6-b26pn-8qgq6   Ready    <none>          28m   v1.34.3
        flow-md-0-4v9w6-b26pn-vbqwv   Ready    <none>          28m   v1.34.3
        flow-zfck9-57vxk              Ready    control-plane   28m   v1.34.3
        ```
        ```{ .text .no-copy }
        $ kubectl get all -n ovn-kubernetes
        #
        NAME                                  READY   STATUS    RESTARTS   AGE
        pod/ovnkube-db-8cbf9bf6-kclm5         2/2     Running   0          28m
        pod/ovnkube-master-64cbc8c88d-nnrbf   2/2     Running   0          28m
        pod/ovnkube-node-hvw7f                3/3     Running   0          28m
        pod/ovnkube-node-w9qnz                3/3     Running   0          28m
        pod/ovnkube-node-xlzqm                3/3     Running   0          28m
        pod/ovs-node-29zmx                    1/1     Running   0          28m
        pod/ovs-node-dln5j                    1/1     Running   0          28m
        pod/ovs-node-g9f2q                    1/1     Running   0          28m
        
        NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)             AGE
        service/ovnkube-db   ClusterIP   None         <none>        6641/TCP,6642/TCP   28m
        
        NAME                          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
        daemonset.apps/ovnkube-node   3         3         3       3            3           kubernetes.io/os=linux   28m
        daemonset.apps/ovs-node       3         3         3       3            3           kubernetes.io/os=linux   28m
        
        NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
        deployment.apps/ovnkube-db       1/1     1            1           28m
        deployment.apps/ovnkube-master   1/1     1            1           28m
        
        NAME                                        DESIRED   CURRENT   READY   AGE
        replicaset.apps/ovnkube-db-8cbf9bf6         1         1         1       28m
        replicaset.apps/ovnkube-master-64cbc8c88d   1         1         1       28m
        ```

We have now deployed ``nkpflow`` cluster with **Flow CNI**. We can now proceed to onboarding this cluster from Nutanix Prism Central and creating required network components.