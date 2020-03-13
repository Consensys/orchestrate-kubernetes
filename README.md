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
- [Configure Orchestrate](#configure-orchestrate)
- [Set-up Orchestrate ](#set-up-orchestrate)
  - [Set-up tiller ](#set-up-tiller )
- [Deploy Orchestrate](#deploy-orchestrate)
- [Delete deployment of Orchestrate](#delete-deployment-of-orchestrate)


The following repo has example reference implementations of deploying Orchestrate and his dependency using k8s, HELM Chart and Helmfile. 
This is intended to get developers and ops people familiar with how to run Orchestrate in k8s and understand the concepts involved.

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