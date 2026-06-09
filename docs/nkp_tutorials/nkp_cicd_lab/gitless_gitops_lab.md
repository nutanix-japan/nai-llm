# Gitless GitOps CD lab with Flux

This lab shows a minimal **gitless GitOps** continuous delivery flow using Flux, an OCI registry, and a simple NGINX app. Flux watches an OCI artifact in a registry instead of a Git repository, then applies the manifests to the cluster through an `OCIRepository` and `Kustomization`.

## Goal

Deploy a simple app to Kubernetes where:
- CI or a workstation packages Kubernetes YAML into an OCI artifact and pushes it to a registry.
- Flux source-controller watches that OCI artifact using the `OCIRepository` CRD [web:1].
- Flux kustomize-controller applies the content to the cluster through a `Kustomization` that references the `OCIRepository`.

This is useful when you want declarative reconciliation without depending on Git as the runtime source of truth, especially for edge or disconnected clusters that can reach a registry more easily than a Git service.

## Architecture

1. Build an OCI artifact from Kubernetes manifests with `flux push artifact` or equivalent OCI tooling.
2. Push the artifact to a registry such as Harbor or GHCR.
3. Create an `OCIRepository` in `flux-system` that points at the registry artifact.
4. Create a `Kustomization` that uses that `OCIRepository` as its source.
5. Flux polls the registry, detects new tags or digests, fetches the artifact, and reconciles the cluster.

## What to confirm first

Run these checks on the target cluster:

=== ":octicons-command-palette-16: Command"

    ```bash
    kubectl get crd ocirepositories.source.toolkit.fluxcd.io
    kubectl get crd kustomizations.kustomize.toolkit.fluxcd.io
    kubectl -n flux-system get deploy
    kubectl -n flux-system get pods
    ```


=== ":octicons-command-palette-16: Command output"

    ```{ .text .no-copy }
    NAME                                       CREATED AT
    ocirepositories.source.toolkit.fluxcd.io   2026-06-08T05:41:26Z

    kustomizations.kustomize.toolkit.fluxcd.io   2026-06-08T05:41:26Z
    ```

If `ocirepositories.source.toolkit.fluxcd.io` exists, the cluster has the CRD needed for Flux to monitor OCI sources. If `source-controller` and `kustomize-controller` are present in `flux-system`, the core control-plane pieces for this lab are likely in place.

## Demo flow

Use these namespaces:
- `flux-system` for Flux sources and reconciliation objects.
- `demo-app` for the application workload.

The app will be a simple NGINX Deployment and Service.

## Example app manifests

We will create application manifests in the following manner:

=== ":octicons-command-palette-16: Directory layout"

    ```text
    lab/
    ├── app
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── kustomization.yaml
    └── flux
        ├── ocirepository.yaml
        └── kustomization.yaml
    ```

1. Create the ``Deployment`` manifests 

    === ":octicons-file-code-16: Template ``app/deployment.yaml``"
    
        ```yaml
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: demo-nginx
          namespace: demo-app
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: demo-nginx
          template:
            metadata:
              labels:
                app: demo-nginx
            spec:
              containers:
                - name: nginx
                  image: nginx:1.27-alpine
                  ports:
                    - containerPort: 80
                  readinessProbe:
                    httpGet:
                      path: /
                      port: 80
                    initialDelaySeconds: 3
                    periodSeconds: 5
        ```

1. Create the ``Service`` manifest 

    === ":octicons-file-code-16: Template ``app/service.yaml``"
    
        ```yaml
        apiVersion: v1
        kind: Service
        metadata:
          name: demo-nginx
          namespace: demo-app
        spec:
          selector:
            app: demo-nginx
          ports:
            - port: 80
              targetPort: 80
        ```

1. Create the ``Kustomization`` manifest

    === ":octicons-file-code-16: Template ``app/kustomization.yaml``"
    
        ```yaml
        apiVersion: kustomize.config.k8s.io/v1beta1
        kind: Kustomization
        namespace: demo-app
        resources:
          - deployment.yaml
          - service.yaml
        ```

## Package the manifests as an OCI artifact

Create the namespace first:

