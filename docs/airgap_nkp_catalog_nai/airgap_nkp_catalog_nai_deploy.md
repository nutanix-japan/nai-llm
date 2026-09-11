---

title: Deploying Nutanix Enterprise AI
description: This lab takes your through installing NAI using NKP catalog applications once all pre-requistes as NKP cluster and other infrastructure components are installed and available to access.

---

# Deploying Nutanix Enterprise AI

!!! info "Version 2.8.0"

    This version of the NAI deployment is based on the Nutanix Enterprise AI (NAI) ``v2.8.0`` release.
   
## Prepare for NAI Deployment

!!! example "GA Software with NAI v2.8.0"
    
    In this lab, we will deploy GA version of the following software to test the following:

    -  Nutanix Enterprise AI 
  
        * **Unified Endpoints** - multiple endpoints for HA and token-based rate limiting
        * **Providers** - Add remote endpoints from providers to utilize their models in Nutanix Enterprise AI workloads.

!!! info

    Changes in NAI ``v2.8.0``

    - Kserve is of at least of ``v0.19.0``
    - Cert-manager is at least of ``v1.17.2``
    - OpenTelemetry operator is at least of ``v0.114.1``
    - Envoy Gateway is at least of ``v1.8.1``
    - Prometheus Monitoring is at least of ``82.13.6``
    - CloudNativePG Operator is ar least of ``0.28.0`` [usually pre-installed with NKP]
    - LeaderWorkerSet is at least of ``0.8.0``
  
## Enable Pre-requisite Applications  

!!! warning
    
    Make sure to license NKP cluster with at least **NKP Pro License** to make use of the NKP Applications catalog to provision NAI (and other applications)
    
### Prometheus

The following pre-requisite applications will be enabled on NKP GUI:

!!! note

    In this lab, we will be using the **Management Cluster Workspace** to deploy our Nutanix Enterprise AI (NAI)

    However, in a customer environment, it is recommended to use a separate workload NKP cluster.

**Search** and **Enable** the following applications: follow this order to install dependencies for NAI application


1. In the NKP GUI, Go to **Clusters**
2. Click on **Management Cluster Workspace**
3. Go to **Applications** to search and enable the following:
   
     * **Prometheus Monitoring** : version ``82.13.6`` or higher with the following ``Values`` configuration 

4. Wait for ``Deployed`` state in the GUI

??? "Cert Manager" 

    Cert Manager is pre-installed on all NKP Clusters. If not installed, use the following method to install:
    
    1. In the NKP GUI, Go to **Clusters**
    2. Click on **Management Cluster Workspace**
    3. Go to **Applications** to search and enable the following:
    
         * **Cert-manager**- at least ``v1.17.2``
            
    4. Wait for ``Deployed`` state in the GUI
  
### Envoy Gateway


1. In the NKP GUI, Go to **Clusters**
2. Click on **Management Cluster Workspace**
3. Go to **Applications** to search and enable the following:
   
     * **NAI - Envoy Gateway** : version ``v1.8.1`` or higher with the following ``Values`` configuration 
     
        ```yaml hl_lines="12 22"
        config:
          envoyGateway:
            gateway:
              controllerName: "gateway.envoyproxy.io/gatewayclass-controller"
            logging:
              level:
                default: "info"
            provider:
              kubernetes:
                rateLimitDeployment:
                  container:
                    image: "nutanix/nai-ratelimit:1e50889b" # (1)!
                  patch:
                    type: "StrategicMerge"
                    value:
                      spec:
                        template:
                          spec:
                            containers:
                              - imagePullPolicy: "IfNotPresent"
                                name: "envoy-ratelimit"
                                image: "nutanix/nai-ratelimit:1e50889b" # (1)!
                                env:
                                  - name: REDIS_TYPE
                                    value: "sentinel"
                                  - name: REDIS_PIPELINE_WINDOW
                                    value: "150us"
              type: "Kubernetes"
            extensionApis:
              enableEnvoyPatchPolicy: true
              enableBackend: true
            extensionManager:
              maxMessageSize: 11Mi
              backendResources:
                - group: inference.networking.k8s.io
                  kind: InferencePool
                  version: v1
              hooks:
                xdsTranslator:
                  translation:
                    listener:
                      includeAll: true
                    route:
                      includeAll: true
                    cluster:
                      includeAll: true
                    secret:
                      includeAll: true
                  post:
                    - "Translation"
                    - "Cluster"
                    - "Route"
              service:
                fqdn:
                  hostname: "ai-gateway-controller.nai-system.svc.cluster.local"
                  port: 1063
            rateLimit:
              backend:
                type: "Redis"
                redis:
                  url: "mymaster,nai-valkey-sentinel.nai-system.svc.cluster.local:26379"
        ```

        1. :man_tipping_hand: Make sure align with the repository name of the image with the internal (Harbor) registry's repository. In our workflow we have used ``nutanix`` as repository from URL ``oci://harbor.10.x.x.134.nip.io/nutanix/``

