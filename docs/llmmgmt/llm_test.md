# Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)

```mermaid
stateDiagram-v2
    direction LR
    
    state TestLLMApp {
        [*] --> CheckInferencingService
        CheckInferencingService -->  TestFrontEndApp
        TestFrontEndApp --> TestRAG
        TestRAG --> [*]
    }

    [*] --> PreRequisites
    PreRequisites --> DeployLLMV1 
    DeployLLMV1 --> TestLLMApp : previous section
    TestLLMApp --> [*]
```

## Accessing LLM Frontend

Once the bootstrapping is done in the previous section. We can access and test our LLM application.

1. In VSC Terminal, check the status of inferencing service
   
    ```bash
    kubectl get isvc -A
    ```
    ``` { .text .no-copy }
    NAMESPACE   NAME      URL                                                READY   PREV   LATEST   PREVROLLEDOUTREVISION   LATESTREADYREVISION       AGE
    llm         llm-llm   http://llm-llm.llm.dev-cluster.10.x.x.217.nip.io   True           100                              llm-llm-predictor-00001   4h9m
    ```

2. Access the URL to check status and make sure it is alive and well 
   
    ```bash
    $ curl http://llm-llm.llm.dev-cluster.10.x.x.217.nip.io
    ```
    ``` { .text .no-copy }
    $ curl http://llm-llm.llm.dev-cluster.10.x.x.217.nip.io
    {"status":"alive"} 
    ```
   
3. On VSC terminal, get the LLM Frontend ingress endpoints
   
    ```bash
    kubectl get ingress -A | grep frontend
    ```

    ``` { .text .no-copy }
    kubectl get ingress -A | grep frontend
    NAMESPACE              NAME                                                      CLASS   HOSTS                                      ADDRESS        PORTS     AGE
    gptnvd-reference-app   gptnvd-reference-app-gptnvd-ref-app-gptnvd-referenceapp   nginx   frontend.dev-cluster.10.x.x.216.nip.io   10.x.x.216   80, 443   4h9m      
    ```

4. Copy the HOSTS address ``frontend.dev-cluster.10.x.x.216.nip.io `` from the above output and paste it in your browser. You should be able to see the LLM chat interface. Start asking away. 
   
    ![](images/llm_fe.png)

## Testing LLM Frontend Chat App

1. Type any question in the chat box. For example: *give me a python program to print the fibonacci series?*
   
    ![](images/llm_answer.png)