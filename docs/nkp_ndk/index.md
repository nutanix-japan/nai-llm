# Nutanix Data Services for Kubernetes (NDK) Lab Guide

## Introduction

Nutanix Data Services for Kubernetes (NDK) simplifies the management of stateful applications on Kubernetes by providing robust data protection, replication, and recovery capabilities. This lab guide is designed to help you explore NDK's features through hands-on exercises, covering setup, snapshot management, cross-namespace operations, and multi-cluster replication. The labs progress from single-cluster to multi-cluster workflows, including new features introduced in NDK ``2.0.0``, such as support for Read-Write-Many (RWX), Nutanix Files Replication and Protection.

---

## Lab Content

<div class="grid cards" markdown>

-   :material-kubernetes:{ .lg .middle } __Set up source NKP in Primary and Secondary Sites__

    ---

    Start here to read about gathering requirements and considering general design considerations.

    [:octicons-arrow-right-24: Setup NKP on Primary Site](../infra/infra_nkp.md)

    [:octicons-arrow-right-24: Setup NKP on Secondary Site](../infra/infra_nkp.md)

</div>

<div class="grid cards" markdown>

-   :material-kubernetes:{ .lg .middle } __Set up source NDK in Primary and Secondary Sites__

    ---

    Start here to read about gathering requirements and considering general design considerations.

    [:octicons-arrow-right-24: Setup NDK on Primary Site](../nkp_ndk/nkp_ndk.md)

    [:octicons-arrow-right-24: Setup NDK on Secondary Site](../nkp_ndk/nkp_ndk_k8s_replication/#install-ndk-on-secondary-nkp-cluster.md)

</div>


---
**Single PC/PE/K8s Workflows** 

<div class="grid cards" markdown>

-   :material-content-duplicate:{ .lg .middle } __Application Snapshot & Restore__

    ---

    Create and restore application snapshots within a single Prism Central/Prism Element/Kubernetes environment. 

    [:octicons-arrow-right-24: Workflow](../nkp_ndk/nkp_ndk_singlek8s.md) 


-   :material-content-duplicate:{ .lg .middle } __Application Cross-Namespace Restore using ReferenceGrant__

    ---

    Perform application restoration across namespaces using ReferenceGrant to manage access between source and target namespaces.

    [:octicons-arrow-right-24: Workflow](../nkp_ndk/nkp_ndk_singlek8s/#cross-namespace-recovery)

-   :material-content-duplicate:{ .lg .middle } __Schedule Protection Policy/Plan__

    ---

    Configure and schedule a protection policy to automate application backups. 

    **Under construction** :construction_site: :construction:

    

-   :material-content-duplicate:{ .lg .middle } __New (NDK ``2.0.0``) Application Snapshot & Restore with RWX/Files__

    ---

    Explore snapshot and restore functionality for applications using Read-Write-Many (RWX) file storage, a new feature in NDK ``2.0.0``.

    [:octicons-arrow-right-24: Workflow](../nkp_ndk/nkp_ndk_singlek8s_files/)

</div>

---
**Multi PC/PE/K8s Workflows**


<div class="grid cards" markdown>

-   :material-content-duplicate:{ .lg .middle } __Snapshot Asynchronous Replication & Recovery__

    ---

    Set up and test asynchronous replication of snapshots across multiple clusters and recover applications. 

    [:octicons-arrow-right-24: Workflow](../nkp_ndk/nkp_ndk_k8s_replication.md) 


-   :material-content-duplicate:{ .lg .middle } __Multi-site (3 PE/3 K8s, 2 PC) Asynchronous Replication__

    ---

    Configure asynchronous replication across three Prism Elements and Kubernetes clusters managed by two Prism Central instances.

    **Under construction** :construction_site: :construction:

-   :material-content-duplicate:{ .lg .middle } __New (NDK ``2.0.0``) Multi-site Application Snapshot & Restore with RWX/Files Asynchronous__

    ---

    Implement and test asynchronous replication for applications across multiple NKP clusters, leveraging NDK ``2.0.0`` enhancements.

    Test cross-namespace recovery. 

    [:octicons-arrow-right-24: Workflow](../nkp_ndk/nkp_ndk_k8s_files_replication.md)

</div>
---