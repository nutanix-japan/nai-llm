# Welcome

## Introduction

This project will take your through design and hosting AI applications on Nutanix.

Intended to be used by any Nutanix user to setup and run LLMs, LLM with RAG, Support GPT and other AI applications. 

This site follows **Design > Deploy** model.

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

-   :material-kubernetes:{ .lg .middle } __Set up Nutanix Karbon Engine [ NKE ] in 10 minutes__

    ---

    Setup a NKE K8S cluster in under an hour using Foundation to prepare your infrastructure.

    [:octicons-arrow-right-24: Setup Nutanix Karbon Engine](infra/infra_nke.md)

-   :material-kubernetes:{ .lg .middle } __Set up Nutanix Kubernetes Platform [ NKP ] in 30 minutes__

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

    [:octicons-arrow-right-24: Start](iep/index.md)

-   :material-clock-fast:{ .lg .middle } __Set up Air-gapped Nutanix Enterprise AI (NAI)__

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