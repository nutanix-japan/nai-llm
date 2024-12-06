# Install Harbor

In this section, we will install Harbor container registry in the cluster.

## Prerequisites

We will use the jumphost to install and host Harbor container registry.

Since the jumphost also will host the ``kind`` cluster, we will need to ensure that the jumphost has enough resources.

| #    | CPU | Memory | Disk | Purpose | 
|-----| --- | ------ | ---- |----------|
|Before | 4  | 16 GB   | 300 GB |  ``Jumphost`` + ``Tools``|
|After |   `8`   | 16 GB   | 300 GB | ``Jumphost`` + ``Tools`` + ``Harbor`` + ``kind`` |

!!! note 
    If the jumphost does not have the resources, make sure to stop the jumphost and add the resources in Prism Central.

## Install Harbor

Follow the instructions in **Appendix** section of this site to deploy Harbor container registry.

> [Harbor Container Registry](../infra/harbor.md)