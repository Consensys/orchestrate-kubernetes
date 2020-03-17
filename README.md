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
    - [Access to registry](#Access-to-registry)
  - [Configure Orchestrate](#Configure-Orchestrate)
      - [Blockchain setting](#Blockchain-setting)
      - [Hashicorp Vault in AWS](#Hashicorp-Vault-in-AWS)
      - [Multi-tenancy](#Multi-tenancy)
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

### Access to registry
You need to have credentials to pull docker image and helm chart to deploy Orchestrate. If you do not have credentials, please contact support@pegasys.tech

To set your credentials of Docker registry, you have to fill the following fields in the file `values/tags.yaml`
- `registry.credentials.username`: Account of the Docker Registry to pull Orchestrate image
- `registry.credentials.password`: Password of the Docker Registry to pull Orchestrate image

To set your credentials of Hem Chart registry, you have to fill the following fields in the file `helmfile-common.yaml`
- `repositories.username`: Account of the Helm Registry to pull Orchestrate Helm Chart
- `repositories.password`: Password of the Helm Registry to pull Orchestrate Helm Chart

## Configure Orchestrate 
In `environments` directory, you will find a template file (`template-placeholder.yam`) and an example file (`orchestrate-demo.yaml`) 

First, you need to copy the file `environments/template-placeholder.yam`, then you need to rename it with the name of your kubernetes namesapce and past it in the directory `environments` 
Then, all configuration will be done in the file you have rename and past. 
> **Note:** _keep the name of the file and the kubernetes namespace in mind, you will need it to set up Orchestrate for the variable _

#### Blockchain setting

- `chainRegistry.init`: List of chains including name, URL to communicate with the blockchain 

#### Hashicorp Vault in AWS
- `IAMRole`: ARN of the AWS IAM role (string)
- `Region`: AWS Region in which the resources are created (string)
- `KMSKeyId`: The AWS KMS key ID to use for encryption and decryption (string)
- `SecretId`: Alias / Name of the AWS Secretmanager's secret where the root token is stored (string)

#### Multi-tenancy
- `multitenancy.enabled`: Enable the usage of multi-tenancy (default: false)
- `AUTH_JWT_CLAIMS_NAMESPACE`: Tenant Namespace to retrieve the tenant id in the OpenId or Access Token (JWT) (default: "http://tenant.info/"). You will find the information in your identity provider
- `authentication.AUTH_JWT_CERTIFICATE`: Certificate of the authentication service encoded in base64. You will find the information in your identity provider
- `authentication.AUTH_API_KEY`: Key used for authentication between Orchestrate internal applications. Set this variable to the value you want to use as Key for authentication, we recommend you to use a UUID format

## Set-up Orchestrate 
You need to define the kubernetes namespace where you will deploy Orchestrate.
Set the env variable `TARGET_NAMESPACE` with the value of kubernetes namespace.

```bash
export TARGET_NAMESPACE=<KUBERNETES_NAMESPACE>
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
