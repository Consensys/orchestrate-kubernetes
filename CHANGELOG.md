# CHANGELOG

All notable changes to this project will be documented in this file.

## v2.0.0 (2020-03-12)

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