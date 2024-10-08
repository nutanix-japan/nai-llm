# Getting Started

This guide covers two different scenarios for deploying Nutanix Enterprise AI [NAI] (previously known as GPT-In-A-Box).  

The first scenario is a walkthrough on How-To [Deploy Nutanix Enterprise AI with Nutanix Kubernetes Platform (NKP)](#deploy-nutanix-enterprise-ai-with-nutanix-kubernetes-platform-nkp), and the second scenario covers the (soon to be deprecated) option on How-To [Deploy GPT-In-A-Box v1 Nutanix Validated Design (NVD) with NKE](#deploy-gpt-in-a-box-v1-nutanix-validated-design-nvd-with-nke) .

Each scenario goes through four phases to prepare the infrastructure on which you can deploy Nutanix Enterprise AI applications.


```mermaid
stateDiagram-v2
    direction LR
    
    state PrepWorkstation {
        [*] --> GenrateRSAKeys
        GenrateRSAKeys --> InstallTofu
        InstallTofu --> InstallVSCode
        InstallVSCode --> [*]
    }

    state DeployJumpHost {
        [*] --> CreateCloudInit
        CreateCloudInit --> CreateJumpHostVM
        CreateJumpHostVM --> DeployNaiUtils
        DeployNaiUtils --> [*]
    }

    PrepWorkstation --> DeployJumpHost 
    DeployJumpHost --> DeployNkp : Option A
    DeployNkp --> DeployNai
    DeployJumpHost --> DeployNke : Option B
    DeployNke --> DeployGiabGitOps
```

## Deploy Nutanix Enterprise AI with Nutanix Kubernetes Platform (NKP)

1. Prepare Local Development Workstation (Mac/Windows)
2. Deploy Jumphost VM
3. Deploy Nutanix Kubernetes Platform (NKP) Management Cluster
4. Deploy Nutanix Enterprise AI (NAI)

```mermaid
stateDiagram-v2
    direction LR
    
    state DeployNKP {
        [*] --> CreateNkpMachineImage
        CreateNkpMachineImage --> CreateNkpSelfManagedCluster
        CreateNkpSelfManagedCluster --> DeployGPUNodePool
        DeployGPUNodePool --> [*]
    }
    state DeployNai {
        [*] --> PrepareNai
        PrepareNai --> DeployNaiHelm 
        DeployNaiHelm --> [*]
    }

    [*] --> PrepWorkstation
    PrepWorkstation --> DeployJumpHost
    DeployJumpHost --> DeployNKP
    DeployNKP --> DeployNai
    DeployNai --> [*]
```

## Deploy GPT-In-A-Box (v1) Nutanix Validated Design (NVD) with NKE

1. Prepare your Local Development Workstation (Mac/Windows)
2. Deploy Jumphost VM
3. Deploy Nutanix Kubernetes Engine (NKE) - Management Cluster
4. Deploy Nutanix Kubernetes Engine (NKE) - Development Workload Cluster
5. Deploy Nutanix GPT-In-A-Box (v1) Validated Design Reference RAG Applications using Flux GitOps

```mermaid
stateDiagram-v2
    direction LR
    
    state DeployNKE {
        [*] --> CreateTofuWorkspaces
        CreateTofuWorkspaces --> CreateMgtK8SCluster
        CreateMgtK8SCluster --> CreateDevK8SCluster
        CreateDevK8SCluster --> DeployGPUNodePool
        DeployGPUNodePool --> [*]
    }
    state DeployGiabGitOps {
        [*] --> BootstrapFlux
        BootstrapFlux --> DeployAIApps
        DeployAIApps --> [*]
    }

    [*] --> PrepWorkstation
    PrepWorkstation --> DeployJumpHost
    DeployJumpHost --> DeployNKE
    DeployNKE --> DeployGiabGitOps
    DeployGiabGitOps --> [*]
```
