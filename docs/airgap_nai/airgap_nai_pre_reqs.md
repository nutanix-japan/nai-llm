# Pre-requisites for Deploying NAI

In this part of the lab we will prepare pre-requisites for LLM application on GPU nodes.

The following is the flow of the applications lab:

```mermaid
stateDiagram-v2
    direction LR

    state PreRequisites {
        [*] --> CreateFilesShare  
        CreateFilesShare --> PrepareHuggingFace
        PrepareHuggingFace --> [*]
    }
    state CreateOfflineHelmContainers {
        [*] --> PrepareNAIHelmCharts
        PrepareNAIHelmCharts --> PrepareNAIContainerImages
        PrepareNAIContainerImages --> [*]
    }

    [*] --> PreRequisites
    PreRequisites --> CreateOfflineHelmContainers
    CreateOfflineHelmContainers --> DeployNAI : next section
    DeployNAI --> TestNAI
    TestNAI --> [*]
```

Prepare the following pre-requisites needed to deploy NAI on target kubernetes cluster.

## Create Nutanix Files Storage Class

We will create Nutanix Files storage class which will be used to create a pvc that will store the ``LLama-3-8B`` model files.

1. In **Prism Central**, choose **Files** from the menu
3. Choose the file server (e.g. labFS)
4. Click on **Shares & Exports**
5. Click on **+New Share or Export**
6. Fill the details of the Share
   
    - **Name** - model_share
    - **Description** - for NAI model store
    - **Share path** - leave blank
    - **Max Size** - 10 GiB (adjust to the model file size)
    - **Primary Protocol Access** - NFS

7. Click **Next** and make sure **Enable compression** in checked
8. Click **Next** 
9. In NFS Protocol Access, choose the following: 
   
    - **Authentication** - System
    - **Default Access (for all clients)** - Read-Write 
    - **Squash** - Root Squash

    !!! note
        Consider changing access options for Production environment
  
10. Click **Next**
11. Confirm the share details and click on **Create**

### Create the Files Storage Class

12. Run the following command to check K8S status of the ``nkpdev`` cluster
    
    ```bash
    kubectl get nodes
    ```

12. In VSC Explorer, click on **New File** :material-file-plus-outline: and create a config file with the following name:

    ```bash
    nai-nfs-storage.yaml
    ```

    Add the following content and replace the `nfsServerName` with the name of the Nutanix Files server name .


    ![Finding nfsServerName and nfsServer fqdn](images/nfs_server_domain_identify.png)

    === "Template YAML"

        ```yaml hl_lines="6 7"
        apiVersion: storage.k8s.io/v1
        kind: StorageClass
        metadata:
          name: nai-nfs-storage
        parameters:
          nfsPath: <nfs-path>
          nfsServer: <nfs-server>
          storageType: NutanixFiles
        provisioner: csi.nutanix.com
        reclaimPolicy: Delete
        volumeBindingMode: Immediate
        ```

    === "Sample YAML"

        ```yaml hl_lines="6 7"
        apiVersion: storage.k8s.io/v1
        kind: StorageClass
        metadata:
          name: nai-nfs-storage
        parameters:
          nfsPath: /model_share
          nfsServer: labFS.ntnxlab.local
          storageType: NutanixFiles
        provisioner: csi.nutanix.com
        reclaimPolicy: Delete
        volumeBindingMode: Immediate
        ```

13. Create the storage class

    ```bash
    kubectl apply -f nai-nfs-storage.yaml
    ```

14. Check storage classes in the cluster for the Nutanix Files storage class

    === "Command"

        ```bash
        kubectl get storageclass
        ```
  
    === "Command output"

        ```bash hl_lines="5"
        kubectl get storageclass

        NAME                       PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
        dkp-object-store           kommander.ceph.rook.io/bucket   Delete          Immediate              false                  28h
        nai-nfs-storage            csi.nutanix.com                 Delete          Immediate              true                   24h
        nutanix-volume (default)   csi.nutanix.com                 Delete          WaitForFirstConsumer   false                  28h
        ```

## Request Access to Model on Hugging Face

Follow these steps to request access to the `meta-llama/Meta-Llama-3.1-8B-Instruct` model:

