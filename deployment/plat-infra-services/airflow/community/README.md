Airflow
-------
> a work in progress!


### Helm chart

As an alternative to the official chart, the community-maintained
one looks much better:
- https://github.com/airflow-helm/charts

We're using version `8.7.1` of this chart
- https://github.com/airflow-helm/charts/tree/airflow-8.7.1/charts/airflow

Our values file is a tweaked version of the K8s executor example
- https://github.com/airflow-helm/charts/blob/airflow-8.7.1/charts/airflow/sample-values-KubernetesExecutor.yaml

But it didn't work for us---at least version `8.7.1` of that chart.
The values file we used was basically identical to their K8s executor
example, except for the Postgres volume where we specified the DirectPV
storage class and 1GB storage claim.


### Deployment

Manual procedure for now, we'll hook it into Argo CD later.

Get a Nix shell, set your K8s config for the target cluster and cd
into the Airflow deployment dir

```bash
$ cd nix
$ nix shell
$ export KUBECONFIG=/your/cluster/k8s/config.yaml
$ cd ../deployment/plat-infra-services/airflow
```

Add the Helm repo and update the cache

```bash
$ helm repo add airflow-stable https://airflow-helm.github.io/charts
$ helm repo update
```

Then install the `8.7.1` version of the chart with our config

```bash
$ kubectl apply -f namespace.yaml
$ helm install airflow airflow-stable/airflow \
    --namespace airflow \
    --version "8.7.1" \
    --values ./helm-values.yaml
```


### debug

helm template airflow airflow-stable/airflow \
  --namespace airflow \
  --version "8.7.1" \
  --values ./helm-values.yaml > out.yaml

helm uninstall airflow --namespace airflow
