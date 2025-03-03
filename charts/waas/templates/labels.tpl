{{/*
Include global labels
*/}}
{{- define "waas.labels" }}
{{- range $k, $v := .Values.global.labels }}
{{ $k }} : {{ toYaml $v}}
{{- end }}

{{- range $k, $v := .Values.labels }}
{{ $k }} : {{ toYaml $v}}
{{- end }}
{{- end }}
