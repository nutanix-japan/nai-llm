---
title: "NKP Workload with NDB Database"
lastupdate: git
lastupdateauthor: "Lakshmi Balaramane"
---

## Install Custom Three-Layer Application

This section deploys a three-layer application (React frontend, Django backend, Postgres database) based on [this blog](https://www.datagraphi.com/blog/post/2021/2/10/kubernetes-guide-deploying-a-machine-learning-app-built-with-django-react-and-postgresql-using-kubernetes), adapted for Kubernetes and NDB.

### Create Database Schema and Data
1. Apply application secrets:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/nutanix-japan/ocp-gitp/main/docs/ocp_ndb/k8s/app-secrets.yaml -n ndb
   ```
2. Download and edit the ConfigMap:
   ```bash
   curl -LO https://raw.githubusercontent.com/nutanix-japan/ocp-gitp/main/docs/ocp_ndb/k8s/app-variables.yaml
   ```
   Update `DB_HOST` and `DB_PORT` in `app-variables.yaml`:
   ```yaml
   DB_HOST: dbforflower-svc
   DB_PORT: "80"
   ```
3. Apply the ConfigMap:
   ```bash
   kubectl apply -f app-variables.yaml -n ndb
   ```
4. Run the Django job to populate the database:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/nutanix-japan/ocp-gitp/main/docs/ocp_ndb/k8s/django-job.yaml -n ndb
   ```
5. Monitor the job:
   ```bash
   kubectl get job django-job -n ndb -w
   ```
   Example output:
   ```text
   NAME         COMPLETIONS   DURATION   AGE
   django-job   1/1           19s        20s
   ```
6. Check job logs:
   ```bash
   kubectl logs -n ndb $(kubectl get pod -n ndb -l job-name=django-job -o jsonpath='{.items[0].metadata.name}')
   ```
7. Verify new tables:
   ```bash
   kubectl exec -it psql -n ndb -- psql -h dbforflower-svc -p 80 -U postgres -d predictiondb
   ```
   ```sql
   \dt
   ```
   Expected output: ~11 tables (e.g., `auth_user`, `django_migrations`).

### Install Frontend and Backend
1. Deploy Django and React applications:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/nutanix-japan/ocp-gitp/main/docs/ocp_ndb/k8s/django-deployment.yaml -n ndb
   kubectl apply -f https://raw.githubusercontent.com/nutanix-japan/ocp-gitp/main/docs/ocp_ndb/k8s/react-deployment.yaml -n ndb
   ```
2. Verify pods:
   ```bash
   kubectl get pods -n ndb
   ```

### Create Ingress for Access
1. Create an Ingress resource to replace OpenShift Routes:
   
    ```bash
    cat << EOF > ingress.yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: flower-app
      namespace: ndb
      annotations:
        traefik.ingress.kubernetes.io/router.entrypoints: web
        traefik.ingress.kubernetes.io/router.pathmatcher: PathPrefix
    spec:
      rules:
      - host: flower.apps.k8suserXX.ntnxlab.local
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: react-cluster-ip-service
                port:
                  number: 80
          - path: /admin
            pathType: Prefix
            backend:
              service:
                name: django-cluster-ip-service
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: django-cluster-ip-service
                port:
                  number: 80
          - path: /static/admin/
            pathType: Prefix
            backend:
              service:
                name: django-cluster-ip-service
                port:
                  number: 80
          - path: /static/rest_framework/
            pathType: Prefix
            backend:
              service:
                name: django-cluster-ip-service
                port:
                  number: 80
          - path: /static/
            pathType: Prefix
            backend:
              service:
                name: django-cluster-ip-service
                port:
                  number: 80
          - path: /media/
            pathType: Prefix
            backend:
              service:
                name: django-cluster-ip-service
                port:
                  number: 80
    EOF
    ```

2. Replace `k8suserXX` with your user ID:

    ```bash
    sed -i 's/k8suserXX/your_user_id/g' ingress.yaml
    ```

3. Apply the Ingress:

    ```bash
    kubectl apply -f ingress.yaml -n ndb
    ```

4. Verify if Ingress resources are created
   
    ```bash
    kubectl get ingress -n ndb
    ```

### Test Frontend React Application
1. Update your local hosts file:
   ```text
   10.38.18.220 flower.apps.k8suserXX.ntnxlab.local
   ```
2. Access the React app:
   ```url
   http://flower.apps.k8suserXX.ntnxlab.local/
   ```
3. Log in with:
    - **Username**: admin
    - **Password**: admin_password
4. Use the sliders to predict flower names.

### Test Backend Django Application
1. Access the Django admin:
   ```url
   http://flower.apps.k8suserXX.ntnxlab.local/admin
   ```
2. Log in with:
    - **Username**: admin
    - **Password**: admin_password
3. Add a new user:
    - **Username**: xyz-user
    - **Password**: your_password
4. Save and test the new user in the React app.

### Check Postgres Database Data
1. Connect to the database:
   ```bash
   kubectl exec -it psql -n ndb -- psql -h dbforflower-svc -p 80 -U postgres -d predictiondb
   ```
2. Query users:
   ```sql
   SELECT username, last_login FROM auth_user;
   ```
   Expected output:
   ```text
   username  | last_login
   ----------+-------------------------------
   admin     | 2022-12-14 01:38:41.480801+00
   xyz-user  | 2022-12-14 01:38:53.474404+00
   ```

## Takeaways
- The NDB Operator simplifies VM-based database deployment in Kubernetes.
- Databases are provisioned via YAML manifests and exposed as Kubernetes Services.
- Security is managed with `securityContext` instead of SCCs, ensuring non-root execution.

## Cleanup (optional)

```bash
kubectl delete -f ingress.yaml -n ndb
kubectl delete -f https://raw.githubusercontent.com/nutanix-japan/ocp-gitp/main/docs/ocp_ndb/k8s/react-deployment.yaml -n ndb
kubectl delete -f https://raw.githubusercontent.com/nutanix-japan/ocp-gitp/main/docs/ocp_ndb/k8s/django-deployment.yaml -n ndb
kubectl delete -f https://raw.githubusercontent.com/nutanix-japan/ocp-gitp/main/docs/ocp_ndb/k8s/django-job.yaml -n ndb
kubectl delete -f app-variables.yaml -n ndb
kubectl delete -f https://raw.githubusercontent.com/nutanix-japan/ocp-gitp/main/docs/ocp_ndb/k8s/app-secrets.yaml -n ndb
kubectl delete -f database.yaml -n ndb
kubectl delete -f ndbserver.yaml -n ndb
kubectl delete -f your-db-secret.yaml -n ndb
kubectl delete -f your-ndb-secret.yaml -n ndb
kubectl delete pod psql -n ndb
kubectl delete namespace ndb
helm uninstall ndb-operator -n ndb-operator
kubectl delete namespace ndb-operator
```

Decommission the Postgres database in the NDB UI.