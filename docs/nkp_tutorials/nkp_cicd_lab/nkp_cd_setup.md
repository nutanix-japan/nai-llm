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

### Setup Github Repo

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

13. Create a local copy of the gitrepo on the jumphost VM
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        cd $HOME/cicd/
        git clone https://github.com/_your_github_handle/gitops-config.git
        ```
    
    === ":octicons-command-palette-16: Sample command"
    
        ```bash
        cd $HOME/cicd/
        git clone https://github.com/student1/app-source.git
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```bash
        Cloning into 'gitops-config'...
        remote: Enumerating objects: 166, done.
        remote: Counting objects: 100% (166/166), done.
        remote: Compressing objects: 100% (126/126), done.
        remote: Total 166 (delta 53), reused 127 (delta 27), pack-reused 0 (from 0)
        Receiving objects: 100% (166/166), 61.07 KiB | 1.39 MiB/s, done.
        Resolving deltas: 100% (53/53), done.
        ```
    

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
        --components-extra=image-reflector-controller,image-automation-controller \
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
        --components-extra=image-reflector-controller,image-automation-controller \
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


### Deploy Application

We will deploy the application on our ``nkpcicd`` cluster with Flux in this section.

1. Create the dev and staging namespaces
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl create ns dev
        kubectl create ns staging
        ```   

2. Create the ``ImageRepository`` for flux to pull application container images from

    === ":octicons-command-palette-16: Command"
    
        ```yaml
        kubectl apply -f -<<EOF
        apiVersion: image.toolkit.fluxcd.io/v1
        kind: ImageRepository
        metadata:
          name: my-app
          namespace: flux-system
        spec:
          image: docker.io/_your_git_handle/app-source
          interval: 1m
          insecure: true
        EOF
        ```

    === ":octicons-command-palette-16: Sample command"
    
        ```yaml
        kubectl apply -f -<<EOF
        apiVersion: image.toolkit.fluxcd.io/v1
        kind: ImageRepository
        metadata:
          name: my-app
          namespace: flux-system
        spec:
          image: docker.io/ariesbabu/app-source
          interval: 1m
          insecure: true
        EOF
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```bash
        imagerepository.image.toolkit.fluxcd.io/my-app created
        ```

3. Create ``ImagePolicy`` which choose image tags alphabetically (keeping is simple for now)
    
    === ":octicons-command-palette-16: Command"
    
        ```yaml
        k apply -f -<<EOF
        apiVersion: image.toolkit.fluxcd.io/v1
        kind: ImagePolicy
        metadata:
          name: my-app
          namespace: flux-system
        spec:
          imageRepositoryRef:
            name: my-app          # matches ImageRepository name above
          filterTags:
            pattern: '^[a-f0-9]{7,}$'
          policy:
            alphabetical:
              order: desc         # latest pushed tag wins
        EOF
        ```

    === ":octicons-command-palette-16: Command output"
    
        ```bash
        imagepolicy.image.toolkit.fluxcd.io/my-app created
        ```
    
4. Create ``ImageUpdateAutomation`` to push new image tag to ``gitops-config`` git repository which holds the application ``Deployment`` manifests
    
    === ":octicons-command-palette-16: Command"
    
        ```yaml
        k apply -f -<<EOF
        apiVersion: image.toolkit.fluxcd.io/v1
        kind: ImageUpdateAutomation
        metadata:
          name: my-app
          namespace: flux-system
        spec:
          interval: 1m
          sourceRef:
            kind: GitRepository
            name: flux-system
          git:
            checkout:
              ref:
                branch: main
            commit:
              author:
                email: flux-bot@example.com
                name: Flux Bot
              messageTemplate: 'chore: update image from Tekton build {{range .Changed.Changes}}{{print .OldValue}} -> {{println .NewValue}}{{end}}'
              # Debug - messageTemplate: "{{.}}"
            push:
              branch: main
          update:
            path: ./apps
            strategy: Setters
        EOF
        ```

    === ":octicons-command-palette-16: Command output"
    
        ```bash
        imageupdateautomation.image.toolkit.fluxcd.io/my-app created
        ```

