TARGET_NAMESPACE=orchestrate-demo

.PHONY: init
init:
	helm init --client-only

.PHONY: lint
lint:
	@yamllint -c test/yamllint_rules.yaml values/ environments/ helmfile.yaml
	@helmfile -f helmfile.yaml -e ${TARGET_NAMESPACE} lint

.PHONY: diff
diff:
	helmfile -f helmfile.yaml -e ${TARGET_NAMESPACE} diff --suppress-secrets --detailed-exitcode=false
