---
title: "Continuous Deployment NKP"
lastupdate: git
lastupdateauthor: "Lakshmi Balaramane"
---

## Introduction - Continuous Integration

This section walks you through building the Continuous Integration setup using Tekton pipelines. 


```mermaid

```

## CD Setup

### Github Repository Stucture

Flux CD is a declarative GitOps tool for Kubernetes that ensures your cluster state matches the configuration stored in a Git repository. Instead of "pushing" code to your cluster via a CI pipeline, Flux "pulls" the state from Git, making your repository the single source of truth.

**The Core Components**

Flux is comprised of several specialized controllers (the "GitOps Toolkit"). Each handles a specific part of the deployment lifecycle:

* **Source Controller:** The **Watcher**. It monitors your Git repositories, Helm charts, or OCI artifacts for changes and pulls them into the cluster as "artifacts."
* **Kustomize Controller:** The **Applier**. It takes the YAML or Kustomize manifests fetched by the Source Controller and applies them to the Kubernetes API.
* **Helm Controller:** The **Operator**. Specifically manages `HelmRelease` objects, handling upgrades, rollbacks, and dependencies for Helm charts.
* **Notification Controller:** The **Messenger**. It handles inbound events (webhooks from GitHub/GitLab) and outbound alerts (Slack, Microsoft Teams, or Discord notifications).
---

**Repo Structure: Monorepo vs. Split Repo**

**It is generally considered a best practice to separate your Application code from your GitOps (infrastructure) definitions.** So we will work with two repositories

**Standard Pattern:**

