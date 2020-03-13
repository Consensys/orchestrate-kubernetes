# Vault

## Goals

This chart aims to deploy a prod-worthy [Hashicorp's Vault](https://www.vaultproject.io/) on Kubernetes, backed by AWS.

## Requirements

This chart assumes that the following AWS resources exist:

- a **DynamoDB** table for state and leader election (required for high availability)
- a **KMS** key for auto-unsealing
- an [**AWS Secret**](aws.amazon.com/secrets-manager)
- an **IAM Role** allowing access to above ressources

See related `terraform` config [here](https://gitlab.com/ConsenSys/client/fr/core-stack/infra/vault-core-stack).

The following Kubernetes features are also expected:

- RBAC
- [**kube2iam**](https://github.com/jtblin/kube2iam), where the Kubernetes worker nodes are allowed to assume Vault's **IAM Role**
- Some means to automatically validate [Kubernetes CSRs](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/); see [Kapprover](https://github.com/proofpoint/kapprover).

To enable the initialization and provisionning hooks, the chart needs to have acces to a `Docker` image with the following programs available:

- `vault`
- `aws-cli`
- `jq`

Feel free to use https://hub.docker.com/r/eviln1/vault-init

## Features

### Initialization

This chart allows for automatic [Vault initialization](https://www.vaultproject.io/docs/commands/operator/init.html), performed by a Kubernetes `Job`, created by a [Helm hook](https://helm.sh/docs/charts_hooks/) and executed in the `post-install` phase of the Helm chart deployment.

The initialization consists of following steps:

- `vault operator init`: generates a [root token](https://www.vaultproject.io/docs/concepts/tokens.html#root-tokens), unseal and recovery keys. These are stored in the provided AWS Secret.
- enable [Kubernetes authentication](https://www.vaultproject.io/docs/auth/kubernetes.html): allow Pods to request tokens

### Provisionning

This chart allows for automatic provisionning of Vault resources through `values.yaml` files. These resources are:

- One secrets engine (KV v2) #TODO: make it configurable.
- An arbitrary number of configurable [policies](https://www.vaultproject.io/docs/concepts/policies.html)
- An arbitrary number of configurable roles for the Kubernetes auth backend

As for the Initialization step, this is done using a `Job`, created by a Helm hook, and executed in the `post-install` and `post-upgrade` phases.


## Configuration

Entries in the `values.yaml` adhere to the de-facto practices of the Helm chart developers community; ie the behaviour for `replicaCount`, `image`, `resources`, `fullnameOverride` etc... is predictable.

Values specific to this charts are :

- `aws.kube2iamRole`: ARN of the AWS IAM role (string)
- `vault.init.enabled`: Create initialization hook ressources (boolean)
- `vault.init.awsRegion`: AWS Region in which the resources are created (string)
- `vault.init.awsSecretID`: Alias / Name of the AWS Secretmanager's secret where the root token is stored (string)
- `vault.init.image`: Similar to the `image` map; references the `Docker` image used for initialization. (map)
- `vault.provision.enabled` Create provisionning hook ressources (boolean)
- `vault.provision.awsRegion`: AWS Region in which the resources are created (string)
- `vault.provision.awsSecretID`: Alias / Name of the AWS Secretmanager's secret where the root token is stored (string)
- `vault.provision.image`: Similar to the `image` map; references the `Docker` image used for provisionning. (map)
- `vault.provision.secretsPath`: The path on which to mount the KV v2 secrets engine.
- `vault.provision.policies`: A list of maps describing the policies to provision:
  ```yaml
    - name: "example-policy"
      policy: |
        path "secrets/data/keys/*" {
          capabilities = ["create", "read"]
        }
  ```
  The `policy` key contains a policy in `.hcl` or `.json` format


- `vault.provision.roles`: A list of maps describing the roles to provision:
  ```yaml
    - name: "example-role"
      serviceAccountNames: ["client-serviceaccount"]
      serviceAccountNamespaces: ["client-namespace"]
      policies: ["example-policy"]
  ```
- `vault.config`: A `yaml` representation of the [Vault configuration](https://www.vaultproject.io/docs/configuration/index.html). Will be rendered to JSON, and passed to Vault _after being merged with the default `values.yaml`_
