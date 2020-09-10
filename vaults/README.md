<H1>Harshicorp Vault (Bank-Vaults)</H1>

- [1. Overview](#1-overview)
- [2. Requirements](#2-requirements)
- [3. Prerequisites](#3-prerequisites)
- [4. Deployment](#4-deployment)
  - [4.1. Vault Operator](#41-vault-operator)
  - [4.2. Configuration](#42-configuration)
    - [4.2.1. Vault instances](#421-vault-instances)
    - [4.2.2. Orchestrate environment](#422-orchestrate-environment)
- [5. Create Vault instances](#5-create-vault-instances)
- [6. Delete Vault servers and Vault Operator](#6-delete-vault-servers-and-vault-operator)

# 1. Overview

This repository aims to deploy a prod-worthy [Hashicorp's Vault](https://www.vaultproject.io/) on Kubernetes, base on [Bank-Vaults](https://github.com/banzaicloud/bank-vaults).

# 2. Requirements

This deployment assumes the following tools and infra exist and are up to date:

- [Kubernetes](https://kubernetes.io/) version 1.12 or upper
- [Helm](https://helm.sh/) version 3 or upper
- [Helm diff plugin](https://github.com/databus23/helm-diff)

The following Kubernetes knowledge are also expected:

- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kubernetes Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)

!!! Important: 
  For Production environment, It's recommended to use [Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) Kubernetes feature

# 3. Prerequisites

To segregate responsibilities, we have to create two distinguished namesapces 
- `<VaultOperatorNamespace>` Kubernetes namespace where the vault operator will be deployed
- `<VaultNamespace>` Kubernetes namespace where vault servers will be deployed

```shell
kubectl create namespace <VaultOperatorNamespace>
kubectl create namespace <VaultNamespace>
```

# 4. Deployment

## 4.1. [Vault Operator](https://banzaicloud.com/docs/bank-vaults/operator/)

We use the Banzai Cloud Vault Operator to manage the deployment of Vault servers

```shell
helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com
helm upgrade --namespace <VaultOperatorNamespace> --install vault-operator banzaicloud-stable/vault-operator
```

## 4.2. Configuration
### 4.2.1. Vault instances

To deploy Harshicorps Vault you have to set RBAC configuration in `operator-deploy/rbac.yaml` 

Replace `<VaultNamespace>` and `<OrchestrateNamespace>` respectively by the vault namespace and the namespace where Orchestrate will be deployed
```helmyaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-auth-delegator-orchestrate
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator-orchestrate
subjects:
subjects:
  - kind: ServiceAccount
    name: vault
    namespace: <VaultNamespace>
  - kind: ServiceAccount
    name: vault
    namespace: <OrchestrateNamespace>
``` 


Then, you have to define Vault Operator CRD's (Custom Ressource Definition) in `operator-deploy/vault-k8s-sample.yaml` 

Replace the `<VaultNamespace>` by the namespace where you want to deploy your Vault instance
```helmyaml
  unsealConfig:
    options:
      # The preFlightChecks flag enables unseal and root token storage tests
      # This is true by default
      preFlightChecks: true
    kubernetes:
      secretNamespace: <VaultNamespace>
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
        rules: path "secret/data/<OrchestrateNamespace>/keys/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
          }
```

Define and specify the rules for your [Vault authentication](https://www.vaultproject.io/docs/concepts/auth)
```helmyaml
  externalConfig:
    auth:
      - type: kubernetes
        roles:
          - name: tx-signer
            bound_service_account_names: ["tx-signer", "vault-secrets-webhook", "vault"]
            bound_service_account_namespaces: ["<VaultOperatorNamespace>", "<VaultNamespace>", "<OrchestrateNamespace>"]
            policies: ["allow_secrets", "tx_signer_demo"]
```

Define and specify the rules for your [Vault Secrets Engines](https://www.vaultproject.io/docs/secrets)

   !!! Note:
    The Secrets Engines for Orchestrate is Key/Value version 2

```helmyaml
    secrets:
      - path: secret
        type: kv
        description: General secrets.
        options:
          version: 2
```

### 4.2.2. Orchestrate environment

In the `environments` directory, you need to set variables to connect the `tx-signer` to the harshicorp vault

- `SECRET_STORE`: Secret storage type. Use `hashicorp` to connect use Harshicorp Vault instance.
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
    VAULT_SECRET_PATH: "<OrchestrateNamespace>/keys"
    VAULT_ADDR: http://vault.<VaultNamespace>:8200
    VAULT_CACERT: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    VAULT_SKIP_VERIFY: true
```

If you need to initialize private key in the Vault (Not recommended for Production)
```helmyaml
txSigner:
  environment:
    SECRET_PKEY: "<PRIVATE_KEY_1> <PRIVATE_KEY_2> etc..."
```

# 5. Create Vault instances

Apply Kubernetes `CustomResource` called `Vault` based on the configuration to create Vault instances

```shell
kubectl apply --namespace <VaultNamespace> -f operator-deploy/rbac.yaml
kubectl apply --namespace <VaultNamespace> -f operator-deploy/vault-k8s-sample.yaml
```


# 6. Delete Vault servers and Vault Operator
First, you need to delete all deployed Vault server and RBAC

```shell
kubectl delete --namespace <VaultNamespace> -f operator-deploy/vault-k8s-sample.yaml
kubectl delete --namespace <VaultNamespace> secret vault-unseal-keys
kubectl delete --namespace <VaultNamespace> -f operator-deploy/rbac.yaml
```

Then, you need to delete the operator

```shell
helm del --namespace <VaultOperatorNamespace> vault-operator