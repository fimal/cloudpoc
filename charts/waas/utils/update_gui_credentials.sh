#!/usr/bin/env bash
###
# IMPORTANT:
#    - User id that running this script should be eligible to make kubectl commands
#    - K8S environment should be set. 'kubectl' should be resolvable in the shell.
###

### Default variables
NAMESPACE="default"
### Init valirables
USERNAME=
PASSWORD=
GUI_LABEL="configid=waas-gui-container"
GUI_DEPLOYMENT_NAME="deployment.apps/waas-gui-deployment"
# Max amount of time to wait for job to complete
MAX_TTL_SECS=15
###

help () {
  echo "Usage: $(basename $0) [OPTIONS]" >&2
  echo "Options:" >&2
  printf "%7s - %s\n" "[-u]" "Username (required parameter)" >&2
  printf "%7s - %s\n" "[-p]" "Password (required parameter)" >&2
  printf "%7s - %s\n" "[-n]" "Kubernetes namespace (default: \"${NAMESPACE}\")" >&2
  printf "%s\n" " Example: $0 -u waas_user -p waas_password" >&2
  exit 0
}

function gui_authentication {
    local guiUserName=$1
    local guiPassword=$2

    secret_name="waas-gui-users-secret"
    set -e
    kubectl create secret generic ${secret_name} --from-literal=password=${guiPassword} --from-literal=user=${guiUserName} --namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - 
    set +e
}

function bump_deployment {
  local resourceName=$1

  set -e
  kubectl rollout restart "${resourceName}" --namespace "${NAMESPACE}"
  set +e
}

while getopts 'p:u:n:' OPTION; do
  case "$OPTION" in
    u)
      USERNAME="$OPTARG"
      ;;
    p)
      PASSWORD="$OPTARG"
      ;;
    n)
      NAMESPACE="$OPTARG"
      ;;
    *)
      help
      ;;
  esac
done

if [[ "${USERNAME}" == "" || "${PASSWORD}" == "" ]]; then
  help
fi

echo  "Updating credentials"

# Replace secret with updated username/password
gui_authentication "${USERNAME}" "${PASSWORD}"

# Bump GUI deployment to take effect of the updated username/password
bump_deployment "${GUI_DEPLOYMENT_NAME}"

## Wait for gui deployment to update credentials
kubectl wait --timeout=90s --for=condition=ready -n kwaf pod -l configid=waas-gui-container 
