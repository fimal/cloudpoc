#!/bin/bash

# Script to bring up redis in cluster or ha (sentinel) modes .
#  
# Persistent volume "cfg" should be used if you'd like pods to recover and rejoin cluster after pod reset,
# otherwise pods will restart but will not join cluster since they need /conf/nodes.conf to recover
# 
# Script is only active for pod #0
#
# In clustered mode, cluster state is checked and if cluster already running, script does nothing .
# If cluster doesn't exist, script awaits all relevant pods to be up (masters + replicas) and adds them
# to form a redis cluster .
#
# If any of the relevant pods is not up or not responding, redis-cli container (running this script) in pod #0
# restarts forever, the pod itself isn’t killed .
# If bad pod recovers (same for master or slave), pod #0 succeeds in building cluster .


SEPARATOR="----------------------------------------------------------------\n"

printf "### ################################################################\n"
printf "### \n"
printf "### redis options:\n$SEPARATOR"
printf "### redis mode = $REDIS_MODE\n"
printf "### redis masters = $REDIS_MASTERS\n"
printf "### redis replicas = $REDIS_REPLICAS\n"
printf "### redis port = $REDIS_PORT\n"
POD_COUNT=$(( REDIS_MASTERS + REDIS_MASTERS*REDIS_REPLICAS ))
printf "### total redis pods = $POD_COUNT\n"
printf "### pod roles:\n"
if [[ "$REDIS_MODE" == "clustered" ]]
then
    for i in `seq 0 $(( POD_COUNT - 1 ))`; do
        if [[ $i -lt $REDIS_MASTERS ]]; then
            printf "###   pod $i is master\n"
        else
            printf "###   pod $i is replica of $(( $i % $REDIS_MASTERS ))\n"
        fi
    done
elif [[ "$REDIS_MODE" == "ha" ]]
then
    printf "###   pod 0 is master, all the others are replicas\n"
    printf "###   and everyone is a sentinel\n"
    printf "### sentinel opts = $SENTINEL_CMD_OPTS\n"
else
    printf "standlone mode\n"
fi
printf "### \n"
printf "### ################################################################\n"
printf "### \n"
printf "### \n"

function wait_for_ready_nodes {
    printf "### waiting for $POD_COUNT redis pods to become ready\n"
    printf "### retrying $REDIS_RETRIES times (\$REDIS_RETRIES) with $REDIS_WAIT_BETWEEN_CLUSTER_CHECKS second intervals (\$REDIS_WAIT_BETWEEN_CLUSTER_CHECKS)\n"
 
    count=0
    max=${REDIS_RETRIES}
    while true; do
      PODS=$(nslookup waas-redis-headless| grep "^Name:" | wc -l)
      printf "### ready pods $PODS/$POD_COUNT\n"
      if [ "$PODS" -eq "$POD_COUNT" ]; then
        sleep 3
        printf "### \n### all $PODS pods have IP addresses\n"
        return 0
      fi
      count=$(( count+1 ))
      if [ "$count" -gt "$max" ]; then
        printf "### \n### waited too long, exiting without initializing cluster \n"
        return 1
      fi
      sleep $REDIS_WAIT_BETWEEN_CLUSTER_CHECKS
    done
}

function reset_cluster {
    set -x
    for pod_number in `seq 0 $(( POD_COUNT - 1 ))`;
    do
        POD="waas-redis-statefulset-${pod_number}.waas-redis-headless"
        redis-cli $REDIS_TLS -h $POD -p $REDIS_PORT flushall
        redis-cli $REDIS_TLS -h $POD -p $REDIS_PORT cluster reset
    done
    set +x
}

