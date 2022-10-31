define CROSSPLANE_NAMESPACE
apiVersion: v1
kind: Namespace
metadata:
  name: crossplane-system
endef

define CROSSPLANE_SECRET
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: crossplane-system
type: Opaque
stringData:
  creds: |
    [default]
    aws_access_key_id = $(AWS_ACCESS_KEY_ID)
    aws_secret_access_key = $(AWS_SECRET_ACCESS_KEY)
endef

export CROSSPLANE_NAMESPACE
export CROSSPLANE_SECRET

## Create initial Crossplane namespace and cloud provider secret.
crossplane-init = \
	if [[ -z "$(AWS_ACCESS_KEY_ID)" || -z "$(AWS_SECRET_ACCESS_KEY)" ]]; then \
		printf "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set\n"; \
		exit 1; \
	fi; \
	kubectl apply -f - <<< "$$CROSSPLANE_NAMESPACE"; \
	kubectl apply -f - <<< "$$CROSSPLANE_SECRET"
