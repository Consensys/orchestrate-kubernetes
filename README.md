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
- [2. Configure Orchestrate](#2-configure-orchestrate)
  - [2.1. Docker registry credentials](#21-docker-registry-credentials)
  - [2.2. Namespace environement values](#22-namespace-environement-values)
  - [2.3. Hashicorp Vault](#23-hashicorp-vault)
  - [2.4. Multi-tenancy](#24-multi-tenancy)
- [3. Deploy Orchestrate](#3-deploy-orchestrate)

This repository contains an implementation example on how to deploy Orchestrate and its dependencies using Kubernetes, Helm charts and Helm files.
This is intended to help the understanding on how to run and configure Orchestrate using Kubernetes.

# Compatibility

| Orchestrate-kubernetes versions | Orchestrate versions |
|---------------------------------|----------------------|
| master/HEAD                     | Orchestrate v2.4.x   |
| v3.0.0                          | Orchestrate v2.4.x   |

# 1. Requirements

## 1.1. Credentials

- Credentials to pull Orchestrate's Docker images;

!!! Note: 
  If you do not have them yet, please contact [orchestrate@consensys.net](mailto:orchestrate@consensys.net).

## 1.2. CLI tools

- [Kubernetes](https://kubernetes.io/) version 1.12 or upper;
- [Helm](https://helm.sh/) version 3 or upper;
- [Helmfile](https://github.com/roboll/helmfile);
- [Helm diff plugin](https://github.com/databus23/helm-diff).

## 1.3. Hashicorp Vault on AWS (optionnal)

- [Amazon DynamoDB](https://aws.amazon.com/dynamodb/);
- [AWS Key Management Service (KMS)](https://aws.amazon.com/kms/);
- [AWS Secrets Manager](aws.amazon.com/secrets-manager);
- [AWS Identity and Access Management (IAM)](https://aws.amazon.com/iam/).

# 2. Configure Orchestrate

## 2.1. Docker registry credentials

Set your Orchestrate Docker images' credentials setting the following environment variable `$REGISTRY_USERNAME`, `$REGISTRY_PASSWORD` and optionally `$REGISTRY_URL`, see [`values/tags.yaml`](./values/tags.yaml) 

```helmyaml
registry:
  url: {{ env "REGISTRY_URL" | default "docker.cloudsmith.io" }}
  credentials:
    username: {{ requiredEnv "REGISTRY_USERNAME" }}
    password: {{ requiredEnv "REGISTRY_PASSWORD" }}
```

## 2.2. Namespace environement values

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

## 2.3. Hashicorp Vault

If you want to deploy Hashicorp Vault in kubernetes please follow the instructions in [`vaults/README.md`](vaults/). It will also detail how to configure Orchestrate accordingly

## 2.4. Multi-tenancy

- `multitenancy.enabled`: Enables this Orchestrate feature (default: false).
- `authentication.AUTH_JWT_CLAIMS_NAMESPACE`: Tenant namespace to retrieve tenantID in OpenId or Access Token (JWT) (default: "http://tenant.info/"). You will find this information on your identity provider.
- `authentication.AUTH_JWT_CERTIFICATE`: Certificate of authentication service **encoded in base64**. You will find the information in your identity provider.
- `authentication.AUTH_API_KEY`: This key is used for authentication internally on Orchestrate, we highly recommend to use a UUID format.
  
# 3. Deploy Orchestrate

1. Set the variable `TARGET_NAMESPACE` to the Kubernetes namespace where Orchestrate will be deployed (the same value as `<OrchestrateNamespace>` previously used)

```bash
export TARGET_NAMESPACE=<OrchestrateNamespace>
```

2. Deploy Orchestrate and its dependencies with the following command:

```bash
helmfile -f helmfile.yaml -e $TARGET_NAMESPACE apply --suppress-secrets
```

!!!hint
  to delete Orchestrate's deployment run the following command:

```bash
helmfile -f helmfile.yaml -e $TARGET_NAMESPACE delete --purge
```

> Notes: Update `values/tags.yaml` with valid bintray credentials before executing above command