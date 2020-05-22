# Observability

## Overview

This repository aims to deploy an Observability stack for an Orchestrate infrastructure

### Prometheus Overview

The `Prometheus` repository aims to deploy a [Prometheus Operator](https://github.com/coreos/prometheus-operator) and instance of [Prometheus](https://prometheus.io/) base on the [Helm chart](https://github.com/helm/charts/tree/master/stable/prometheus-operator).

#### CustomResourceDefinitions
The Operator acts on the following custom resource definitions (CRDs):

* `Prometheus`, which defines a desired Prometheus deployment. The Operator ensures at all times that a deployment matching the resource definition is running.

* `ServiceMonitor`, which declaratively specifies how groups of services should be monitored. The Operator automatically generates Prometheus scrape configuration based on the definition.

* `PodMonitor`, which declaratively specifies how groups of pods should be monitored. The Operator automatically generates Prometheus scrape configuration based on the definition.

* `PrometheusRule`, which defines a desired Prometheus rule file, which can be loaded by a Prometheus instance containing Prometheus alerting and recording rules.

* `Alertmanager`, which defines a desired Alertmanager deployment. The Operator ensures at all times that a deployment matching the resource definition is running.

To learn more about the CRDs introduced by the Prometheus Operator have a look at the [design doc](https://github.com/coreos/prometheus-operator/blob/master/Documentation/design.md).

## Requirements

This deployment assumes that the following tools and infra exist and are up to date:

- [Kubernetes](https://kubernetes.io/) version 1.12 or upper
- [Helm](https://helm.sh/) version 3 or upper
- [Helm diff plugin](https://github.com/databus23/helm-diff)

The following Kubernetes features are also expected:

- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kubernetes Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)

!!! Important: 
  For Production environment, It's recommended to use [Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) Kubernetes feature


## Prerequisites

To segregate responsibilities, we would create two distinguished namesapces 
- `<ObservabilityKubernetesNameSpace>` Kubernetes namespace which will receive instance for Oberservability tools (Prometheus, Grafana, etc....)

```shell
kubectl create namespace <ObservabilityKubernetesNameSpace>
```

## Set-up Observability

Set the variable  `TARGET_NAMESPACE` to the Kubernetes namespace where you will deploy your Observability stack, for doing so:

1. If you do not have the Kubernetes namespace yet, please create it:

```bash
kubectl create namespace $TARGET_NAMESPACE
```

2. Initialize the variable:

```bash
export TARGET_NAMESPACE=<KUBERNETES_NAMESPACE>
```

## Deploy Observability

### Deploy Prometheus

To deploy Prometheus and its dependencies run the following command:

```bash
helmfile -f helmfile.yaml -e $TARGET_NAMESPACE apply --suppress-secrets
```

## Configure Prometheus Exporters

The documentation for [Running Exporter or ServiceMonitor](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/running-exporters.md)

Deploy the ServiceMonitor to scrap metrics from Orchestrate app 

```shell
kubectl apply --namespace <ObservabilityKubernetesNameSpace> -f prometheus/orchestrate-ServiceMonitor.yaml
```

### Deploy Grafana

```shell
helm install -f grafana/values.yaml grafana stable/grafana --namespace <ObservabilityKubernetesNameSpace>
```

## Delete Prometheus
First, you need to delete the Helm Chart

```shell
helmfile -f helmfile.yaml -e $TARGET_NAMESPACE delete --purge
```

Then, you need to delete the Custom Ressources

```shell
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com

kubectl delete clusterroles prometheus-kube-state-metrics
kubectl delete clusterroles prometheus-server
kubectl delete clusterroles prometheus

kubectl delete clusterrolebinding prometheus-kube-state-metrics
kubectl delete clusterrolebinding prometheus-server
kubectl delete clusterrolebinding prometheus
```