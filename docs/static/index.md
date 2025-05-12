# Introduction

The simulator section of the site is to help visualise kubernetes node and pod deployment.

!!! warning

    This is just a static HTML page with javascript. There is no backend logic to persist simulations.

    Remember to take screen shots are download them to your personal device for persistence.

We are covering four scenarios in this section. We will add more as it becomes available. 

## Simulators

<div class="grid cards" markdown>

-   :material-kubernetes:{ .lg .middle } __Kubernetes Pods and Nodepools__

    ---

    Simulate and visualise how pods and nodepools are deployed with your own criteria.

    [:octicons-arrow-right-24: Simulation](../static/scheduling-mixed-pods-and-nodepool-v1.html)

-   :material-kubernetes:{ .lg .middle } __Kubernetes Deployment Strategies__

    ---

    Visualise various Kubernetes Deployment Strategies

    - Rolling updates
    - Recreate
    - Blue/Green

    [:octicons-arrow-right-24: Simulation](../static/nai-llm-model-selectr.html)



</div>

<div class="grid cards" markdown>
-   :octicons-ai-model-16: __LLM Model Selector__
    
    ---

    This Simulation helps you visualize and choose LLMs for your use case. 

    [:octicons-arrow-right-24: Simulation](../static/k8s-deployment-strategies-visualizer.html)
</div>

<div class="grid cards" markdown>

-   :octicons-ai-model-16: __LLM Scheduling on Kubernetes Clusters__

    ---

    This is a visual simulator that demonstrates how Kubernetes  schedules Large Language Model (LLM) workloads across different types of compute nodes. It helps users understand how resource management, scheduling decisions, and pod placement works in a Kubernetes environment, specifically for AI/ML workloads that often have specialized resource requirements like GPUs.

    [:octicons-arrow-right-24: Simulation](../static/nai-llm-simulation-v1-nim-rag.html)

    
    > **Interactive Model Configuration** 
    
    > The ability to select different LLM models with varying resource requirements, configure deployment parameters > like inference engines, and see how these affect resource needs.
    
    > **Visual Node Pool Management**
    
    > The feature to create and customize different node pools with various hardware specifications 
    > (CPU, memory, GPU types/counts), simulating real-world Kubernetes cluster architecture.

    > **Realistic Scheduling Simulation**
    
    > Shows the actual scheduling process, demonstrating how Kubernetes evaluates node resources, makes placement  decisions, and handles resource constraints.
    
    > **GPU Compatibility & Resource Constraints** 
    
    > Demonstrates how specific models might require particular GPU types or hardware configurations, and how resource constraints affect deployment.
    
    >**Test Scenarios** 
    > Predefined test configurations that showcase different scheduling scenarios, from CPU-only deployments to mixed workloads and resource constraints.

</div>