5. Create Flux ``Kustomization`` to deploy the app to dev and staging namespaces
   
    === ":octicons-command-palette-16: Command"
    
        ```yaml
        kubectl apply -f -<<EOF
        ---
        apiVersion: kustomize.toolkit.fluxcd.io/v1
        kind: Kustomization
        metadata:
          name: my-app-dev
          namespace: flux-system
        spec:
          interval: 1m
          path: ./apps/dev
          prune: true
          sourceRef:
            kind: GitRepository
            name: flux-system
          targetNamespace: dev
          # --- Health Check Integration ---
          wait: true
          timeout: 2m
          healthChecks:
            - apiVersion: apps/v1
              kind: Deployment
              name: my-app
              namespace: dev # Must match the namespace where the app actually runs
        ---
        apiVersion: kustomize.toolkit.fluxcd.io/v1
        kind: Kustomization
        metadata:
          name: my-app-staging
          namespace: flux-system
        spec:
          interval: 1m
          path: ./apps/staging
          prune: true
          sourceRef:
            kind: GitRepository
            name: flux-system
          targetNamespace: staging
          # --- Health Check Integration ---
          wait: true
          timeout: 2m
          healthChecks:
            - apiVersion: apps/v1
              kind: Deployment
              name: my-app
              namespace: staging # Updated to match staging
        EOF
        ```

    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text, .no-copy}
        kustomization.kustomize.toolkit.fluxcd.io/my-app-dev configured
        kustomization.kustomize.toolkit.fluxcd.io/my-app-staging configured
        ```

6. Verify the three resources are healthy
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        flux get images repository my-app
        flux get images policy my-app
        flux get images update my-app
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        NAME    LAST SCAN               SUSPENDED       READY   MESSAGE                                                
        my-app  2026-04-22T06:46:28Z    False           True    successful scan: found 18 tags with checksum 611007973
        NAME    IMAGE                           TAG     READY   MESSAGE                                                                 
        my-app  docker.io/ariesbabu/app-source  3338bbe True    Latest image tag for docker.io/ariesbabu/app-source resolved to 3338bbe
        NAME    LAST RUN                SUSPENDED       READY   MESSAGE               
        my-app  2026-04-22T06:46:19Z    False           True    repository up-to-date
        ```

7. Watch the pods and Ingresses come up. This is synchronised by **Flux** from the ``deployment.yaml`` file in the ``gitops-config`` git repository
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl get pods -n dev 
        kubectl get pods -n staging 
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        $ k get pods -n dev
        #
        NAME                         READY   STATUS    RESTARTS   AGE
        dev-my-app-b58bcb4b8-nplmm   1/1     Running   0          48m
        dev-my-app-b58bcb4b8-vdp5d   1/1     Running   0          48m
        
        $ k get pods -n staging
        #
        NAME                              READY   STATUS    RESTARTS   AGE
        staging-my-app-787875fb78-dzw97   1/1     Running   0          42m
        staging-my-app-787875fb78-wzwpr   1/1     Running   0          42m
        ```

### Tests

#### Delete Workload Test

In this test we will delete workloads directly on the ``nkpcicd`` cluster and check if Flux detects the change and maintains desired state that is defined in the deployment.yaml file in the ``gitops-config`` github repository.

1. Delete the ``staging-my-app`` deployment
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl delete  deploy staging-my-app -n staging
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        deployment.apps "staging-my-app" deleted
        ```

