# CHANGELOG

All notable changes to this project will be documented in this file.

## v7.0.0 (Unreleased)

 * Removed Kafka deployment
 * Removed Postgres deployment
 * Removed Redis deployment
 * Removed quorum-key-manager deployment
 * Moved observability stack (prometheus - grafana) to orchestrate-infra

## v6.0.0 (2022-02-22)

 * Support latest v21.12.x orchestrate version
 * Support Hashicorp Vault image with embedded plugin
 * Remove Key manager and replace it with Quorum Key Manager dependency
 * Make chart Azure compliant
 * Updated Ingresses
 * Made dependencies optional


## v5.1.0 (Unreleased)

 * Make Vault, Postgres, Redis Highly Available in Multi-Availability Zones

## v5.0.0 (2020-11-27)
### 🆕 Features
 * Make Orchestrate Kubernetes compatible with Orchestrate v21.1.X versions
   * Remove orchestrate-helm-worker and orchestrate-helm-api and use the single Orchestrate Helm Chart
   * Add Orchestrate Vault plugin to hashicorp vault
   * Add Grafana Dashboard for Orchestrate
 * Add Vault Dashbord and its Prometheus configuration
 * Add Ingress for Orchestrate API, Grafana and Prometheus
 * Add 3 environments values: default, staging, and qa

### ⚠ BREAKING CHANGES
 * Reorganized helmfile structure:
   * `.Values` are structured as:
     * orchestrate
       * global
       * api
       * keyManager
       * txListener
       * txSender
       * test
     * vaultOperator
     * vault
     * kafka
     * redis
     * postgresql
     * observability 
   * `environments/common.yaml.gotmpl`: all environment variables that could be pass and that are common accross all environment values set
   * `helmfile-core.yaml`: Releases Orchestrate, Kafka, Postgres and Redis

## v4.0.0 (2020-11-27)

### 🆕 Features
 * Add Prometheus and Grafana stack in the deployment, including standard dashboards.
 * Reorganized folder structure and group helmfiles to deploy Observability, Vault and Orchestrate stack in a single command

### 🛠 Bug fixes
 * For a better stability of Kafka we updated the following values:
   * `logRetentionHours` from 168 to 24
   * `resources.requests.memory` 1Gi from to 4Gi
   * `resources.limits.memory` 1.5Gi from to 8Gi
   * `resources.limits.cpu` 300m from to 500m

### ⚠ BREAKING CHANGES
 * New helmfile structure where Observability and Vault deployments are part of a single root Helmfile. Vault folder and its manual deployment has been deleted.
 * `TARGET_NAMESPACE` environment variable is deprecated for the following environment variables:
   * `ORCHESTRATE_NAMESPACE` namespace where Orchestrate stack will be deployed
   * `VAULT_NAMESPACE` namespace where Vault servers will be deployed
   * `OBSERVABILITY_NAMESPACE` namespace where Prometheus and Grafana stack will be deployed (optional)

## v3.1.0 (2020-10-20)

### 🛠 Bug fixes
 * Split `REDIS_URL` into `REDIS_HOST` and `REDIS_PORT` to support Orchestrate v2.5.x

## v3.0.0 (2020-10-19)

### 🆕 Features

* Add optional environment variables `ORCHESTRATE_TAG`, `E2E_TAG`, `ORCHESTRATE_REPOSITORY`, `E2E_REPOSITORY`, `REGISTRY_URL` (`/values/tags.yaml.gotmpl`) 
* Add CircleCI configuration
* Update values and Helm Charts to be able to run an end-to-end test
* Add Helmfile environment values sets to deploy Orchestrate in minikube

### ⚠ BREAKING CHANGES
 * Use Bank-Vaults as vault operator (`/vaults`) and remove the vault deployment in the main helmfile scripts
 * Add two required environment variables: `REGISTRY_USERNAME` and `REGISTRY_PASSWORD` as credentials of the docker registry of Orchestrate (`/values/tags.yaml.gotmpl`)

## v2.0.0 (2020-04-01)

* Upgrade the deployment to Helm v3

## v1.0.0 (2020-03-12)

* Remove all topics `topic-tx-decoder-{chainID}` for `tx-decoder`
* Remove the topic `topic-tx-nonce` for `tx-nonce`
* Remove Environment variable `REDIS_LOCKTIMEOUT` for `tx-nonce`

### 🆕 Multi-tenancy & Chain-registry
* Add the chain-registry micro-service and its environment variables
* Add environment variables for Multi-tenancy:
      * `MULTI_TENANCY_ENABLED` to enable multi-tenancy. 
      * `AUTH_JWT_CERTIFICATE` to provision trusted certificate to control signature of ID / Access Token (JWT)
      * `AUTH_JWT_CLAIMS_NAMESPACE` to provision the namespace to retrieve Orchestrate AUth element in OpenId or Access Token (JWT) (in particular multitenancy information)
      * `AUTH_API_KEY` secret allowing to bypass JWT authentication (used for some microservice to microservice communications)

### ⚠ BREAKING CHANGES
 * Bump the version of PostgreSQL from v10 to v11
    * If there is already a deployed PostgreSQL databse in version 10, it will not be compatible with PostgreSQL version 11. 
     However Orchestrate is compatible with PosgreSQL v10 and v11.
* Rename the default topic names from `topic-wallet-generator` and `topic-wallet-generated` to `topic-account-generator` and `topic-account-generated` respectively
* Remove the `tx-decoder` microservice to merge it into `tx-listener` microservice. The `tx-listener` publish transactions directly in the `topic-tx-decoded` 
* Remove the `tx-nonce` microservice to merge it into `tx-crafter` microservice. The `tx-crafter` publish transactions directly in the `topic-tx-signer`
* Move Environment variables `NONCE_MANAGER_TYPE` `REDIS_URL` `REDIS_LOCKTIMEOUT` from `tx-nonce` to `tx-crafter`
* Remove Environment variable `ETH_CLIENT_URL`, the chains urls have to be set in `CHAIN_REGISTRY_INIT` of `chain-registry` microservice
* Add Environment variable `CHAIN_REGISTRY_URL` to `tx-listener`, `tx-crafter`, `tx-sender`
* Removes flag and environment variable `DISABLE_EXTERNAL_TX` in the tx-listener and tx-decoder