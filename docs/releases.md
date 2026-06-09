# Site Releases

Track the progression and added content of the Nutanix Cloud Native and AI Solutions documentation site over time.

---

### June 09, 2026

**[Gitless GitOps CD lab with Flux](nkp_tutorials/nkp_cicd_lab/gitless_gitops_lab.md)**

This demo packages Kubernetes manifests as an OCI artifact and stores them in a container registry. Flux watches that registry through an `OCIRepository`, th...

---

### June 04, 2026

**[Deploying Unified Endpoints](uep/iep_uep_test.md)**

6. Go to command line and test a query         !!! note

---

### June 01, 2026

**[Roadmap](roadmap.md)**

Detailed walk-through and deployment instructions.

**[Contributing](contributing.md)**

For more information about CLAs, please check out Alex Russell's excellent post, ["Why Do I Need to Sign This?"](https://infrequently.org/2008/06/why-do-i-ne...

**[nkp_cicd_prereq](nkp_tutorials/nkp_cicd_lab/nkp_cicd_prereq.md)**

Detailed walk-through and deployment instructions.

**[Get the ImageRepository name](nkp_tutorials/nkp_cicd_lab/nkp_cicd_tshooting.md)**

Apply it, wait for a reconcile, then read the error message — it prints the entire available data structure with real field names.

**[nkp_cd_setup](nkp_tutorials/nkp_cicd_lab/nkp_cd_setup.md)**

Detailed walk-through and deployment instructions.

**[nkp_ci_setup](nkp_tutorials/nkp_cicd_lab/nkp_ci_setup.md)**

Detailed walk-through and deployment instructions.

**[nkp_nai_n8n](nkp_tutorials/nkp_mcp_lab/nkp_nai_n8n.md)**

Detailed walk-through and deployment instructions.

**[Nutanix MCP Server](nkp_tutorials/nkp_mcp_lab/nkp_nai_mcp.md)**

9. Go to **Cline** chat and ask questions about the Nutanix PC environment

**[nkp_ndb_install_app](nkp_tutorials/nkp_ndb_lab/nkp_ndb_install_app.md)**

Detailed walk-through and deployment instructions.

**[Nutanix NKP and Nutanix NDB Integration](nkp_tutorials/nkp_ndb_lab/nkp_ndb_lab.md)**

4. Connect to the database:    ```bash    kubectl exec -it psql -n ndb -- psql -h dbforflower-svc -p 80 -U postgres -d predictiondb    ```    Enter `postgres...

**[Deploying Nutanix Enterprise AI (NAI) NVD Reference Application](airgap_nai/airgap_nai_deploy.md)**

This should resolve the issue the issue with the TGI image.

**[Install Harbor](airgap_nai/harbor.md)**

Follow the instructions in **Appendix** section of this site to deploy Harbor container registry.

**[Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](airgap_nai/airgap_nai_test.md)**

We have successfully deployed the following:    - Inferencing endpoint  - A sample chat application that uses NAI to provide chatbot capabilities

**[Pre-requisites for Deploying NAI](airgap_nai/airgap_nai_pre_reqs.md)**

Now we are ready to deploy our NAI workloads.

**[Deploy NKP Clusters](airgap_nai/infra_nkp_airgap.md)**

Now we are ready to deploy our AI workloads.

**[Deploying Private CA Certificate to NKP Cluster](appendix/nkp_cert_ds.md)**

9. Now that the manifests are applied, the CA certificate will be added to the trusted CA store on the nodes.

**[Deploy NKP Clusters](appendix/infra_nkp_hard_way.md)**

2. Delete the workload cluster

**[Appendix](appendix/opentofu.md)**

Remove-Item install-opentofu.ps1 ```

**[Deploy NKP Clusters](appendix/infra_nkp_airgap.md)**

Now we are ready to deploy our AI workloads.

**[Workstation Setup](infra/workstation.md)**

We will proceed to deploying jumphost VM.

**[Deploy NKE Clusters](infra/infra_nke.md)**

We now have a node that can be used to deploy AI applications and use the GPU.

**[Manually Creating Ubuntu Linux Jumphost VM on Nutanix AHV](infra/infra_jumphost.md)**

3. Change working directory and see ``Task`` help        ```bash     cd $HOME/sol-cnai-infra/ && task     ```

**[Deploy NKP Clusters](infra/infra_nkp.md)**

Now we are ready to deploy our AI workloads.

**[Deploy Jumphost](infra/infra_jumphost_tofu.md)**

Now the jumphost VM is ready with all the tools to deploy other sections on this site.

**[Install Harbor](infra/harbor.md)**

Harbor registry and ``nkp`` projects will be used to store the container images for NKP air-gapped deployments.

**[Tools Used](tools/tools.md)**

Detailed walk-through and deployment instructions.

**[Pre-requisites for Deploying NAI](nai/pre_reqs_nai.md)**

Use this token for accessing Hugging Face resources with read-only permissions.

**[Deploy NKP Clusters](nai/infra_nkp_nai.md)**

Now we are ready to deploy our AI workloads.

**[Deploying Nutanix Enterprise AI (NAI) NVD Reference Application](nai/deploy_nai.md)**

