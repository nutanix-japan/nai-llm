# Introduction

This section will take you through install NKE(Kubernetes) on Nutanix cluster as we will be deploying AI applications on these kubernetes clusters. 

This section will expand to other available Kubernetes implementations on Nutanix.


# NKE Setup

We will use Infrastucture as Code framework to deploy NKE kubernetes clusters. 

## Pre-requsitis

- NKE is enabled on Nutanix Prism Central
- NKE is at version 1.8 (updated through LCM)
- NKE OS at version 1.5

## Preparing OpenTofu 

On your Linux workstation run the following scripts to install OpenTofu. See [here]for latest instructions and other platform information. 

```bash
# Download the installer script:
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
# Alternatively: wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh

# Give it execution permissions:
chmod +x install-opentofu.sh

# Please inspect the downloaded script
# Run the installer:
./install-opentofu.sh --install-method rpm
```

## NKE High Level Cluster Design

