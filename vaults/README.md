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

### Configuration
#### Vault instances

To deploy Harshicorps Vault in your environment, you have to set configuration in `operator-deploy/vault-k8s-sample.yaml` 

Change the <VaultKubernetesNameSpace> by the namespace where you want to deploy your Vault instance
```helmyaml
  unsealConfig:
    options:
      # The preFlightChecks flag enables unseal and root token storage tests
      # This is true by default
      preFlightChecks: true
    kubernetes:
      secretNamespace: <VaultKubernetesNameSpace>
``` 

Define and specify the rules for your [Vault policy](https://www.vaultproject.io/docs/concepts/policies)
```helmyaml
  externalConfig:
    policies:
      - name: allow_secrets
        rules: path "secret/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
          }
      - name: tx_signer_demo
        rules: path "secret/data/orchestrate-demo/keys/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
          }
```

Define and specify the rules for your [Vault authentication](https://www.vaultproject.io/docs/concepts/auth)
```helmyaml
  externalConfig:
    auth:
      - type: kubernetes
        roles:
          # Allow every pod in the default namespace to use the secret kv store
          - name: tx-signer
            bound_service_account_names: ["tx-signer", "vault-secrets-webhook", "vault"]
            bound_service_account_namespaces: ["operator", "vault-sandbox", "orchestrate-demo"]
            policies: ["allow_secrets", "tx_signer_demo"]
```

Define and specify the rules for your [Vault Secrets Engines](https://www.vaultproject.io/docs/secrets)

   !!! Note:
    The Secrets Engines for Orchestrate is Key/Value version 2_

```helmyaml
    secrets:
      - path: secret
        type: kv
        description: General secrets.
        options:
          version: 2
```

#### Orchestrate environment

In the 'environments' directory, you need to set variables to connect the `tx-signer` to the harshicorp vault

- `SECRET_STORE`: Value have to be `hashicorp` to connect to Harshicorp Vault instance.
- `VAULT_MOUNT_POINT`: Root name of the secret engine. Value is the name of the `path` variable in `secrets` structure in Harshicorp Vault configuration.
- `VAULT_SECRET_PATH`: Path of secret key store of ethereum wallet. Value is the `rules: path` variable in `policies` structure in Harshicorp Vault configuration.
- `VAULT_ADDR`: Hostname and port of Harshicorp Vault instance.
- `VAULT_CACERT`: Path to a PEM-encoded CA certificate file on the local disk. This file is used to verify the Vault server's SSL certificate.
- `VAULT_SKIP_VERIFY`: Do not verify Vault's presented certificate before communicating with it.

A sample of configuration:
```helmyaml
txSigner:
  environment:
    SECRET_STORE: "hashicorp"
    VAULT_MOUNT_POINT: "secret"
    VAULT_SECRET_PATH: "<KubernetesNameSpace>/keys"
    VAULT_ADDR: http://vault.<VaultKubernetesNameSpace>:8200
    VAULT_CACERT: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    VAULT_SKIP_VERIFY: true
```

If you need to initialize private key in the Vault (Not recommended ofr Production)
```helmyaml
txSigner:
  environment:
    SECRET_PKEY: "<PRIVATE_KEY_1> <PRIVATE_KEY_2> etc..."
```

## Create Vault instances

Apply Kubernetes `CustomResource` called `Vault` based on the configuration to create Vault instances

```shell
kubectl apply --namespace <VaultKubernetesNameSpace> -f operator-deploy/rbac.yaml
kubectl apply --namespace <VaultKubernetesNameSpace> -f operator-deploy/vault-k8s-sample.yaml
```


## Delete
First, you need to delete all deployed Vault server and RBAC

```shell
kubectl delete --namespace <VaultKubernetesNameSpace> -f operator-deploy/vault-k8s-sample.yaml
kubectl delete --namespace <VaultKubernetesNameSpace> -f operator-deploy/rbac.yaml
```

Then, you need to delete the operator

```shell
helm del --namespace <OperatorKubernetesNameSpace> vault-operator