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
- `environments/default.yaml`: default value set when executing `helmfile apply`
  - Deploy a light one-replica of Orchestrate services
  - One partition per Kafka topic 
- `environments/qa.yaml`: `helmfile -e qa apply`
  - Deploy a Orchestrate services with multitenancy
  - 3 partitions per Kafka topic
- `environments/staging.yaml`: `helmfile -e staging apply`
  - Deploy a 3-replica of Orchestrate services with multitenancy distributed accros Availability-Zones
  - 3-replica of Kafka and Zookeeper with 3 partitions per Kafka topic
  - Postgres cluster with 1 master and 2 slaves. With PGPool-II and Repmgr 
  - Redis in cluter mode with 1 master and 2 slaves
  - 3 Hashicorp Vault with raft integrated storage

Note: All the passwords and usernames of every dependendcies are located in `environments/common.yaml.gotmpl`. Do not forget to change, eventually extract, those values depending on how you want to manage those secrets.

The following tables lists the configurable values for the environments. Some of them are directly configurable bia envronement variable:

| Parameter                                      | Description                                                                | Default                                                     |
|------------------------------------------------|----------------------------------------------------------------------------|-------------------------------------------------------------|
| `orchestrate.namespace`                        | Namespace where Orchestrate will be deployed (env `ORCHESTRATE_NAMESPACE`) | `orchestrate`                                               |
| `orchestrate.chart.name`                        | This deployment orchestrate chart (env `ORCHESTRATE_CHART`) | `consensys/orchestrate`                                               |
| `orchestrate.chart.version`                        | Namespace where Orchestrate will be deployed (env `ORCHESTRATE_CHART_VERSION`) | `1.0.6`                                               |
| `orchestrate.global.imageCredentials.registry` | Docker registry where Orchestrate images are stored (env `REGISTRY_URL`)   | `docker.consensys.net`                                      |
| `orchestrate.global.imageCredentials.username` | [REQUIRED] Username of the registry (env `REGISTRY_USERNAME`)              |                                                             |
| `orchestrate.global.imageCredentials.password` | [REQUIRED] Password of the registry (env `REGISTRY_PASSWORD`)              |                                                             |
| `orchestrate.global.image.repository`          | Path to Orchestrate image (env `ORCHESTRATE_REPOSITORY`)                   | `docker.consensys.net/priv/orchestrate` |
| `orchestrate.global.image.tag`                 | Orchestrate image tag (env `ORCHESTRATE_TAG`)                              | `v21.1.2`                                                   |
| `orchestrate.api`                              | Orchestrate API values                                                     |                                                             |
| `orchestrate.keyManager`                       | Orchestrate Key Manager values, for usage with version 21.1.X                                             |                                                             |
| `orchestrate.qkm`                       | Orchestrate Key Manager values, for usage with version 21.10.X                                             |                                                             |
| `orchestrate.txListener`                       | Orchestrate Tx Listener values                                             | `nil`                                                       |
| `orchestrate.txSender`                         | Orchestrate Tx Sender values                                               | `nil`                                                       |
| `orchestrate.test.image.repository`            | Path to Orchestrate test image (env `TEST_REPOSITORY`)                     | `nil`                                                       |
| `orchestrate.test.image.tag`                   | Orchestrate test image tag (env `TEST_TAG`)                                | `nil`                                                       |

For more information about values defined in values/orchestrate.yaml.gotmpl, please see https://github.com/ConsenSys/orchestrate-helm


| Parameter                 | Description                                                                          | Default          |
|---------------------------|--------------------------------------------------------------------------------------|------------------|
| `vaultOperator.namespace` | Namespace where the Vault Operator will be deployed (env `VAULT_OPERATOR_NAMESPACE`) | `vault-operator` |

For more information about Vault Operator, please see https://github.com/banzaicloud/bank-vaults/tree/master/charts/vault-operator

