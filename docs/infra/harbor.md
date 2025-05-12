# Install Harbor

In this section, we will install Harbor container registry in the cluster.

## Prerequisites

We will use the jumphost to install and host Harbor container registry.

Since the jumphost also will host the ``kind`` cluster, we will need to ensure that the jumphost has enough resources.

| #    | CPU | Memory | Disk | Purpose | 
|-----| --- | ------ | ---- |----------|
|Before | 4  | 16 GB   | 300 GB |  ``Jumphost`` + ``Tools``|
|After |  8  | 16 GB   | 300 GB | ``Jumphost`` + ``Tools`` + ``Harbor`` + ``kind`` |

!!! note 
    If the jumphost does not have the resources, make sure to stop the jumphost and add the resources in Prism Central.

## Install Harbor

We will use the following commands to install Harbor on the jumphost.

### Download Harbor

1. Open new VSCode window on your jumphost

2. In `VSCode` Explorer pane, Click on **New Folder** :material-folder-plus-outline: and name it: ``harbor``
   
3. In `VSCode` Terminal pane, run the following commands to download Harbor.
   
    ```bash
    cd $HOME/harbor
    export HARBOR_VERSION=v2.9.4
    curl -sSOL https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/harbor-offline-installer-${HARBOR_VERSION}.tgz
    tar -xzvf harbor-offline-installer-${HARBOR_VERSION}.tgz
    ```

### Setup SSL Certificates for Harbor

4. Setup up folders to hold certificates for Harbor
   
    ```bash
    cd $HOME/harbor
    mkdir certs && cd certs 
    HARBOR_HOST=$(hostname -I | awk '{print $1}')
    HARBOR_HOST_EXTERNAL=$HARBOR_HOST
    ```
    Confirm the environment variables values.

    === "Command"
        
        ```bash
        echo ${HARBOR_HOST}  
        echo ${HARBOR_HOST_EXTERNAL}
        ```

    === "Command output"
       
        ```bash
        10.x.x.111
        10.x.x.111
        ```


5. Create a root CA certificate and key
   
    ```bash
    openssl genrsa -out ca.key 4096
    openssl req -x509 -new -nodes -key ca.key -sha256 -days 1024 -out ca.crt -subj "/CN=harborroot"
    ```

6. Install the CA certificate on the jumphost VM trusted root CA store

    ```bash
    sudo cp ca.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates
    ```

6. Create private key for Harbor

    ```bash
    openssl genrsa -out harbor.key 2048
    ```

7. Create CSR for Harbor

    ```bash
    openssl req -new -key harbor.key -subj /CN=${HARBOR_HOST} -out harbor.csr
    ```

8. Add all possible FQDNs and IPs to the certificate's subjectAltName (SAN) field and generate the certificate for Harbor
   
    ```bash
    openssl x509 -req -extfile <(printf "subjectAltName=IP:${HARBOR_HOST_EXTERNAL},IP:`hostname -I | awk '{print $1}'`,DNS:harbor.${HARBOR_HOST}.nip.io,DNS:${HARBOR_HOST}.nip.io") -days 1024 -in harbor.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out harbor.crt
    ```

9. Convert the cert from PEM to DER for Docker
    
    ```bash
    cd ..
    cp certs/harbor.crt certs/harbor.crt_convert # To preserve the PEM format
    openssl x509 -inform PEM -in certs/harbor.crt_convert  -out certs/harbor.cert
    ```

10. Set Harbor certificate in local Docker instance
    
     ```bash
     sudo mkdir -p /etc/docker/certs.d/${HARBOR_HOST}
     ```

11. Copy to ca.crt,harbor.cert and harbor.key to Docker certs directory 

     ```
     sudo cp certs/ca.crt /etc/docker/certs.d/${HARBOR_HOST}/.

     sudo cp certs/harbor.cert /etc/docker/certs.d/${HARBOR_HOST}/.

     sudo cp certs/harbor.key /etc/docker/certs.d/${HARBOR_HOST}/.

     sudo systemctl restart docker
     ```

### Add Harbor's CA Certificate to the Trusted CA Store of NKP Nodes

