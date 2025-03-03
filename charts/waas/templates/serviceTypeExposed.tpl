{{/*
Include an internal service node port
*/}}
{{- define "waas.serviceTypeExposed" }}
{{- if .Values.global.useLoadBalancer }}
  type: LoadBalancer
{{- else }}
{{- include "waas.serviceTypeInternal" . }}
{{- end }}
{{- end }}
