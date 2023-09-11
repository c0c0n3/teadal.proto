Airflow
-------
> a work in progress!


### Helm chart

We'll use the official chart

- https://airflow.apache.org/docs/helm-chart/stable/index.html
- https://www.astronomer.io/events/webinars/airflow-helm-chart/

We'll use the official chart, the community-maintained one looks
much better:
- https://github.com/airflow-helm/charts

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
$ helm repo add apache-airflow https://airflow.apache.org
$ helm repo update
```

Then install the `1.10.0` version of the chart with our config

```bash
$ kubectl apply -f namespace.yaml
$ helm install airflow apache-airflow/airflow \
    --namespace airflow \
    --version "1.10.0" \
    --values ./helm-values.yaml
```


### debug

helm template airflow apache-airflow/airflow \
  --namespace airflow \
  --version "1.10.0" \
  --values ./helm-values.yaml > out.yaml