4. Check if Envoy Gateway resources are ready either in the GUI by watching for ``Deployed`` state or in the commandline as follows:
    
    !!! warning 
        
        The ``envoy-ratelimit-`` pod will temporarily be in ``CrashLoopBackOff`` state and eventually will transition to ``Running`` after redis-standalone pod is fully deployed in the upcoming [Deploy NAI](iep_deploy.md#deploy-nai) section.

        Ignore the ``CrashLoopBackOff`` state for now and move on to the next section. 
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl get po -n envoy-gateway-system
        ```


    === ":octicons-command-palette-16: Output"

        ```{ .text .no-copy }
        $ kubectl get pods -n envoy-gateway-system
        #
        NAME                               READY   STATUS    RESTARTS      AGE
        envoy-gateway-5c8b5fd5fb-zwhwz     1/1     Running   5 (90m ago)   5m
        envoy-ratelimit-6b4657bddd-5zzms   1/1     Running   9 (89m ago)   5m
        ```

### Kserve


1. In the NKP GUI, Go to **Clusters**
2. Click on **Management Cluster Workspace**
3. Go to **Applications** to search and enable the following:
   
     * **Kserve** : version ``v0.15.0``

4. Check if Kserve resources are ready either in the GUI by watching for ``Deployed`` state or in the commandline as follows:
    
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubens kserve
        kubectl get pods    
        ```

    === ":octicons-command-palette-16: Output"
    
        ```{ .text .no-copy }
        $ kubectl get pods 
        #
        NAME                                         READY   STATUS    RESTARTS   AGE
        kserve-controller-manager-857dcfb7d8-fqmpw   2/2     Running   0          4m
        llmisvc-controller-manager-cf84cf6db-mwftz   1/1     Running   0          4m
        ```
### CloudNativePG

!!! note
    
    NKP will have CloudNativePG pre-installed as a part of regular install. Check in the Applications Catalog of the NKP cluster for its presence. 

    Check for CloudNativePG ``v0.28.0``, if present, skip this section. 

1. In the NKP GUI, Go to **Clusters**
2. Click on **Management Cluster Workspace**
3. Go to **Applications** to search and enable the following:
   
     * **CloudNativePG** : version ``0.28.0``

### LeaderWorkerSet

LeaderWorkerSet (LWS) is an open-source, custom Kubernetes API designed to deploy and manage multi-node AI/ML workloads—such as large language model (LLM) distributed inference and training—as a single, cohesive unit. It automatically groups a collection of pods into a specific topology consisting of one leader pod and multiple worker pods, managing their entire lifecycle simultaneously so that if a single pod fails, the entire group restarts together to prevent data inconsistency. Furthermore, LWS simplifies network communication across these nodes by automatically injecting group environment variables and optimizing pod placement within the same network topology to guarantee high-throughput, low-latency data transfers between GPUs.

1. In the NKP GUI, Go to **Clusters**
2. Click on **Management Cluster Workspace**
3. Go to **Applications** to search and enable the following:
   
     * **LeaderWorkerSet** : version ``0.8.0`` 

### Opentelemetry


1. In the NKP GUI, Go to **Clusters**
2. Click on **Management Cluster Workspace**
3. Go to **Applications** to search and enable the following:
   
     * **Opentelemetry Operator** : version ``v0.114.1`` 

## Deploy NAI

We will use the Docker login credentials we created in the previous section to download the NAI Docker images.

??? "Deploy NAI Profiles using Helm"

    NAI ``v2.8.0`` onwards has support for profiles for different capacity of NAI use cases.

    Use the Helm method [here](../iep/iep_deploy.md#deploy-nai) to install these profiles depending on your requirements.

    | Name     	| Capacity                                                    	|
    |----------	|------------------------------------------------------------	|
    | Default 	| 300 concurrent requests and 100 API Keys       	            |
    | c1k_k200  | 1000 concurrent requests and 200 API Keys                     |
    | c5k_k1k   | 	5000 concurrent requests and 1000 API Keys 	                |

1. Open ``$HOME/.env`` file in ``VSCode``

2. Add (append) the following environment variables and save it

    === ":octicons-file-code-16: Template ``.env``"

        ```bash
        export NAI_USER=_your_desired_nai_ui_username
        export NAI_TEMP_PASS=_your_desired_nai_ui_password # At least 8 characters
        export NAI_API_RWX_STORAGECLASS=_nkp_rwx_storage_class
        export NAI_DEFAULT_RWO_STORAGECLASS=_nkp_rwo_storage_class
        #
        # Optional - for NAI Mangement UI endpoint
        # To install public CA certificates for NAI UI endpoint 
        #
        export CLUSTER_ISSUER=_cluster_issuer_name
        export NAI_PUBLIC_DOMAIN_NAME=_nai_domain_name
        ```

    === ":octicons-file-code-16: Sample ``.env``"

        ```text
        export NAI_USER=admin
        export NAI_TEMP_PASS=_Xxxxxxxxxx
        export NAI_API_RWX_STORAGECLASS=nai-nfs-storage
        export NAI_DEFAULT_RWO_STORAGECLASS=nutanix-volume
        #
        # Optional - for NAI Mangement UI endpoint
        # To install public CA certificates for NAI UI endpoint 
        #
        export CLUSTER_ISSUER=letsencrypt-cloudflare
        export NAI_PUBLIC_DOMAIN_NAME=nai.domain.com
        ```

3. Source the environment variables

    === ":octicons-command-palette-16: Command"

        ```bash
        source $HOME/.env
        ```

4. In the NKP GUI, Go to **Clusters**
5. Click on **Management Cluster Workspace**
6. Create a template file with Values configuration
   
   
    === ":octicons-command-palette-16: Command"
    
        ```yaml
        cat << EOF > nai-core-values.yaml
        global:
          storage:
            storageClassNameRWX: ${NAI_API_RWX_STORAGECLASS}
            storageClassName: ${NAI_DEFAULT_RWO_STORAGECLASS}
        
        naiApi:
          superAdmin:
            username: ${NAI_UI_USER}
            password: ${NAI_TEMP_PASS}      # At least 8 characters
            # email: admin@nutanix.com
            # firstName: admin
        #
        # Optional - for NAI demo labs
        #
        # naiLabs:
        #   enabled: true
        #
        # Optional - for NAI Mangement UI endpoint
        # To install public CA certificates for NAI UI endpoint 
        #
        # gateway:
        #   tlsSecretName: "nai-cert"         # secret name written by cert-manager
        #   certManager:
        #     selfSigned: true                # enables self-signed issuer + certificate

        # Optional - use if you are using cert-manager and ClusterIssuer with your own domain 
        # gateway:
        #  certManager:
        #    issuerRef:
        #      name: letsencrypt-cloudflare # ClusterIssuer must be existing
        #      kind: ClusterIssuer
        #    dnsNames:
        #      - nai.domain.com
        EOF
        ```

    === ":octicons-file-code-16: Sample values"
        
        ```yaml
        global:
          storage:
            storageClassNameRWX: nai-nfs-storage
            storageClassName: nutanix-volume
      
        naiApi:
          superAdmin:
            username: admin
            password: _XXXXXXXXX # At least 8 characters
            # email: admin@nutanix.com
            # firstName: admin
        #
        # Optional - for NAI demo labs
        #
        # naiLabs:
        #   enabled: true
        #
        # Optional - for NAI Mangement UI endpoint
        # To install public CA certificates for NAI UI endpoint 
        #
        # gateway:
        #   tlsSecretName: "nai-cert"         # secret name written by cert-manager
        #   certManager:
        #     selfSigned: true                # enables self-signed issuer + certificate
        
        # Optional - use if you are using cert-manager and ClusterIssuer with your own domain
        # gateway:
        #  certManager:
        #    issuerRef:
        #      name: letsencrypt-cloudflare
        #      kind: ClusterIssuer
        #    dnsNames:
        #      - nai.domain.com
        ```  

7.  Go to **Applications** to search and enable the following:
   
     * **Nutanix Enterprise AI** : version ``v2.8.0`` or higher with contents of ```nai-core-values.yaml``` file from previous step.
        

10. Check if NAI resources are ready either in the GUI by watching for ``Deployed`` state or in the commandline as follows:
    
    !!! note
        
        This operation will take at least ``5 - 8 minutes`` depending on the resources available. 

        The NKP Catalog application will deploy nai-operators first before proceeding to install NAI resources.
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubens nai-system
        kubectl get pods    
        ```

    === ":octicons-command-palette-16: Output"
    
        ```{ .text .no-copy }
        Active namespace is "nai-system".

        READY   STATUS      RESTARTS   AGE
        ai-gateway-controller-6fff98cbd6-lv8dd                   1/1     Running     0          67m
        chi-nai-clickhouse-server-chcluster1-0-0-0               1/1     Running     0          64m
        chk-nai-clickhouse-keeper-chkeeper-0-0-0                 1/1     Running     0          63m
        iam-database-bootstrap-pdzxh-7j9m7                       0/1     Completed   0          64m
        iam-proxy-5bd954bb85-qmdwx                               1/1     Running     0          64m
        iam-proxy-control-plane-5ff697cdfb-5pnlz                 1/1     Running     0          64m
        iam-themis-849478f448-7c6bx                              2/2     Running     0          60m
        iam-themis-bootstrap-e5pyk-pl96p                         0/1     Completed   0          64m
        iam-ui-7476458cb-q8rns                                   1/1     Running     0          64m
        iam-user-authn-57d8b4dd67-nsdt5                          2/2     Running     0          60m
        nai-agent-5d7b86946d-8b8jn                               1/1     Running     0          64m
        nai-api-86d58c7b6f-5fg4h                                 1/1     Running     0          64m
        nai-api-db-migrate-vk5y2-2dfr8                           0/1     Completed   5          64m
        nai-clickhouse-schema-job-1788408841-hvwl8               0/1     Completed   0          64m
        nai-db-iep-1                                             1/1     Running     0          66m
        nai-oauth2-proxy-595d65db9c-lt6bs                        1/1     Running     0          64m
        nai-operators-nai-clickhouse-operator-687479c97b-m9hn7   2/2     Running     0          67m
        nai-otel-collector-collector-2b5xm                       1/1     Running     0          64m
        nai-otel-collector-collector-5xj4k                       1/1     Running     0          64m
        nai-otel-collector-collector-7jdln                       1/1     Running     0          64m
        nai-otel-collector-collector-7tlz8                       1/1     Running     0          64m
        nai-otel-collector-collector-b6vpl                       1/1     Running     0          64m
        nai-otel-collector-collector-k52pv                       1/1     Running     0          64m
        nai-otel-collector-collector-qnk9d                       1/1     Running     0          64m
        nai-otel-collector-collector-w4zlf                       1/1     Running     0          64m
        nai-otel-collector-targetallocator-7fcccfc477-ndgkr      1/1     Running     0          64m
        nai-securityscan-manager-77679b5554-94p4z                1/1     Running     0          64m
        nai-ui-7b5b9b88b4-c9wzz                                  1/1     Running     0          64m
        nai-valkey-0                                             1/1     Running     0          67m
        nai-valkey-sentinel-0                                    1/1     Running     0          67m
        ```
## Install SSL Certificate and Gateway Elements

In this section we will install SSL Certificate to access the NAI UI. This is required as the endpoint will only work with a ssl endpoint with a valid certificate.

NAI UI is accessible using the Envoy Ingress Gateway.

??? tip "Optional and manual - using Public Certificate Authority (CA)"
    
    If an organization generates certificates using a different mechanism then obtain the certificate **+ key** and create a kubernetes secret manually using the following command:
    
    1. Create the certificate from the files (generated using certbot or provided to you)
  
        ```bash
        kubectl -n nai-system create secret tls nai-cert \
        --cert=path/to/nai.crt \
        --key=path/to/nai.key
        ```
    
    2. Combine the certificates to get the certificate bundle
       
        ```bash
        cat server.crt intermediate.crt > tls-bundle.crt
        ```
    
    3. Create a kubernetes secret in the nai-system namespace to use during NAI install
  
        ```bash
          kubectl secret tls nai-cert \
          --cert=tls-bundle.crt \
          --key=server.key \
          -n nai-system
        ```
    
    6. Patch the Envoy gateway with the ``nai-cert`` certificate details
       
        ```bash
        kubectl patch gateway nai-ingress-gateway -n nai-system --type='json' -p='[{"op": "replace", "path": "/spec/listeners/1/tls/certificateRefs/0/name", "value": "nai-cert"}]'
        ```

??? tip "Optional to automate - using Public Certificate Authority (CA) and Cert Manager"  

    Using **Cert Manager** to manage the Public Certificate Authority (CA) for NAI SSL Certificate is also a possiblity.

    At a high level (Cloudflare Example):

    1. Get a API key from DNS provider woth Edit Zone rights
    2. Create a Kubernetes ``Secret`` from the API key
       
        === "Cloudflare Example" 
        
            ```yaml hl_lines="8"
            apiVersion: v1
            kind: Secret
            metadata:
              name: cloudflare-api-token-secret
              namespace: harbor
            type: Opaque
            stringData:
              api-token: _YOUR_CLOUDFLARE_API_TOKEN_HERE
            ```
        
        === "AWS Route 53 Example"
        
            ```yaml hl_lines="8 9"
            apiVersion: v1
            kind: Secret
            metadata:
              creationTimestamp: null
              name: route53-api-token-secret
              namespace: cert-manager
            data:
              access-key-id: "_YOUR_AWS_ACCESS_KEY_ID"
              secret-access-key: "_YOUR_AWS_SECRET_KEY_ID"
            ```

    3. Create a ``ClusterIssuer`` with Cert Mangager/Let's Encrypt - Configure cert-manager to use DNS-01 challenge with Cloudflare for automatic certificate issuance.
        
        === "Cloudflare Example"

            ```yaml hl_lines="8"
            apiVersion: cert-manager.io/v1
            kind: ClusterIssuer
            metadata:
              name: letsencrypt-cloudflare
              namespace: cert-manager
            spec:
              acme:
                email: _YOUR_DOMAIN_OWNER_EMAIL_ADDRESS
                server: https://acme-v02.api.letsencrypt.org/directory
                privateKeySecretRef:
                  name: letsencrypt-cloudflare-account-key
                solvers:
                - dns01:
                    cloudflare:
                      apiTokenSecretRef:
                        name: cloudflare-api-token-secret
                        key: api-token
            ```

        === "AWS Route 53 Example"
            
            ```yaml hl_lines="7"
            apiVersion: cert-manager.io/v1
            kind: ClusterIssuer
            metadata:
              name: letsencrypt-cloudflare
            spec:
              acme:
                email: _YOUR_DOMAIN_OWNER_EMAIL_ADDRESS
                server: https://acme-v02.api.letsencrypt.org/directory
                privateKeySecretRef:
                  name: nai-letsencrypt-cluster
                solvers:
                  - dns01:
                      route53:
                        region: us-east-1
                        accessKeyIDSecretRef:
                          name: route53-api-token-secret
                          key: access-key-id
                        secretAccessKeySecretRef:
                          name: route53-api-token-secret
                          key: secret-access-key
                        hostedZoneID: _HOSTED_ZONE_ID
            ```

    4. Create the ingress resource certificate using the following command:
    
        ```bash hl_lines="12 14 16"
        cat << EOF | k apply -f -
        apiVersion: cert-manager.io/v1
        kind: Certificate
        metadata:
          name: nai-cert
          namespace: nai-system
        spec:
          issuerRef:
            name: letsencrypt-cloudflare
            kind: ClusterIssuer
          secretName: nai-cert
          commonName: nai.domain.com
          dnsNames:
          - nai.domain.com
        EOF
        ```
    
    5. Patch the Envoy gateway with the ``nai-cert`` certificate details
       
        ```bash
        kubectl patch gateway nai-ingress-gateway -n nai-system --type='json' -p='[{"op": "replace", "path": "/spec/listeners/1/tls/certificateRefs/0/name", "value": "nai-cert"}]'
        ```

The following steps show how cert-manager can be used to generate a **self signed certificate** using the default **selfsigned-issuer** present in the cluster for the purposes of the lab.

1. Get the NAI UI ingress gateway host using the following command:

    ```bash
    NAI_UI_ENDPOINT=$(kubectl get svc -n envoy-gateway-system -l "gateway.envoyproxy.io/owning-gateway-name=nai-ingress-gateway,gateway.envoyproxy.io/owning-gateway-namespace=nai-system" -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
    ```

2. Get the value of ``NAI_UI_ENDPOINT`` environment variable

    === "Command"
  
        ```bash
        echo $NAI_UI_ENDPOINT
        ```
               
    === "Command output"
      
        ```{ .text .no-copy }
        10.x.x.216
        ```

3. We will use the command output e.g: ``10.x.x.216`` as the IP address for NAI as reserved in this [section](../infra/infra_nkp.md#reserve-control-plane-and-metallb-endpoint-ips)

4. Construct the FQDN of NAI UI using [nip.io](https://nip.io/) and we will use this FQDN as the certificate's Common Name (CN).

    === "Template URL"
    
       ```bash
       nai.${NAI_UI_ENDPOINT}.nip.io
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
      namespace: nai-system
    spec:
      issuerRef:
        name: selfsigned-issuer
        kind: ClusterIssuer
      secretName: nai-cert
      commonName: nai.${NAI_UI_ENDPOINT}.nip.io
      dnsNames:
      - nai.${NAI_UI_ENDPOINT}.nip.io
      ipAddresses:
      - ${NAI_UI_ENDPOINT}
    EOF
    ```

6. Patch the Envoy gateway with the ``nai-cert`` certificate details
   
    ```bash
    kubectl patch gateway nai-ingress-gateway -n nai-system --type='json' -p='[{"op": "replace", "path": "/spec/listeners/1/tls/certificateRefs/0/name", "value": "nai-cert"}]'
    ```

7. Create EnvoyProxy
   
    ```bash
    k apply -f -<<EOF
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyProxy
    metadata:
      name: envoy-service-config
      namespace: nai-system
    spec:
      provider:
        type: Kubernetes
        kubernetes:
          envoyService:
            type: LoadBalancer
    EOF
    ```

8. Patch the ``nai-ingress-gateway`` resource with the new ``EnvoyProxy`` details

    ```bash
    kubectl patch gateway nai-ingress-gateway -n nai-system --type=merge \
    -p '{
        "spec": {
            "infrastructure": {
                "parametersRef": {
                    "group": "gateway.envoyproxy.io",
                    "kind": "EnvoyProxy",
                    "name": "envoy-service-config"
                }
            }
        }
    }'
    ```

## Access NAI UI

NAI UI is accessible using the Envoy Ingress Gateway.


1. Get the NAI UI ingress gateway host using the following command:

    === ":octicons-command-palette-16: Command"

        ```bash
        NAI_UI_ENDPOINT=$(kubectl get svc -n envoy-gateway-system -l "gateway.envoyproxy.io/owning-gateway-name=nai-ingress-gateway,gateway.envoyproxy.io/owning-gateway-namespace=nai-system" -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
        ```

2. Patch the Envoy gateway with the ``nai-cert`` certificate details
   
    === ":octicons-command-palette-16: Command"

        ```bash
        kubectl patch gateway nai-ingress-gateway -n nai-system --type='json' -p='[{"op": "replace", "path": "/spec/listeners/1/tls/certificateRefs/0/name", "value": "nai-cert"}]'
        ```

3. Access NAI UI through a web browser using the NAI UI IP Address

    === ":octicons-command-palette-16: Template URL"
    
        ```bash
        https://$NAI_UI_ENDPOINT
        ```
    
    === ":octicons-command-palette-16: Sample URL"
     
        ``` { .text .no-copy }
        https://10.x.x.216
        ```

## Test NAI

1. Follow instructions [here](../iep/iep_test.md) to test NAI inferencing endpoints with an LLM
2. Follow instruction [here](../uep/index.md) to deploy NAI Unified Endpoints with LLM(s).