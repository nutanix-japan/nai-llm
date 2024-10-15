# Deploying GPT-in-a-Box v2 NVD Reference Application

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

1. Login to VSC on the jumphost VM, go to **Terminal** :octicons-terminal-24: and run the following commands to source the environment variables

    ```bash
    source $HOME/.env
    ```

2. In `VSCode` Explorer pane, Click on **New Folder** :material-folder-plus-outline: and name it: ``nai``

3. In ``VSCode``, under the newly created ``nai`` folder, click on **New File** :material-file-plus-outline: and create file with the following name:

    ```bash
    nai-prepare.sh
    ```

    with the following content:

    ```bash
    #!/usr/bin/env bash

    set -ex
    set -o pipefail

    ## Deploy Istio 1.20.8
    helm upgrade --install istio-base base --repo https://istio-release.storage.googleapis.com/charts --version=1.20.8 -n istio-system --create-namespace --wait

    helm upgrade --install istiod istiod --repo https://istio-release.storage.googleapis.com/charts --version=1.20.8 -n istio-system \
        --set gateways.securityContext.runAsUser=0 \
        --set gateways.securityContext.runAsGroup=0 \
        --wait
    
    helm upgrade --install istio-ingressgateway gateway --repo https://istio-release.storage.googleapis.com/charts --version=1.20.8 -n istio-system \
        --set securityContext.runAsUser=0 \
        --set securityContext.runAsGroup=0 \
        --set containerSecurityContext.runAsUser=0 \
        --set containerSecurityContext.runAsGroup=0 \
        --wait

    ## Deploy Knative 1.13.1 
    helm upgrade --install knative-serving-crds nai-knative-serving-crds --repo https://nutanix.github.io/helm-releases  --version=1.13.1 -n knative-serving --create-namespace --wait
    
    helm upgrade --install knative-serving nai-knative-serving --repo https://nutanix.github.io/helm-releases -n knative-serving --version=1.13.1 --wait
    
    helm upgrade --install knative-istio-controller nai-knative-istio-controller --repo https://nutanix.github.io/helm-releases -n knative-serving --version=1.13.1 --wait

    kubectl patch configmap config-features -n knative-serving --patch '{"data":{"kubernetes.podspec-nodeselector":"enabled"}}'

    kubectl patch configmap config-autoscaler -n knative-serving --patch '{"data":{"enable-scale-to-zero":"false"}}'

    ## Deploy Kserve 0.13.1
    helm upgrade --install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd --version=v0.13.1 -n kserve --create-namespace --wait

    helm upgrade --install kserve oci://ghcr.io/kserve/charts/kserve --version=v0.13.1 -n kserve --wait \
    --set kserve.modelmesh.enabled=false --set kserve.controller.image=docker.io/nutanix/nai-kserve-controller \
    --set kserve.controller.tag=v0.13.1
    ```

4. Run the script from the Terminal

    === "Command"

        ```bash
        chmod +x $HOME/nai/nai-prepare.sh
        $HOME/nai/nai-prepare.sh
        ```
        
    === "Command output"

        ```{ .text .no-copy }
        Release "istiod" has been upgraded. Happy Helming!
        NAME: istiod
        LAST DEPLOYED: Tue Oct 15 02:01:58 2024
        NAMESPACE: istio-system
        STATUS: deployed
        REVISION: 2
        TEST SUITE: None
        NOTES:
        "istiod" successfully installed!

        NAME: istio-ingressgateway
        LAST DEPLOYED: Tue Oct 15 02:02:01 2024
        NAMESPACE: istio-system
        STATUS: deployed

        NAME: knative-serving-crds
        LAST DEPLOYED: Tue Oct 15 02:02:03 2024
        NAMESPACE: knative-serving
        STATUS: deployed

        NAME: knative-serving
        LAST DEPLOYED: Tue Oct 15 02:02:05 2024
        NAMESPACE: knative-serving
        STATUS: deployed

        NAME: kserve-crd
        LAST DEPLOYED: Tue Oct 15 02:02:16 2024
        NAMESPACE: kserve
        STATUS: deployed

        NAME: kserve
        LAST DEPLOYED: Tue Oct 15 02:02:19 2024
        NAMESPACE: kserve
        STATUS: deployed
        ```

    ??? tip "Check helm deployment status"

        Check the status of the ``nai`` helm deployments using the following command:
        
        ```bash
        helm list -n istio-system
        helm list -n kserve
        helm list -n knative-serving
        ```


