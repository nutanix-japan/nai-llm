# Pre-requisites for MGMT and DEV Cluster

In this part of the lab we will prepare pre-requisites for LLM application on GPU nodes.

The following is the flow of the applications lab:

```mermaid
stateDiagram-v2
    direction LR

    state PreRequisites {
        [*] --> ReserveIPs
        ReserveIPs --> CreateBuckets
        CreateBuckets --> CreateFilesShare
        CreateFilesShare --> [*]
    }
  

    [*] --> PreRequisites
    PreRequisites --> DeployLLMV1 : next section
    DeployLLMV1 --> TestLLMApp
    TestLLMApp --> [*]
```

Prepare the following pre-requisites for mgmt-cluster and dev-cluster kubernetes clusters. 

## Using Devbox NIX Shell

This project uses [devbox](https://github.com/jetpack-io/devbox) to manage its development environment.

6.  On VS Code, Click **View > Command Palette** and **Connect to Host**

7.  Select the IP address of your jumphost VM

8.  A new Visual Studio Code window will open
    
9.  Click the **Explorer** button from the left-hand toolbar and select **Open Folder**.

10. Provide the ``/home/ubuntu/nainai-llm-fleet-infra`` as the folder you want to open and click on **OK**.
 
11. Install `devbox` using the following command and accept all defaults

    ```sh
    curl -fsSL https://get.jetpack.io/devbox | bash
    ```

12. Start the `devbox shell` and if `nix` isn't available, you will be prompted to install:

    ```sh
    devbox shell
    ```

## Reserve Ingress and Istio Endpoint IPs 

Nutanix AHV IPAM network allows you to black list IPs that needs to be reserved for specific application endpoints. We will use this feature to find and reserve two IPs. 

We will need a total of four IPs for the following:

  
| Cluster Role  | Cluster Name            |    Ingress IP   |    Istio  IP  |          
| -------------  | --------            |  ------------ |  --------   | 
| Management |``mgmt-cluster``|  1            |  1          |
| Dev  |``dev-cluster``       |  1             |  1          |  

1. Get the CIDR range for the AHV network(subnet) where the application will be deployed

    ```buttonless title="CIDR example for your Nutanix cluster"
    10.x.x.0/24
    ```

2. From VSC, logon to your jumpbox VM (if not already done)

3. Install ``nmap`` tool 
   
    ```bash
    devbox add nmap
    ```

4. Find four unused static IP addresses in the subnet

    === "Template command"
    
        ```bash
        nmap -v -sn  <your CIDR>
        ```

    === "Sample command"

        ```bash 
        nmap -v -sn 10.x.x.0/24
        ```

    ```text title="Sample output - choose the first four consecutive IPs"
    Nmap scan report for 10.x.x.214 [host down]
    Nmap scan report for 10.x.x.215 [host down]
    Nmap scan report for 10.x.x.216 [host down]
    Nmap scan report for 10.x.x.217 [host down]
    Nmap scan report for 10.x.x.218
    Host is up (-0.098s latency).
    ```

5. Logon to any CVM in your Nutanix cluster and execute the following to add chosen static IPs to the **Primary** IPAM network

    - **Username:** nutanix
    - **Password:** your Prism Element password 

    === "Template command"
    
        ```text
        acli net.add_to_ip_blacklist <your-ipam-ahv-network> \
        ip_list=10.x.x.214,10.x.x.215,10.x.x.216,10.x.x.217
        ```

    === "Sample command"

         ```text
         acli net.add_to_ip_blacklist User1 \
         ip_list=10.x.x.214,10.x.x.215,10.x.x.216,10.x.x.217
         ```

## Create Nginx Ingress and Istio VIP/FDQN

We will use nip.io address to assign FQDNs for our Nginx Ingress and Istio by using the 4 IPs that we just reserved in the previous section for use in the next section. We will leverage the ``NIP.IO`` with the vip and self-signed certificates.

We will need a total of three/four IPs for the following:

### Management Cluster
  
Assign the first two reserved IPs to Management cluster.

|   Component  | Sub-component| IP/FQDN   |    
|  ------------ | --| --------   | 
| Nginx Ingress | `vip`| ``10.x.x.214``  |
|  Nginx Ingress   | ``wildcard_ingress_subdomain``| ``mgmt-cluster.10.x.x.214.nip.io``    | 
|  Nginx Ingress   |  ``management_cluster_ingress_subdomain``| ``mgmt-cluster.10.x.x.214.nip.io``     | 

### Dev Cluster

Assign the next two reserved IPs to Dev cluster.

!!!note
       The ``management_cluster_ingress_subdomain`` appears in this table once again and it is just a reference for ``dev-cluster`` to ``mgmt-cluster``. This entry will be used in the ``.env.dev-cluster.yaml`` file during the [Deploy Dev Cluster](llm_mgt_deploy.md#bootstrap-management-cluster) section.

|   Component  | Sub-component| IP/FQDN   |    
|  ------------ | --| --------   | 
| Nginx Ingress | `vip`|`` 10.x.x.216   ``  |
|  Nginx Ingress   | `wildcard_ingress_subdomain`| ``dev-cluster.10.x.x.216.nip.io``    | 
|  Nginx Ingress   |  `management_cluster_ingress_subdomain`| ``mgmt-cluster.10.x.x.214.nip.io``     | 
|  Istio   |  ``vip``| ``10.x.x.217``     | 
|  Istio  | ``wildcard_ingress_subdomain``| ``dev-cluster.10.x.x.217.nip.io``    | 

## Create Buckets in Nutanix Objects

We will create access keys to buckets that we will be using in the project.

### Generating Access Keys for Buckets

!!!note
       Follow instructions [here](https://portal.nutanix.com/page/documents/details?targetId=Objects-v4_4:top-object-store-deployment-t.html) to create a Nutanix Objects Store (if you do not have it)

       We are assuming that the name of the Objects Store is ``ntnx-objects``.

1.  Go to **Prism Central** > **Objects** > **ntnx-objects**

2.  On the right-hand pane, click on **Access Keys**

3.  Click on **+ Add people**

4.  Select **Add people not in a directory service**

5.  Enter an email ``llm-admin@example.com`` and name `llm-admin`

6.  Click on **Next**

7.  Click on **Generate Keys**

8.  Once generated, click on **Download Keys**

9.  Once downloaded, click on **Close**

10. Open the downloaded file to verify contents

    ``` { .text .no-copy}
    Username: llm-admin@example.com
    Access Key: 1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    Secret Key: gxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    Display Name: milvus-user
    ```

11. Store the access key and secret key in a safe place for access 

#### Create Buckets

We will create buckets for Milvus database store and document store for uploaded files for querying will be stored.

1.  On the top menu, click on **Object Stores**

2.  Click on **ntnx-objects**
   
3.  Click on **Create Bucket**

4.  Enter **mgmt-cluster-milvus** as the bucket name

5.  Click on **Create**
   
6.  Follow the same steps to create another bucket called **documents01**

#### Provide Access to Buckets

7.  In the list of buckets, click on the **mgmt-cluster-milvus** bucket

8.  Click on **User Access** menu and **Edit User Access**

9.  In the **mgmt-cluster-milvus** window, type in the ``llm-admin@example.com`` email that you configured in the [Generating Access Keys for Buckets](#generating-access-keys-for-buckets) section

10. Give **Full Access** permissions

11. Click on **Save**
    
12. Follow the same steps to give **Full Access** to the ``llm-admin@example.com`` email for **documents01** bucket

### Create Nutanix Files Share

Create NFS share for hosting the LLM model file ``llama-2-13b-chat`` and model archive file

!!!note
       Follow instructions [here](https://portal.nutanix.com/page/documents/details?targetId=Files-v5_0:fil-file-server-create-wc-t.html) to create a Nutanix Files cluster (if you do not have it)

       We are assuming that the name of the Files cluster is `ntnx-files`.

1. Go to **Prism Central** > **Files** > **ntnx-files**

2. Click on **Shares & Exports**
3. Click on **+ New Share or Export**
4. Enter the following details:

    - **Name** - llm-model-store
    - **Enable compression** - checked
    - **Authentication** - system
    - **Default Access** - Read-Write
    - **Squash** - Root Squash

5. Click on **Create**
6. Copy the Share/Export Path from the list of shares and note it down for later use (e.g: ``/llm-model-store``)

## Prepare Github Repository and API Token

We need to fork this projects Github repository to you github organization(hadle). This repository will be used to hold the flux files for GitOps sections. 

A ``repo_api_token`` needs to be created to allow for git changes.

1. **Log in to GitHub**:
   go to [GitHub](https://github.com/) and log in to your account.

2. Fork the following source repository
   ```text
   https://github.com/jesse-gonzalez/nai-llm-fleet-infra
   ```
3. **Access Settings**:
   click on your profile picture in the top-right corner and select **Settings** from the dropdown menu.

4. **Developer Settings**:
   scroll down in the left sidebar and click on **Developer settings**.

5. **Personal Access Tokens**:
   in the left sidebar, click on **Personal access tokens** and then **Tokens (classic)**.

6. **Generate New Token**:
   click on the **Generate new token** button. You might need to re-enter your GitHub password.

7. **Configure Token**:
    - **Give your token a descriptive name**: `for nai-llm-fleet-infra actions`
    - **Expiration**: choose an expiration period of ``7 days``
    - **Scopes**: under `repo`, select the **public repo** (full control of public repositories)

8. **Generate Token**:
   after selecting the scopes, click on the **Generate token** button at the bottom of the page.

9. **Copy Token**:
   GitHub will generate the token and display it. **Copy this token** and store it securely. It can't be seen again.

???tip "Single repository access?"
       **Restricting Token to a Single Repository**

       GitHub's PATs are account-wide and cannot be restricted to a single repository directly. However, you can control access using repository permissions and organizational policies. Here are some options:

       - **Create a Dedicated GitHub User**:
       
        Create a new GitHub user specifically for accessing the repository. Invite this user to your repository with the necessary permissions, then generate a PAT for this user.
<!--         
       - **Use Repository Deploy Keys**:
       
        Deploy keys are SSH keys that give access to a single repository. They can be read-only or read/write. Deploy keys are more restrictive than PATs but can be an alternative if you only need repository-specific access. -->


We will use this token in the next section. 

## Prepare Docker Hub Credentials

Docker hub credentials are required to prevent rate limits on image downloads. 

If you do not have docker account, please create it here. 

Store the docker username and password securely for use in the next section.

## Install nai-llm Utilities on Jumphost VM

We have compiled a list of utilities that needs to be installed on the jumphost VM to use for the rest of the lab. We have affectionately called it as ``nai-llm`` utilities. Use the following method to install these utilities:

1. Using VSC, open Terminal on the jumphost VM

2. From the ``$HOME`` directory Clone Git repo and change working directory

    ```bash
    git clone https://github.com/<your_github_org>/nai-llm-fleet-infra.git
    cd $HOME/nai-llm-fleet-infra/
    ```

3. Run Post VM Create - Workstation Bootstrapping Tasks
  
    ```bash
    sudo snap install task --classic
    task ws:install-packages ws:load-dotfiles --yes -d $HOME/nai-llm-fleet-infra/
    source ~/.bashrc
    ```

4. Change working directory and see ``Task`` help
  
    ```bash
    $ cd $HOME/nai-llm-fleet-infra/ && task
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

We have now completed all of the pre-requisites for hte LLM deployment on Nutanix. 