!!! info "LLM Recommendation"

    From testing ``google/gemma-2-2b-it`` model is quicker to download and obtain download rights, than ``meta-llama/Meta-Llama-3.1-8B-Instruct`` model.

    Feel free to use the [google/gemma-2-2b-it](https://hf.co/google/gemma-2-2b-it) model if necessary. The procedure to request access to the model is the same.


1. **Sign in to your Hugging Face account**:  

      - Visit [Hugging Face](https://huggingface.co) and log in to your account.

2. **Navigate to the model page**:  

      - Go to the [Meta-Llama-3.1-8B-Instruct model page](https://huggingface.co/meta-llama/Meta-Llama-3.1-8B-Instruct).

3. **Request access**:

      - On the model page, you will see a section or button labeled **Request Access** (this is usually near the top of the page or near the "Files and versions" section).
      - Click **Request Access**.

4. **Complete the form**:

      - You may be prompted to fill out a form or provide additional details about your intended use of the model.
      - Complete the required fields and submit the request.

5. **Wait for approval**:

      - After submitting your request, you will receive a notification or email once your access is granted.
      - This process can take some time depending on the approval workflow.

Once access is granted, there will be an email notification.

!!! note

    Email from Hugging Face can take a few minutes or hours before it arrives.

## Create a Hugging Face Token with Read Permissions

Follow these steps to create a Hugging Face token with read permissions:

1. **Sign in to your Hugging Face account**:  

    - Visit [Hugging Face](https://huggingface.co) and log in to your account.

2. **Access your account settings**:
    - Click on your profile picture in the top-right corner.
    - From the dropdown, select **Settings**.

3. **Navigate to the "Access Tokens" section**:

    - In the sidebar, click on **Access Tokens**.
    - You will see a page where you can create and manage tokens.

4. **Create a new token**:

    - Click the **New token** button.
    - Enter a name for your token (i.e., `read-only-token`).

5. **Set token permissions**:

    - Under the permissions dropdown, select **Read**. For Example:
        ![hf-token](images/hf-token.png)

6. **Create and copy the token**:

    - After selecting the permissions, click **Create**.
    - Your token will be generated and displayed only once, so make sure to copy it and store it securely.
  
Use this token for accessing Hugging Face resources with read-only permissions.

## Prepare Helm Charts

In this section we will prepare the helm charts necessary for NAI and pre-requisite applications install

 - NAI
 - Envoy Gateway
 - Kserve
 - OpenTelemetry Operator

The procedure will be done on the jumphost VM.

1. Login to [Nutanix Portal](https://portal.nutanix.com/page/downloads?product=nkp) using your credentials

2. Go to **Downloads** > **NAI Airgapped Bundle**

3. Copy the download link for NAI air-gap helm bundle
   
4. Open new `VSCode` window on your jumphost VM

5.  In `VSCode` Explorer pane, click on existing ``$HOME`` folder

6.  Click on **New Folder** :material-folder-plus-outline: name it: ``airgap-nai``

7.  On `VSCode` Explorer plane, click the ``$HOME/airgap-nai`` folder

8.  On `VSCode` menu, select ``Terminal`` > ``New Terminal``

9.  Browse to ``airgap-nai`` directory

    ```bash
    cd $HOME/airgap-nai
    ```

10. In ``VSC``, under the newly created ``airgap-nai`` folder, click on **New File** :material-file-plus-outline: and create file with the following name:
   
    ```bash
    .env
    ```

11. Add (append) the following environment variables and save it

    === ":octicons-file-code-16: Template ``$HOME/airgap-nai/.env``"

        ```bash
        export REGISTRY=harbor.10.x.x.134.nip.io
        export REGISTRY_USERNAME=admin
        export REGISTRY_CACERT=_path_to_ca_cert_of_registry  # (1)!
        ```

        1. File must contain CA server and Harbor server's public certificate in one file

    === ":octicons-file-code-16: Sample ``$HOME/airgap-nai/.env``"
        
        ```{ .bash .no-copy }
        export REGISTRY=harbor.10.x.x.134.nip.io
        export REGISTRY_USERNAME=admin
        export REGISTRY_PASSWORD=xxxxxxx
        export REGISTRY_CACERT=$HOME/harbor/certs/full_chain.pem  # (1)!
        ```

        2. File must contain CA server and Harbor server's public certificate in one file

12. Source the ``$HOME/airgap-nai/.env`` file to import environment variables
   
     ```bash
     source $HOME/airgap-nai/.env
     ```

13.  Download the NAI ``2.6.0`` helm chart bundle from Nutanix Portal
   
    === ":octicons-command-palette-16: Command"

        ```bash
        curl -o " nai-helm-charts-2.6.0.tar" "_paste_download_URL_here"
        ```
    
    === ":octicons-command-palette-16: Sample command"
    
        ```{ .text .no-copy }
        curl -o "nai-helm-charts-2.6.0.tar" "https://download.nutanix.com/downloads/nai/2.6.0/nai-helm-charts-2.6.0.tarr?Expires=xxxxx"
        ```

14. Extract the helm charts file
    
    === ":octicons-command-palette-16: Command"
    
        ```bash
        tar xvf nai-helm-charts-2.6.0.tar
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```bash
        $ tar xvf nai-helm-charts-2.6.0.tar

        gateway-crds-helm-v1.6.3.tgz
        gateway-helm-v1.6.3.tgz
        kserve-crd-v0.15.0.tgz
        kserve-v0.15.0.tgz
        nai-core-2.6.0.tgz
        nai-operators-2.6.0.tgz
        opentelemetry-operator-0.102.0.tgz
        ```
    
15. Login to Harbor registry on the command line (if not done so)
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        docker login harbor.10.x.x.134.nip.io --username ${REGISTRY_USERNAME} --password ${REGISTRY_PASSWORD}
        ```

    === ":octicons-command-palette-16: Command output"
    
        ```bash
        Login succeeded!
        ```
   
16.  Upload the downloaded and prepared helm charts to Harbor
    
    === ":octicons-command-palette-16: Command"
    
        ```bash
        # Change to chart directory
        cd charts/
        ```
        ```bash
        # Push charts
        for chart in $(ls *.tgz); do echo $chart;helm push $chart oci://$REGISTRY/nutanix;done
        ```

    === ":octicons-command-palette-16: Command output"

        ```{ .text, .no-copy}
        for chart in $(ls *.tgz); do echo $chart;helm push $chart oci://harbor.10.x.x.134.nip.io/nutanix;done
        gateway-crds-helm-v1.6.3.tgz
        Pushed: harbor.10.x.x.134.nip.io/nutanix/gateway-crds-helm:v1.6.3
        Digest: sha256:55a2c0a4974cc2a83b9e144ec5b9ac687f0ae1b9d26ec178762184d0185db096
        gateway-helm-v1.6.3.tgz
        Pushed: harbor.10.x.x.134.nip.io/nutanix/gateway-helm:v1.6.3
        Digest: sha256:924799edea136fe405ea37480f5d5e65a81c6b01e3cbe53bf2ab5cde935ef0d6
        kserve-crd-v0.15.0.tgz
        Pushed: harbor.10.x.x.134.nip.io/nutanix/kserve-crd:v0.15.0
        Digest: sha256:01533cdda82c767fdd39172846f04c5185011eab2769b2c3d727bdd0f244a8f5
        kserve-v0.15.0.tgz
        Pushed: harbor.10.x.x.134.nip.io/nutanix/kserve:v0.15.0
        Digest: sha256:ee7fb3824268edc253f2b7d4ccae4a326e35cda38c89d3635b12a4a58cf45339
        nai-core-2.6.0.tgz
        Pushed: harbor.10.x.x.134.nip.io/nutanix/nai-core:2.6.0
        Digest: sha256:5859e99b2c4eff85bd6f78fd4170b7c580fc03131978dcf1f707811d908fe859
        nai-operators-2.6.0.tgz
        Pushed: harbor.10.x.x.134.nip.io/nutanix/nai-operators:2.6.0
        Digest: sha256:06d4b66a5d64add26bc6cc0f0864482ddabcdf735e05ab2a5ba347fcf4deae9b
        opentelemetry-operator-0.102.0.tgz
        Pushed: harbor.10.x.x.134.nip.io/nutanix/opentelemetry-operator:0.102.0
        Digest: sha256:1616912e98fbce5236707de9f7c8b91a98c9ecef6c207f625d9d5fa7683a31c8
        Now the charts are available in the OCI compatible container/chart registry.
        ```

## Prepare Container Images

The Jumphost VM will be used as a medium to download the NAI container images and upload them to the internal Harbor container registry.

```mermaid
stateDiagram-v2
    direction LR

    state LoginToNutanixPortal {
        [*] --> CreateDockerIDandAccessToken
        CreateDockerIDandAccessToken --> LoginToDockerCLI
        LoginToDockerCLI --> [*]
    }

    state PrepareNAIDockerImages {
        [*] --> DownloadUploadImagesToHarbor
        DownloadUploadImagesToHarbor --> [*]
    }
    
    [*] --> LoginToNutanixPortal
    LoginToNutanixPortal --> PrepareNAIDockerImages
    PrepareNAIDockerImages --> [*]
```

### Upload NAI Docker Images to Harbor

!!! info
    
    The download and upload of the container images will be done in one ``docker push`` command which will use the internal/private Harbor container registry details.

    This will be a two-step process.

    1. Upload the container images from the downloaded ``nai-2.x.x.tar`` to the jumphost VM local docker images store
    2. Upload it to the internal Harbor container registry 

1.  Download the NAI air-gap bundles (NAI container images) from the **Nutanix Portal** > **Downloads** > **Nutanix Enterprise AI**
    
    === ":octicons-command-palette-16: Command"

        ```text title="Paste the download URL within double quotes"
        curl -o nai-2.6.0.tar "_paste_download_URL_here"
        ```

    === ":octicons-command-palette-16: Sample command"
        
        ```bash title="This download is about 63 GBs"
        curl -o nai-2.6.0-1.tar "https://download.nutanix.com/downloads/nai/2.6.0/nai-2.6.0.tar?..."
        ```

2. Since we will be using the same internal Harbor container registry to upload container images, make sure the following environment variables are set (these were already set during air-gap NKP preparation). Append (add) the following to your ``$HOME/airgap-nai/.env`` file
   
    
    === ":octicons-file-code-16: Template ``$HOME/airgap-nai/.env``"
    
        ```bash
        export REGISTRY=harbor.10.x.x.134.nip.io
        export REGISTRY_USERNAME=admin
        export REGISTRY_PASSWORD=xxxxxxx
        export REGISTRY_CACERT=$HOME/harbor/certs/ca.crt
        ```

3. **(Optional)** - To view the container images loaded in your local docker container registry, run the following command:

    === ":octicons-command-palette-16:Command"

         ```bash
         docker images --format '{{.Repository}}:{{.Tag}}' | grep nai
         ```
    === ":octicons-command-palette-16: Output"
    
         ```bash
         nutanix/nai-python-processor:v2.6.0
         nutanix/nai-iep-operator:v2.6.0
         nutanix/nai-inference-ui:v2.6.0
         nutanix/nai-finetuning:v2.6.0
         nutanix/nai-kserve-custom-model-server:v2.6.0
         nutanix/nai-iam-bootstrap:v2.6.0
         nutanix/nai-jobs:v2.6.0
         nutanix/nai-clickhouse-udf:v2.6.0
         nutanix/nai-rag-app:v2.6.0
         nutanix/nai-ai-gateway-extproc:df2530f2
         nutanix/nai-ai-gateway-controller:df2530f2
         nutanix/nai-gateway:v1.6.3
         nutanix/nai-clickhouse-schemas:1.1.3
         nutanix/nai-vllm:v0.13.0-gpu
         nutanix/nai-vllm:v0.13.0
         nutanix/nai-epp-inference-scheduler:v1.2.1-98db134-982d862
         nutanix/nai-envoy:distroless-v1.36.4
         nutanix/nai-target-allocator:0.141.0
         nutanix/nai-opentelemetry-operator:0.141.0
         nutanix/nai-opentelemetry-collector-contrib:0.141.0
         nutanix/nai-ratelimit:99d85510
         nutanix/nai-iam-ui:v2.6.0
         nutanix/nai-iam-user-authn:v2.6.0
         nutanix/nai-kube-rbac-proxy:v0.20.0
         nutanix/nai-vllm:v0.10.2-gpu
         nutanix/nai-iam-proxy-control-plane:v2.6.0
         nutanix/nai-iam-proxy:v2.6.0
         nutanix/nai-iam-themis:v2.6.0
         nutanix/nai-clickhouse-keeper:25.3.5.42
         nutanix/nai-clickhouse-server:25.3.5.42
         nutanix/nai-oauth2-proxy:v7.9.0
         nutanix/nai-kserve-controller:v0.15.0
         nutanix/nai-clickhouse-metrics-exporter:0.24.2
         nutanix/nai-clickhouse-operator:0.24.2
         nutanix/nai-kube-rbac-proxy:v0.18.0
         nutanix/nai-postgres:16.1-alpine
         nutanix/nai-redis:7.0.11-alpine
         ```

4. Push the images to the jumphost VM local docker images store
   
    === ":octicons-command-palette-16: Command"

         ```bash
         docker image load -i nai-2.6.0.tar
         ```
   
5. Tag and push all the NAI images to refer to the internal/private harbor registry
   
    !!! tip "Use image upload script provided by Nutanix"

        Use the upload script provided by Nutanix. This is available on the Nutanix [portal](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Enterprise-AI-v2_6:top-push-image-registry-airgap-t.html).

        For most cases the following simple script works. 

    === ":octicons-command-palette-16: Command"

         ```bash
         for image in $(docker images --format '{{.Repository}}:{{.Tag}}' | grep 'nai' | grep -v ${REGISTRY}); do
           docker tag $image ${REGISTRY}/nutanix/$(echo $image);
           docker push ${REGISTRY}/nutanix/$(echo $image);
         done
         ```
Now we are ready to deploy our NAI workloads.