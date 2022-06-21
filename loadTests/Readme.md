# Performance testing

In order to run relevant perfomance tests it is recommended to run API pods on AWS `m5.xlarge`instances (4vCpus / 16Gio), at least. Or equivalent on other platforms.

These instances are targeted using the k8s node selector technique, as you may see in both the load profile and orchestrate values file. Respectively located in `environments/load.yaml` and `values/orchestrate.yaml.gotmpl`

## Deployment

### orchestrate

Define a load test namespace within you k8s cluster and set the `ORCHESTRATE_NAMESPACE` accordingly, one good choice could be :
`export ORCHESTRATE_NAMESPACE=benchmark`

The following command will deploy orchestrate in performance testing mode within the defined namespace

`helmfile apply -e load --suppress-secrets`

### Test smart contract

The provided `Counter.sol` smart contract must be deployed into a test blockchain, in the given test we have been using a Besu node. This might be changed at line 32 of the `vegeta-pod.yaml`file, accordingly with your registered/targeted chains.

The `Counter-formatted-abi.json` file will help you deploy that contract quicker using orchestrate contract registration API.

## Run test

Current test is proposed as a Pod that enables running the vegeta tool against the deployed version of orchestrate. You should be careful to run the test within the same namespace as you load instances. Using the following command :

`kubectl apply -f vegeta-pod.yaml -n $ORCHESTRATE_NAMESPACE`

If you are not using default API-KEY, the value must be changed before running at line 27 of the `vegeta-pod.yaml`file.

## Note

Current version of the test has run successfully (100% success) with the given configuration.