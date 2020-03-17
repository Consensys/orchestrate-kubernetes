![](./orchestrate-logo.png)

PegaSys Orchestrate is a platform that enables enterprises to easily build secure and reliable applications on Ethereum blockchains.

It provides extensive features to connect to blockchain networks:

- Transaction management (transaction crafting, gas management, nonce management, transaction listening...)
- Account management with private key storage in Hashicorp Vault
- Smart Contract Registry
- Multi-chain & Multi-protocol (public or private)

For more information please refer to [PegaSys Orchestrate Official Documentation](https://docs.orchestrate.pegasys.tech/).

# Orchestrate-Kubernetes

- [Orchestrate-Kubernetes](#Orchestrate-Kubernetes)
  - [Prerequisites](#Prerequisites)
    - [Deployment](#Deployment)
    - [Hashicorp Vault with AWS](#Hashicorp-Vault-with-AWS)
  - [Configure Orchestrate](#Configure-Orchestrate)
  - [Set-up Orchestrate](#Set-up-Orchestrate)
    - [If using Helm version 2 -only- : Set-up tiller](#If-using-Helm-version-2--only---Set-up-tiller)
  - [Deploy Orchestrate](#Deploy-Orchestrate)
  - [Delete deployment of Orchestrate](#Delete-deployment-of-Orchestrate)

This repository contains an implementation example on how to deploy Orchestrate and its dependencies using Kubernetes, Helm charts and Helm files.
This is intended to to help the understanding on how to run and configure Orchestrate using Kubernetes.

## Prerequisites

### Deployment

- [Kubernetes](https://kubernetes.io/) version 1.12 or upper;
- [Helm](https://helm.sh/) version 2 or upper;
- [Helmfile](https://github.com/roboll/helmfile);
- [Helm diff plugin](https://github.com/databus23/helm-diff).

### Hashicorp Vault with AWS

- [DynamoDB](https://aws.amazon.com/dynamodb/) table for state and leader election (used for high availability)
- [AWS KMS](https://aws.amazon.com/kms/) key for auto-unsealing
- [AWS Secret](aws.amazon.com/secrets-manager)
- [IAM](https://aws.amazon.com/iam/) Role allowing access to above resources

## Configure Orchestrate

## Set-up Orchestrate

Set the env variable `TARGET_NAMESPACE`

sample:

```bash
export TARGET_NAMESPACE=orchestrate-demo
```

Create the kubernetes namespace, if it does not exist
```bash
kubectl create namespace $TARGET_NAMESPACE
```

### If using Helm version 2 -only- : Set-up tiller

Apply Role Base Access Control to tiller & Deploy tiller

```bash
cat tiller.yaml | envsubst | kubectl apply -f -
```

```bash
helm init --tiller-namespace $TARGET_NAMESPACE --upgrade --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' --service-account tiller --wait
```

## Deploy Orchestrate

Deploy Orchestrate and his dependency in namespace set in `TARGET_NAMESPACE` env variable

```bash
helmfile -f helmfile.yaml -e $TARGET_NAMESPACE apply --suppress-secrets
```

## Delete deployment of Orchestrate

```bash
helmfile -f helmfile.yaml -e $TARGET_NAMESPACE delete --purge
```