```bash
kubectl create namespace demo-app
```

Package and push the manifests to your OCI registry. Flux documents building and publishing Kubernetes manifests as OCI artifacts that can later be consumed by `OCIRepository`. An example using GHCR looks like this:

```bash
flux push artifact oci://ghcr.io/YOUR_ORG/demo-manifests:0.1.0 \
  --path=./app \
  --source="$(pwd)" \
  --revision="demo@sha1:$(git rev-parse --short HEAD 2>/dev/null || echo manual)"
```

If you are using Harbor, the shape is the same, for example:

```bash
flux push artifact oci://harbor.example.com/gitops/demo-manifests:0.1.0 \
  --path=./app \
  --source="lab-demo" \
  --revision="demo@sha1:manual"
```

## Flux objects

1. Access the NKP cluster and create the following Flux resources

1. Create the ``OCIRepository`` manifest 

    === ":octicons-file-code-16: Template ``flux/ocirepository.yaml``"

        ```yaml
        apiVersion: source.toolkit.fluxcd.io/v1beta2
        kind: OCIRepository
        metadata:
          name: demo-manifests
          namespace: flux-system
        spec:
          interval: 1m
          url: oci://ghcr.io/YOUR_ORG/demo-manifests
          ref:
            tag: 0.1.0
          provider: generic
        ```

    This tells Flux to poll the registry artifact on a schedule and fetch the referenced OCI content.

2. Create the ``Kustomization`` manifest 

    === ":octicons-file-code-16: Template ``flux/kustomization.yaml``"

        ```yaml
        apiVersion: kustomize.toolkit.fluxcd.io/v1
        kind: Kustomization
        metadata:
          name: demo-manifests
          namespace: flux-system
        spec:
          interval: 5m
          prune: true
          wait: true
          targetNamespace: demo-app
          path: ./
          sourceRef:
            kind: OCIRepository
            name: demo-manifests
        ```

    This tells Flux to apply the unpacked OCI artifact contents into the cluster by using the `OCIRepository` as the source instead of a `GitRepository`.

## Private registry auth

If the registry is private, create an OCI pull secret. Flux supports authenticated OCI access through a secret reference on the `OCIRepository`.

```bash
flux create secret oci regcred \
  --url=ghcr.io \
  --username=YOUR_USER \
  --password=YOUR_TOKEN \
  --namespace=flux-system \
  --export > regcred.yaml
kubectl apply -f regcred.yaml
```

Then add the secret reference:

```yaml
spec:
  secretRef:
    name: regcred
```

## Apply the Flux resources

=== ":octicons-command-palette-16: Command"

    ```bash
    kubectl apply -f flux/ocirepository.yaml
    kubectl apply -f flux/kustomization.yaml
    ```

Check reconciliation:

=== ":octicons-command-palette-16: Command"

    ```bash
    flux get sources oci -A
    flux get kustomizations -A
    kubectl -n demo-app get all
    ```

Flux will report the fetched revision for the OCI source, and the Kustomization status will show whether the manifests were applied successfully.

## Demo update story

A simple demo sequence:

1. Push version `0.1.0` with one NGINX replica.
2. Show Flux reconciling and the app becoming ready.
3. Change `replicas: 2` in `deployment.yaml`.
4. Push version `0.2.0` of the OCI artifact.
5. Update `ref.tag` in `OCIRepository` to `0.2.0`, or use a semver selector if you want Flux to track versions automatically where supported.
6. Show the rollout to two replicas.

## Optional security angle

Flux documentation also supports verifying OCI artifacts with Cosign or Notation before reconciliation, which is a strong talking point for supply-chain controls. A high-level message for the customer is that OCI-based delivery can combine image-style registry governance, signatures, and admission policies with GitOps-style reconciliation.

## Take away

This demo packages Kubernetes manifests as an OCI artifact and stores them in a container registry. Flux watches that registry through an `OCIRepository`, then applies the manifests with a `Kustomization`. The result is a Gitless runtime delivery flow that still preserves declarative reconciliation, and it is a strong fit for edge or intermittently connected clusters that already rely on an OCI registry.
