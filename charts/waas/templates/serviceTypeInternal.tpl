{{/*
Include an internal service node port
*/}}
{{- define "waas.serviceTypeInternal" }}
{{- if .Values.global.useNodePort }}
  type: NodePort
{{- else }}
  type: ClusterIP
{{- end }}
{{- end }}