5. Validate if the resources are running in the following namespaces.

    - `istio-system`, 
    - `knative-serving`, and 
    - `kserve`
   
    === "Command"

        ```bash
        kubectl get po -n istio-system
        k get po -n kserve
        k get po -n knative-serving
        ```
        
    === "Command output"

        ```{ .text .no-copy }
        $ k get po -n istio-system
        NAME                                    READY   STATUS    RESTARTS   AGE
        istio-ingressgateway-6675867d85-qzrpq   1/1     Running   0          26d
        istiod-6d96569c9b-2dww4                 1/1     Running   0          26d

        $ k get po -n kserve
        NAME                                         READY   STATUS    RESTARTS   AGE
        kserve-controller-manager-6654f69d5c-45n64   2/2     Running   0          26d

        $ k get po -n knative-serving
        NAME                                   READY   STATUS    RESTARTS   AGE
        activator-58db57894b-g2nx8             1/1     Running   0          26d
        autoscaler-76f95fff78-c8q9m            1/1     Running   0          26d
        controller-7dd875844b-4clqb            1/1     Running   0          26d
        net-istio-controller-57486f879-85vml   1/1     Running   0          26d
        net-istio-webhook-7ccdbcb557-54dn5     1/1     Running   0          26d
        webhook-d8674645d-mscsc                1/1     Running   0          26d
        ```

## Deploy NAI

!!! warning
    This ``Deploy NAI`` section requires installation of a release candidate. Reach out to a Nutanix representative for download token for containers in this helm chart. This will have to be done until the solution becomes generally available. 

    The following Docker based environment variable values will be different from your own Docker environment variables.

    - ``$DOCKER_USERNAME``
    - ``$DOCKER_PASSWORD``
    - ``$DOCKER_EMAIL``


1. Open ``$HOME/.env`` file in ``VSCode``

2. Add (append) the following environment variables and save it

    === "Template .env"

        ```text
        export DOCKER_USERNAME=_release_candidate_docker_username
        export DOCKER_PASSWORD=_release_candidate_your_docker_password
        export DOCKER_EMAIL=_release_candidate_docker_email
        export NAI_CORE_VERSION=_release_candidate_nai_core_version
        ```

    === "Sample .env"

        ```text
        export DOCKER_USERNAME=ntnx-xxx
        export DOCKER_PASSWORD=*********
        export DOCKER_EMAIL=email@domain.com
        export NAI_CORE_VERSION=1.0.0-rc1
        ```

3. Source the environment variables (if not done so already)

    ```bash
    source $HOME/nai/.env
    ```

4. In `VSCode` Explorer pane, browse to ``/home/ubuntu/`` folder

5. Click on **New Folder** :material-folder-plus-outline: and name it: ``nai``
6. Download the values file from git hub and place it in ``/home/ubuntu/nai`` folder

    ```bash
    cd /home/ubuntu/nai
    curl -OL https://raw.githubusercontent.com/jesse-gonzalez/sol-cnai-infra/6656107ade4dde682dff36802b2bd805ce00dcb4/scripts/nai/iep-values-nkp.yaml
    ```

7. In ``VSCode``, Click on **New File** :material-file-plus-outline: and create a file with the following name:

    ```bash
    nai-deploy.sh
    ```

    with the following content:

    ```bash
    #!/usr/bin/env bash

    set -ex
    set -o pipefail

    helm repo add ntnx-charts https://nutanix.github.io/helm-releases
    helm repo update ntnx-charts

    #NAI-core
    helm upgrade --install nai-core ntnx-charts/nai-core --version=$NAI_CORE_VERSION -n nai-system --create-namespace --wait \
    --set imagePullSecret.credentials.username=$DOCKER_USERNAME \
    --set imagePullSecret.credentials.email=$DOCKER_EMAIL \
    --set imagePullSecret.credentials.password=$DOCKER_PASSWORD \
    --set naiApi.naiApiImage.tag=v1.0.0-rc2 \
    --insecure-skip-tls-verify \
    -f iep-values-nkp.yaml
    ```
   