6. Once the services are running, check the status of the inference service         === "Command"

**[Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](nai/test_nai.md)**

We have successfully deployed the following:    - Inferencing endpoint  - A sample chat application that uses NAI to provide chatbot capabilities

**[takeaways](takeaways/takeaways.md)**

Detailed walk-through and deployment instructions.

**[Conceptual Design](conceptual/conceptual.md)**

The workload clusters will host the following:

**[Under constuction](supportgpt/supportgpt.md)**

Detailed walk-through and deployment instructions.

**[Sizing for AI Applications on Nutanix](sizing/sizing.md)**

By carefully considering these factors and employing appropriate optimization techniques, organizations can effectively size and optimize their LLM infrastru...

**[Replicating and Recovering Application to a Different K8S Cluster](nkp_ndk/nkp_ndk_k8s_replication.md)**

We have successfully replicated application data to a secondary NKP cluster and recovered it using NDK.

**[Preparing NDK](nkp_ndk/nkp_ndk.md)**

Now we are ready to create local cluster snapshots and snapshot restores using the following NDK custom resources:

**[Recovering Application within the same K8S Cluster](nkp_ndk/nkp_ndk_singlek8s_files.md)**

You have succesfully restored the Wordpress application with Files and Volumes ``pvc`` among other resources.

**[Preparing Air-gap NDK](nkp_ndk/airgap_nkp_ndk.md)**

NDK in air-gap enviroment is now install.

**[Recovering Application within the same K8S Cluster](nkp_ndk/nkp_ndk_singlek8s.md)**

We have now successfully restored our application accross namespaces.

**[Replicating and Recovering Application to a Different K8S Cluster](nkp_ndk/nkp_ndk_k8s_files_replication.md)**

We have used the following NDK objects to achieve our cross-namespace application recovery.

**[ntxcomponents](ntxcomponents/ntxcomponents.md)**

Detailed walk-through and deployment instructions.

**[Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](llmmgmt/llm_test.md)**

1. Type any question in the chat box. For example: *give me a python program to print the fibonacci series?*         ![](images/llm_answer.png)

**[Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](llmmgmt/llm_mgt_deploy.md)**

3. There is no user name and password for Milvus database as this is a test environment. Feel free to update password for ``root`` user in the user settings....

**[Pre-requisites for MGMT and DEV Cluster](llmmgmt/llm_pre_reqs.md)**

We are now ready to deploy the LLM app.

**[Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](llmmgmt/llm_dev_deploy.md)**

Wait for all GPU based services are in TRUE state, we are ready to test LLM App.

**[possibilities](possibilities/possibilities.md)**

Detailed walk-through and deployment instructions.

**[Pre-requisites for Deploying NAI](iep/iep_pre_reqs.md)**

3. Copy the generated Docker ID and access token to a safe place as we will need it for the [Deploy NAI](../iep/iep_deploy.md#deploy-nai) section.

**[Deploying Nutanix Enterprise AI (NAI) NVD Reference Application](iep/iep_deploy.md)**

6. Once the services are running, check the status of the inference service         === ":octicons-command-palette-16: Command"

**[Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](iep/iep_test.md)**

We have successfully deployed the following:    - Inferencing endpoint  - A sample chat application that uses NAI to provide chatbot capabilities

---

### September 24, 2024

**[Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](iep_250/iep_test.md)**

We have successfully deployed the following:    - Inferencing endpoint  - A sample chat application that uses NAI to provide chatbot capabilities

**[Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](iep_260/iep_test.md)**

We have successfully deployed the following:    - Inferencing endpoint  - A sample chat application that uses NAI to provide chatbot capabilities

**[Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](iep_240/iep_test.md)**

We have successfully deployed the following:    - Inferencing endpoint  - A sample chat application that uses NAI to provide chatbot capabilities

---

### September 19, 2024

**[Deploying Nutanix Enterprise AI (NAI) NVD Reference Application](iep_250/iep_deploy.md)**

6. Once the services are running, check the status of the inference service         === "Command"

**[Deploying Nutanix Enterprise AI (NAI) NVD Reference Application](iep_260/iep_deploy.md)**

6. Once the services are running, check the status of the inference service         === ":octicons-command-palette-16: Command"

**[Deploying Nutanix Enterprise AI (NAI) NVD Reference Application](iep_240/iep_deploy.md)**

6. Once the services are running, check the status of the inference service         === "Command"

---

### September 17, 2024

**[Pre-requisites for Deploying NAI](iep_250/iep_pre_reqs.md)**

3. Copy the generated Docker ID and access token to a safe place as we will need it for the [Deploy NAI](../iep/iep_deploy.md#deploy-nai) section.

**[Pre-requisites for Deploying NAI](iep_260/iep_pre_reqs.md)**

3. Copy the generated Docker ID and access token to a safe place as we will need it for the [Deploy NAI](../iep/iep_deploy.md#deploy-nai) section.

**[Pre-requisites for Deploying NAI](iep_240/iep_pre_reqs.md)**

3. Copy the generated Docker ID and access token to a safe place as we will need it for the [Deploy NAI](../iep/iep_deploy.md#deploy-nai) section.

---

