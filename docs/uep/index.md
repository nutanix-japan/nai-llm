---

title: "Nutanix AI Unified Endpoints"
description: "NAI Unified Endpoints acting as a centralized inferencing control plane, a Unified Endpoint allows you to route, secure, and govern all your generative AI models—both self-hosted and cloud-based—behind a single, OpenAI-compatible API endpoint, all without needing to refactor your application code."

---

# Getting Started: Mastering Nutanix Enterprise AI Unified Endpoints

## Introduction

Welcome to the **Nutanix Enterprise AI (NAI) Unified Endpoints** lab. As organizations scale their generative AI initiatives, managing multiple AI model providers quickly becomes a governance and security challenge. Platform engineering and IT teams often struggle with scattered API keys, a lack of visibility into token spend, and application downtime when a cloud model experiences an outage or hits a rate limit.

Nutanix Enterprise AI v2.7 introduces the **Agent Gateway and Unified Endpoints** to solve these challenges. Acting as a centralized inferencing control plane, a Unified Endpoint allows you to route, secure, and govern all your generative AI models—both self-hosted and cloud-based—behind a single, OpenAI-compatible API endpoint, all without needing to refactor your application code.

In this lab, you will get hands-on experience configuring and managing Unified Endpoints to build a resilient, secure, and observable enterprise AI architecture.

!!! example "Pre-requisites"

    Before starting the lab exercises, please ensure you have the following:

    * Access to a Nutanix Enterprise AI (``v2.7.0`` or higher) environment running on a compatible Kubernetes cluster (e.g., NKP, EKS, AKS, GKE).
    * **Admin** or appropriate **User** permissions within the Nutanix Enterprise AI dashboard.
    * Valid API keys for any third-party cloud AI providers you wish to test (e.g., OpenAI, Anthropic) configured as Third-Party Credentials.
    * A basic understanding of REST APIs and generative AI concepts (tokens, context windows, etc.).
    * An API testing tool (such as Postman, AnythingLLM, or simple `curl` commands via terminal) to test your endpoints.

## Lab Objectives

* **Abstract Model Providers:** Consolidate local, self-hosted models (e.g., Hugging Face, NVIDIA NIM) and remote cloud providers (e.g., OpenAI, Anthropic, Google Gemini, AWS Bedrock) behind a single unified interface.
* **Ensure High Availability:** Configure load balancing and automatic fallback mechanisms so that if a primary model goes down, traffic seamlessly routes to a backup model.
* **Implement Enterprise Governance:** Manage credentials securely to eliminate API key sprawl and apply Role-Based Access Control (RBAC).
* **Control AI Costs:** Set up granular and global rate-limiting to protect organizational token budgets and prevent surprise cloud billing.
* **Monitor and Audit:** Utilize the NAI Observability Dashboard to track token consumption, correlate AI usage to actual costs, and audit request logs.


## Use Cases Covered

This lab is divided into sequential modules, each illustrating a practical, real-world use case for the Nutanix Unified Endpoint:

### Unified Model Routing and Provider Abstraction
Learn how to create a single Unified Endpoint that routes application requests to different backend models based on the required workload, shielding developers from the complexity of managing multiple provider APIs.

### Zero-Downtime Resilience (Fallback & Load Balancing)
Simulate a provider outage or strict rate limit. You will configure the Unified Endpoint to automatically fail over to a secondary model (e.g., falling back from a cloud-hosted LLM to a local, self-hosted LLM running on Nutanix) ensuring uninterrupted application uptime.

### API Key Consolidation & Credential Management
See how NAI acts as a secure proxy. We will abstract third-party API credentials away from developers, replacing them with a single, NAI-scoped API key with strict access controls. 

### Cost Control via Dual-Layer Rate Limiting
Configure granular rate limits to prevent specific users, teams, or applications from exhausting your organization's token allocation.

---
*Ready to take control of your AI deployments? Let's get started!*