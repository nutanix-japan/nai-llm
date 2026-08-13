---

title: Deploying Nutanix Enterprise AI
description: This lab takes your through installing NAI using NKP catalog applications once all pre-requistes as NKP cluster and other infrastructure components are installed and available to access.

---

# Deploying Nutanix Enterprise AI

!!! info "Version 2.7.0"

    This version of the NAI deployment is based on the Nutanix Enterprise AI (NAI) ``v2.7.0`` release.
   
## Prepare for NAI Deployment

!!! example "GA Software with NAI v2.7.0"
    
    In this lab, we will deploy GA version of the following software to test the following:

    -  Nutanix Enterprise AI 
  
        * **Unified Endpoints** - multiple endpoints for HA and token-based rate limiting
        * **Providers** - Add remote endpoints from providers to utilize their models in Nutanix Enterprise AI workloads.

!!! info

    Changes in NAI ``v2.7.0``

    - Kserve is of at least of ``v0.15.0``
    - Cert-manager is at least of ``v1.17.2``
    - OpenTelemetry operator is at least of ``v0.102.0``
    - Envoy Gateway is at least of ``v1.7.0``
    - Prometheus Monitoring is at least of ``78.4.0``
  
## Enable Pre-requisite Applications  

!!! warning
    
    Make sure to license NKP cluster with at least NKP Pro License to make use of the NKP Applications catalog to provision NAI (and other applications)
    
### Prometheus

The following pre-requisite applications will be enabled on NKP GUI:

!!! note

    In this lab, we will be using the **Management Cluster Workspace** to deploy our Nutanix Enterprise AI (NAI)

    However, in a customer environment, it is recommended to use a separate workload NKP cluster.

**Search** and **Enable** the following applications: follow this order to install dependencies for NAI application


1. In the NKP GUI, Go to **Clusters**
2. Click on **Management Cluster Workspace**
3. Go to **Applications** to search and enable the following:
   
     * **Prometheus Monitoring** : version ``78.4.0`` or higher with the following ``Values`` configuration 

4. Wait for ``Deployed`` state in the GUI

??? "Cert Manager" 

    Cert Manager is pre-installed on all NKP Clusters. If not installed, use the following method to install:
    
    1. In the NKP GUI, Go to **Clusters**
    2. Click on **Management Cluster Workspace**
    3. Go to **Applications** to search and enable the following:
    
         * **Cert-manager**- ``v1.17.2``
            
    4. Wait for ``Deployed`` state in the GUI
  
### Envoy Gateway


1. In the NKP GUI, Go to **Clusters**
2. Click on **Management Cluster Workspace**
3. Go to **Applications** to search and enable the following:
   
     * **NAI - Envoy Gateway** : version ``v1.7.0`` or higher with the following ``Values`` configuration 
     
        ```yaml
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
                    image: "nutanix/nai-ratelimit:99d85510"
                  patch:
                    type: "StrategicMerge"
                    value:
                      spec:
                        template:
                          spec:
                            containers:
                              - imagePullPolicy: "IfNotPresent"
                                name: "envoy-ratelimit"
                                image: "nutanix/nai-ratelimit:99d85510"
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
                  url: "redis-sentinel.nai-system.svc.cluster.local:6379"
        ```

6. Check if Envoy Gateway resources are ready either in the GUI by watching for ``Deployed`` state or in the commandline as follows:
    
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
   
     * **Kserve** : version ``v0.15.0`` or higher with the following ``Values`` configuration 
     
        ```yaml
        kserve:
          controller:
            deploymentMode: RawDeployment
            gateway:
              disableIngressCreation: true
        ```

4. Check if Kserve resources are ready either in the GUI by watching for ``Deployed`` state or in the commandline as follows:
    
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubens kserve
        kubectl get pods    
        ```

    === ":octicons-command-palette-16: Output"
    
        ```{ .text .no-copy }
        NAME                                         READY   STATUS    RESTARTS   AGE
        kserve-controller-manager-69b6dbf9cf-ft55b   2/2     Running   0          2m
        ```

### Opentelemetry


1. In the NKP GUI, Go to **Clusters**
2. Click on **Management Cluster Workspace**
3. Go to **Applications** to search and enable the following:
   
     * **Opentelemetry Operator** : version ``v0.102.0`` 

## Deploy NAI

We will use the Docker login credentials we created in the previous section to download the NAI Docker images.

1. Open ``$HOME/.env`` file in ``VSCode``

2. Add (append) the following environment variables and save it
   
    ??? tip "Optional - NAI with Public CA Certificate and Cert Manager"  
 
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
   
     * **Nutanix Enterprise AI** : version ``v2.7.0`` or higher with contents of ```nai-core-values.yaml``` file from previous step.
        

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

        NAME                                                    READY   STATUS      RESTARTS   AGE
        ai-gateway-controller-d6bb9d79b-qrml2                   1/1     Running     0             6m
        chi-nai-clickhouse-server-chcluster1-0-0-0              1/1     Running     0             6m
        chk-nai-clickhouse-keeper-chkeeper-0-0-0                1/1     Running     0             6m
        iam-database-bootstrap-cfwxl-zljjl                      0/1     Completed   0             6m
        iam-proxy-7756b78f4c-nqswf                              1/1     Running     0             6m
        iam-proxy-control-plane-64d65947bf-lgx5x                1/1     Running     0             6m
        iam-themis-b4bffcf6d-ssg5f                              1/1     Running     1 (1m ago)    6m
        iam-themis-bootstrap-6rqfk-xf2lm                        0/1     Completed   0             6m
        iam-ui-c57c768d-fg7b7                                   1/1     Running     0             6m
        iam-user-authn-d9c68c9f7-nm4sf                          1/1     Running     0             6m
        nai-agent-7fd556556f-6t7f9                              1/1     Running     0             6m
        nai-api-77bcff5b4f-hdnp6                                1/1     Running     2 (1m ago)    6m
        nai-api-db-migrate-wiojv-9v2p8                          0/1     Completed   2             6m
        nai-clickhouse-schema-job-1780198147-q9drf              0/1     Completed   0             6m
        nai-db-0                                                1/1     Running     0             6m
        nai-iep-model-controller-56f79987c7-nhj7t               1/1     Running     0             6m
        nai-oauth2-proxy-86c574869c-6vw54                       1/1     Running     0             6m
        nai-operators-nai-clickhouse-operator-f8f666db9-2746s   2/2     Running     0             6m
        nai-otel-collector-collector-29qwn                      1/1     Running     0             6m
        nai-otel-collector-collector-78lcj                      1/1     Running     0             6m
        nai-otel-collector-collector-rp7nt                      1/1     Running     0             6m
        nai-otel-collector-collector-s6j7c                      1/1     Running     0             6m
        nai-otel-collector-collector-tqxj7                      1/1     Running     0             6m
        nai-otel-collector-collector-trbqn                      1/1     Running     0             6m
        nai-otel-collector-collector-xgcmb                      1/1     Running     0             6m
        nai-otel-collector-targetallocator-75799c778-h2wf2      1/1     Running     0             6m
        nai-pulse-job-29671205-4t2kp                            0/1     Completed   0             7m
        nai-securityscan-manager-c6bc5c8b4-v5jfn                1/1     Running     4 (1m ago)    6m
        nai-ui-557f5f6c89-xjlzt                                 1/1     Running     0             6m
        redis-standalone-cf49969d-pzqmt                         2/2     Running     0             6m
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