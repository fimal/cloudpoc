#/bin/bash
function test_dashboards_loaded {
    echo "Verify Grafana dashboards  are loaded"
    num_of_waas_dashboards="$(curl -f -s -u ${GF_SECURITY_ADMIN_USER}:${GF_SECURITY_ADMIN_PASSWORD} -H "Content-Type: application/json" http://${GRAFANA_SERVICE}/api/search?dashboardsIds | jq .[].title | wc -l)"
    res=$?
    echo "Found $num_of_waas_dashboards WAAS dashboards"
    if [ $num_of_waas_dashboards -ge 3 ];then echo "Passed" && exit 0;else echo "Failed, cURL Code is $res" && exit 1;fi
}
echo "running as user: ${UID} for namespace ${NAMESPACE}"

function test_prometheus {
    echo "Check Prometheus is ready"
    count=0
    interval=2
    max_retries=3
    while true;
    do
    count=$((count+1))
    code="$(curl --connect-timeout 5 -s -o /dev/null -w '%{http_code}' -L http://${PROMETHEUS_SERVICE}:9090/-/healthy)"
    echo "[$(date +"%T")] try number $count - result $code"
    if [[ "$code" == 200 ]]; then break;fi
    if [[ "$count" -gt "$max_retries" ]]; then echo "Failed, cURL Code is $code" && exit 1;fi
    sleep $interval
    done
}
test_prometheus
echo "Prometheus is ready"
test_dashboards_loaded