8. Run the following command to deploy NAI
   
    === "Command"

        ```bash
        cd $HOME/nai-llm-fleet-infra/; devbox shell
        $HOME/nai/nai-deploy.sh
        ```

    === "Command output"
      
        ```{ .text .no-copy }
        $HOME/sol-cnai-infra/scripts/nai/nai-deploy.sh 

        + set -o pipefail
        + helm repo add ntnx-charts https://nutanix.github.io/helm-releases
        "ntnx-charts" already exists with the same configuration, skipping
        + helm repo update ntnx-charts
        Hang tight while we grab the latest from your chart repositories...
        ...Successfully got an update from the "ntnx-charts" chart repository
        Update Complete. ⎈Happy Helming!⎈
        helm upgrade --install nai-core ntnx-charts/nai-core --version=$NAI_CORE_VERSION -n nai-system --create-namespace --wait \
        --set imagePullSecret.credentials.username=$DOCKER_USERNAME \
        --set imagePullSecret.credentials.email=$DOCKER_EMAIL \
        --set imagePullSecret.credentials.password=$DOCKER_PASSWORD \
        --set naiApi.naiApiImage.tag=v1.0.0-rc2 \
        --insecure-skip-tls-verify \
        -f iep-values-nkp.yaml
        Release "nai-core" has been upgraded. Happy Helming!
        NAME: nai-core
        LAST DEPLOYED: Mon Sep 16 22:07:24 2024
        NAMESPACE: nai-system
        STATUS: deployed
        REVISION: 7
        TEST SUITE: None
        ```

9.  Verify that the NAI Core Pods are running and healthy
    
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

In this section we will install SSL Certificate to access the NAI UI. 

1. Create a certificate file using the Istio ingress gateway's IP address that was reserved in this [section](../infra/infra_nkp.md#reserve-control-plane-and-metallb-endpoint-ips). 
   
    Of three IPs ``10.x.x.214``,``10.x.x.215``,`10.x.x.216`, we will use ``10.x.x.216`` as the IP address of the ingress gateway.

2. Construct the FQDN of NAI UI using [nip.io](https://nip.io/)
   
    ```url
    nai.10.x.x.216.nip.io
    ```

3. In VSC Explorer, go to ``/home/ubuntu/`` folder, click on **New File** :material-file-plus-outline:  and create a file with the following name
   
    ```bash
    iep-cert.yaml
    ``` 
   
    Add the following content to the file and replace the IP address with the IP address of ingress gateway.

    Replace the values in the highlighted lines with the IP address of ingress gateway that was reserved in this [section](../infra/infra_nkp.md#reserve-control-plane-and-metallb-endpoint-ips).
   
    ```yaml hl_lines="11 13 15"
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: iep-cert
      namespace: istio-system
    spec:
      issuerRef:
        name: selfsigned-issuer
        kind: ClusterIssuer
      secretName: iep-cert
      commonName: nai.10.x.x.216.nip.io
      dnsNames:
        - nai.10.x.x.216.nip.io
      ipAddresses:
        - 10.x.x.216
    ```

4. Create the certificate using the following command
    
    ```bash
    kubectl apply -f /home/ubuntu/iep-cert.yaml
    ```

5. Patch the ingress gateway's IP address to the certificate file.
    
    === "Command"
   
        ```bash
        kubectl patch gateway -n knative-serving knative-ingress-gateway --type merge --patch-file=/dev/stdin <<EOF
        spec:
          servers:
          - hosts:
            - '*'
            port:
              name: https
              number: 443
              protocol: HTTPS
            tls:
              mode: SIMPLE
              credentialName: iep-cert
        EOF
        ```

    === "Command output"
     
        ```{ .text .no-copy }
        gateway.networking.istio.io/knative-ingress-gateway patched 
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
3. Input your Hugging Face token that was created in the previous [section](../iep/iep_pre_reqs.md#create-a-hugging-face-token-with-read-permissions) and click **Save**

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

