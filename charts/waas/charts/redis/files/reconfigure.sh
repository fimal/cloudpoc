#!/bin/bash

# from k8s docs at (https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/)
# Point to the internal API server hostname
APISERVER=https://kubernetes.default.svc

# Path to ServiceAccount token
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

# Read this Pod's namespace
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

# Read the ServiceAccount bearer token
TOKEN=$(cat ${SERVICEACCOUNT}/token)

# Reference the internal certificate authority (CA)
CACERT=${SERVICEACCOUNT}/ca.crt


# from sentinel docs (https://raw.githubusercontent.com/redis/redis/7.0/sentinel.conf)
# CLIENTS RECONFIGURATION SCRIPT
#
# sentinel client-reconfig-script <master-name> <script-path>
#
# When the master changed because of a failover a script can be called in
# order to perform application-specific tasks to notify the clients that the
# configuration has changed and the master is at a different address.
# 
# The following arguments are passed to the script:
#
# <master-name> <role> <state> <from-ip> <from-port> <to-ip> <to-port>
#
# <state> is currently always "start"
# <role> is either "leader" or "observer"
# 
# The arguments from-ip, from-port, to-ip, to-port are used to communicate
# the old address of the master and the new address of the elected replica
# (now a master).

function echod {
    if [[ "$DEBUG" == "true" ]]; then
        echo $@
    fi
}

function label_pod {
    label_value=$1
    label_name="kwaf.radware.com/redis-role"

    curl -s -o /dev/null --cacert ${CACERT} \
        --header "Authorization: Bearer ${TOKEN}" \
        -X PATCH \
        ${APISERVER}/api/v1/namespaces/kwaf/pods/${HOSTNAME} \
        -H "Accept: application/json" \
        -H "Content-Type: application/merge-patch+json" \
        --data "{\"metadata\": { \"labels\": { \"${label_name}\": \"${label_value}\"}}}"
}

# check if master and label accordingly
# if [[ "$(redis-cli $REDIS_TLS info replication|grep 'role:')" == *"master"* ]];
# then
#     echo "[$(date)] $HOSTNAME is master"
#     label_pod "master"
#     echo "      set to master" | tee -a /conf/iamready
# else
#     echo "[$(date)] $HOSTNAME is replica"
#     label_pod "replica"
#     echo "      set to replica" | tee -a /conf/iamready
# fi

MASTER=""
case $1 in
    # reconfigure event
    "kwaf-master")
      echod "reconfigure event"
      MASTER=$6
      ;;
    # startup notification event
    +monitor)
      echod "notification monitor event"
      MASTER=$2
      ;;
    #else
    *)
      echod "notification event for [$1] , doing nothing"
      ;;
esac



if [[ "$MASTER" != "" ]]; then
    echod "master is [$MASTER]"
    if [[ "$MASTER" == *"$HOSTNAME"* ]]; then
        echod "[$HOSTNAME] in [$MASTER]"
        echo "setting master label"
        label_pod "master"
    else 
        echod "[$HOSTNAME] not in [$MASTER]"
        echo "setting replica label"
        label_pod "replica"
    fi
else
    echod "master is empty"
fi

echod "log [$(date)]" $@ | tee -a /conf/iamready
