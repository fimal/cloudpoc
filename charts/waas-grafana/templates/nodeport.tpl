{{/*
Include a service node port
*/}}
{{- define "waas.nodeport" }}
{{- if eq .Values.serviceType "NodePort" }}
{{- $port := toString .Values.nodePort | int }}
{{- if  $port }}
{{- printf "nodePort: %d" $port }}
{{- end }}
{{- end }}
{{- end }}