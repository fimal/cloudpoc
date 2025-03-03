{{/*
create masters init list
*/}}
{{- define "waas.elasticsearch.masters" }}
{{- if eq (.Values.replicaCount | toString) "1" }}
waas-elasticsearch-deployment-0
{{- else if eq (.Values.replicaCount | toString) "2" }}
waas-elasticsearch-deployment-0,waas-elasticsearch-deployment-1
{{- else }}
waas-elasticsearch-deployment-0,waas-elasticsearch-deployment-1,waas-elasticsearch-deployment-2
{{- end }}
{{- end }}
