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


## Deploy Observability

1. Set the variable  `TARGET_NAMESPACE` for referring to the namespace where the observability stack will be deployed:

```bash
export TARGET_NAMESPACE=observability
```

2. Deploy the Prometheus operator, Prometheus, Alertmanager, and Grafana:

```bash
helmfile -f helmfile.yaml -e $TARGET_NAMESPACE sync --suppress-secrets
```

## Access Observability

### Access Prometheus

```shell
kubectl port-forward --namespace $TARGET_NAMESPACE svc/prometheus-kube-prometheus-prometheus 9090:9090
```

### Access Grafana

```shell
kubectl port-forward --namespace $TARGET_NAMESPACE svc/grafana 3000:80
```

## Delete Observability
First, you need to delete the Helm Chart

```shell
helmfile -f helmfile.yaml -e $TARGET_NAMESPACE delete --purge
```

In addition, you need to delete the Custom Ressources

```shell
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```