function create_cluster {
    printf "### pinging pods, giving each pod a $REDIS_WAIT_FOR_POD_PONG seconds (\$REDIS_WAIT_FOR_POD_PONG) timeout to respond\n"
    ONE_LINE=""
    for pod_number in `seq 0 $(( POD_COUNT - 1 ))`;
    do
        POD="waas-redis-statefulset-${pod_number}.waas-redis-headless"
        if [[ $pod_number -lt $REDIS_MASTERS ]]; then
            ONE_LINE="$ONE_LINE ${POD}:${REDIS_PORT}"
        fi
        timeout $REDIS_WAIT_FOR_POD_PONG redis-cli -h $POD -p ${REDIS_PORT} $REDIS_TLS ping
        res=$?
        if [[ $res -ne 0 ]]; then
            printf "### pod $pod_number pinged but didn't pong\n"
            return 1
        fi
    done
    printf "### all ponged\n$SEPARATOR"
    printf "### creating cluster with $REDIS_MASTERS masters\n"
    FIRST_NODE="waas-redis-statefulset-0.waas-redis-headless"
    redis-cli -h $FIRST_NODE -p $REDIS_PORT --cluster create $REDIS_TLS $ONE_LINE --cluster-yes
    res=$?
    if [[ $res -ne 0 ]]; then
        printf "### failed to create cluster. exit code $res\n"
        return 1
    fi
    printf "### $SEPARATOR"
    printf "### waiting $REDIS_WAIT_FOR_CLUSTER_CREATION seconds (\$REDIS_WAIT_FOR_CLUSTER_CREATION) for cluster creation to finish\n"
    sleep $REDIS_WAIT_FOR_CLUSTER_CREATION
    printf "\n### CLUSTER INFO\n### $SEPARATOR"
    redis-cli -h $FIRST_NODE -p $REDIS_PORT $REDIS_TLS cluster info
    printf "### $SEPARATOR"
    printf "### adding replicas $REDIS_MASTERS to $(( POD_COUNT - 1 ))\n"
    for pn in $(seq $REDIS_MASTERS $(( POD_COUNT - 1 )));
    do
        current_master=$(( $pn % $REDIS_MASTERS ))
        res=$?
        if [[ $res -ne 0 ]]; then
            printf "### failed to calculate replicas master. exit code $res\n"
            return 1
        fi
        printf "### pod $pn is replica of $current_master\n"
        POD="waas-redis-statefulset-${pn}.waas-redis-headless"
        MASTER_POD="waas-redis-statefulset-${current_master}.waas-redis-headless"
        MASTER_ID=$(redis-cli $REDIS_TLS -h $MASTER_POD -p $REDIS_PORT cluster myid)
        res=$?
        if [[ $res -ne 0 ]]; then
            printf "### failed to get master id of $MASTER_POD of replica pod $POD. exit code $res\n"
            return 1
        fi
        printf "### adding pod $POD to redis cluster, will act as a replica of $MASTER_POD with id $MASTER_ID\n"
        # add the current node to the cluster
        redis-cli $REDIS_TLS --cluster add-node $POD:$REDIS_PORT $FIRST_NODE:$REDIS_PORT
        res=$?
        if [[ $res -ne 0 ]]; then
            printf "### failed adding $POD to cluster. exit code $res\n"
            return 1
        fi
        # wait some
        sleep $REDIS_WAIT_AFTER_ADDING_REPLICA_TO_CLUSTER
        # now designate it as a replica
        redis-cli $REDIS_TLS -h $POD -p $REDIS_PORT cluster replicate $MASTER_ID
        res=$?
        if [[ $res -ne 0 ]]; then
            printf "### failed configuring $POD as a replica of $MASTER_POD with $MASTER_ID. exit code $res\n"
            return 1
        fi
    done
    sleep 10
    printf "### $SEPARATOR### CLUSTER INFO\n### $SEPARATOR"
    redis-cli -h $FIRST_NODE -p $REDIS_PORT $REDIS_TLS cluster info
    printf "### $SEPARATOR### CLUSTER NODES\n### $SEPARATOR"
    redis-cli -h $FIRST_NODE -p $REDIS_PORT $REDIS_TLS cluster nodes | sort -k 2
    printf "### $SEPARATOR"
    return 0
}

