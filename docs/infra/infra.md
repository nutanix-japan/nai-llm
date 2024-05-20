# Introduction

This section will take you through install NKE(Kubernetes) on Nutanix cluster as we will be deploying AI applications on these kubernetes clusters. 

This section will expand to other available Kubernetes implementations on Nutanix.

# NKE Setup

We will use Infrastucture as Code framework to deploy NKE kubernetes clusters. 

## Pre-requsitis

- NKE is enabled on Nutanix Prism Central
- NKE is at version 1.8 (updated through LCM)
- NKE OS at version 1.5

## Preparing OpenTofu 

On your Linux workstation run the following scripts to install OpenTofu. See [here]for latest instructions and other platform information. 

```bash title="Download the installer script:"
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
```
```bash title="Give it execution permissions:"
chmod +x install-opentofu.sh
```
```bash title="Run the installer:"
./install-opentofu.sh --install-method rpm
```

## NKE High Level Cluster Design

We will create the following resources for a PROD and DEV NKE (kubernetes) cluster to deploy our AI applications:

We will create PROD and DEV clusters to deploy our application. Once DEV deployment is tested successful, we can deploy applications to PROD cluster.

### PROD Cluster
  
| OCP Role   |  No. of Nodes (VM) | Operating System    |    vCPU    |  RAM         | Storage   | IOPS |           
| -------------| ----| ---------------------- |  -------- | ----------- |  --------- |  -------- | 
| Master    | 3 | NKE 1.5                 |  4       |  16 GB       | 100 GB    | 300 | 
| ETCD       | 3 | NKE 1.5                 |  4        | 16 GB      |  100 GB   |  300 | 
| Worker       | 3| NKE 1.5               |  8  |  16 GB      |  100 GB |    300 | 

### DEV Cluster
  
| OCP Role   |  No. of Nodes (VM) | Operating System    |    vCPU    |  RAM         | Storage   | IOPS |           
| -------------| ----| ---------------------- |  -------- | ----------- |  --------- |  -------- | 
| Master    | 3 | NKE 1.5                 |  4       |  16 GB       | 100 GB    | 300 | 
| ETCD       | 3 | NKE 1.5                 |  4        | 16 GB      |  100 GB   |  300 | 
| Worker       | 3| NKE 1.5               |  8  |  16 GB      |  100 GB |    300 | 


## Getting TOFU Setup to connect to Prism Central

1. Create the variables definitions file

    ```bash
    cat << EOF > variables.tf
    variable "cluster_name" {
    type = string
    }

    variable "subnet_name" {
    type = string
    }

    variable "port" {
    type = number
    default = 9440
    }

    variable "user" {
    description = "nutanix cluster username"
    type      = string
    sensitive = true
    }

    variable "password" {
    description = "nutanix cluster password"
    type      = string
    sensitive = true

    }
    variable "endpoint" {
    type = string
    }
    ```

2. Create the variables file and modify the values to suit your Nutanix environment
   
    ```bash
    vi terraform.tfvars
    ```
    
    === "Template file"

        ```bash
        cluster_name        = "your cluster name" # << Change this
        subnet_name         = "your AHV network's name"  # << Change this
        user                = "admin"             # << Change this
        password            = "XXXXXXX"           # << Change this
        endpoint            = "Prism Element IP"  # << Change this
        vm_domain           = "yourdomain.com"    # << Change xyz to your initials
        vm_master_count     = 3
        vm_worker_count     = 2
        ```

    === "Example file with values"

        ```bash
        cluster_name        = "my-pe-cluster"          
        subnet_name         = "primary"       
        user                = "admin"            
        password            = "mypepassword"           
        endpoint            = "10.55.64.100"     
        vm_domain           = "ntnxlab.local"
        vm_master_count     = 3
        vm_worker_count     = 2
        ```
    
3. Create ``main.tf`` file to initialize nutanix provider
   
    ```bash
    cat << EOF > main.tf
    terraform {
    required_providers {
        nutanix = {
        source  = "nutanix/nutanix"
        version = "1.9.1"
        }
    }
    }

    data "nutanix_cluster" "cluster" {
    name = var.cluster_name
    }

    data "nutanix_subnet" "subnet" {
    subnet_name = var.subnet_name
    }

    provider "nutanix" {
    username     = var.user
    password     = var.password
    endpoint     = var.endpoint
    port         = var.port
    insecure     = true
    wait_timeout = 60
    }
    EOF
    ```