2. Watch the staging namespace pods
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl get pods -n staging 
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        $ k get pods -n staging
        No resources found in staging namespace.
        ```

3. It takes 1 minute interval for the ``Kustomization`` to synchronise state from github as we have set the interval to 1 minute in this [section step 5](#deploy-application)
   
4. Check the my-app-staging ``Kustomization`` status
    
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl get kustomization -w
        ```

    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        $ kubectl get kustomization 
        #
        NAME             AGE     READY      STATUS
        my-app-staging   6h32m   Unknown    Reconciliation in progress
        my-app-staging   6h32m   True       Applied revision: main@sha1:469dca4487fdac19deff465f7c363fc5161589cd
        my-app-staging   6h32m   True       Applied revision: main@sha1:469dca4487fdac19deff465f7c363fc5161589cd
        ```
    
5. Now check the pods come up in staging namespace
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl get pods -n staging
        ```

    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        NAME                              READY   STATUS    RESTARTS   AGE
        staging-my-app-787875fb78-h567t   1/1     Running   0          1m
        staging-my-app-787875fb78-j2vk4   1/1     Running   0          1m
        ```
    
#### Increase Workload Replicas Test

In this test we will increase the number of replicas in the ``deployment.yaml`` file, which serves as the one source of desired state and check if Flux reconciles and maintains desired state on the ``nkpcicd`` cluster.

1. Open ``VSCode`` on the Jumphost VM and increase the deployment replicas from 2 to 3 in the following file
   
    === ":octicons-file-code-16: ``deployment.yaml``"
    
        ```bash
        $HOME/cicd/gitops-config/apps/base/deployment.yaml
        ```

2. Increase the replicas to 3 and save the file
   
    === ":octicons-file-code-16: Edited ``deployment.yaml``"
     
         ```yaml hl_lines="6"
         apiVersion: apps/v1
         kind: Deployment
         metadata:
           name: my-app
         spec:
           replicas: 3      # from 2 
           selector:
             matchLabels:
               app: my-app
         ```
         
    === ":octicons-file-code-16: Original ``deployment.yaml``"
     
         ```yaml hl_lines="6"
         apiVersion: apps/v1
         kind: Deployment
         metadata:
           name: my-app
         spec:
           replicas: 2 
           selector:
             matchLabels:
               app: my-app
         ```

3. Push the changes to git
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        cd $HOME/cicd/gitops-config/
        git add .
        git commit -am "Update: Testing first automated Flux reconciling Deployment"
        git push
        cd ..
        ```

    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        $ git add .
        
        $ git commit -am "Update: Testing first automated Flux reconciling Deployment"
        
        $ git push
        #
        [main a13dd3e] Update: Testing first automated Flux reconciling Deployment
        1 file changed, 1 insertion(+), 1 deletion(-)
        Enumerating objects: 9, done.
        Counting objects: 100% (9/9), done.
        Delta compression using up to 12 threads
        Compressing objects: 100% (5/5), done.
        Writing objects: 100% (5/5), 493 bytes | 493.00 KiB/s, done.
        Total 5 (delta 2), reused 0 (delta 0), pack-reused 0
        remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
        To https://github.com/ariesbabu/gitops-config.git
        469dca4..a13dd3e  main -> main
        ```

4. Watch the pods in the dev and staging namespace for at least 1 minute interval. The additional pod will be spinning up soon.

    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl get po -n dev -w
        kubectl get po -n staging -w
        ```

    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        $ kubectl get po -n dev -w
        #
        NAME                         READY   STATUS              RESTARTS   AGE
        dev-my-app-b58bcb4b8-nplmm   1/1     Running             0          161m
        dev-my-app-b58bcb4b8-vdp5d   1/1     Running             0          161m
        dev-my-app-b58bcb4b8-gm7sq   0/1     Pending             0          0s
        dev-my-app-b58bcb4b8-gm7sq   0/1     Pending             0          0s
        dev-my-app-b58bcb4b8-gm7sq   0/1     ContainerCreating   0          0s
        dev-my-app-b58bcb4b8-gm7sq   0/1     Running             0          2s
        dev-my-app-b58bcb4b8-gm7sq   1/1     Running             0          13s
        #
        $ kubectl get po -n staging -w
        NAME                              READY   STATUS    RESTARTS   AGE
        staging-my-app-787875fb78-6mlrv   1/1     Running   0          33s
        staging-my-app-787875fb78-h567t   1/1     Running   0          111m
        staging-my-app-787875fb78-j2vk4   1/1     Running   0          111m
        ```

#### CICD Flow Test

In this test we will do a combined CI(Tekton) and CD(Flux) automation test. 

1.  Push a change to the python application
2.  Commit the change to ``app-source`` git repository
3.  Let tekton detect the change in the repository and clone the repository
4.  Tekton to build and push a new image to the registry
5.  Flux to detect the change in the container registry and update the ``Deployment`` in the ``gitops-config`` git repository and update the deployments in the ``nkpcicd`` cluster

---

1. Go to ``VSCode`` > Terminal
2. Check the current deployment's image and make a note of it
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        k get deploy dev-my-app -n dev -ojsonpath='{.spec.template.spec.containers[0].image}'
        ```
    
    === ":octicons-command-palette-16: Command output"
    
         ```bash
        docker.io/_your_git_handle/app-source:3338bbe
        ```

