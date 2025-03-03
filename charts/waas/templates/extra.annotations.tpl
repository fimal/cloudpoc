{{/*
Include global annotations
*/}}
{{- define "waas.annotations" }}
{{- range $k, $v := .Values.global.extraAnnotations }}
{{ $k }} : {{ toYaml $v}}
{{- end }}

{{- range $k, $v := .Values.extraAnnotations }}
{{ $k }} : {{ toYaml $v}}
{{- end }}
{{- end }}