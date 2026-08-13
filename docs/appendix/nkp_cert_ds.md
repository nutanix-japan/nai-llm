# Deploying Private CA Certificate to NKP Cluster

In this tutorial we will deploy a private CA certificate to the NKP air-gapped cluster nodes if not already added at the time of deployment for registry and registry mirrors.


!!! warning "Best Practice for Private CA Certificates"
    
    The best practice is to deploy the NKP air-gapped cluster with a private CA certificate for validating registry and registry mirrors is as follows:
    
    - ``nkp create cluster nutanix --registry-cacert``
    - ``nkp create cluster nutanix --registry-mirror-cacert``

    For Day 1 and 2 operations, the private CA certificate will need to be added to all the NKP air-gapped cluster nodes as and when it is updated

    - Update corresponding ``_cluster_name_-image-registry-mirror-credentials ``secret
    - Rollout all nodes in the NKP cluster 

Follow the steps here to add the Harbor container registry's CA certificate ``ca.crt`` that you created in this [section](../infra/harbor.md#setup-ssl-certificates-for-harbor) to the nodes.

!!! info "Registry vs Registry Mirror"

    In a Cluster API (CAPI) architecture, the core difference is how your image paths are resolved: a Registry requires you to explicitly change your Kubernetes YAML files to point to a specific server URL, whereas a Registry Mirror acts as a transparent, automated fallback configured directly within the container runtime (like containerd) of your workload nodes.

    ## Quick Comparison
    
    | Feature | Registry (Custom/Private) | Registry Mirror (Pull-Through Cache) |
    |---|---|---|
    | **Image Path in YAML**| Must match the specific registry URL. | Keeps standard paths (e.g., docker.io/...). |
    | **How it Works** | Direct pull from specified server. | Node intercepts pull request and redirects to local mirror. |
    | **Air-Gap Use Case** | Requires fully modifying all CAPI manifests. | Keeps manifests intact; relies on node configurations. |
    | **Configuration Level**| Kubernetes API / Manifest layer. | Node OS / Container runtime layer (containerd). |
    | **Day 2 File Change**| Update Node OS file ``/etc/containerd/certs.d/_default/hosts.toml`` | Update Node OS file ``/etc/containerd/certs.d/_default/hosts.toml`` |
    | **Day 2 Ops**| Update Node OS files / Container runtime restart (containerd).| Update Node OS files / Container runtime restart (containerd). |
    

!!! danger "Private CA or Self-signed Certificates"
    
    Make sure to install Private CA or self-signed certificates **only** if you are using a test, lab or development environment.

    For production environments, use a trusted public CA certificate. 

    The recommendation from **Nutanix** is to use a trusted public CA certificate. For dark site environments, a robust Private CA should be used. 

1. Login to the Jumphost VM using VSCode