## Deploying DEV Cluster

1. Create the following tofu resource file for Dev NKE cluster

    ```json
    cat << EOF > nke-dev.tf
    resource "nutanix_karbon_cluster" "example_cluster" {
    name       = "example_cluster"
    version    = "1.25.6-0"
    storage_class_config {
        reclaim_policy = "Delete"
        volumes_config {
        file_system                = "ext4"
        flash_mode                 = false
        password                   = var.password
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        storage_container          = "default"
        username                   = var.user
        }
    }
    cni_config {
        node_cidr_mask_size = 24
        pod_ipv4_cidr       = "172.20.0.0/16"
        service_ipv4_cidr   = "172.19.0.0/16"
    }
    worker_node_pool {
        node_os_version = "ntnx-1.5.1"
        num_instances   = 3
        ahv_config {
        network_uuid               = data.nutanix_subnet.subnet.id
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        }
    }
    etcd_node_pool {
        node_os_version = "ntnx-1.5.1"
        num_instances   = 3
        ahv_config {
        network_uuid               = data.nutanix_subnet.subnet.id
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        }
    }
    master_node_pool {
        node_os_version = "ntnx-1.5.1"
        num_instances   = 3
        ahv_config {
        network_uuid               = data.nutanix_subnet.subnet.id
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        }
    }
    timeouts {
        create = "1h"
        update = "30m"
        delete = "10m"
        }
    }
    EOF
    ```

2. Validate your tofu code

    ```bash
    tofu validate
    ```

3.  Apply your tofu code to create NKE cluster, associated virtual machines and other resources
  
    ```bash
    tofu apply 

    # Terraform will show you all resources that it will to create
    # Type yes to confirm 
    ```

4.  Run the Terraform state list command to verify what resources have been created

    ``` bash
    tofu state list
    ```

    ``` { .bash .no-copy }
    # Sample output for the above command

    data.nutanix_cluster.cluster            # < This is your existing Prism Element cluster
    data.nutanix_subnet.subnet              # < This is your existing primary subnet
    ```

## Deploying PROD cluster

1. Create the following tofu resource file for Dev NKE cluster

    ```json
    cat << EOF > nke-prod.tf
    resource "nutanix_karbon_cluster" "example_cluster" {
    name       = "example_cluster"
    version    = "1.25.6-0"
    storage_class_config {
        reclaim_policy = "Delete"
        volumes_config {
        file_system                = "ext4"
        flash_mode                 = false
        password                   = var.password
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        storage_container          = "default"
        username                   = var.user
        }
    }
    cni_config {
        node_cidr_mask_size = 24
        pod_ipv4_cidr       = "172.20.0.0/16"
        service_ipv4_cidr   = "172.19.0.0/16"
    }
    worker_node_pool {
        node_os_version = "ntnx-1.5.1"
        num_instances   = 3
        ahv_config {
        network_uuid               = data.nutanix_subnet.subnet.id
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        }
    }
    etcd_node_pool {
        node_os_version = "ntnx-1.5.1"
        num_instances   = 3
        ahv_config {
        network_uuid               = data.nutanix_subnet.subnet.id
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        }
    }
    master_node_pool {
        node_os_version = "ntnx-1.5.1"
        num_instances   = 3
        ahv_config {
        network_uuid               = data.nutanix_subnet.subnet.id
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        }
    }
    timeouts {
        create = "1h"
        update = "30m"
        delete = "10m"
        }
    }
    EOF
    ```

2. Validate your tofu code

    ```bash
    tofu validate
    ```

3.  Apply your tofu code to create NKE cluster, associated virtual machines and other resources
  
    ```bash
    tofu apply 

    # Terraform will show you all resources that it will to create
    # Type yes to confirm 
    ```

4.  Run the Terraform state list command to verify what resources have been created

    ``` bash
    tofu state list
    ```

    ``` { .bash .no-copy }
    # Sample output for the above command

    data.nutanix_cluster.cluster            # < This is your existing Prism Element cluster
    data.nutanix_subnet.subnet              # < This is your existing primary subnet

    ```



