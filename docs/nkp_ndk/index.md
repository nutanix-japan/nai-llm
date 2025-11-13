# Nutanix Data Services for Kubernetes (NDK) Lab Guide

## Introduction

Nutanix Data Services for Kubernetes (NDK) simplifies the management of stateful applications on Kubernetes by providing robust data protection, replication, and recovery capabilities. This lab guide is designed to help you explore NDK's features through hands-on exercises, covering setup, snapshot management, cross-namespace operations, and multi-cluster replication. The labs progress from single-cluster to multi-cluster workflows, including new features introduced in NDK ``2.0.0``, such as support for Read-Write-Many (RWX), Nutanix Files Replication and Protection.

## Lab Content

1. **Set up source NKP in Primary PC**  
   Configure the Nutanix Kubernetes Platform (NKP) on the primary Prism Central (PC) to serve as the source environment for NDK operations.

2. **Set up destination NKP in Secondary PC**  
   Configure NKP on the secondary Prism Central to act as the destination environment for replication and recovery workflows.

3. **Install NDK on the Primary PC**  
   Install NDK on the primary PC, disabling TLS for simplified setup.

4. **Install NDK on the Secondary PC**  
   Install NDK on the secondary PC, disabling TLS to match the primary setup.

**Single PC/PE/K8s Workflows** 

   - **Workflow 1: Application Snapshot & Restore**  
     Create and restore application snapshots within a single Prism Central/Prism Element/Kubernetes environment.  
   - **Workflow 2: Application Cross-Namespace Restore using ReferenceGrant**  
     Perform application restoration across namespaces using ReferenceGrant to manage access between source and target namespaces.  
   - **Workflow 3: Schedule Protection Policy/Plan**  
     Configure and schedule a protection policy to automate application backups.  
   - **New (NDK 2.0.0) - Workflow 4: Application Snapshot & Restore with RWX/Files**  
     Explore snapshot and restore functionality for applications using Read-Write-Many (RWX) file storage, a new feature in NDK ``2.0.0``.

**Multi PC/PE/K8s Workflows**

   - **Workflow 1: Snapshot Asynchronous Replication & Recovery**  
     Set up and test asynchronous replication of snapshots across multiple clusters and recover applications.  
   - **Workflow 2: Multi-Cluster (3 PE/3 K8s, 2 PC) Asynchronous Replication**  
     Configure asynchronous replication across three Prism Elements and Kubernetes clusters managed by two Prism Central instances.  
   - **New (NDK 2.0.0) - Workflow 3: Multi-Cluster (3 PE/3 K8s, 2 PC) Asynchronous + Synchronous Replication**  
     Implement and test both asynchronous and synchronous replication for applications across multiple clusters, leveraging NDK ``2.0.0`` enhancements.