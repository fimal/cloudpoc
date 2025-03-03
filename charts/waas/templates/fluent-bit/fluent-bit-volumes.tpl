{{/*
volumes configuration for pods where
 one container (enforcer) writes logs
 and another (fluent-bit) reads them
 and a third (log-rotate) rotates them
*/}}
{{- define "waas.fluent-bit-volumes" }}
- name: logs-volume
  emptyDir:
    {{- toYaml .Values.volumeLogs | nindent 4 }}
{{/* fluentbit client TLS volumes */}}
{{- with .Values.tls.clients.fluentbit }}
  {{- if eq .enabled true -}}
    {{- with .volumes}}
      {{- toYaml . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}