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
- [2. Installing Orchestrate](#2-installing-orchestrate)
  - [2.1. Docker registry credentials](#21-docker-registry-credentials)
  - [2.2. Namespaces](#22-namespaces)
  - [2.3. Environement values](#23-environement-values)
  - [2.4. Deploy Orchestrate](#24-deploy-orchestrate)
  - [2.5. Delete Orchestrate](#25-delete-orchestrate)
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
| master/HEAD                     | Orchestrate v2.6.x or higher |
| v4.1.0                          | Orchestrate v2.6.x or higher |
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

# 2. Installing Orchestrate

## 2.1. Docker registry credentials

Set your Orchestrate Docker images' credentials setting the following environment variable `$REGISTRY_USERNAME`, `$REGISTRY_PASSWORD` and optionally `$REGISTRY_URL`

```bash
export REGISTRY_USERNAME=<USER>
export REGISTRY_PASSWORD=<PASSWORD>
```

You also need to fill the github token to retrieve the Hashicorp plugin
```bash
export GITHUB_TOKEN=<TOKEN>
```

## 2.2. Namespaces

Set environment variables to specify what namespace Orchesrate and its dependencies will be deployed. Note: all the releases could be deployed in the same namespace. Example:

```bash
export ORCHESTRATE_NAMESPACE=orchestrate-demo
```

Optionally, specifiy the namespace where Vault Operator, Vault, Prometheus and Grafana stack will be deployed
```
export VAULT_OPERATOR_NAMESPACE=vault
export VAULT_NAMESPACE=vault
export OBSERVABILITY_NAMESPACE=observability
```
In that case you also have to add the value `metrics.enabled=true`. Example like `envinronments/orchestrate-demo.yaml`
```yaml
metrics:
  enabled: true
```

## 2.3. Environement values

The repository provides two examples of environment values set:
- `envinronments/orchestrate-minikube.yaml` for a deployment in minikube using the default storageClass
- `envinronments/orchestrate-staging.yaml` for a deployment in AWS using the default "gp2" storageClass

Feel free to create your own environment values with the following:

1. Make a copy of the file ['environments/template-placeholder.yaml'](./environments/template-placeholder.yaml) to `environments/<OrchestrateNamespace>.yaml`
   !!! Note:
    Keep the name of the file and of the Kubernetes namespace in mind, as you will need them to set up Orchestrate.

2. Add the environment `<OrchestrateNamespace>` into the file  `helmfile-common.yaml` 
 
```helmyaml
environments:
  <OrchestrateNamespace>:
    values:
      - environments/common.yaml.gotmpl
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

2. Once deployed you could easily test Orchestrate APIs:

```
kubectl port-forward --namespace $ORCHESTRATE_NAMESPACE svc/api-chain-registry 8081:8081
```
```
kubectl port-forward --namespace $ORCHESTRATE_NAMESPACE svc/api-contract-registry 8081:8081
```
```
kubectl port-forward --namespace $ORCHESTRATE_NAMESPACE svc/api-identity-manager 8081:8081
```
```
kubectl port-forward --namespace $ORCHESTRATE_NAMESPACE svc/api-transaction-scheduler 8081:8081
```

[See Orchestrate APIs documentation](https://consensys.gitlab.io/client/fr/core-stack/orchestrate/latest/)

## 2.5. Delete Orchestrate
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

- Vault CRD's, including [Vault policy](https://www.vaultproject.io/docs/concepts/policies), [Vault authentication](https://www.vaultproject.io/docs/concepts/auth), and [Orchestrate Hashicorp Vault Plugin](https://github.com/ConsenSys/orchestrate-hashicorp-vault-plugin)

[Vault policy](https://www.vaultproject.io/docs/concepts/policies)
```yaml
  externalConfig:
    policies:
        {{ if .Environment.Values.metrics.enabled }}
        - name: prometheus
          rules: path "sys/metrics" {
            capabilities = ["list", "read"]
            }
        {{ end }}
      - name: allow_secrets
        rules: path "orchestrate/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
          }
      - name: api_key_manager_demo
        rules: path "orchestrate/data/{{ .Environment.Values.orchestrateNamespace }}/keys/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
          }
```

[Vault authentication](https://www.vaultproject.io/docs/concepts/auth)
```yaml
  externalConfig:
    auth:
      - type: kubernetes
        roles:
          - name: api-key-manage
            bound_service_account_names: ["api-key-manage", "vault-secrets-webhook", "vault"]
            bound_service_account_namespaces: ["{{ .Environment.Values.vaultNamespace }}", "{{ .Environment.Values.vaultOperatorNamespace }}", "{{ .Environment.Values.orchestrateNamespace }}"]
            policies: ["allow_secrets", "api_key_manager_demo"]
      {{ if .Environment.Values.metrics.enabled }}
      - type: kubernetes
        roles:
          - name: prometheus
            bound_service_account_names: prometheus
            bound_service_account_namespaces: {{ .Environment.Values.observabilityNamespace }}
            policies: prometheus
      {{ end }}
```
- PVC
- Service Account
- RBAC configuration

Warning (Temporary): As of today the Orchestrate Vault Plugin is mounted to Hashicorp Vault with `mLock` disabled which is not recommended in production. A fix of the Vault Operator to be compatible with third-party plugins will come later. 


As set in the existing envinonment configurations in the `environments` directory, the `tx-signer` has to be connected to the harshicorp vault with the following values:

- `SECRET_STORE`: Secret storage type (default: hashicorp)
- `VAULT_MOUNT_POINT`: Root name of the secret engine (default: orchestrate)
- `VAULT_SECRET_PATH`: Path of secret key store of ethereum wallet (default: {{ .Environment.Values.orchestrateNamespace }}/keys)
- `VAULT_ADDR`: Hostname and port of Harshicorp Vault instance. (default: http://vault.{{ .Environment.Values.vaultNamespace }}:8200)
- `VAULT_CACERT`: Path to a PEM-encoded CA certificate file on the local disk. This file is used to verify the Vault server's SSL certificate
- `VAULT_SKIP_VERIFY`: Skip verifying Vault's certificate before communicating with it (default: false)

A sample of configuration:
```yaml
keyManager:
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
