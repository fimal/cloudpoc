{{/*
Include global labels
*/}}
{{- define "waas.labels" }}
{{- range $k, $v := .Values.labels }}
{{ $k }} : {{ toYaml $v}}
{{- end }}
{{- end }}
