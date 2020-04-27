# Harshicorp Vault (Bank-Vaults)

## Overview

This repository aims to deploy a prod-worthy [Hashicorp's Vault](https://www.vaultproject.io/) on Kubernetes, base on [Bank-Vaults](https://github.com/banzaicloud/bank-vaults).

## Requirements

This deployment assumes that the following tools and infra exist:

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
- `<OperatorKubernetesNameSpace>` Kubernetes namespace which will receive the vault operator
- `<VaultKubernetesNameSpace>` Kubernetes namespace which will receive vault servers

```shell
kubectl create namespace <OperatorKubernetesNameSpace>
kubectl create namespace <VaultKubernetesNameSpace>
```

## Deployment

### [Vault Operator](https://banzaicloud.com/docs/bank-vaults/operator/)

It will be used the Banzai Cloud Vault Operator to manage the deployment of Vault servers

```shell
helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com
helm upgrade --namespace <OperatorKubernetesNameSpace> --install vault-operator banzaicloud-stable/vault-operator
```

### Configuration Vault instances

// TODO


## Create Vault instances

Apply Kubernetes `CustomResource` called `Vault` based on the configuration to create Vault instances

```shell
kubectl apply --namespace <VaultKubernetesNameSpace> -f operator-deploy/rbac.yaml
kubectl apply --namespace <VaultKubernetesNameSpace> -f operator-deploy/cr-k8s-startup-secret.yaml
```


## Delete
First, you need to delete all deployed Vault server and RBAC

```shell
kubectl delete --namespace <VaultKubernetesNameSpace> -f operator-deploy/cr-k8s-startup-secret.yaml
kubectl delete --namespace <VaultKubernetesNameSpace> -f operator-deploy/rbac.yaml
```

Then, you need to delete the operator

```shell
helm del --namespace <OperatorKubernetesNameSpace> vault-operator