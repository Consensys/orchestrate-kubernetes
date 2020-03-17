<p align="center">
  <img src="orchestrate-logo.png" width="300px" alt="Orchestrate Logo"/>
</p>

PegaSys Orchestrate is a platform that enables enterprises to easily build secure and reliable applications on Ethereum blockchains.

It provides extensive features to connect to blockchain networks:

- Transaction management (transaction crafting, gas management, nonce management, transaction listening...)
- Account management with private key storage in Hashicorp Vault
- Smart Contract Registry
- Multi-chain & Multi-protocol (public or private)

For more information please refer to [PegaSys Orchestrate Official Documentation](https://docs.orchestrate.pegasys.tech/).

# Orchestrate-Kubernetes (k8s)

- [Requirements](#requirements)
  - [Deployment](#deployment)
  - [Vault for AWS](#vault-for-aws)
  - [Access to registry](#access-to-registry) 
- [Configure Orchestrate](#configure-orchestrate)  
- [Set-up Orchestrate ](#set-up-orchestrate)
  - [Set-up tiller ](#set-up-tiller )
- [Deploy Orchestrate](#deploy-orchestrate)
- [Delete deployment of Orchestrate](#delete-deployment-of-orchestrate)


The following repo has example reference implementations of deploying Orchestrate and his dependency using k8s, HELM Chart and Helmfile. 

## Requirements
### Deployment
- [Kubernetes](https://kubernetes.io/) 1.12+
- [Helm](https://helm.sh/docs/) v2
- [helmfile](https://github.com/roboll/helmfile)
- [Helm Diff plugin](https://github.com/databus23/helm-diff)

### Vault for AWS
- [DynamoDB](https://aws.amazon.com/dynamodb/) table for state and leader election (required for high availability)
- [AWS KMS](https://aws.amazon.com/kms/) key for auto-unsealing
- [AWS Secret](aws.amazon.com/secrets-manager)
- [IAM](https://aws.amazon.com/iam/) Role allowing access to above ressources

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

### Set-up tiller 
> **Note:** _Only necessary for HELM v2_

Apply Role Base Access Control to tiller
```bash
cat tiller.yaml | envsubst | kubectl apply -f -
```

Deploy tiller
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