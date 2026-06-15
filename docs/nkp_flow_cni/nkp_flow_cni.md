---

title: "Flow CNI - Pre-requisites"
description: ""

---

!!! example "Pre-requisites"

    To enable and use Flow CNI to extend VM-configured VPCs to NKP-managed Kubernetes workload clusters, your Nutanix environment must meet the following hardware, software, and configuration prerequisites.

    ### Minimum Software Versions
    * **Nutanix Kubernetes Platform (NKP):** Version ``2.15`` or later (must be running the Rocky Linux operating system)
    * **AOS (Acroplis Operating System):** Version ``7.5`` or later
    * **AHV (Acropolis Hypervisor):** Version ``11.0`` or later
    * **Prism Central:** Version ``pc.7.5`` or later
    * **Network Controller:** Version ``7.0.0`` or later

### Resource and Configuration Requirements

!!! warning 
      Only Network Controller (Flow deployed in the **Integrated** with Prism Central mode) supports Flow CNI. The Flow Controller (Flow deployed in the Standalone mode) does not support Flow CNI.


* Enable Flow in the **Integrated** with Prism Central (Network Controller) mode in Prism Central.
* **Underlay Networking:** Ensure that the underlying AHV cluster nodes are successfully connected to a VLAN Basic subnet.
* **IP Address Management (IPAM):** Ensure that the CIDR blocks designated for your Kubernetes pods and services **do not overlap** with the CIDRs of the Nutanix VPCs.
* **Namespace Consistency:** The cluster name and namespace defined in all custom resources must perfectly match the specific Kubernetes workload clusters during provisioning.

* Provision the NKP-managed Kubernetes workload cluster with the Flow CNI YAML for Flow CNI services in the Kubernetes cluster.
Onboard the Kubernetes cluster to an **extra-large (XL) Prism Central instance** to use Flow CNI to extend the VPCs with VM configurations to the Kubernetes workload clusters.
* Ensure that the AHV cluster nodes are connected to a VLAN Basic subnet.
* Ensure that the CIDRs for pods and services do not overlap with the CIDRs of the VPCs.

For more information on deploying Flow in the Integrated with Prism Central mode, see the [Flow Management Reference Guide](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Virtual-Networking-Guide-v7_0_0:ear-flow-cni-prerequisites-pc-r.html).
