# Creating Ubuntu Linux jump host VM on Nutanix AHV

Below is walkthrough for manually creating a Linux VM on Nutanix AHV to support the various deployment scenarios.

## Prerequisites

- Existing Nutanix AHV Subnet configured with IPAM
- Existing Linux OS machine image (i.e., `Ubuntu 22.04 LTS` ) with cloud-init service enabled. If not existing, See [Upload Generic Cloud Image into Prism Central](#upload-generic-cloud-image-into-prism-central) example.
- SSH Private Key for inital `cloud-init` bootstrapping. If not existing:
  - On MacOS/Linux machine, See [Generate a SSH Key on Linux](#generate-a-ssh-key-on-linux) example.
  - On Windows machine, See [Generate a SSH Key on Windows](https://portal.nutanix.com/page/documents/details?targetId=Self-Service-Admin-Operations-Guide-v3_8_0:nuc-app-mgmt-generate-ssh-key-windows-t.html) example.
- OpenTofu installation - see [instructions](../appendix/appendix.md#preparing-opentofu) here.

## Jump Host VM Requirements

The following jump host resources are recommended for the jump host VM:

- Supported OS: `Ubuntu 22.04 LTS`
- Resources:
  - CPU: `2 vCPU`
  - Cores Per CPU: `4 Cores`
  - Memory: `16 GiB`
  - Storage: `300 GiB`
  
## Install OpenTofu 

Install OpenTofu for Infrastructure as Code requirement

Follow the [instructions](../appendix/appendix.md#preparing-opentofu) here to get it installed on your workstation.

!!!note
       This is the only binary that you will need to install on your workstation or any other OS to get the jump host VM running. 

       Once jump host VM is installed, install OpenTofu on the jump host VM as well. 

## Generate a SSH Key on Linux/Mac

1. Run the following command to generate an RSA key pair.
  
    ```bash
    ssh-keygen -t rsa
    ```
  
2. Accept the default file location as ``~/.ssh/id_rsa``
  
3. The keys will be available in the following locations:
    
    ``` { .bash .no-copy }
    ~/.ssh/id_rsa.pub 
    ~/.ssh/id_rsa
    ```

    !!!tip
          On Windows machine, See [Generate a SSH Key on Windows](https://portal.nutanix.com/page/documents/details?targetId=Self-Service-Admin-Operations-Guide-v3_8_0:nuc-app-mgmt-generate-ssh-key-windows-t.html) example.

## Create Jump Host VM

We will create a jump host VM using OpenTofu. 

1. Create a ``cloudinit`` file using the following contents
   
    ```bash
    vi jumphostvm_cloudinit.yaml
    ```

    with the following content:

   
    ```yaml
    #cloud-config
    hostname: nai-llm-jumphost
    package_update: true
    package_upgrade: true
    package_reboot_if_required: true
    packages:
      - open-iscsi
      - nfs-common
      - linux-headers-generic
    runcmd:
      - systemctl stop ufw && systemctl disable ufw
    users:
      - default
      - name: ubuntu
        groups: sudo
        shell: /bin/bash
        sudo:
          - 'ALL=(ALL) NOPASSWD:ALL'
        ssh-authorized-keys: 
        - ssh-rsa XXXXXX.... # (1)    
    ```

    1.  :material-fountain-pen-tip: Copy and paste the contents of your ``~/.ssh/id_rsa.pub ``file or any public key file that you wish to use. 
   
          ---

          If you are using a Mac, the command ``pbcopy``can be used to copy the contents of a file to clipboard. 

          ```bash
          cat ~/.ssh/id_rsa.pub | tr -d '\n' | pbcopy
          ```

          ++cmd+"v"++ will paste the contents of clipboard to the console.


    !!!warning
          Make sure to paste the value of the RSA public key in the ``jumphostvm_cloudinit.yaml`` file.
          
2. Create a base64 decode for your cloudinit yaml file
   
    ```bash
    cat jumphostvm_cloudinit.yaml | base64 | tr -d '\n' # (1)
    ```
    
    1.  If you are using a Mac, the command ``pbcopy``can be used to copy the contents of a file to clipboard. 

        ```bash
        cat jumphostvm_cloudinit.yaml | base64 | tr -d '\n' | pbcopy
        ```

        ++cmd+"v"++ will paste the contents of clipboard to the console.

3. Create a config ``yaml`` file to define attributes for all your jump host VM
   
    ```bash
    vi jumphostvm_config.yaml
    ```

    with the following content:

    ```yaml
    user: "admin"
    password: "XXXXXX"
    subnet_name: "subnet"
    cluster_name: "PE Cluster Name"
    endpoint: "PC FQDN"
    storage_container: "default"
    nke_k8s_version: "1.26.8-0"
    node_os_version: "ntnx-1.6.1"
    master_num_instances: 1
    etcd_num_instances: 1
    worker_num_instances: 1
    name: "nai-llm-jumphost"
    num_vcpus_per_socket: "1"
    num_sockets: "2"
    memory_size_mib: 4096
    guest_customization_cloud_init_user_data: ""
    disk_list:
      - data_source_reference:
          kind: "image"
          uuid: "nutanix_image.jumpvmimage.id"
    disk_size_mib: 40960  # 40 GB in MiB for jump vm host OS disk
    nic_list:
      - subnet_uuid: "data.nutanix_subnet.subnet.id"
    source_uri: "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
    guest_customization_cloud_init_user_data: "I2Nsb3VkLWNvbmZpZw....." # (1)
    ```

    1.  :material-fountain-pen-tip: copy and paste the output of the command ``cat jumphostvm_cloudinit.yaml | base64 | tr -d '\n'``
         
        ---
        If you are using a Mac and ``pbcopy`` utility as suggested in the previous command's tip window, ++cmd+"v"++ will paste the contents of clipboard to the console.

    !!!warning
          Make sure to paste the output of the command ``cat jumphostvm_cloudinit.yaml | base64 | tr -d '\n'``
    
    !!!note
           There are other variables in the local config file. These will be used in the later part of the lab to create NKE clusters.


4. Create an image and a VM resource file with 
  
    ```bash
    vi jumphostvm.tf
    ```

    with the following content:

    ```json
    terraform {
      required_providers {
        nutanix = {
          source  = "nutanix/nutanix"
          version = "1.9.5"
        }
      }
    }

    locals {
      config = yamldecode(file("${path.module}/vm_config.yaml"))
    }

    data "nutanix_cluster" "cluster" {
      name = local.config.cluster_name
    }
    data "nutanix_subnet" "subnet" {
      subnet_name = local.config.subnet_name
    }

    provider "nutanix" {
      username     = local.config.user
      password     = local.config.password
      endpoint     = local.config.endpoint
      insecure     = false
      wait_timeout = 60
    }

    resource "nutanix_image" "jumphost-image" {
      name        = "jumpvmimage"
      description = "Jumphost VM image"
      source_uri  = local.config.source_uri
    }

    resource "nutanix_virtual_machine" "nai-llm-jumphost" {
      name                 = local.config.name
      cluster_uuid         = data.nutanix_cluster.cluster.id
      num_vcpus_per_socket = local.config.num_vcpus_per_socket
      num_sockets          = local.config.num_sockets
      memory_size_mib      = local.config.memory_size_mib
      guest_customization_cloud_init_user_data = local.config.guest_customization_cloud_init_user_data
      disk_list {
        data_source_reference = {
          kind = "image"
          uuid = nutanix_image.jumpvmimage.id
        }
        disk_size_mib = local.config.disk_size_mib
      }
      nic_list {
        subnet_uuid = data.nutanix_subnet.subnet.id
      }

      depends_on = [nutanix_image.jumpvmimage]
    }

    output "nai-llm-jumphost-ip-address" {
      value = nutanix_virtual_machine.nai-llm-jumphost.*.nic_list
      description = "Mac address of the jump host vm"
    }
    ```

5. Apply your tofu code to create jump host VM 
  
    ```bash
    tofu validate
    tofu apply 

    # Terraform will show you all resources that it will to create
    # Type yes to confirm 
    # Check the output to get the IP address of the VM
    ```

6. Obtain the IP address of the jump host VM from the Tofu output
  
    ``` { .bash .no-copy }
    # Command output

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

    Outputs:

    jumpvm_ip_address = [
      tolist([
        {
          "ip_endpoint_list" = tolist([
            {
              "ip" = "10.x.x.x"             ## << This is your jump host VM's IP
              "type" = "ASSIGNED"
            },
    ]
    ```

7.  Run the Terraform state list command to verify what resources have been created

    ``` bash
    tofu state list
    ```

    ``` { .bash .no-copy }
    # Sample output for the above command

    data.nutanix_cluster.cluster              # < This is your existing Prism Element cluster
    data.nutanix_subnet.subnet                # < This is your existing primary subnet
    nutanix_image.jumphost-image              # < This is the image file for jump host VM
    nutanix_virtual_machine.nai-llm-jumphost  # < This is the jump host VM
    ```


6. Validate that VM is accessible using ssh: 
  
    ```bash
    ssh -i ~/.ssh/id_rsa ubuntu@<ip-address-from-tofu-output>
    ```

## Install nai-llm utilities

We have compiled a list of utilities that needs to be installed on the jump host VM to use for the rest of the lab. We have affectionately called it as ``nai-llm`` utilities. Use the following method to install these utilities:

1. SSH into Linux VM  

    ```bash
    ssh -i ~/.ssh/id_rsa ubuntu@<ip-address>
    ```

2. Clone Git repo and change working directory

    ```bash
    git clone https://github.com/jesse-gonzalez/nai-llm-fleet-infra
    cd $HOME/nai-llm-fleet-infra/
    ```

3. Run Post VM Create - Workstation Bootstrapping Tasks
  
    ```bash
    sudo snap install task --classic
    task ws:install-packages ws:load-dotfiles --yes -d $HOME/nai-llm-fleet-infra/
    source ~/.bashrc
    ```

3. Change working directory and see ``Task`` help
  
    ```bash
    cd $HOME/nai-llm-fleet-infra/ && task
    ```
    ``` { .bash .no-copy }
    # command output
    task: bootstrap:silent

    Silently initializes cluster configs, git local/remote & fluxcd

    See README.md for additional details on Getting Started

    To see list of tasks, run `task --list` or `task --list-all`

    dependencies:
    - bootstrap:default

    commands:
    - Task: bootstrap:generate_local_configs
    - Task: bootstrap:verify-configs
    - Task: bootstrap:generate_cluster_configs
    - Task: nke:download-creds 
    - Task: flux:init
    ```

We have a jumphost VM now that we will be using to perform the rest of the labs. 