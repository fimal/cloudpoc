#!/usr/bin/env bash
##
##############################################################################
##                                                                          ##
## use this script to generate all cluster roles, cluster role bindings     ##
## and service account manifests needed by kwaf installation                ##
##                                                                          ##
##--------------------------------------------------------------------------##
##                                                                          ##
## Parameters:                                                              ##
## -n       namespace                                                       ##
## -o       output file                                                     ##
##                                                                          ##
## Example usage:                                                           ##
## ./create_rbac_manifests.sh -n kwaf -o rbac.yaml                          ##
##                                                                          ##
## Note:                                                                    ##
## Everything else provided on the command line will be used as arguments   ##
## to the helm template command used internally                             ##
##                                                                          ##
##--------------------------------------------------------------------------##
##                                                                          ##
## Once the output file is created use kubectl to apply it to your cluster  ##
## Note: the namespace provided with the -n flag should already exist       ##
## in your cluster prior to using kubectl to apply the output file          ##
##                                                                          ##
##--------------------------------------------------------------------------##
##                                                                          ##
## To install kwaf without creating the rbac components                     ##
## A. run the create_rbac_manifests.sh script                               ##
## B. apply the output file created by the script                           ##
## C. install kwaf with the global.rbac parameter set to false              ##
##                                                                          ##
##############################################################################

usage () {
    echo "usage: $0 -n namespace -o output_file"
    echo "example:"
    echo "$0 -n kwaf -o ./rbac.yaml"
}

while getopts ":n:o:" options; do
  case "${options}" in
    n)
        NAMESPACE=${OPTARG}
        ;;
    o)
        OUTPUT=${OPTARG}
        ;;
  esac
done

shift 4
echo "creating manifests for namespace => $NAMESPACE."
echo "saving into file => $OUTPUT"

if [[ "$NAMESPACE" == "" ]]; then
    echo "namespace is required. use -n to provide namespace"
    usage
    exit 1
fi

if [[ "$OUTPUT" == "" ]]; then 
    echo "output file is required. use -o to provide output file"
    usage
    exit 1
fi



CMD="helm template temp -n $NAMESPACE ./waas --set global.elasticStorageManagement.policy=poc $@"
for t in $(helm template temp -n $NAMESPACE ./waas --set global.elasticStorageManagement.policy=poc $@| grep "^kind: ServiceAccount\|^kind: ClusterRole$\|^kind: Role$\|^kind: ClusterRoleBinding\|^kind: RoleBinding" -B2 | grep "# Source: " | sed 's@# Source: waas/@@'); do
    echo $t
    CMD="$CMD -s $t"
done
$CMD > $OUTPUT