!!! warning

    The local CA certificate that is certifying Harbor's certificate will need to be added to all the NKP air-gapped cluster nodes.

    Kubernetes nodes will only trust the CA certificates present on the nodes apart from the public CA certificates (Let's Encrypt, Digicert, etc.).

Follow the steps in this [Deploying Private CA Certificate to NKP Cluster section](../appendix/nkp_cert_ds.md) to add the Harbor container registry's CA certificate ``ca.crt`` that you created in the above section to the NKP air-gapped cluster nodes.

!!! warning "Best Practice for Self-signed Certificates"
    
    The best practice is to deploy the NKP air-gapped cluster with a Self-signed Certificates (private) CA certificate at Day 0 using the ``nkp create cluster nutanix --additional-trust-bundle`` among other options.

    For Day 1 and 2 operations, the private CA certificate will need to be added to all the NKP air-gapped cluster nodes.


### Configure Harbor Installation Manifest

1. In VSCode Terminal, run the following command to setup and create the manifest file:
 
    ```bash
    export OS_USER=ubuntu # Set OS User
    export CERTS_DIR=/home/${OS_USER}/harbor/certs
    export HOST=${HARBOR_HOST}
    ```

2. In VSCode Explorer, create the manifest file
   
    ```text
    harbor.yml
    ```
   with the following content: (focus on the hightlighted lines)
   
    === "Template file"

        ```yaml hl_lines="1 10 11 13"
        hostname: ${HOST}
        http:
          port: 80
        https:
          port: 443
          certificate: ${CERTS_DIR}/harbor.crt
          private_key: ${CERTS_DIR}/harbor.key
        # Uncomment external_url if you want to enable external proxy
        # And when it enabled the hostname will no longer used
        external_url: https://${HOST}/
        harbor_admin_password: _your_harbor_password
        database:
          password: _your_harbor_db_password
          max_idle_conns: 100
          max_open_conns: 900
          conn_max_idle_time: 0
        data_volume: /data
        trivy:
          ignore_unfixed: false
          skip_update: false
        jobservice:
          max_job_workers: 10
          logger_sweeper_duration: 1 #days 
          job_loggers:
            - STD_OUTPUT
            - FILE
            # - DB
        notification:
          webhook_job_max_retry: 3
          webhook_job_http_client_timeout: 3 #seconds
        chart:
          absolute_url: disabled
        log:
          level: info
          local:
            rotate_count: 50
            rotate_size: 200M
            location: /var/log/harbor
        proxy:
          http_proxy:
          https_proxy:
        # no_proxy endpoints will appended to 127.0.0.1,localhost,.local,.internal,log,db,redis,nginx,core,portal,postgresql,jobservice,registry,registryctl,clair,chartmuseum,notary-server
          no_proxy:
          components:
            - core
            - jobservice
            - trivy
        _version: ${HARBOR_VERSION}
        ```

    === " Sample file"

        ```yaml hl_lines="1 10 11 13"
        hostname: 10.x.x.111
        http:
          port: 80
        https:
          port: 443
          certificate: /home/ubuntu/harbor/certs/harbor.crt
          private_key: /home/ubuntu/harbor/certs/harbor.key
        # Uncomment external_url if you want to enable external proxy
        # And when it enabled the hostname will no longer used
        external_url: https://harbor.10.x.x.111.nip.io/
        harbor_admin_password: xxxxxxx
        database:
          password: xxxxxxx
          max_idle_conns: 100
          max_open_conns: 900
          conn_max_idle_time: 0
        data_volume: /data
        trivy:
          ignore_unfixed: false
          skip_update: false
        jobservice:
          max_job_workers: 10
          logger_sweeper_duration: 1 #days 
          job_loggers:
            - STD_OUTPUT
            - FILE
            # - DB
        notification:
          webhook_job_max_retry: 3
          webhook_job_http_client_timeout: 3 #seconds
        chart:
          absolute_url: disabled
        log:
          level: info
          local:
            rotate_count: 50
            rotate_size: 200M
            location: /var/log/harbor
        proxy:
          http_proxy:
          https_proxy:
        # no_proxy endpoints will appended to 127.0.0.1,localhost,.local,.internal,log,db,redis,nginx,core,portal,postgresql,jobservice,registry,registryctl,clair,chartmuseum,notary-server
          no_proxy:
          components:
            - core
            - jobservice
            - trivy
        _version: v2.9.4
        ```    

### Install and Verify

1. Run the installation
   
    ```bash
    sudo ./install.sh --with-trivy
    ```

2. Verify the installation
   
    ===  "Command"

        ```bash     
        sudo docker-compose ps
        ```
    === "Command output"

        ```{ .text .no-copy }
        $ sudo docker-compose ps 

        Name                     Command                  State                                          Ports                                    
        ------------------------------------------------------------------------------------------------------------------------------------------------
        harbor-core         /harbor/entrypoint.sh            Up (healthy)                                                                               
        harbor-db           /docker-entrypoint.sh 13 14      Up (healthy)                                                                               
        harbor-jobservice   /harbor/entrypoint.sh            Up (healthy)                                                                               
        harbor-log          /bin/sh -c /usr/local/bin/ ...   Up (healthy)   127.0.0.1:1514->10514/tcp                                                   
        harbor-portal       nginx -g daemon off;             Up (healthy)                                                                               
        nginx               nginx -g daemon off;             Up (healthy)   0.0.0.0:80->8080/tcp,:::80->8080/tcp, 0.0.0.0:443->8443/tcp,:::443->8443/tcp
        redis               redis-server /etc/redis.conf     Up (healthy)                                                                               
        registry            /home/harbor/entrypoint.sh       Up (healthy)                                                                               
        registryctl         /home/harbor/start.sh            Up (healthy)                                                                               
        trivy-adapter       /home/scanner/entrypoint.sh      Up (healthy)                    
        ```

3. Login to Harbor Web UI using the following credentials
   
    - Username: ``admin``
    - Password: ``xxxxxxx`` (password you set in the manifest file)
     

6. Go to Projects and create a new project ``nkp``
   
Harbor registry and ``nkp`` projects will be used to store the container images for NKP air-gapped deployments.