1.  **App Repo:** Contains source code, Dockerfile, and CI workflows (GitHub Actions/Tekton).- (previously setup in [CI section](../nkp_cicd_lab/nkp_ci_setup.md#setup-github-repo))
2.  **GitOps Repo:** Contains Kubernetes manifests, Flux objects (`GitRepository`, `Kustomization`), and environment-specific configs (Dev/Staging)

Here is the comparison of the two repositories organized into a Markdown table for better clarity.

**GitOps Repository Structure**

| **Repository** | **Repository Name** | **Purpose** | **Key Components** |
| :---           | :---                | :---        | :---               |
| **App Repo** | (`app-source`) | Houses the application logic and build instructions. | Source code, Dockerfile, CI workflows (GitHub Actions/Tekton). |
| **GitOps Repo** |(`gitops-config`) | Defines the desired state of the infrastructure and environments. | K8s manifests, Flux objects (`GitRepository`, `Kustomization`), Env configs (Dev/Prod). |

---

### Key Workflow Differences
* **The App Repo** is where developers spend most of their time writing code and triggering automated builds (CI).
* **The GitOps Repo** acts as the "Source of Truth" for your cluster, where Flux monitors for changes to deploy the application (CD).
---

**Why separate them?**

* **Security:** Your CI system needs write access to the GitOps repo to update image tags, but it only needs read access to the App repo.
* **Reduced Noise:** Merging a README change in the App repo won't trigger a Flux reconciliation of your infrastructure.
* **Clean Audit Trail:** The GitOps repo becomes a pure "log" of every deployment to production, separate from the messy history of feature development.


---

**The Basic Workflow**

1.  **Developer** pushes code to the **App Repo**.
2.  **CI (e.g., Tekton/GitHub Actions)** builds a Docker image and pushes it to a registry.
3.  **CI** (Flux Image Automation controller) updates the image tag in the **GitOps Repo**.
4.  **Flux Source Controller** detects the commit in the GitOps Repo.
5.  **Flux Kustomize Controller** applies the new manifest to the cluster.

---

#### Setup Github Repo

1. We will create Tekton objects in the NKP cluster using manifests files
2. Open [Github](https://www.github.com) in a browser
3. Login with you Github account
4. Open this repository URL on a different browser tab
   
    !!! info 
    
        This repository hosts the manifests of two functions:
        
         *  The sample application's source code
         *  The tekton objects that we will create to enable CI

    === ":material-link: Git URL"
    
        ```bash
        https://github.com/ariesbabu/gitops-config.git
        ```

5. **Fork** the following repo to your GitHub account
   
6. After the fork, there will be copy of the source repo in your github handle
   
    === ":material-link: Git URL"
     
         ```bash
         https://github.com/_your_git_handle/gitops-config.git
         ```
    
    === ":material-link: Example Git URL"
     
         ```bash
         https://github.com/student1/gitops-config.git
         ```

7. Go to **Settings** page of your Github handle
8. Select **Developer Settings**
9. Click on **Personal Access Tokens** > **Fine-grained tokens**
10. Click on **Generate New Token**
11. Populate details:
    
     - **Token name** - for-cicd-lab
     - **Expiration** - 30 days
     - **Repository access** - Only select repositories
     - **Repositories** - select ``app-source`` and ``gitops-config`` repositories
     - **Permissions** - select **Read access to metadata** and **Read and Write access to code and repository hooks**
12. Copy the token value to use in the next section

### Bootstrap Flux

1. Open ``$HOME/cicd/.env`` file in VSC and add (append) the following environment variables to your ``.env`` file and save
   
    
    === ":octicons-file-code-16: Template ``.env``"

        ```bash hl_lines="9"
        export REGISTRY_URL=_your_registry_url
        export REGISTRY_USERNAME=_your_registry_username
        export REGISTRY_PASSWORD=_your_registry_password
        export REGISTRY_CACERT=_path_to_ca_cert_of_registry  # (1)!
        # Optional if using Docker - Public Docker Registry Details
        export DOCKER_REGISTRY_URL=_your_registry_url
        export DOCKER_REGISTRY_USERNAME=_your_registry_username
        export DOCKER_REGISTRY_PASSWORD=_your_registry_password
        export SMEE_URL=_your_smee_url
        export GIT_USER=_your_git_handle
        export GIT_PAT=_your_git_repos_personal_token       # (2)!
        ```

        1. File must contain CA server and Harbor server's public certificate in one file
        2. Github token copied from previous [section](../nkp_cicd_lab/nkp_cd_setup.md#setup-github-repo)

    === ":octicons-file-code-16: Sample ``.env``"

        ```bash hl_lines="9"
        export REGISTRY_URL=https://harbor.10.x.x.111.nip.io/nkp
        export REGISTRY_USERNAME=admin
        export REGISTRY_PASSWORD=xxxxxxxx
        export REGISTRY_CACERT=$HOME/harbor/certs/full_chain.pem  # (1)!
        # Optional if using Docker - Public Docker Registry Details
        export DOCKER_REGISTRY_URL=https://index.docker.io/v1/
        export DOCKER_REGISTRY_USERNAME=dockeruser
        export DOCKER_REGISTRY_PASSWORD=_XXXXXXXXXX
        export SMEE_URL=https://smee.io/pPxxxxxxxxxxxxxxxd
        export GIT_USER=ariesbabu
        export GIT_PAT=github_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        ```

        3. File must contain CA server and Harbor server's public certificate in one file

2. Source the new variables and values to the environment
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        cd $HOME/cicd/
        source .env
        ```


3.  Login to the ``nkpcicd`` workload kubernetes server and ensure you are using the right context before proceeding
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        export KUBECONFIG=nkpcicd.conf
        kubectl get nodes  # (1)!
        ```

        1. Run any kubectl command to ensure your are in the correct context (workload cluster ``nkpcicd``)
    
    === ":octicons-command-palette-16: Command output"
    
        ```bash
        $ kubectl get nodes
        #
        NAME                                STATUS   ROLES           AGE    VERSION
        nkpcicd-lkr26-lc56p                 Ready    control-plane   5d3h   v1.34.3
        nkpcicd-md-0-4jkvk-mcp9r-bbjvq      Ready    <none>          5d3h   v1.34.3
        nkpcicd-md-0-4jkvk-mcp9r-phlv7      Ready    <none>          5d3h   v1.34.3
        ```

5. Create github-pat secret
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl apply -f -<<EOF
        apiVersion: v1
        kind: Secret
        metadata:
          name: git-pat
        type: Opaque
        stringData:
          username: $GITHUB_USER
          token: $GITHUB_TOKEN
        EOF
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```bash
        secret/git-pat created
        ```
   
6. Bootstrap flux to see your new ``gitops-config`` repository

    === ":octicons-command-palette-16: Command"
    
        ```bash
        flux bootstrap github \
        --owner=$GITHUB_USER \
        --repository=gitops-config \
        --branch=main \
        --path=clusters/nkpcicd \
        --personal \
        --token-auth
        ```
    
    === ":octicons-command-palette-16: Sample command"
    
        ```bash
        flux bootstrap github \
        --owner=ariesbabu \
        --repository=gitops-config \
        --branch=main \
        --path=clusters/nkpcicd \
        --personal \
        --token-auth
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        ► connecting to github.com
        ► cloning branch "main" from Git repository "https://github.com/ariesbabu/gitops-config.git"
        ✔ cloned repository
        ► generating component manifests
        ✔ generated component manifests
        ✔ committed component manifests to "main" ("1faf5ed6dc36f854ae772ef782e02aced7808a1d")
        ► pushing component manifests to "https://github.com/ariesbabu/gitops-config.git"
        ► installing components in "flux-system" namespace
        ✔ installed components
        ✔ reconciled components
        ► determining if source secret "flux-system/flux-system" exists
        ► generating source secret
        ► applying source secret "flux-system/flux-system"
        ✔ reconciled source secret
        ► generating sync manifests
        ✔ generated sync manifests
        ✔ committed sync manifests to "main" ("f90d8517cb51ad792176e1053f9f337d25d057fd")
        ► pushing sync manifests to "https://github.com/ariesbabu/gitops-config.git"
        ► applying sync manifests
        ✔ reconciled sync configuration
        ◎ waiting for GitRepository "flux-system/flux-system" to be reconciled
        ✔ GitRepository reconciled successfully
        ◎ waiting for Kustomization "flux-system/flux-system" to be reconciled
        ✔ Kustomization reconciled successfully
        ► confirming components are healthy
        ✔ helm-controller: deployment ready
        ✔ kustomize-controller: deployment ready
        ✔ notification-controller: deployment ready
        ✔ source-controller: deployment ready
        ✔ all components are healthy
        ```

7. Run a flux check to verify 
8. 
    === ":octicons-command-palette-16: Command"
    
        ```bash
        flux check
        kubectl get pods -n flux-system
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        $ flux check
        #
        ► checking prerequisites
        ✔ Kubernetes 1.35.0 >=1.33.0-0
        ► checking version in cluster
        ✔ distribution: flux-v2.8.5
        ✔ bootstrapped: true
        ► checking controllers
        ✔ helm-controller: deployment ready
        ► ghcr.io/fluxcd/helm-controller:v1.5.3
        ✔ kustomize-controller: deployment ready
        ► ghcr.io/fluxcd/kustomize-controller:v1.8.3
        ✔ notification-controller: deployment ready
        ► ghcr.io/fluxcd/notification-controller:v1.8.3
        ✔ source-controller: deployment ready
        ► ghcr.io/fluxcd/source-controller:v1.8.2
        ► checking crds
        ✔ alerts.notification.toolkit.fluxcd.io/v1beta3
        ✔ buckets.source.toolkit.fluxcd.io/v1
        ✔ externalartifacts.source.toolkit.fluxcd.io/v1
        ✔ gitrepositories.source.toolkit.fluxcd.io/v1
        ✔ helmcharts.source.toolkit.fluxcd.io/v1
        ✔ helmreleases.helm.toolkit.fluxcd.io/v2
        ✔ helmrepositories.source.toolkit.fluxcd.io/v1
        ✔ kustomizations.kustomize.toolkit.fluxcd.io/v1
        ✔ ocirepositories.source.toolkit.fluxcd.io/v1
        ✔ providers.notification.toolkit.fluxcd.io/v1beta3
        ✔ receivers.notification.toolkit.fluxcd.io/v1
        ✔ all checks passed

        $ kubectl get pods -n flux-system
        #
        NAME                                     READY   STATUS    RESTARTS   AGE
        helm-controller-9655d6568-4hbkh          1/1     Running   0          38m
        kustomize-controller-8c5b8dfbb-c44w7     1/1     Running   0          38m
        notification-controller-54fccc9d-p8mgg   1/1     Running   0          38m
        source-controller-7768cbf8d5-7xw5w       1/1     Running   0          38m
        ```

Rest is under constuction.. Be sure to check tomorrow. ^^