3. Create a small change to the application source code and push to git hub
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        cd $HOME/cicd/app-source/
        echo "# Testing first CICD" >> app.py
        git add .
        git commit -am "Chore: Testing first CICD flow"
        git push
        cd ..
        ```
    
    === ":octicons-command-palette-16: Sample command"
    
        ```bash
        [main bdd2a1b] Chore: Testing first CICD flow
        1 file changed, 1 insertion(+)
        Enumerating objects: 5, done.
        Counting objects: 100% (5/5), done.
        Delta compression using up to 12 threads
        Compressing objects: 100% (3/3), done.
        Writing objects: 100% (3/3), 307 bytes | 307.00 KiB/s, done.
        Total 3 (delta 2), reused 0 (delta 0), pack-reused 0
        remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
        To https://github.com/ariesbabu/app-source.git
        eb9a379..bdd2a1b  main -> main
        ```
    
    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        [main bdd2a1b] Chore: Testing first CICD flow
        1 file changed, 1 insertion(+)
        Enumerating objects: 5, done.
        Counting objects: 100% (5/5), done.
        Delta compression using up to 12 threads
        Compressing objects: 100% (3/3), done.
        Writing objects: 100% (3/3), 307 bytes | 307.00 KiB/s, done.
        Total 3 (delta 2), reused 0 (delta 0), pack-reused 0
        remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
        To https://github.com/ariesbabu/app-source.git
        eb9a379..bdd2a1b  main -> main
        ```

4. Observe the ``PipelineRun`` logs using ``tkn`` command
   
    === ":octicons-command-palette-16: Command"
    
        ```bash
        tkn pipelinerun list 
        tkn pipelinerun logs --last -f 
        ```
    === ":octicons-command-palette-16: Command output"
    
        ```text hl_lines="12-13 67-68"
        $ tkn pipelinerun list 
        #
        tkn pipelinerun list 
        NAME                       STARTED          DURATION   STATUS
        build-triggered-xkxkt      32 seconds ago   23s        Succeeded

        $  tkn pipelinerun logs --last -f 
        #
        [build-image : build-and-push] INFO[0000] Retrieving image manifest python:3.12-slim   
        [build-image : build-and-push] INFO[0000] Retrieving image python:3.12-slim from registry index.docker.io 
        [build-image : build-and-push] INFO[0001] Retrieving image manifest python:3.12-slim   
        [build-image : build-and-push] INFO[0001] Returning cached image manifest              
        [build-image : build-and-push] INFO[0001] Built cross stage deps: map[]                
        [build-image : build-and-push] INFO[0001] Retrieving image manifest python:3.12-slim   
        [build-image : build-and-push] INFO[0001] Returning cached image manifest              
        [build-image : build-and-push] INFO[0001] Retrieving image manifest python:3.12-slim   
        [build-image : build-and-push] INFO[0001] Returning cached image manifest              
        [build-image : build-and-push] INFO[0001] Executing 0 build triggers                   
        [build-image : build-and-push] INFO[0001] Building stage 'python:3.12-slim' [idx: '0', base-idx: '-1'] 
        [build-image : build-and-push] INFO[0001] Checking for cached layer docker.io/ariesbabu/app-source-cache:d5894a48dadadea8a0ccb1abca54eeab333b15a9009c1e7357e837bf2d21cafa... 
        [build-image : build-and-push] INFO[0002] Using caching version of cmd: RUN useradd -u 1001 -m appuser 
        [build-image : build-and-push] INFO[0002] Checking for cached layer docker.io/ariesbabu/app-source-cache:d47dbdb272eb6f36798a009ed40a006fe8b623d6ef12b15ccaf7659d591f3dab... 
        [build-image : build-and-push] INFO[0002] Using caching version of cmd: RUN pip install --no-cache-dir -r requirements.txt 
        [build-image : build-and-push] INFO[0002] Cmd: USER                                    
        [build-image : build-and-push] INFO[0002] Cmd: EXPOSE                                  
        [build-image : build-and-push] INFO[0002] Adding exposed port: 8000/tcp                
        [build-image : build-and-push] INFO[0002] Unpacking rootfs as cmd COPY requirements.txt . requires it. 
        [build-image : build-and-push] INFO[0005] ARG APP_VERSION=dev                          
        [build-image : build-and-push] INFO[0005] No files changed in this command, skipping snapshotting. 
        [build-image : build-and-push] INFO[0005] ARG GIT_SHA=dev                              
        [build-image : build-and-push] INFO[0005] No files changed in this command, skipping snapshotting. 
        [build-image : build-and-push] INFO[0005] ARG BUILD_TIME=dev                           
        [build-image : build-and-push] INFO[0005] No files changed in this command, skipping snapshotting. 
        [build-image : build-and-push] INFO[0005] ENV APP_VERSION=${APP_VERSION} GIT_SHA=${GIT_SHA} BUILD_TIME=${BUILD_TIME} 
        [build-image : build-and-push] INFO[0005] No files changed in this command, skipping snapshotting. 
        [build-image : build-and-push] INFO[0005] RUN useradd -u 1001 -m appuser               
        [build-image : build-and-push] INFO[0005] Found cached layer, extracting to filesystem 
        [build-image : build-and-push] INFO[0005] WORKDIR /app                                 
        [build-image : build-and-push] INFO[0005] Cmd: workdir                                 
        [build-image : build-and-push] INFO[0005] Changed working directory to /app            
        [build-image : build-and-push] INFO[0005] Creating directory /app with uid -1 and gid -1 
        [build-image : build-and-push] INFO[0005] Taking snapshot of files...                  
        [build-image : build-and-push] INFO[0005] COPY requirements.txt .                      
        [build-image : build-and-push] INFO[0005] Taking snapshot of files...                  
        [build-image : build-and-push] INFO[0005] RUN pip install --no-cache-dir -r requirements.txt 
        [build-image : build-and-push] INFO[0005] Found cached layer, extracting to filesystem 
        [build-image : build-and-push] INFO[0007] COPY app.py .                                
        [build-image : build-and-push] INFO[0007] Taking snapshot of files...                  
        [build-image : build-and-push] INFO[0007] USER appuser                                 
        [build-image : build-and-push] INFO[0007] Cmd: USER                                    
        [build-image : build-and-push] INFO[0007] No files changed in this command, skipping snapshotting. 
        [build-image : build-and-push] INFO[0007] EXPOSE 8000                                  
        [build-image : build-and-push] INFO[0007] Cmd: EXPOSE                                  
        [build-image : build-and-push] INFO[0007] Adding exposed port: 8000/tcp                
        [build-image : build-and-push] INFO[0007] No files changed in this command, skipping snapshotting. 
        [build-image : build-and-push] INFO[0007] CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"] 
        [build-image : build-and-push] INFO[0007] No files changed in this command, skipping snapshotting. 
        [build-image : build-and-push] INFO[0007] Pushing image to docker.io/ariesbabu/app-source:027ad8c 
        [build-image : build-and-push] INFO[0011] Pushed index.docker.io/ariesbabu/app-source@sha256:52ce84ac64ad3468257eddba2530dec97ea583873a6aaad2c2fc33a6df102961 
        ```

