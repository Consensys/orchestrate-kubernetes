# Codefi Orchestrate

[Orchestrate](https://codefi.consensys.net) is a platform that enables enterprises to easily build
secure and reliable applications on Ethereum blockchains.

It provides extensive features to connect to blockchain networks:

- Transaction management (transaction crafting, gas management, nonce management, transaction listening)
- Account management with private key storage in Hashicorp Vault
- Smart Contract Registry
- Multi-chain & Multi-protocol (public or private)

For more information, refer to the [Orchestrate documentation](https://docs.orchestrate.consensys.net/).

<H1>Orchestrate-Kubernetes</H1>

- [Codefi Orchestrate](#codefi-orchestrate)
- [Compatibility](#compatibility)
- [1. Requirements](#1-requirements)
  - [1.1. Credentials](#11-credentials)
  - [1.2. CLI tools](#12-cli-tools)
  - [1.3. Hashicorp Vault on AWS (optionnal)](#13-hashicorp-vault-on-aws-optionnal)
- [2. Installing Orchestrate](#2-installing-orchestrate)
  - [2.1. Docker registry credentials](#21-docker-registry-credentials)
  - [2.2. Namespaces](#22-namespaces)
  - [2.3. Environement values](#23-environement-values)
  - [2.4. Deploy Orchestrate](#24-deploy-orchestrate)
- [3. Multi-tenancy](#3-multi-tenancy)
- [4. Hashicorp Vault](#4-hashicorp-vault)
- [5. Observability](#5-observability)
  - [5.1. Prometheus dashboard](#51-prometheus-dashboard)
  - [5.2. Grafana](#52-grafana)

This repository contains an implementation example on how to deploy Orchestrate and its dependencies using Kubernetes, Helm charts and Helm files.
This is intended to help the understanding on how to run and configure Orchestrate using Kubernetes.

# Compatibility

| Orchestrate-kubernetes versions | Orchestrate versions         |
|---------------------------------|------------------------------|
| master/HEAD                     | Orchestrate v2.5.x or higher |
| v4.0.0                          | Orchestrate v2.5.x or higher |
| v3.1.0                          | Orchestrate v2.5.x or higher |
| v3.0.0                          | Orchestrate v2.4.x           |

# 1. Requirements

## 1.1. Credentials

- Credentials to pull Orchestrate's Docker images;

!!! Note: 
  If you do not have them yet, please contact [orchestrate@consensys.net](mailto:orchestrate@consensys.net).

## 1.2. CLI tools

- [Kubernetes](https://kubernetes.io/) version 1.16 or upper;
- [Helm](https://helm.sh/) version 3 or upper;
- [Helmfile](https://github.com/roboll/helmfile);
- [Helm diff plugin](https://github.com/databus23/helm-diff).

## 1.3. Hashicorp Vault on AWS (optionnal)

- [Amazon DynamoDB](https://aws.amazon.com/dynamodb/);
- [AWS Key Management Service (KMS)](https://aws.amazon.com/kms/);
- [AWS Secrets Manager](aws.amazon.com/secrets-manager);
- [AWS Identity and Access Management (IAM)](https://aws.amazon.com/iam/).

# 2. Installing Orchestrate

## 2.1. Docker registry credentials

Set your Orchestrate Docker images' credentials setting the following environment variable `$REGISTRY_USERNAME`, `$REGISTRY_PASSWORD` and optionally `$REGISTRY_URL`

```bash
export REGISTRY_USERNAME=<USER>
export REGISTRY_PASSWORD=<PASSWORD>
```

## 2.2. Namespaces

Set environment variables to specify what namespace Orchesrate, its dependencies, and tools will be deployed. Note: all the releases could be deployed in the same namespace. Example:

```bash
export ORCHESTRATE_NAMESPACE=orchestrate-demo
export VAULT_OPERATOR_NAMESPACE=hashicorp-vault
export VAULT_NAMESPACE=hashicorp-vault
```

Optionally, specifiy the namespace where the Prometheus and grafana stack will be deployed
```
export OBSERVABILITY_NAMESPACE=observability
```
In that case you also have to add the value `metrics.enabled=true`. Example like `envinronments/orchestrate-demo.yaml`
```yaml
metrics:
  enabled: true
  namespace: {{ requiredEnv "OBSERVABILITY_NAMESPACE" }}
```

## 2.3. Environement values

The repository provides two examples of environment values set:
- `envinronments/orchestrate-minikube.yaml` for a deployment in minikube using the default storageClass
- `envinronments/orchestrate-demo.yaml` for a deployment in AWS using the default "gp2" storageClass

Feel free to create your own environment values with the following:

1. Make a copy of the file ['environments/template-placeholder.yaml'](./environments/template-placeholder.yaml) to `environments/<OrchestrateNamespace>.yaml`
   !!! Note:
    Keep the name of the file and of the Kubernetes namespace in mind, as you will need them to set up Orchestrate.

2. Add the environment `<OrchestrateNamespace>` into the file  `helmfile-common.yaml` 
 
```helmyaml
environments:
  <OrchestrateNamespace>:
    values:
      - environments/<OrchestrateNamespace>.yaml
      - values/tags.yaml
```

3. (Optional) Declare the blockchain networks you want to connect Orchestrate at the initilization (separate each node by a space). This step is optional as you can register a chain by REST API once deployed.

```yaml
chainRegistry:
  init:'{"name":"<ChainName1>","tenantID":"<tenatID1>", "urls":["<ChainURL1A>","<ChainURL1B>"]} {"name":"<ChainName2>","tenantID":"<tenatID2>", "urls":["<ChainURL2A>","<ChainURL2B>"]}}'
```
  
## 2.4. Deploy Orchestrate

1. Deploy Orchestrate and its dependencies with the following command:

```bash
helmfile -f helmfile.yaml -e $ORCHESTRATE_NAMESPACE apply --suppress-secrets
```

!!!hint
  to delete Orchestrate's deployment and its ressources run the following command:

```bash
helmfile -f helmfile.yaml -e $ORCHESTRATE_NAMESPACE delete --purge
kubectl delete --namespace $VAULT_NAMESPACE secret vault-unseal-keys
```

If you have deployed the observability stack, you have to delete the following
```bash
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```

# 3. Multi-tenancy

- `multitenancy.enabled`: Enables this Orchestrate feature (default: false).
- `authentication.AUTH_JWT_CLAIMS_NAMESPACE`: Tenant namespace to retrieve tenantID in OpenId or Access Token (JWT) (default: "http://tenant.info/"). You will find this information on your identity provider.
- `authentication.AUTH_JWT_CERTIFICATE`: Certificate of authentication service **encoded in base64**. You will find the information in your identity provider.
- `authentication.AUTH_API_KEY`: This key is used for authentication internally on Orchestrate, we highly recommend to use a UUID format.

# 4. Hashicorp Vault

This helmfiles deploys [Hashicorp's Vault](https://www.vaultproject.io/) based on [Bank-Vaults](https://github.com/banzaicloud/bank-vaults). We deploy first the Vault operator, then the following ressources `values/vault.yaml`:

- Vault CRD's, including [Vault policy](https://www.vaultproject.io/docs/concepts/policies) and [Vault authentication](https://www.vaultproject.io/docs/concepts/auth)

[Vault policy](https://www.vaultproject.io/docs/concepts/policies)
```yaml
  externalConfig:
    policies:
      - name: allow_secrets
        rules: path "secret/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
          }
      - name: tx_signer_demo
        rules: path "secret/data/{{ .Values.orchestrate.namespace }}/keys/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
          }
```

[Vault authentication](https://www.vaultproject.io/docs/concepts/auth)
```yaml
  externalConfig:
    auth:
      - type: kubernetes
        roles:
          - name: tx-signer
            bound_service_account_names: ["tx-signer", "vault-secrets-webhook", "vault"]
            bound_service_account_namespaces: ["{{ .Values.vaultOperator.namespace }}", "{{ .Values.vault.namespace }}", "{{ .Values.orchestrate.namespace }}"]
            policies: ["allow_secrets", "tx_signer_demo"]
```
- PVC
- Service Account
- RBAC configuration


As set in the existing envinonment configurations in the `environments` directory, the `tx-signer` has to be connected to the harshicorp vault with the following values:

- `SECRET_STORE`: Secret storage type. Use `hashicorp` to connect use Harshicorp Vault instance.
- `VAULT_MOUNT_POINT`: Root name of the secret engine. Value is the name of the `path` variable in `secrets` structure in Harshicorp Vault configuration.
- `VAULT_SECRET_PATH`: Path of secret key store of ethereum wallet. Value is the `rules: path` variable in `policies` structure in Harshicorp Vault configuration.
- `VAULT_ADDR`: Hostname and port of Harshicorp Vault instance.
- `VAULT_CACERT`: Path to a PEM-encoded CA certificate file on the local disk. This file is used to verify the Vault server's SSL certificate.
- `VAULT_SKIP_VERIFY`: Do not verify Vault's presented certificate before communicating with it.

A sample of configuration:
```yaml
txSigner:
  environment:
    SECRET_STORE: "hashicorp"
    VAULT_MOUNT_POINT: "secret"
    VAULT_SECRET_PATH: "{{ requiredEnv "ORCHESTRATE_NAMESPACE" }}/keys"
    VAULT_ADDR: http://vault.{{ requiredEnv "VAULT_NAMESPACE" }}:8200
    VAULT_CACERT: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    VAULT_SKIP_VERIFY: true
```

# 5. Observability

This helmfile could deploy [Prometheus Operator](https://github.com/coreos/prometheus-operator) and [Prometheus](https://prometheus.io/) base on the [Helm chart](https://github.com/bitnami/charts/tree/master/bitnami/kube-prometheus). It also deploys Grafana with default dashboards for Kubernetes, Golang metrics, Kafka, Postgres, Redis

## 5.1. Prometheus dashboard

```shell
kubectl port-forward --namespace $OBSERVABILITY_NAMESPACE svc/prometheus-kube-prometheus-prometheus 9090:9090
```

## 5.2. Grafana

```shell
kubectl port-forward --namespace $OBSERVABILITY_NAMESPACE svc/grafana 3000:80
```