function check_cluster_state {
    printf "### $SEPARATOR### CLUSTER INFO\n### $SEPARATOR"
    redis-cli $REDIS_TLS cluster info
    printf "### $SEPARATOR### CLUSTER NODES\n### $SEPARATOR"
    redis-cli $REDIS_TLS cluster nodes
    printf "### $SEPARATOR"

    required_pods=$(( REDIS_MASTERS + REDIS_MASTERS * REDIS_REPLICAS ))
    known_nodes=$(redis-cli $REDIS_TLS cluster info| grep cluster_known_nodes|sed s'/.*:\(.*\)$/\1/'|tr -d '[:space:]')
    cluster_size=$(redis-cli $REDIS_TLS cluster info| grep cluster_size|sed s'/.*:\(.*\)$/\1/'|tr -d '[:space:]')
    printf "### checking if cluster sized correctly\n"
    printf "### required pod number = $required_pods, actual cluster nodes = $known_nodes\n"
    printf "### required master count = $REDIS_MASTERS, actual master count = $cluster_size\n"
    if [ $required_pods -eq $known_nodes ] && [ $REDIS_MASTERS -eq $cluster_size ]; then
      printf "### cluster configured\n"
      printf "### \n$SEPARATOR"
      return 0
    else
      printf "### $required_pods != $known_nodes or $REDIS_MASTERS != $cluster_size\n"
      printf "### cluster not configured\n"
      printf "### \n$SEPARATOR"
      return 1
    fi
}

function run_sentinel {
    exec /usr/local/bin/redis-sentinel /conf/sentinel.conf ${SENTINEL_CMD_OPTS}
}

function setup {
    case "$REDIS_MODE" in
        clustered)
            # if first node
            if echo "$HOSTNAME"| grep -Eq "^.*set-0$"; then
                # check if cluster setup was already done
                printf "### will check cluster state in $REDIS_WAIT_BEFORE_CHECK_CLUSTER seconds (\$REDIS_WAIT_BEFORE_CHECK_CLUSTER)\n"
                sleep $REDIS_WAIT_BEFORE_CHECK_CLUSTER
                check_cluster_state
                if [ $? -eq 0 ]; then
                    printf "### cluster is already ready\n$SEPARATOR"
                    return 0
                fi

                printf "### setting up cluster\n"
                # wait for all nodes to get an IP address
                wait_for_ready_nodes
                res=$?
                if [[ $res -ne 0 ]]; then
                    printf "### failed checking if pods are ready. exit code was $res\n"
                    exit 1
                fi

                printf "### $SEPARATOR### waiting for pods to stabilize for $REDIS_WAIT_PODS_STABLE_BEFORE_CLUSTER_CREATION seconds (\$REDIS_WAIT_PODS_STABLE_BEFORE_CLUSTER_CREATION) before forming redis cluster\n"
                sleep $REDIS_WAIT_PODS_STABLE_BEFORE_CLUSTER_CREATION 
                
                #configure the cluster
                create_cluster
                res=$?
                if [[ $res -ne 0 ]]; then
                    printf "### failed setup cluster. exit code was $res\n"
                    # force redis-cli ($0) container to restart
                    exit 1
                else
                    echo "ok" > /conf/iamready
                    printf "### am ready\n"
                fi
            else
                printf "### not the first one\n"
                echo "ok" > /conf/iamready
            fi
            ;;
        ha)
            printf "### ha mode, configuring and lunching sentinel\n"
            # wait for all nodes to get an IP address
            wait_for_ready_nodes
            res=$?
                if [[ $res -ne 0 ]]; then
                    exit 1
                fi
            rm -rf /conf/iamready
            run_sentinel

            ;;
        standalone)
            printf "### really shouldn't run redis-cli container in standalone mode\n"
            exit 1
            ;;
        *)
            printf "### unknown node [$REDIS_MODE], defaulting to standalone\n"
            printf "### really shouldn't run redis-cli container in standalone mode\n"
            exit 1
            ;;
    esac
}


# handle incoming signals
trap 'quit=1' SIGINT SIGTERM

setup

printf "### $0 going into sleep mode\n"
quit=2
while [ "$quit" -ne 1 ]; do
    if [[ "$quit" -eq 2 ]]; then
        #printf "### \n\ngoing into sleep mode $(date '+%Y/%m/%d %H:%M:%S')\n\n"
        quit=0
    fi
    # printf "### still here. quit=$quit $(date '+%Y/%m/%d %H:%M:%S')\n"
    sleep 1
done

printf "### $0 got the signal. exiting\n"
