TARGET_NAMESPACE := orchestrate-demo
export TARGET_NAMESPACE

.PHONY: init
init:
	helm init --client-only

.PHONY: lint
lint:
	echo ${TARGET_NAMESPACE}
	@yamllint -c test/yamllint_rules.yaml values/ environments/ helmfile.yaml
	@helmfile -f helmfile.yaml -e ${TARGET_NAMESPACE} lint

.PHONY: diff
diff:
	helmfile -f helmfile.yaml -e ${TARGET_NAMESPACE} diff --suppress-secrets --detailed-exitcode=false
