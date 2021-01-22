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
  - [1.1. CLI tools](#11-cli-tools)
  - [1.2. Credentials](#12-credentials)
- [2. Installing Orchestrate](#2-installing-orchestrate)
  - [2.1. Quickstart](#21-quickstart)
  - [2.2. Delete Orchestrate](#22-delete-orchestrate)
  - [2.3. Advanced configuration](#23-advanced-configuration)
- [3. Hashicorp Vault](#3-hashicorp-vault)
- [4. Observability](#4-observability)
  - [4.1. Prometheus dashboard](#41-prometheus-dashboard)
  - [4.2. Grafana](#42-grafana)
- [5. Upgrading](#5-upgrading)
  - [5.1. From Orchestrate v2.5.X to v21.1.X](#51-from-orchestrate-v25x-to-v211x)

This repository contains an implementation example on how to deploy Orchestrate and its dependencies using Kubernetes and Helm charts.

# Compatibility

| Orchestrate-kubernetes versions | Orchestrate versions          |
|---------------------------------|-------------------------------|
| master/HEAD                     | Orchestrate v21.1.x or higher |
| v5.0.0                          | Orchestrate v21.1.x or higher |
| v4.0.0                          | Orchestrate v2.5.x            |
| v3.1.0                          | Orchestrate v2.5.x            |
| v3.0.0                          | Orchestrate v2.4.x            |

# 1. Requirements

## 1.1. CLI tools

- [Kubernetes](https://kubernetes.io/) version 1.16 or upper;
- [Helm](https://helm.sh/) version 3 or upper;
- [Helmfile](https://github.com/roboll/helmfile);
- [Helm diff plugin](https://github.com/databus23/helm-diff).

## 1.2. Credentials

- Credentials to pull Orchestrate's Docker images;

!!! Note: 
  To get a free trial please contact [orchestrate@consensys.net](mailto:orchestrate@consensys.net).

Set your Orchestrate Docker images' credentials setting the following environment variable `$REGISTRY_USERNAME`, `$REGISTRY_PASSWORD` and optionally `$REGISTRY_URL`

```bash
export REGISTRY_USERNAME=<USER>
export REGISTRY_PASSWORD=<PASSWORD>
```

You also need to fill the github token to retrieve the Hashicorp plugin
```bash
export GITHUB_TOKEN=<TOKEN>
```

# 2. Installing Orchestrate

## 2.1. Quickstart

1. To deploy a simple Orchestrate (not production ready) and its dependencies, run the following command:

```bash
helmfile apply --suppress-secrets
```

2. Once deployed you could easily test Orchestrate API in http://localhost:8081:

```
kubectl port-forward --namespace orchestrate svc/orchestrate-api 8081:8081
```

[See Orchestrate APIs documentation](https://consensys.gitlab.io/client/fr/core-stack/orchestrate/latest/)

## 2.2. Delete Orchestrate
!!!hint
  to delete Orchestrate's deployment and its ressources run the following commands:

```bash
helmfile delete --purge
kubectl delete namespace orchestrate
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

## 2.3. Advanced configuration

This repository provides few examples of environment values sets:
- `envinronments/default.yaml`: default value set when executing `helmfile apply`
  - Deploy a light one-replica of Orchestrate services
  - Kafka, Zookeeper, and Postgres data are not persisted 
  - One partition per Kafka topic 
  - Redis is not deployed and the nonce is kept in memory
- `envinronments/staging.yaml`: `helmfile -e staging apply`
  - Deploy a one-replica of Orchestrate services with multitenancy
  - Kafka, Zookeeper, and Postgres data are persisted
  - One partition per Kafka topic 
  - Nonce are cached in Redis
  - Deploy the observability stack
- `envinronments/qa.yaml`: `helmfile -e qa apply`
  - Deploy a 3-replica of Orchestrate services with multitenancy
  - Kafka, Zookeeper, and Postgres data are persisted and replicated to 3
  - Three partitions per Kafka topic 
  - Deploy the observability stack
  - Please note that vault is not HA and requires to setup an HA backend instead of file, see https://www.vaultproject.io/docs/configuration.

The following tables lists the configurable values for the environments. Some of them are directly configurable bia envronement variable:

| Parameter                                      | Description                                                                | Default                                                     |
|------------------------------------------------|----------------------------------------------------------------------------|-------------------------------------------------------------|
| `orchestrate.namespace`                        | Namespace where Orchestrate will be deployed (env `ORCHESTRATE_NAMESPACE`) | `orchestrate`                                               |
| `orchestrate.global.imageCredentials.registry` | Docker registry where Orchestrate images are stored (env `REGISTRY_URL`)   | `docker.cloudsmith.io`                                      |
| `orchestrate.global.imageCredentials.username` | [REQUIRED] Username of the registry (env `REGISTRY_USERNAME`)              |                                                             |
| `orchestrate.global.imageCredentials.password` | [REQUIRED] Password of the registry (env `REGISTRY_PASSWORD`)              |                                                             |
| `orchestrate.global.image.repository`          | Path to Orchestrate image (env `ORCHESTRATE_REPOSITORY`)                   | `docker.cloudsmith.io/consensys/docker-private/orchestrate` |
| `orchestrate.global.image.tag`                 | Orchestrate image tag (env `ORCHESTRATE_TAG`)                              | `v21.1.0`                                                   |
| `orchestrate.api`                              | Orchestrate API values                                                     |                                                             |
| `orchestrate.keyManager`                       | Orchestrate Key Manager values                                             |                                                             |
| `orchestrate.txListener`                       | Orchestrate Tx Listener values                                             | `nil`                                                       |
| `orchestrate.txSender`                         | Orchestrate Tx Sender values                                               | `nil`                                                       |
| `orchestrate.test.image.repository`            | Path to Orchestrate test image (env `TEST_REPOSITORY`)                     | `nil`                                                       |
| `orchestrate.test.image.tag`                   | Orchestrate test image tag (env `TEST_TAG`)                                | `nil`                                                       |

For more information about values defined in values/orchestrate.yaml.gotmpl, please see https://github.com/ConsenSys/orchestrate-helm


| Parameter                 | Description                                                                          | Default          |
|---------------------------|--------------------------------------------------------------------------------------|------------------|
| `vaultOperator.namespace` | Namespace where the Vault Operator will be deployed (env `VAULT_OPERATOR_NAMESPACE`) | `vault-operator` |

For more information about Vault Operator, please see https://github.com/banzaicloud/bank-vaults/tree/master/charts/vault-operator

| Parameter             | Description                                                                                                                                                        | Default                                                            |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------|
| `vault.namespace`     | Namespace where Hashicop Vault will be deployed (env `VAULT_NAMESPACE`)                                                                                            | `orchestrate`                                                      |
| `vault.plugin.token`  | [REQUIRED] Github token to retrieve the [Orchestrate Hashicorp Vault Plugin](https://github.com/ConsenSys/orchestrate-hashicorp-vault-plugin) (env `GITHUB_TOKEN`) |                                                                    |
| `vault.plugin.tag`    | Orchestrate Hashicorp Vault Plugin tag (env `VAULT_PLUGIN_TAG`)                                                                                                    | `v0.0.5`                                                           |
| `vault.plugin.sha256` | Orchestrate Hashicorp Vault Plugin SHA256 checksum  (env `VAULT_PLUGIN_SHA256SUM`)                                                                                 | `5d63d9891463c8b7dc281759c105b45835bc8e91cde019a9bde74d858f795740` |

For more information about values defined in values/vault.yaml.gotmpl, please see https://github.com/banzaicloud/bank-vaults/tree/master/operator/deploy and https://github.com/banzaicloud/bank-vaults/tree/master/charts/vault

| Parameter                 | Description                                                                        | Default |
|---------------------------|------------------------------------------------------------------------------------|---------|
| `kafka.namespace`         | Namespace where Kafka and Zookeeper Vault will be deployed (env `KAFKA_NAMESPACE`) | `1`     |
| `kafka.replicaCount`      | Number of Kafka nodes                                                              | `1`     |
| `kafka.numPartitions`     | The default number of log partitions per topic                                     | `1`     |
| `kafka.logRetentionHours` | The minimum age of a log file to be eligible for deletion due to age               | `24`    |
| `kafka.persistence`       | Kafka data persistence using PVC                                                   |         |
| `kafka.resources`         | Resources requested and limits for Kafka containers                                |         |
| `zookeeper.replicaCount`  | Number of Zookeeper nodes                                                          | `1`     |
| `zookeeper.persistence`   | Zookeeper data persistence using PVC                                               |         |
| `zookeeper.resources`     | Resources requested and limits for Zookeeper containers                            |         |

For more information about values defined in values/kafka.yaml.gotmpl, please see https://github.com/bitnami/charts/tree/master/bitnami/kafka


| Parameter                  | Description                                                    | Default       |
|----------------------------|----------------------------------------------------------------|---------------|
| `redis.enabled`            | If true, Redis will be deployed                                | `true`        |
| `redis.namespace`          | Namespace where Redis will be deployed (env `REDIS_NAMESPACE`) | `orchestrate` |
| `redis.password`           | Redis password                                                 | `such-secret` |
| `redis.cluster.enabled`    | Use master-slave topology                                      | `false`       |
| `redis.cluster.slaveCount` | Number of slaves                                               | `0`           |

For more information about values defined in values/redis.yaml.gotmpl, please see https://github.com/bitnami/charts/tree/master/bitnami/redis

| Parameter                             | Description                                                          | Default       |
|---------------------------------------|----------------------------------------------------------------------|---------------|
| `postgresql.namespace`                | Namespace where Postgres will be deployed (env `POSTGRES_NAMESPACE`) | `orchestrate` |
| `postgresql.username`                 | Username of Postgres                                                 | `api`         |
| `postgresql.password`                 | Password of Postgres                                                 | `such-secret` |
| `postgresql.database`                 | Database name                                                        | `api`         |
| `postgresql.replication.enabled`      | Enable replication                                                   | `false`       |
| `postgresql.replication.readReplicas` | Number of read replicas replicas                                     | `1`           |
| `postgresql.persistence`              | Persistence using PVC                                                |               |

For more information about values defined in values/postgresql.yaml.gotmpl, please see https://github.com/bitnami/charts/tree/master/bitnami/postgresql


| Parameter                 | Description                                                                                                 | Default         |
|---------------------------|-------------------------------------------------------------------------------------------------------------|-----------------|
| `observability.enabled`   | If true, The Observability stack will be deployed as well as the service monitors and the metrics exporters | `false`         |
| `observability.namespace` | Namespace where the observability stack will be deployed  (env `OBSERVABILITY_NAMESPACE`)                   | `observability` |

| Parameter    | Description                                                                                                                                                                                                                                                                                                    | Default |
|--------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
| `domainName` | (Option) Domain name registered to the ingress controller of your kubernetes cluster. If not empty Orchestrate API will be exposed to {{orchestrate.namespace}}.{{domainName}}. If the observability stack is enabled grafana.{{domainName}} and prometheus.{{domainName}} will be exposed too (env `DOMAIN_NAME`) | ``      |

# 3. Hashicorp Vault

This helmfiles deploys [Hashicorp's Vault](https://www.vaultproject.io/) based on [Bank-Vaults](https://github.com/banzaicloud/bank-vaults). We deploy first the Vault operator, then the following ressources contained in `values/vault.yaml`:

- Vault CRD's, including [Vault policy](https://www.vaultproject.io/docs/concepts/policies), [Vault authentication](https://www.vaultproject.io/docs/concepts/auth), and [Orchestrate Hashicorp Vault Plugin](https://github.com/ConsenSys/orchestrate-hashicorp-vault-plugin)

[Vault policy](https://www.vaultproject.io/docs/concepts/policies)
```yaml
  externalConfig:
    policies:
        {{ if .Values.observability.enabled }}
        - name: prometheus
          rules: path "sys/metrics" {
            capabilities = ["list", "read"]
            }
        {{ end }}
      - name: orchestrate_key_manager
        rules: path "orchestrate/*" {
          capabilities = ["create", "read", "update", "list"]
          }
```

[Vault authentication](https://www.vaultproject.io/docs/concepts/auth)
```yaml
  externalConfig:
    auth:
      - type: kubernetes
        roles:
          - name: orchestrate-key-manager
            bound_service_account_names: ["orchestrate-key-manager", "vault-secrets-webhook", "vault"]
            bound_service_account_namespaces: ["{{ .Values.vault.namespace }}", "{{ .Values.orchestrate.namespace }}"]
            policies: orchestrate_key_manager
      {{ if .Values.observability.enabled }}
      - type: kubernetes
        roles:
          - name: prometheus
            bound_service_account_names: prometheus
            bound_service_account_namespaces: {{ .Values.observability.namespace }}
            policies: prometheus
      {{ end }}
```
- PVCs
- Service Account
- RBAC configuration

# 4. Observability

This helmfile could deploy [Prometheus Operator](https://github.com/coreos/prometheus-operator) and [Prometheus](https://prometheus.io/) based on the [Kube-Prometheus Helm chart](https://github.com/bitnami/charts/tree/master/bitnami/kube-prometheus). It also deploys Grafana with default dashboards for Orchestrate, Kubernetes, Golang, Kafka, Postgres, Redis, and Hashicorp Vault

## 4.1. Prometheus dashboard

```shell
kubectl port-forward --namespace $OBSERVABILITY_NAMESPACE svc/prometheus-kube-prometheus-prometheus 9090:9090
```

## 4.2. Grafana

```shell
kubectl port-forward --namespace $OBSERVABILITY_NAMESPACE svc/grafana 3000:80
```


# 5. Upgrading

## 5.1. From Orchestrate v2.5.X to v21.1.X

[Read the steps to upgrade Orchestrate v2.5.X to v21.1.X](docs/upgrades/v21-1-X.md)