---

title: "Flow CNI - Pre-requisites"
description: ""

---

!!! example "Pre-requisites"

    To enable and use Flow CNI to extend VPCs (VM-configured, container-only, or hybrid) to NKP-managed Kubernetes workload clusters, your Nutanix environment must meet the following hardware, software, and configuration prerequisites.

    ### Minimum Software Versions

    **For VPCs with VM-only, container-only, or hybrid (VMs and containers) configurations:**

    * **Nutanix Kubernetes Platform (NKP):** Version ``2.17`` or later (must be running the Rocky Linux operating system on NKP nodes)
    * **Ubuntu OS support** - not available yet. This is upcoming in a future release..
    * **AOS (Acropolis Operating System):** Version ``7.6`` or later
    * **AHV (Acropolis Hypervisor):** Version ``11.2`` or later
    * **Prism Central:** Version ``pc.7.6`` or later
    * **Network Controller:** Version ``7.6.0`` or later

### Resource and Configuration Requirements

!!! warning 
    Only Network Controller (Flow deployed in the **Integrated** with Prism Central mode) supports Flow CNI. The Flow Controller (Flow deployed in the Standalone mode) does not support Flow CNI.

* **Flow Deployment Mode:** Enable Flow in the **Integrated** with Prism Central (Network Controller) mode in Prism Central.
* **Underlay Networking:** Ensure that the underlying AHV cluster nodes are successfully connected to a managed VLAN Basic (AHV-managed) subnet.
* **Prism Central Sizing:** Onboard the Kubernetes workload cluster to a **Prism Central** instance when using Flow CNI to extend VPCs with VM configurations.
* **Helm & Credentials:** Install Helm on the deployment system, and generate base64 authorization credentials using an access token from the Flow Network and Security downloads page to pull the Flow CNI Helm package.
* **Cluster Manifest:** Provision the NKP-managed Kubernetes workload cluster using the cluster manifest and Flow CNI YAML resource for Flow CNI services.
* **Namespace Consistency:** The cluster name and namespace defined in all custom resources must perfectly match the specific Kubernetes workload clusters during provisioning.

### IP Address Planning
* **CIDR Non-Overlap:** Ensure that the CIDRs designated for Kubernetes pods and services **do not overlap** with the CIDRs of the Nutanix VPCs.
* **Container-Only VPCs:** Ensure the Pod CIDR for each container-only VPC is unique and does not overlap with the Pod CIDR of any other VPC on the same cluster, including the Shared Services VPC.
* **Hybrid VPCs:** For hybrid VPCs on the same cluster, ensure VM subnets and Pod CIDRs are unique and do not overlap with any other hybrid VPC on that cluster.
* **Prism Central Reserved Subnets:** Ensure node, pod, and service CIDRs do not overlap with the subnets reserved by Microservices Infrastructure in Prism Central.

### Kubernetes Namespace Requirements
* **Pod-Free Namespaces:** Ensure selected Kubernetes namespaces for a VPC do not contain any existing pods at the time of VPC creation.
* **Unique Mapping:** Ensure selected Kubernetes namespaces are not already mapped to another VPC on the same cluster.
* **Single Mapping Model:** For each Kubernetes cluster, use only **one** hybrid VPC-to-namespace mapping model:
    * Map **all** namespaces of the cluster to a single VPC, **or**
    * Map a set of namespaces to one or more additional VPCs.
    *(A single cluster cannot mix both mapping models simultaneously).*

For more information on deploying Flow in the Integrated with Prism Central mode, see the [Flow Management Reference Guide](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Virtual-Networking-Guide-v7_6_0:ear-flow-cni-prerequisites-pc-r.html).
