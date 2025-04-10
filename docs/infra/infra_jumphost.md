# Manually Creating Ubuntu Linux Jumphost VM on Nutanix AHV

Below is walkthrough for manually creating a Linux VM on Nutanix AHV to support the various deployment scenarios.

## Prerequisites

- Existing Nutanix AHV Subnet configured with IPAM
- Existing Linux OS machine image (i.e., `Ubuntu 22.04 LTS` ) with cloud-init service enabled. If not existing, See [Upload Generic Cloud Image into Prism Central](#upload-generic-cloud-image-into-prism-central) example.
- SSH Private Key for inital `cloud-init` bootstrapping. If not existing:
  - On MacOS/Linux machine, See [Generate a SSH Key on Linux](#generate-a-ssh-key-on-linux) example.
  - On Windows machine, See [Generate a SSH Key on Windows](https://portal.nutanix.com/page/documents/details?targetId=Self-Service-Admin-Operations-Guide-v3_8_0:nuc-app-mgmt-generate-ssh-key-windows-t.html) example.

## Jumphost VM Requirements

The following jumphost resrouces are recommended for the jumphost VM:

- Supported OS: `Ubuntu 22.04 LTS`
- Resources:
  - CPU: `2 vCPU`
  - Cores Per CPU: `4 Cores`
  - Memory: `16 GiB`
  - Storage: `300 GiB`

## Upload Generic Cloud Image into Prism Central

- Navigate to **Prism Central > Infrastructure > Compute & Storage > Images**
- On **Select Image** tab, Click **Add Image > Select URL Button > Input Image** 
  
    ```url
    https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
    ```

- Click **Add URL > Click Next > Accept Remaining Defaults**  
- Click on **Save**

## Generate a SSH Key on Linux

- Run the following command to generate an RSA key pair.
  
    ```bash
    ssh-keygen -t rsa
    ```
  
- Accept the default file location as ``~/.ssh/id_rsa``
  
- The keys will be available in the following locations:

    ``` { .bash .no-copy }
    ~/.ssh/id_rsa.pub 
    ~/.ssh/id_rsa
    ```

## Create Linux VM using Prism Central

Run following commands from Prism Central UI.

- Select **Infrastructure (via App Switcher Dropdown) > Click Compute & Storage > Click VMs > Click Create VM**
- On Configuration Tab:
  - Input Name (i.e., `nai-llm-jumphost`) 
  - Number of VMs (i.e., 1) > Select **Cluster > Update VM Properties** (See [Jumphost VM Requirements](#jumphost-vm-requirements)) 
- Click **Next** and enter the following details:
  - **CPU:** `2 vCPU`
  - **Cores Per CPU:** `4 Cores`
  - **Memory:** `16 GiB`
  - **Storage:**`300 GiB`

- On the **Resources Tab:**, do the following:
  - Under Disks > Attach Disk > Select Clone from Image > Select Image (ex. `ubuntu-22.04-server-cloudimg-amd64.img`) > Update Capacity (See [Jumphost VM Requirements](#jumphost-vm-requirements)) > Click Save
  - Under Networks > Attach to Subnet > Select Subnet > Select DHCP Enabled Network > Select Assign with DHCP > Click Save
  - Select Legacy Bios Mode > Click Next > Accept Remaining Defaults > Click Create VM

- On Management Tab:
  - Under Guest Customization > Select `Cloud-Init (Linux)` on Script Type dropdown
  - Copy and Paste cloud-init YAML config script (example below) > Accept Remaining Defaults
  
    ???tip

          When copying and pasting `<ssh-rsa-public-key>` from a terminal, make sure not to include any new lines. Consider the following command to removes new lines: 
          
          ```bash
          cat ~/.ssh/id_rsa.pub | tr -d '\n'
          ```

    !!!warning
          Make sure to update the following attributes of the VM:

          - `hostname:`
          - `<ssh-rsa-public-key>` line under `ssh-authorized-keys:` attribute
  
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
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh-authorized-keys:
        - <ssh-rsa-public-key>
    ```



-  Click on **Create VM**


Once the jumphost VM has been created:

- Navigate to **Prism Central > Select Infrastructure > Select Compute & Storage** 
- Click on **VMs**
- Filter VM Name (i.e., `nai-llm-jumphost`) 
- Select **VM > Actions > Power On**
- Click on **VM** and Find IP Address in the **NIC tab**

- Validate that VM is accessible using ssh: 
  
    ```bash
    ssh -i ~/.ssh/id_rsa ubuntu@<ip-address>
    ```

## Install nai-llm utilities

We have compiled a list of utilities that needs to be installed on the jumphost VM to use for the rest of the lab. We have affectionately called it as ``nai-llm`` utilities. Use the following method to install these utilities:

1. SSH into Linux VM  

    ```bash
    ssh -i ~/.ssh/id_rsa ubuntu@<ip-address>
    ```

2. Clone Git repo and change working directory

    ```bash
    git clone https://github.com/nutanix-japan/sol-cnai-infra
    cd $HOME/sol-cnai-infra/
    ```

3. Run Post VM Create - Workstation Bootstrapping Tasks
  
    ```bash
    sudo snap install task --classic
    task ws:install-packages ws:load-dotfiles --yes -d $HOME/sol-cnai-infra/
    source ~/.bashrc
    ```

3. Change working directory and see ``Task`` help
  
    ```bash
    cd $HOME/sol-cnai-infra/ && task
    ```

    ``` { .bash .no-copy }
    $ cd $HOME/sol-cnai-infra/ && task
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
