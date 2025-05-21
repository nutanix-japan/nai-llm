# Deploying Nutanix Enterprise AI (NAI) NVD Reference Application

!!! info "Version 2.0.0"

    This version of the NAI deployment is based on the Nutanix Enterprise AI (NAI) ``v2.0.0`` release.

```mermaid
stateDiagram-v2
    direction LR
    
    state DeployNAI {
        [*] --> DeployNAIAdmin
        DeployNAIAdmin -->  InstallSSLCert
        InstallSSLCert --> DownloadModel
        DownloadModel --> CreateNAI
        CreateNAI --> [*]
    }

    [*] --> PreRequisites
    PreRequisites --> DeployNAI 
    DeployNAI --> TestNAI : next section
    TestNAI --> [*]
```

## Prepare for NAI Deployment

## Enable NKE Operators

Enable these NKE Operators from NKP GUI.

!!! note

    In this lab, we will be using the **Management Cluster Workspace** to deploy our Nutanix Enterprise AI (NAI)

    However, in a customer environment, it is recommended to use a separate workload NKP cluster.

1. In the NKP GUI, Go to **Clusters**
2. Click on **Management Cluster Workspace**
3. Go to **Applications** 
4. Search and enable the following applications: follow this order to install dependencies for NAI application
   
    - Prometheus Monitoring: version ``69.1.2`` or later
    - Prometheus Adapter: version ``v4.11.0`` or later
    - Istio Service Mesh: version``1.20.8`` or later
  
5. The next application to enable is
    - Knative: version `v1.17.0` or later

    - Search for Knative in the **Applications**

    - Use the following configuration parameters in **Workspace Configuration**:

    ```yaml
    serving:
      config:
        features:
          kubernetes.podspec-nodeselector: enabled
        autoscaler:
          enable-scale-to-zero: false
      knativeIngressGateway:
        spec:
          selector:
            istio: ingressgateway
          servers:
          - hosts:
            - '*'
            port:
              name: https
              number: 443
              protocol: HTTPS
            tls:
              mode: SIMPLE
              credentialName: nai-cert # (1)
    ```

    1. We will create this credential in the next section


6. Install ``kserve`` using the following commands

    === "Command"
    
        ```bash
        export KSERVE_VERSION=v0.15.0

        helm upgrade --install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd --version ${KSERVE_VERSION} -n kserve --create-namespace
        ```
        ```bash
        helm upgrade --install kserve oci://ghcr.io/kserve/charts/kserve --version ${KSERVE_VERSION} --namespace kserve --create-namespace --wait 
        ```

    === "Output"
    
        ```{ .text .no-copy }
        Pulled: ghcr.io/kserve/charts/kserve-crd:v0.15.0
        Digest: sha256:57ad1a5475fd625cb558214ba711752aa77b7d91686a391a5f5320cfa72f3fa8
        Release "kserve-crd" has been upgraded. Happy Helming!
        NAME: kserve-crd
        LAST DEPLOYED: Mon May 19 06:11:30 2025
        NAMESPACE: kserve
        STATUS: deployed
        REVISION: 2
        TEST SUITE: None
        (devbox) 
        ```
        ```{ .text .no-copy }
        Pulled: ghcr.io/kserve/charts/kserve:v0.15.0
        Digest: sha256:905abce80e975c53b40fba7a12b0b9a1e24bdf65cceebb88fba4ef62bba01406
        Release "kserve" has been upgraded. Happy Helming!
        NAME: kserve
        LAST DEPLOYED: Mon May 19 05:48:45 2025
        NAMESPACE: kserve
        STATUS: deployed
        REVISION: 2
        TEST SUITE: None
        ```
7. Check if ``kserve`` pods are running
    === "Command"
    
        ```bash
        kubens kserve
        kubectl get pods 
        ```

    === "Output"
    
        ```{ .text .no-copy }
        NAME                                         READY   STATUS    RESTARTS   AGE
        kserve-controller-manager-58946fd54d-vsxvn   2/2     Running   0          18m
        ```

