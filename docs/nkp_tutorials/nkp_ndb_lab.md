---
title: "Kubernetes and Nutanix NDB Integration"
lastupdate: git
lastupdateauthor: "Lakshmi Balaramane"
---

# Kubernetes and Nutanix NDB Integration

This lab sets up a custom microservices-based application with a VM-based Nutanix Database Service ([NDB](https://www.nutanix.com/products/database-service)). It demonstrates integrating NDB-provisioned databases with a vanilla Kubernetes cluster, replacing OpenShift-specific features like Routes with Ingress and Security Context Constraints (SCCs) with Kubernetes security contexts.

NDB provides Database-as-a-Service for Microsoft SQL Server, Oracle, PostgreSQL, MongoDB, and MySQL, enabling efficient management of databases in hybrid multicloud environments. Customers often use VM-based databases due to existing expertise, ease of deployment, and robust high availability, disaster recovery, and security practices.

!!! info "Lab Duration"
    Estimated time to complete this lab is **60 minutes**.


??? info "Fun Fact"
    The NDB Operator was developed by Nutanix Japan's Solution Engineers (SE) team during a 2022 Hackathon, addressing customer needs for Kubernetes integration. The team won the Hackathon, and the NDB Operator is now available for customers, showcasing Nutanix's commitment to customer value.


## Prerequisites
- NDB ``v2.5`` or later deployed on a Nutanix cluster 
- Nutanix Kubernetes Platform NKP cluster ``v1.15`` or later deployed, accessible via `kubectl`. See [NKP Deployment](../infra/infra_nkp.md) for NKP install instructions.
- Nutanix CSI driver installed for storage integration.
- Networking configured to allow communication between the Kubernetes cluster and NDB.
- NGINX Ingress controller installed for external access.
- Linux Tools VM or equivalent environment with `kubectl`, `helm`, `curl`, and `jq` installed.
- NDB server credentials and SSH key pair for database provisioning.

!!! note
    Currently, only **Postgres** databases are supported by the NDB Operator. Support for other databases (MSSQL, MySQL, Oracle, etc.) will be added incrementally. Check Nutanix release announcements for updates. Nutanix provides 24/7/365 support for Postgres with Postgres Professional. See the [solution brief](https://www.nutanix.com/content/dam/nutanix/partners/technology-alliances/solution-briefs/sb-postges-professional-and-nutanix.pdf) for more details.


## High-Level Overview
1. Install the NDB Operator on the Kubernetes cluster.
2. Deploy a Postgres database using NDB.
3. Install a custom three-layer application (React frontend, Django backend, Postgres database).
4. Connect the application to the NDB-provisioned database.
5. Create database schema and populate data.
6. Test the application and verify data in the database.

## Install NDB Operator on Kubernetes

### Prepare the Linux Tools VM
1. Log in to your Linux Tools VM (e.g., via SSH as `ubuntu`).
2. Create a working directory: 
   ```bash
   mkdir -p $HOME/k8suserXX/ndb
   cd $HOME/k8suserXX/ndb
   ```
3. Configure `kubectl` to access your NKP Kubernetes cluster:
   
    === "Command"
 
         ```bash
         export KUBECONFIG=$HOME/_nkp_install_dir/nkpclustername.conf
         kubectl cluster-info
         kubectl get nodes
         ```

    === "Sample command"
        
        ```{ .text .no-copy }
        export KUBECONFIG=$HOME/nkp/nkpdev.conf
        kubectl cluster-info
        kubectl get nodes
        ```

4. Install the latest [Cert-Manager](https://cert-manager.io/docs/installation/) as a prerequisite:
    
    ```bash
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.0/cert-manager.yaml
    ```

5. Verify Cert-Manager is running:
 
    ```bash
    kubectl get pods -n cert-manager
    ```

### Install the NDB Operator
1. Add Nutanix’s Helm repository:
   ```bash
   helm repo add nutanix https://nutanix.github.io/helm/
   ```
2. Install the NDB Operator
   
    === "Command"
 
         ```bash
          helm install ndb-operator nutanix/ndb-operator --version 0.5.3 -n ndb-operator --create-namespace
          ```
 
    === "Output"
       
          ```{ .text .no-copy }
          NAME: ndb-operator
          LAST DEPLOYED: [Timestamp]
          NAMESPACE: ndb-operator
          STATUS: deployed
          REVISION: 1
          TEST SUITE: None
          ```
   
3. Verify the NDB Operator is running:
   
    === "Command"
 
          ```bash
          kubectl get all -n ndb-operator
          ```
 
    === "Output"
       
          ```{ .text .no-copy }
          NAME                                                   READY   STATUS    RESTARTS   AGE
          pod/ndb-operator-controller-manager-77fcb496d5-7qcfc   2/2     Running   0          2m16s
          ```

4. Optionally, view operator logs:
   
    ```bash
    kubectl logs -f deployment/ndb-operator-controller-manager -n ndb-operator
    ```

## Create NDB Postgres Database

### High-Level Steps
1. The NDB Operator sends a database creation request to the NDB server.
2. The NDB server provisions a Postgres database VM and database.
3. The NDB server returns the operation result to the NDB Operator.

### Prepare Secrets

1. Create a Kubernetes namespace:
   ```bash
   kubectl create namespace ndb
   ```

2. Create a Secret for NDB server credentials:
    
    ```bash
    cat << EOF > your-ndb-secret.yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: your-ndb-secret
      namespace: ndb
    type: Opaque
    stringData:
      username: admin
      password: _ndb_admin_password
    EOF
    ```

3. Edit `your-ndb-secret.yaml` with your NDB server credentials and apply:
   
    ```bash
    vi your-ndb-secret.yaml
    kubectl apply -f your-ndb-secret.yaml
    ```

4. Create a Secret for the Postgres VM credentials, including an SSH public key:
    
    ??? Tip "Create SSH Key Pair Commands"

          ```bash
          ssh-keygen -t rsa -b 2048 -f ~/.ssh/for_ndb
          ```

5. Copy the public key from `~/.ssh/for_ndb.pub` into `your-secret.yaml`.
   
    ```bash
    vi your-db-secret.yaml
    kubectl apply -f your-db-secret.yaml
    ```

    ```bash
    cat << EOF > your-db-secret.yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: your-db-secret
      namespace: ndb
    type: Opaque
    stringData:
      password: postgres_password
      ssh_public_key: ssh-rsa AAAAB3NzaC1yc2E... # << Paste contents of `~/.ssh/for_ndb.pub` 
    EOF
    ```

### Get NDB Cluster UUID
1. Set the NDB server IP:
   ```bash
   NDB_IP=your_ndb_vm_ip
   echo $NDB_IP
   ```
   Example:
   ```bash
   NDB_IP=10.42.12.18
   ```
2. Retrieve the NDB cluster UUID:
   ```bash
   NDB_UUID="$(curl -X GET -u admin -k https://$NDB_IP/era/v0.9/clusters | jq '.[0].id')"
   echo $NDB_UUID
   ```
   Example output:
   ```text
   "eafdb83c-e512-46ce-8d7d-6859dc170272"
   ```
   Note the UUID for the next step.

### Create NDB Compute Profile
1. In the NDB UI, navigate to **Profiles > Compute Profile**.
2. Create a new compute profile:
   - **Name**: DEFAULT_OOB_SMALL_COMPUTE
   - **CPUs**: 4
   - **Cores per CPU**: 2
   - **Memory**: 8GB

### Create Postgres Database
1. Create an `NDBServer` resource:
   ```bash
   cat << EOF > ndbserver.yaml
   apiVersion: ndb.nutanix.com/v1alpha1
   kind: NDBServer
   metadata:
     name: ndb
     namespace: ndb
   spec:
     credentialSecret: your-ndb-secret
     server: https://$NDB_IP:8443/era/v0.9
     skipCertificateVerification: true
   EOF
   ```
2. Apply the resource:
   ```bash
   kubectl apply -f ndbserver.yaml
   ```
3. Set a database server name:
   ```bash
   MY_DB_SERVER_NAME=k8suserXX
   echo $MY_DB_SERVER_NAME
   ```
4. Create a `Database` resource:
   ```bash
   cat << EOF > database.yaml
   apiVersion: ndb.nutanix.com/v1alpha1
   kind: Database
   metadata:
     name: dbforflower
     namespace: ndb
   spec:
     ndbRef: ndb
     isClone: false
     databaseInstance:
       clusterId: $NDB_UUID
       name: "$MY_DB_SERVER_NAME"
       databaseNames:
         - predictiondb
       credentialSecret: your-db-secret
       size: 10
       timezone: "UTC"
       type: postgres
   EOF
   ```
5. Apply the resource:
   ```bash
   kubectl apply -f database.yaml
   ```
6. Monitor the database provisioning:
   ```bash
   kubectl get database -n ndb
   ```
   Example output:
   ```text
   NAME          IP ADDRESS   STATUS     TYPE
   dbforflower                CREATING   postgres
   ```
7. Check logs for progress:
   ```bash
   kubectl logs -f deployment/ndb-operator-controller-manager -n ndb-operator
   ```
8. Optionally, monitor progress in the NDB UI under **Operations**. Provisioning takes about ~20 minutes.

### Check Database Connectivity
1. Verify the database status:
   ```bash
   kubectl get database -n ndb
   ```
   Example output:
   ```text
   NAME          IP ADDRESS    STATUS   TYPE
   dbforflower   10.38.13.45   READY    postgres
   ```
2. Check the Service and Endpoint:
   ```bash
   kubectl get service,ep -n ndb
   ```
   Example output:
   ```text
   NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
   service/dbforflower-svc   ClusterIP   172.30.188.239   <none>        80/TCP    73s
   endpoints/dbforflower-svc   10.38.13.45:5432   73s
   ```
3. Deploy a test Postgres pod:
   ```bash
   cat << EOF | kubectl apply -f -
   apiVersion: v1
   kind: Pod
   metadata:
     name: psql
     namespace: ndb
   spec:
     restartPolicy: Never
     containers:
     - name: psql
       image: postgres:15
       command: ["/bin/sh", "-c", "echo 'Pod is running' && sleep 7200"]
       env:
       - name: POSTGRES_PASSWORD
         value: postgres_password
       securityContext:
         runAsUser: 1000
         runAsGroup: 1000
         fsGroup: 1000
   EOF
   ```
4. Connect to the database:
   ```bash
   kubectl exec -it psql -n ndb -- psql -h dbforflower-svc -p 80 -U postgres -d predictiondb
   ```
   Enter `postgres_password` when prompted. Run:
   ```sql
   \du
   ```
   Example output:
   ```text
   List of roles
   Role name | Attributes | Member of
   ----------+------------+-----------
   postgres  | Superuser  | {}
   ...
   ```