2. In VSCode explorer pane, change to ``$HOME/harbor`` directory and create the secret manifest file by clicking on :material-file-plus-outline: with the following name:
   
    ```bash
    ca-crt-secret.yaml
    ```
   
    with the following content:
   
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: trusted-ca
      namespace: kube-system
    data:
      ca.crt: |
        -----BEGIN CERTIFICATE-----
 
        PASTE_YOUR_CA_CERTIFICATE_HERE
 
        -----END CERTIFICATE-----    
    ```

3. Create a configmap manifest file by clicking on :material-file-plus-outline: and create a new file with the following name: 
   
    ```bash
    ca-crt-cm.yaml
    ```
    
    with the following content:

    ```yaml
    kind: ConfigMap
    metadata:
      name: registry-ca-setup-script
      namespace: kube-system
    data:
      setup.sh: |
        mkdir /etc/certs
        mkdir -p /etc/containerd/certs.d/${REGISTRY_HOST}
        echo "$TRUSTED_CERT" > /etc/certs/${REGISTRY_HOST}
        cat <<EOF >  /etc/containerd/certs.d/${REGISTRY_HOST}/hosts.toml
        [host."https://${REGISTRY_HOST}/v2"]
        capabilities = ["pull", "resolve"]
        ca = "/etc/certs/${REGISTRY_HOST}"
        override_path = true
    ```

4. Create a DaemonSet manifest file by clicking on :material-file-plus-outline: and create a new file with the following name:
   
    ```bash
    ca-crt-ds.yaml
    ``` 
   
    with the following content:

    !!! warning "Change the registry host name"
    
        Change the highlighted registry host name to the one you are using.

    ```yaml hl_lines="31"
    apiVersion: apps/v1
    kind: DaemonSet
    metadata:
      namespace: kube-system
      name: registry-ca-setup
      labels:
        k8s-app: registry-ca-setup
    spec:
      selector:
        matchLabels:
          k8s-app: registry-ca-setup
      template:
        metadata:
          labels:
            k8s-app: registry-ca-setup
        spec:
          hostPID: true
          hostNetwork: true
          initContainers:
          - name: init-node
            command: ["nsenter"]
            args: ["--mount=/proc/1/ns/mnt", "--", "sh", "-c", "$(SETUP_SCRIPT)"]
            image: debian
            env:
            - name: TRUSTED_CERT
              valueFrom:
                configMapKeyRef:
                  name: trusted-ca
                  key: ca.crt
            - name: REGISTRY_HOST
              value:  10.x.x.111
            - name: SETUP_SCRIPT
              valueFrom:
                configMapKeyRef:
                  name: registry-ca-setup-script
                  key: setup.sh
            securityContext:
              privileged: true
          containers:
          - name: wait
            image: k8s.gcr.io/pause:3.1
    ```

5. Open VSCode Terminal
6. Login to the devbox shell
   
    ```bash
    cd $HOME/sol-cnai-infra/
    devbox shell
    cd $HOME/harbor
    ```

7. Apply the manifests created in the previous steps
    
    ```bash
    kubectl apply -f ca-crt-secret.yaml
    kubectl apply -f ca-crt-cm.yaml
    kubectl apply -f ca-crt-ds.yaml
    ```

8. Verify that the manifests are applied by checking the status of the daemonset and pods

    === "Command"

        ```bash
        kubectl get ds -n kube-system --selector='k8s-app=registry-ca-setup' -owide
        kubectl get po -n kube-system --selector='k8s-app=registry-ca-setup' -owide
        ```

    === "Command output"

        ```{ .text .no-copy }
        $ k get ds -n kube-system --selector='k8s-app=registry-ca-setup' -owide

        NAME                DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE   CONTAINERS   IMAGES                 SELECTOR
        registry-ca-setup   5         5         5       5            5           <none>          25h   wait         k8s.gcr.io/pause:3.1   k8s-app=registry-ca-setup
        ```

        ```{ .text .no-copy }
        $ k get po -n kube-system --selector='k8s-app=registry-ca-setup' -owide

        NAME                      READY   STATUS    RESTARTS   AGE   IP             NODE                                    
        registry-ca-setup-65sgk   1/1     Running   0          23h   10.122.7.224   nkpdev-gpu-nodepool-b57nm-2c8vh-njlnf
        registry-ca-setup-98mfn   1/1     Running   0          23h   10.122.7.129   nkpdev-md-0-b4z9f-mkrt6-sd7vb
        registry-ca-setup-gnpkn   1/1     Running   0          23h   10.122.7.112   nkpdev-md-0-b4z9f-mkrt6-9n89d  
        registry-ca-setup-hdzpl   1/1     Running   0          23h   10.122.7.117   nkpdev-md-0-b4z9f-mkrt6-zz2mk 
        registry-ca-setup-vvhl5   1/1     Running   0          23h   10.122.7.128   nkpdev-md-0-b4z9f-mkrt6-hdrtq
        ```

    !!! note 
        
        The daemonset's pods will run only on the worker nodes and GPU nodes in the cluster.

9. Now that the manifests are applied, the CA certificate will be added to the trusted CA store on the nodes.