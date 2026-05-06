---

title: "Nutanix Cloud Native and AI Solutions"
description: "This project will take your through design, sizing and hosting of Nutanix Cloud Native AI applications. Intended to be used by any Nutanix user to setup and run LLMs, Unified Endpoints, RAG, MCP other AI applications. The project also takes the curious user through setting up Nutanix Kubernetes Platform for various requirements"

---

# Welcome

## Introduction

### **The Nutanix Cloud Native & AI (NAI) Unofficial Field Guide**

---

This site follows **Design > Size > Deploy** model.

---

!!! warning

    **Status:** *This site is unofficial, unsupported, rigourously tested and frequently updated.*

This community-maintained resource provides a practical, **Design > Size > Deploy** framework for architects and engineers looking to harness the power of Nutanix for modern workloads(including AI). While unofficial and unsupported, this site is actively maintained to bridge the gap between high-level documentation and real-world implementation.

**What’s Inside:**

  * **Infrastructure Design:** Architectural deep dives into Nutanix Kubernetes Platform (NKP), Nutanix Enterprise AI (NAI), and GPT-in-a-Box.
  * **Rapid Deployment:** Step-by-step tutorials to stand up Nutanix clusters, NKP, and Large Language Models (LLMs) in record time.
  * **Advanced Scenarios:** Comprehensive guides for air-gapped environments, CI/CD pipelines, and NDB (Nutanix Database Service) integration.
  * **Interactive Simulators:** Visual tools for LLM model selection, pod scheduling, and K8s deployment strategies.
  * **Developer-First:** Built entirely in Markdown—if you find a bug or a better way to do things, the repo is open for PRs.

---

## Design Infra, K8S and AI Apps
---

<div class="grid cards" markdown>

-   :material-robot:{ .lg .middle } __AI Apps Design on Nutanix__

    ---

    Start here to read about gathering requirements and considering general design considerations.

    [:octicons-arrow-right-24: Start designing](conceptual/conceptual.md)

    [:octicons-arrow-right-24: Start sizing :material-size-s: :material-size-m: :material-size-l: ](sizing/sizing.md)

</div>

## Deploy Infra
---

<div class="grid cards" markdown>

-   :material-table-column-plus-after:{ .lg .middle } __Set up Nutanix Cluster in an hour__

    ---

    You can setup a Nutanix cluster in under an hour using Foundation to prepare your infrastructure.

    [:octicons-arrow-right-24: Setup a Nutanix cluster](https://nhtd1.howntnx.win/diyfoundation/diyfoundation/)
  
    [:octicons-arrow-right-24: Deploy Prism Central](https://nhtd1.howntnx.win/pcdeploy/pcdeploy/)

</div>

## Deploy K8S 
---

<div class="grid cards" markdown>

-   :material-kubernetes:{ .lg .middle } __Set up Nutanix Kubernetes Platform [ NKP ] in 10 minutes__

    ---

    Setup a Nutanix NKP K8S cluster to deploy your workloads.

    [:octicons-arrow-right-24: Setup Nutanix Kubernetes Platform](infra/infra_nkp.md)

</div>


<div class="grid cards" markdown>

-   :material-kubernetes:{ .lg .middle } __Set up NKP Advanced__

    ---

    Customize what NKP components to deploy

    [:octicons-arrow-right-24: Setup Customized NKP](appendix/infra_nkp_hard_way.md) 


-   :material-kubernetes:{ .lg .middle } __Setup NKP Air-Gapped__

    ---

    Setup NKP on air-gapped cluster

    [:octicons-arrow-right-24: Air-gapped Install](appendix/infra_nkp_airgap.md)

</div>

## Deploy AI Apps
---

<div class="grid cards" markdown>

-   :material-clock-fast:{ .lg .middle } __Set up Nutanix Enterprise AI (NAI) in 60 minutes__

    ---

    Install and host an LLM on Nutanix Enterprise AI (NAI) platform.

    [:octicons-arrow-right-24: Start](airgap_nai/index.md)


</div>

<div class="grid cards" markdown>

-   :material-clock-fast:{ .lg .middle } __Set up LLM with RAG on Nutanix in 10 minutes - soon to be deprecated__
  
    ---

    Install and host a LLM on Nutanix platform using this framework in this [repo](https://github.com/nutanix-japan/sol-cnai-infra.git). Get up and running in minutes.

    This site will also take you through implementation using **NKE** clusters and **GPT-in-a-Box v1** NVD Reference App.

    [:octicons-arrow-right-24: Start](llmmgmt/index.md)

</div>

## Others
---

<div class="grid cards" markdown>

-   :fontawesome-brands-markdown:{ .lg .middle } __It's just Markdown__

    ---

    Everything is this site is written in .md file. When you see something in this [repo](https://github.com/nutanix-japan/nai-llm), say something by submitting a PR. 
    
    We review PR on a day-to-day basis.

    [:octicons-arrow-right-24: Contributing](contributing.md)

</div>

<div class="grid cards" markdown>

:simple-nutanix: __Nutanix__ components used in this project
{ .card }

:material-hammer-screwdriver: [__Open Source Tools__](tools/tools.md) used in this projects
{ .card }

:octicons-cross-reference-16: [__Appendix__](appendix/appendix.md)
{ .card }

> :material-server-off: __Baremetal servers__ ... huh?

</div>