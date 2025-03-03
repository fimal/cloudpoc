{{- /*
returns the cluster configuration 
options:
- clustered
- standalone
- sentinel
*/ -}}
{{- define "waas.redis.mode" -}}
{{- $mode := "" -}}
{{- if eq .Values.global.redis.configuration "clustered" -}}
    {{- $mode = "clustered" -}}
{{- else if eq .Values.global.redis.configuration "ha" -}}
    {{- $mode = "ha" -}}
{{- else if eq .Values.global.redis.configuration "standalone" -}}
    {{- $mode = "standalone" -}}
{{- else }}
    {{- $mode = "standalone" -}}
{{- end -}}
{{- $mode -}}
{{- end -}}