| Parameter             | Description                                                                        | Default                                                            |
|-----------------------|------------------------------------------------------------------------------------|--------------------------------------------------------------------|
| `vault.namespace`     | Namespace where Hashicop Vault will be deployed (env `VAULT_NAMESPACE`)            | `orchestrate`                                                      |
| `vault.replicaCount`  | Number of Vault instance                                                           | `1`                                                                |
| `vault.plugin.tag`    | Orchestrate Hashicorp Vault Plugin tag (env `VAULT_PLUGIN_TAG`)                    | `v0.0.9`                                                           |
| `vault.plugin.sha256` | Orchestrate Hashicorp Vault Plugin SHA256 checksum  (env `VAULT_PLUGIN_SHA256SUM`) | `4919a7fcf66fe98b459e6a46f9233aae9fc2f224ccbb6a44049e2f608b9eebf5` |

For more information about values defined in values/vault.yaml.gotmpl, please see https://github.com/banzaicloud/bank-vaults/tree/master/operator/deploy and https://github.com/banzaicloud/bank-vaults/tree/master/charts/vault

| Parameter                             | Description                                                                                                                                                                                                                                                               | Default  |
|---------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| `kafka.namespace`                     | Namespace where Kafka and Zookeeper Vault will be deployed (env `KAFKA_NAMESPACE`)                                                                                                                                                                                        | `1`      |
| `kafka.replicaCount`                  | Number of Kafka instance nodes                                                                                                                                                                                                                                            | `1`      |
| `kafka.numPartitions`                 | The default number of log partitions per topic                                                                                                                                                                                                                            | `1`      |
| `kafka.logRetentionHours`             | The minimum age of a log file to be eligible for deletion due to age                                                                                                                                                                                                      | `24`     |
| `kafka.persistence.enabled`           | Enabled Kafka data persistence                                                                                                                                                                                                                                            | `true`   |
| `kafka.persistence.size`              | Kafka data persistence size PVC                                                                                                                                                                                                                                           | `4Gi`    |
| `kafka.resources.requests.memory`     | Memory requested for Kafka containers                                                                                                                                                                                                                                     | `4Gi`    |
| `kafka.resources.requests.cpu`        | CPU requested for Kafka containers                                                                                                                                                                                                                                        | `100m`   |
| `kafka.resources.limits.memory`       | Memory limit for Kafka containers                                                                                                                                                                                                                                         | `8Gi`    |
| `kafka.resources.limits.cpu`          | CPU limit for Kafka containers                                                                                                                                                                                                                                            | `500m`   |
| `kafka.auth.enabled`                  | Enable SASL PLAINTEXT authentification                                                                                                                                                                                                                                    | `true`   |
| `kafka.auth.username`                 | Kafka client username                                                                                                                                                                                                                                                     | `user1`  |
| `kafka.auth.password`                 | Kafka client password                                                                                                                                                                                                                                                     | `secret` |
| `kafka.externalAccess.enabled`        | Enable external access to kafka through a new load balancer (env `KAFKA_EXTERNAL_ACCESS`). If enabled, you use external-dns, and `domainName` is provided, then each kafka brokers will be reachable in kafka-{{environement}}-$i.{{kafka.namespace}}.{{domainName}}:9094 | `false`  |
| `zookeeper.replicaCount`              | Number of Zookeeper nodes                                                                                                                                                                                                                                                 | `1`      |
| `zookeeper.persistence`               | Zookeeper data persistence using PVC                                                                                                                                                                                                                                      |          |
| `zookeeper.resources.requests.memory` | Memory requested for Zookeeper containers                                                                                                                                                                                                                                 | `512Mi`  |
| `zookeeper.resources.requests.cpu`    | CPU requested for Zookeeper containers                                                                                                                                                                                                                                    | `100m`   |
| `zookeeper.resources.limits.memory`   | Memory limit for Zookeeper containers                                                                                                                                                                                                                                     | `1Gi`    |
| `zookeeper.resources.limits.cpu`      | CPU limit for Zookeeper containers                                                                                                                                                                                                                                        | `300m`   |

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
| `postgresql.enabled`                  | If true, Postgres will be deployed                                   | `true`        |
| `postgresql.namespace`                | Namespace where Postgres will be deployed (env `POSTGRES_NAMESPACE`) | `orchestrate` |
| `postgresql.username`                 | Username of Postgres                                                 | `api`         |
| `postgresql.password`                 | Password of Postgres                                                 | `such-secret` |
| `postgresql.database`                 | Database name                                                        | `api`         |
| `postgresql.replication.enabled`      | Enable replication                                                   | `false`       |
| `postgresql.replication.readReplicas` | Number of read replicas                                              | `1`           |
| `postgresql.persistence.size`         | PVC storage request size                                             | `8Gi`         |