!!! note
    It may take a few minutes for each application to be up and running. Monitor the deployment to make sure that these applications are running before moving on to the next section.
        ```

## Deploy NAI

We will use the Docker login credentials we created in the previous section to download the NAI Docker images.

!!! warning "Change the Docker login credentials"

    The following Docker based environment variable values need to be changed from your own Docker environment variables to the credentials downloaded from Nutanix Portal.

    - ``$DOCKER_USERNAME``
    - ``$DOCKER_PASSWORD``

1. Open ``$HOME/.env`` file in ``VSCode``

2. Add (append) the following environment variables and save it

    === "Template .env"

        ```text
        export DOCKER_USERNAME=_GA_release_docker_username
        export DOCKER_PASSWORD=_GA_release_docker_password
        export NAI_CORE_VERSION=_GA_release_nai_core_version
        ```

    === "Sample .env"

        ```text
        export DOCKER_USERNAME=ntnxsvcgpt
        export DOCKER_PASSWORD=dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxx
        export NAI_CORE_VERSION=v2.3.0
        ```

3. Source the environment variables (if not done so already)

    ```bash
    source $HOME/.env
    ```

4. In `VSCode` Explorer pane, browse to ``$HOME/nai`` folder
   
5. Click on **New File** :material-file-plus-outline: and create file with the following name:

    ```bash
    nkp-values.yaml
    ```

    with the following content:

    ```yaml
    # nai-monitoring stack values for nai-monitoring stack deployment in NKE environment
    naiMonitoring:
          
      ## Component scraping node exporter
      ##
      nodeExporter:
        serviceMonitor:
          enabled: true
          endpoint:
            port: http-metrics
            scheme: http
            targetPort: 9100
          namespaceSelector:
            matchNames:
            - kommander
          serviceSelector:
            matchLabels:
              app.kubernetes.io/name: prometheus-node-exporter
              app.kubernetes.io/component: metrics
    
      ## Component scraping dcgm exporter
      ##
      dcgmExporter:
        podLevelMetrics: true
        serviceMonitor:
          enabled: true
          endpoint:
            targetPort: 9400
          namespaceSelector:
            matchNames:
            - kommander
          serviceSelector:
            matchLabels:
              app: nvidia-dcgm-exporter
    ```

    !!!tip

           It is possible to get the values file using the following command
      
           ```bash
           helm repo add ntnx-charts https://nutanix.github.io/helm-releases
           helm repo update ntnx-charts
           helm pull ntnx-charts/nai-core --version=nai-core-version --untar=true
           ```

           All the files will be untar'ed to a folder nai-core in the present working directory

           Use the ``nkp-values.yaml`` file in the installation command

6. In ``VSCode``, Under ``$HOME/nai`` folder, click on **New File** :material-file-plus-outline: and create a file with the following name:

    ```bash
    nai-deploy.sh
    ```

    with the following content:

    ```bash hl_lines="14"
    #!/usr/bin/env bash

    set -ex
    set -o pipefail

    helm repo add ntnx-charts https://nutanix.github.io/helm-releases
    helm repo update ntnx-charts

    #NAI-core
    helm upgrade --install nai-core ntnx-charts/nai-core --version=$NAI_CORE_VERSION -n nai-system --create-namespace --wait \
    --set imagePullSecret.credentials.username=$DOCKER_USERNAME \
    --set imagePullSecret.credentials.password=$DOCKER_PASSWORD \
    --insecure-skip-tls-verify \
    -f nkp-values.yaml
    ```
   
7.  Run the following command to deploy NAI
   
    === "Command"

        ```bash
        $HOME/nai/nai-deploy.sh
        ```

    === "Command output"
      
        ```{ .text .no-copy }
        $HOME/nai/nai-deploy.sh 

        + set -o pipefail
        + helm repo add ntnx-charts https://nutanix.github.io/helm-releases
        "ntnx-charts" already exists with the same configuration, skipping
        + helm repo update ntnx-charts
        Hang tight while we grab the latest from your chart repositories...
        ...Successfully got an update from the "ntnx-charts" chart repository
        Update Complete. ⎈Happy Helming!⎈
        helm upgrade --install nai-core ntnx-charts/nai-core --version=$NAI_CORE_VERSION -n nai-system --create-namespace --wait \
        --set imagePullSecret.credentials.username=$DOCKER_USERNAME \
        --set imagePullSecret.credentials.password=$DOCKER_PASSWORD \
        --insecure-skip-tls-verify \
        -f nkp-values.yaml
        Release "nai-core" has been upgraded. Happy Helming!
        NAME: nai-core
        LAST DEPLOYED: Mon Sep 16 22:07:24 2024
        NAMESPACE: nai-system
        STATUS: deployed
        REVISION: 7
        TEST SUITE: None
        ```

8.  Verify that the NAI Core Pods are running and healthy
    
    === "Command"

        ```bash
        kubens nai-system
        kubectl get po,deploy
        ```
    === "Command output"

        ```{ .text .no-copy }
        $ kubens nai-system
        ✔ Active namespace is "nai-system"

        $ kubectl get po,deploy

        NAME                                            READY   STATUS      RESTARTS   AGE
        pod/nai-api-55c665dd67-746b9                    1/1     Running     0          5d1h
        pod/nai-api-db-migrate-fdz96-xtmxk              0/1     Completed   0          40h
        pod/nai-db-789945b4df-lb4sd                     1/1     Running     0          43h
        pod/nai-iep-model-controller-84ff5b5b87-6jst9   1/1     Running     0          5d8h
        pod/nai-ui-7fc65fc6ff-clcjl                     1/1     Running     0          5d8h
        pod/prometheus-nai-0                            2/2     Running     0          43h

        NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
        deployment.apps/nai-api                    1/1     1            1           5d8h
        deployment.apps/nai-db                     1/1     1            1           5d8h
        deployment.apps/nai-iep-model-controller   1/1     1            1           5d8h
        deployment.apps/nai-ui                     1/1     1            1           5d8h
        ```

## Install SSL Certificate

In this section we will install SSL Certificate to access the NAI UI. This is required as the endpoint will only work with a ssl endpoint with a valid certificate. 

NAI UI is accessible using the Ingress Gateway.

The following steps show how cert-manager can be used to generate a self signed certificate using the default selfsigned-issuer present in the cluster. 

!!! info "If you are using Public Certificate Authority (CA) for NAI SSL Certificate"
    
    If an organization generates certificates using a different mechanism then obtain the certificate **+ key** and create a kubernetes secret manually using the following command:

    ```bash
    kubectl -n istio-system create secret tls nai-cert --cert=path/to/nai.crt --key=path/to/nai.key
    ```

    Skip the steps in this section to create a self-signed certificate resource.

1. Get the Ingress host using the following command:
   
    ```bash
    INGRESS_HOST=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    ```

2. Get the value of ``INGRESS_HOST`` environment variable
   
    === "Command"

        ```bash
        echo $INGRESS_HOST
        ```

    === "Command output"

        ``` { .text .no-copy }
        10.x.x.216
        ```

3. We will use the command output e.g: ``10.x.x.216`` as the IP address for NAI as reserved in this [section](../infra/infra_nkp.md#reserve-control-plane-and-metallb-endpoint-ips)

4. Construct the FQDN of NAI UI using [nip.io](https://nip.io/) and we will use this FQDN as the certificate's Common Name (CN).
   
    === "Template URL"

        ```bash
        nai.${INGRESS_HOST}.nip.io
        ```

    === "Sample URL"

        ``` { .text .no-copy }
        nai.10.x.x.216.nip.io
        ```

5. Create the ingress resource certificate using the following command:
   
    ```bash hl_lines="12 14 16"
    cat << EOF | k apply -f -
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: nai-cert
      namespace: istio-system
    spec:
      issuerRef:
        name: selfsigned-issuer
        kind: ClusterIssuer
      secretName: nai-cert
      commonName: nai.${INGRESS_HOST}.nip.io
      dnsNames:
      - nai.${INGRESS_HOST}.nip.io
      ipAddresses:
      - ${INGRESS_HOST}
    EOF
    ```

6. Create the certificate using the following command
    
    ```bash
    kubectl apply -f $HOME/airgap-nai/nai-cert.yaml
    ```

## Accessing the UI

6. In a browser, open the following URL to connect to the NAI UI
   
    ```url
    https://nai.10.x.x.216.nip.io
    ```

7. Change the password for the `admin` user
8. Login using `admin` user and password.
   
    ![](images/nai-login.png)

## Download Model

We will download and user llama3 8B model which we sized for in the previous section.

1. In the NAI GUI, go to **Models**
2. Click on Import Model from Hugging Face
3. Choose the ``meta-llama/Meta-Llama-3.1-8B-Instruct`` model
4. Input your Hugging Face token that was created in the previous [section](../iep/iep_pre_reqs.md#create-a-hugging-face-token-with-read-permissions) and click **Import**

5. Provide the Model Instance Name as ``Meta-Llama-3.1-8B-Instruct`` and click **Import**
5. Go to VSC Terminal to monitor the download
    
    === "Command"

        ```bash title="Get jobs in nai-admin namespace"
        kubens nai-admin
        
        kubectl get jobs
        ```
        ```bash title="Validate creation of pods and PVC"
        kubectl get po,pvc
        ```
        ```bash title="Verify download of model using pod logs"
        kubectl logs -f _pod_associated_with_job
        ```

    === "Command output"

        ```text title="Get jobs in nai-admin namespace"
        kubens nai-admin

        ✔ Active namespace is "nai-admin"
     
        kubectl get jobs

        NAME                                       COMPLETIONS   DURATION   AGE
        nai-c0d6ca61-1629-43d2-b57a-9f-model-job   0/1           4m56s      4m56
        ```
        ```text title="Validate creation of pods and PVC"
        kubectl get po,pvc

        NAME                                             READY   STATUS    RESTARTS   AGE
        nai-c0d6ca61-1629-43d2-b57a-9f-model-job-9nmff   1/1     Running   0          4m49s

        NAME                                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      VOLUMEATTRIBUTESCLASS   AGE
        nai-c0d6ca61-1629-43d2-b57a-9f-pvc-claim   Bound    pvc-a63d27a4-2541-4293-b680-514b8b890fe0   28Gi       RWX            nai-nfs-storage   <unset>                 2d
        ```
        ```text title="Verify download of model using pod logs"
        kubectl logs -f nai-c0d6ca61-1629-43d2-b57a-9f-model-job-9nmff 

        /venv/lib/python3.9/site-packages/huggingface_hub/file_download.py:983: UserWarning: Not enough free disk space to download the file. The expected file size is: 0.05 MB. The target location /data/model-files only has 0.00 MB free disk space.
        warnings.warn(
        tokenizer_config.json: 100%|██████████| 51.0k/51.0k [00:00<00:00, 3.26MB/s]
        tokenizer.json: 100%|██████████| 9.09M/9.09M [00:00<00:00, 35.0MB/s]<00:30, 150MB/s]
        model-00004-of-00004.safetensors: 100%|██████████| 1.17G/1.17G [00:12<00:00, 94.1MB/s]
        model-00001-of-00004.safetensors: 100%|██████████| 4.98G/4.98G [04:23<00:00, 18.9MB/s]
        model-00003-of-00004.safetensors: 100%|██████████| 4.92G/4.92G [04:33<00:00, 18.0MB/s]
        model-00002-of-00004.safetensors: 100%|██████████| 5.00G/5.00G [04:47<00:00, 17.4MB/s]
        Fetching 16 files: 100%|██████████| 16/16 [05:42<00:00, 21.43s/it]:33<00:52, 9.33MB/s]
        ## Successfully downloaded model_files|██████████| 5.00G/5.00G [04:47<00:00, 110MB/s] 

        Deleting directory : /data/hf_cache
        ```

6. Optional - verify the events in the namespace for the pvc creation 
    
    === "Command"

        ```bash
        k get events | awk '{print $1, $3}'
        ```

    === "Command output"

        ```{ .text, .no-copy}
        $ k get events | awk '{print $1, $3}'
    
        3m43s Scheduled
        3m43s SuccessfulAttachVolume
        3m36s Pulling
        3m29s Pulled
        3m29s Created
        3m29s Started
        3m43s SuccessfulCreate
        90s   Completed
        3m53s Provisioning
        3m53s ExternalProvisioning
        3m45s ProvisioningSucceeded
        3m53s PvcCreateSuccessful
        3m48s PvcNotBound
        3m43s ModelProcessorJobActive
        90s   ModelProcessorJobComplete
        ```

The model is downloaded to the Nutanix Files ``pvc`` volume.

After a successful model import, you will see it in **Active** status in the NAI UI under **Models** menu

![](images/downloaded_model.png)

## Create and Test Inference Endpoint

In this section we will create an inference endpoint using the downloaded model.

1. Navigate to **Inference Endpoints** menu and click on **Create Endpoint** button
2. Fill the following details:
   
    - **Endpoint Name**: ``llama-8b``
    - **Model Instance Name**: ``Meta-LLaMA-8B-Instruct``
    - **Use GPUs for running the models** : ``Checked``
    - **No of GPUs (per instance)**:
    - **GPU Card**: ``NVIDIA-L40S`` (or other available GPU)
    - **No of Instances**: ``1``
    - **API Keys**: Create a new API key or use an existing one

3. Click on **Create**
4. Monitor the ``nai-admin`` namespace to check if the services are coming up
   
    === "Command"

        ```bash
        kubens nai-admin
        kubectl get po,deploy
        ```

    === "Command output"
        
        ```{ .text .no-copy }
        kubens nai-admin
        get po,deploy
        NAME                                                     READY   STATUS        RESTARTS   AGE
        pod/llama8b-predictor-00001-deployment-9ffd786db-6wkzt   2/2     Running       0          71m

        NAME                                                 READY   UP-TO-DATE   AVAILABLE   AGE
        deployment.apps/llama8b-predictor-00001-deployment   1/1     1            0           3d17h
        ```

5. Check the events in the ``nai-admin`` namespace for resource usage to make sure all 
   
    === "Command"
       
        ```bash
        kubectl get events -n nai-admin --sort-by='.lastTimestamp' | awk '{print $1, $3, $5}'
        ```

    === "Command output"
       
        ```bash
        $ kubectl get events -n nai-admin --sort-by='.lastTimestamp' | awk '{print $1, $3, $5}'

        110s FinalizerUpdate Updated
        110s FinalizerUpdate Updated
        110s RevisionReady Revision
        110s ConfigurationReady Configuration
        110s LatestReadyUpdate LatestReadyRevisionName
        110s Created Created
        110s Created Created
        110s Created Created
        110s InferenceServiceReady InferenceService
        110s Created Created
        ```

6. Once the services are running, check the status of the inference service
   
    === "Command"

        ```bash
        kubectl get isvc
        ```

    === "Command output"
        
        ```{ .text .no-copy }
        kubectl get isvc

        NAME      URL                                          READY   PREV   LATEST   PREVROLLEDOUTREVISION   LATESTREADYREVISION       AGE
        llama8b   http://llama8b.nai-admin.svc.cluster.local   True           100                              llama8b-predictor-00001   3d17h
        ```

