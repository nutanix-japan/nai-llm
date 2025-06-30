# Getting Started

In this part of the lab we will deploy a workload on NKP cluster which stores its database in a NDB deployed Postgres server.

We will also deploy a Kubernetes cluster so far as per the NVD [design requirements](../conceptual/conceptual.md#management-kubernetes-cluster).

Deploy the NKP kubernetes cluster with the following components:

- 3 x Control plane nodes
- 3 x Worker nodes

The following is the flow of the NAI lab:

```mermaid
stateDiagram-v2
    direction LR

    state PrepEnvironment {
        [*] --> PrepVM
        PrepVM --> [*]
    }

    state InstallNDBOperator {
        [*] --> InstallNDBOp
        InstallNDBOp --> [*]
    }

    state ConfigureSecrets {
        [*] --> CreateSecrets
        CreateSecrets --> [*]
    }

    state SetupNDB {
        [*] --> GetUUID
        GetUUID --> CreateProfile
        CreateProfile --> DeployDB
        DeployDB --> [*]
    }

    state VerifyDB {
        [*] --> CheckDB
        CheckDB --> [*]
    }

    state DeployApplication {
        [*] --> DeployApp
        DeployApp --> [*]
    }

    state ConfigureIngress {
        [*] --> CreateIngress
        CreateIngress --> [*]
    }

    state TestApplication {
        [*] --> TestFrontend
        TestFrontend --> TestBackend
        TestBackend --> CheckDBData
        CheckDBData --> [*]
    }

    state CleanupResources {
        [*] --> Cleanup
        Cleanup --> [*]
    }

    [*] --> PrepEnvironment
    PrepEnvironment --> InstallNDBOperator
    InstallNDBOperator --> ConfigureSecrets
    ConfigureSecrets --> SetupNDB
    SetupNDB --> VerifyDB
    VerifyDB --> DeployApplication
    DeployApplication --> ConfigureIngress
    ConfigureIngress --> TestApplication
    TestApplication --> CleanupResources
    CleanupResources --> [*]
```