For more information about values defined in values/postgresql.yaml.gotmpl, please see https://github.com/bitnami/charts/tree/master/bitnami/postgresql

| Parameter                                | Description                                                             | Default       |
|------------------------------------------|-------------------------------------------------------------------------|---------------|
| `postgresqlHA.enabled`                   | If true, Postgres HA will be deployed                                   | `false`       |
| `postgresqlHA.namespace`                 | Namespace where Postgres HA will be deployed (env `POSTGRES_NAMESPACE`) | `orchestrate` |
| `postgresqlHA.postgresql.username`       | Username of Postgres                                                    | `api`         |
| `postgresqlHA.postgresql.password`       | Password of Postgres                                                    | `such-secret` |
| `postgresqlHA.postgresql.database`       | Database name                                                           | `api`         |
| `postgresqlHA.postgresql.repmgrPassword` | Repmgr password                                                         | `api`         |
| `postgresqlHA.postgresql.replicaCount`   | Number of replicas                                                      | `1`           |
| `postgresqlHA.persistence.size`          | PVC storage request size                                                | `8Gi`         |
| `postgresqlHA.pgpool.replicaCount`       | Number of PGPool-II replicas                                            | `1`           |

For more information about values defined in values/postgresql.yaml.gotmpl, please see https://github.com/bitnami/charts/tree/master/bitnami/postgresql-ha


| Parameter                        | Description                                                                                                 | Default         |
|----------------------------------|-------------------------------------------------------------------------------------------------------------|-----------------|
| `observability.enabled`          | If true, The Observability stack will be deployed as well as the service monitors and the metrics exporters | `false`         |
| `observability.namespace`        | Namespace where the observability stack will be deployed  (env `OBSERVABILITY_NAMESPACE`)                   | `observability` |
| `observability.grafana.user`     | Root user name                                                                                              | `admin`         |
| `observability.grafana.password` | Root user password                                                                                          | `frenchfries`   |

| Parameter    | Description                                                                                                                                                                                                                                                                                                        | Default |
|--------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
| `domainName` | (Option) Domain name registered to the ingress controller of your kubernetes cluster. If not empty Orchestrate API will be exposed to {{orchestrate.namespace}}.{{domainName}}. If the observability stack is enabled grafana.{{domainName}} and prometheus.{{domainName}} will be exposed too (env `DOMAIN_NAME`) | ``      |


Values below are useful when deploying orchestrate with version 21.10.X, having possibly a Quorum Key Manager running independently

| Parameter                  | Description                                                           | Default       |
|----------------------------|-----------------------------------------------------------------------|---------------|
| `qkm.enabled`              | If true, Quorum Key Manager will be deployed                          | `true`        |
| `qkm.url`                  | Url where Quorum Key Manager may be reached (env `QKM_URL`)           | `http://quorumkeymanager.orchestrate` |
| `qkm.namespace`            | Namespace where Quorum Key Manager is deployed (env `QKM_NAMESPACE`)  | `orchestrate` |
| `qkm.orchestrate.storeName`| Initial and existing eth-account name used by orchestrate             | `eth-accounts` |
| `qkm.orchestrate.apiKey`   | Existing apiKey used by orchestrate to authenticate                   | `YWRtaW4tdXNlcg==` |
| `qkm.chart.name`           | Helm chart of your Quorum Key Manager deployment                      | `consensys/quorumkeymanager` |
| `qkm.chart.version`        | Helm chart version of your Quorum Key Manager deployment              | `1.1.1` |
| `qkm.port`                 | Port of the Quorum Key Manager service                                | `8080`       |

For more information about values defined in values/qkm.yaml.gotmpl, please refer to https://github.com/ConsenSys/quorum-key-manager-helm

# 3. Hashicorp Vault

This helmfiles optionally deploys [Hashicorp's Vault](https://www.vaultproject.io/) with integrated storage with raft with [Bank-Vaults](https://github.com/banzaicloud/bank-vaults). We deploy first the Vault operator, then the following ressources contained in `values/vault.yaml`:
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

Note that it is highly recommended to use the `consensys/quorum-hashicorp-vault-plugin` image when deplying a Vault ressource.

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