4. Watch the pods in the dev and staging namespace for at least 1 minute interval. The additional pod will be spinning up soon.

    === ":octicons-command-palette-16: Command"
    
        ```bash
        kubectl get po -n dev -w
        kubectl get po -n staging -w
        ```

    === ":octicons-command-palette-16: Command output"
    
        ```{ .text .no-copy }
        $ kubectl get po -n dev -w
        #
        NAME                         READY   STATUS    RESTARTS   AGE
        dev-my-app-b58bcb4b8-gm7sq   1/1     Running   0          16h
        dev-my-app-b58bcb4b8-nplmm   1/1     Running   0          19h
        dev-my-app-b58bcb4b8-vdp5d   1/1     Running   0          19h
        dev-my-app-69c89bc7d7-zlvrb   0/1     Pending   0          0s
        dev-my-app-69c89bc7d7-zlvrb   0/1     Pending   0          0s
        dev-my-app-69c89bc7d7-zlvrb   0/1     ContainerCreating   0          0s
        dev-my-app-69c89bc7d7-zlvrb   0/1     Running             0          4s
        dev-my-app-69c89bc7d7-zlvrb   1/1     Running             0          16s
        dev-my-app-b58bcb4b8-nplmm    1/1     Terminating         0          19h
        #
        $ kubectl get po -n staging -w
        NAME                              READY   STATUS    RESTARTS   AGE
        staging-my-app-787875fb78-6mlrv   1/1     Running   0          33s
        staging-my-app-787875fb78-h567t   1/1     Running   0          111m
        staging-my-app-787875fb78-j2vk4   1/1     Running   0          111m
        ```

We have seen end-to-end event. When a developer pushes an application code change, Tekton builds a new image and Flux detects the new image and deploys to the kubernetes cluster. This is completely automated and checks can be implemented in several phases of this pipeline. 

