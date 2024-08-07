# Getting Started

We will go through four phases in this section to prepare infrastructure on which you can deploy AI applications.

1. Preparing your Local Workstation (Mac/Windows)
2. Deploying Jumphost VM
3. Deploying Kuberenetes
   1. Managment Cluster
   2. Dev Workload cluster

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
    state DeployK8S {
        [*] --> CreateTofuWorkspaces
        CreateTofuWorkspaces --> CreateMgtK8SCluster
        CreateMgtK8SCluster --> CreateDevK8SCluster
        CreateDevK8SCluster --> [*]
    }
    state DeployAIApps {
        [*] --> BootstrapK8S
        BootstrapK8S --> DeplyAIApps
        DeplyAIApps --> [*]
    }

    [*] --> PrepWorkstation
    PrepWorkstation --> DeployJumpHost
    DeployJumpHost --> DeployK8S
    DeployK8S --> DeployAIApps
    DeployAIApps --> [*]
```
