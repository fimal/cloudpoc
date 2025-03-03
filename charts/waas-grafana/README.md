# Project Title
This is helm for Grafana - deployment MUST be in KWAF NAMESPACE
## Getting Started
git clone http://bitbucket:7990/scm/waas/waas_helms.git

### HELM TEMPLATE GENERATOR FOR GRAFANA
```
helm template helm3/waas-grafana/ -n kwaf -f helm3/tests/grafana.yaml --output-dir helm3/hacks/target
```

### HELM INSTALL EXAMPLE FOR GRAFANA
### NOTE: Deployment MUST be in KWAF NAMESPACE, Please choose correct NAMESPACE!!!
```
helm install grafana -n kwaf helm3/waas-grafana -f helm3/tests/grafana.yaml --debug --wait
```

## HELM TEST
```
helm test <<HELM-RELEASE-NAME>> -n kwaf
```

## HELM DELETE
```
helm uninstall <<HELM-RELEASE-NAME>> -n kwaf
```
