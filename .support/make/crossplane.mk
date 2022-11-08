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
  credentials: |
    [default]
    aws_access_key_id = $(AWS_ACCESS_KEY_ID)
    aws_secret_access_key = $(AWS_SECRET_ACCESS_KEY)
    aws_session_token = $(AWS_SESSION_TOKEN)
endef

export CROSSPLANE_NAMESPACE
export CROSSPLANE_SECRET

## Ensures that variable is defined.
ensure-defined = \
	$(if $(value $1),,$(error Error: Variable $1 is expected but undefined))

## Create initial Crossplane namespace and cloud provider secret.
crossplane-init = \
	$(call ensure-defined,AWS_ACCESS_KEY_ID) \
	$(call ensure-defined,AWS_SECRET_ACCESS_KEY) \
	$(call ensure-defined,AWS_SESSION_TOKEN) \
	kubectl apply -f - <<< "$$CROSSPLANE_NAMESPACE"; \
	kubectl apply -f - <<< "$$CROSSPLANE_SECRET"
