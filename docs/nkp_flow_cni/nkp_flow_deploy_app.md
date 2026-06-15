---
title: "Deploy and Test App with Flow CNI"
description: 
---

In this section of the lab we will do the following:

1. Deploy a Postgres DB on a VM and configure
2. Deploy a front end network tester app on ``nkpflow`` cluster which we deployed in the previous section
3. Run a few performance and network tests from the front end app's UI
4. Implement a network policy and check how the communication between VM and front end app can be restricted

!!! warning
    
    These are tests just to show case Flow CNI's capability in a **test** environment. 

    For production environments, use Nutanix database, Flow CNI, and HCI [Nutanix Validated Design (NVD)](https://www.nutanix.com/blog/nutanix-validated-designs-blueprints-for-success) directions.

## Deploy Postgres DB VM

1. In Prism Central go to Compute > VM
2. Create a Postgres VM with the following attributes
   
    -  **Name**: ``pg-test-vm`` 
    -  **VM Properties**: 
        -  **CPUs** - `6` vCPU
        -  **Cores per CPU** - `1`
        -  **Memory** - `8` GB
    -  **Attach Disk**:
        -  **Operation** - clone from image
        -  **Image** - ``Ubuntu-24.04-server-cloudimg-amd64.img``
        -  **Click** on **Save**
    -  **Attach to Subnet**
        -  **Subnet**: ``lb-vm-subnet`` (VPC Internal only subnet created in the previous section)
        -  **Assignment Type**: Assign with DHCP
        -  Click on **Save**
    - **Guest Customization**:
       - Script Type: Cloud-init (Linux)
       - Use the following sample cloud-init
 
         ```yaml hl_lines="2 24"
         #cloud-config
         hostname: pg-test-vm                   # << Change to your pg vm >>
         package_update: true
         package_upgrade: true
         package_reboot_if_required: true
         packages:
           - open-iscsi
           - nfs-common
           - git
           - jq
           - bind-utils
           - nmap
           - docker.io
         users:
           - default
           - name: ubuntu
             groups: sudo
             shell: /bin/bash
             sudo:
               - 'ALL=(ALL) NOPASSWD:ALL'
             lock_passwd: false
             shell: /bin/bash
             ssh-authorized-keys: 
             - ssh-rsa AAAAB3xxxxxxxxxxx     # << Change to your ssh public key >>
         runcmd:
           - systemctl stop ufw && systemctl disable ufw
           - eject
           - reboot
         ```

3. Obtain an Floating IP for the VM in **Prism Central** > **Network & Security** and **Floating IPs**

4. Click on Request Floating IP
   
    - **External subnet:** - ``lb-external``
    - **Number of Floating IPs:** - ``1``
    - Select **Assign Floating IPs** 
    - Choose the ``pg-test-vm`` VM
    - Click on **Save**
  
5. Login to the VM using SSH (get IP address from Prism Central)
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        ssh -l ubuntu _IP_ADDRESS_OF_PG_VM
        ```
    
    === ":octicons-command-palette-16: Command"
    
        ```bash
        ssh -l ubuntu 10.24.155.106
        ```

   
6. Configure Postgres
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        sudo apt update
        sudo apt install -y postgresql postgresql-contrib iperf3
        ```

7. Edit the main config file to listen on all interfaces.
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        sudo vi /etc/postgresql/16/main/postgresql.conf
        ```


6. Find `#listen_addresses = 'localhost'` and change it to:
   
    === ":octicons-command-palette-16: Command"
 
        ```text
        listen_addresses = '*'
        ```


7. **Whitelist the NKP Pod Network:**
    Edit the client authentication file.

    === ":octicons-command-palette-16: Command"
 
        ```bash
        sudo nano /etc/postgresql/16/main/pg_hba.conf
        ```
    
    
    Add your cluster's Pod CIDR (e.g., `10.24.0.0/16`) to the bottom of the file:

    === ":octicons-command-palette-16: Command"
 
        ```text
        host    all             all             10.24.0.0/16            md5
        # Optional pod and service networks
        # host    all             all             192.168.0.0/16          md5
        # host    all             all             192.168.0.0/24          md5
        # host    all             all             10.96.0.0/12            md5
        ```


8. **Restart PostgreSQL:**
   
    === ":octicons-command-palette-16: Command"
  
        ```bash
        sudo systemctl restart postgresql
        ```


9. Run these commands sequentially to set up the `pgbench` environment: **Create the Database, User, and Permissions:**

    === ":octicons-command-palette-16: Command"

        ```bash
        sudo -u postgres psql -c "CREATE DATABASE pgbench_test;"
        sudo -u postgres psql -c "CREATE USER tester WITH PASSWORD 'testpassword';"
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE pgbench_test TO tester;"
        
        # Crucial: Grant schema permissions inside the test database for PG 15+
        sudo -u postgres psql -d pgbench_test -c "GRANT ALL ON SCHEMA public TO tester;"
        ```

---

## Deploy the Frontend App to NKP

Now we will deploy the testing UI to your Kubernetes cluster.

1. From the jumphost VM set kubernetes context to ``nkpflow`` NKP cluster (created in the previous sections)
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        export KUBECONFIG=nkpflow.conf
        ```

     
2.  Apply the ``ConfigMap``:
    
    === ":octicons-command-palette-16: Command"

        ```bash
        kubectl apply -f https://raw.githubusercontent.com/nutanix-japan/nai-llm/refs/heads/main/docs/nkp_flow_cni/cm.yaml
        ```


3. Apply the Deployment and Service:
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl apply -f kubectl apply -f https://raw.githubusercontent.com/nutanix-japan/nai-llm/refs/heads/main/docs/nkp_flow_cni/app.yaml
        ```

---

## Access and Run Tests

1. **Port Forward to the UI:** Once the pod is fully running (`kubectl get pods`), forward your local port to the service:

    === ":octicons-command-palette-16: Command"
     
         ```bash
         kubectl port-forward svc/network-tester-svc 8080:80
         ```


2. **Execute the Testing Sequence:**
   
   * Open your web browser and go to `http://localhost:8080`.
   * Ensure your **VM IP** is correct in the input box.
   * Click **1. Run iperf3 Test** to establish your raw network baseline.
   * Click **2. Init DB Data** to build the database tables and insert dummy data (this only needs to be run once).

4. Get the name of front end pod
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl get pods
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```bash hl_lines="5"
        $ kubectl get pods
        #
        NAME                             READY   STATUS    RESTARTS   AGE
        flow-ovn-ic-86bc48984c-lxx8s     1/1     Running   0          46h
        network-tester-9c4dd5754-5b5xb   1/1     Running   0          20m
        nginx-pod                        1/1     Running   0          6d2h
        ```
    
5. Set environment variables for VM IP and pod name
   
    === ":octicons-file-code-16: Template ``.env``"
    
        ```bash
        export VM_IP=x.x.x.x
        export POD_NAME=_POD_NAME
        ```
    
    === ":octicons-file-code-16: Sample ``.env``"
    
        ```bash
        export VM_IP=10.24.155.106
        export POD_NAME=network-tester-9c4dd5754-5b5xb
        ```
    
6. Run a DB load test from the pod. The test will run for approximately ``2 minutes``
   
    === ":octicons-command-palette-16: Command"
      
          ```bash
          kubectl exec -it ${POD_NAME} -- curl -N "http://localhost:8080/test/db-run?ip=${VM_IP}&clients=5&threads=2&time=30"
          ```
    
    === ":octicons-command-palette-16: Sample command"
      
          ```bash
          kubectl exec -it network-tester-9c4dd5754-5b5xb -- curl -N "http://localhost:8080/test/db-run?ip=10.24.155.106&clients=5&threads=2&time=30"
          ```
    
    === ":octicons-command-palette-16: Command output"
      
          ```bash
          data: scaling factor: 50

          data: query mode: simple
          
          data: number of clients: 5
          
          data: number of threads: 2
          
          data: maximum number of tries: 1
          
          data: duration: 30 s
          
          data: number of transactions actually processed: 27635
          
          data: number of failed transactions: 0 (0.000%)
          
          data: latency average = 5.763 ms
          
          data: latency stddev = 108.880 ms
          
          data: initial connection time = 48.826 ms
          
          data: tps = 851.217054 (without initial connection time)
          
          data: Exit code: 0
          
          data: [DONE]
          ```

10. Login to the Prism Central UI 
11. Go to **Compute** > **VMs** > Click the ``pg-test-vm`` VM
12. Go to **Metrics** and observe storage and network related graphs
    
     ![](images/storage-metrics.png)

13. Go to **Network** > **Virtual Private Clouds**
14. Choose ``vpc-lb-flow`` and go to **Metrics**
15. Check the **Ingress and Egress** metrics
    ![](images/network-metrics.png)

You now have a fully functional, repeatable testing harness to measure Nutanix Flow performance between your Kubernetes pods and your external infrastructure.