{{/*
determine number of redis replicas based on configuration
if standalone - 1 replica only
if ha - at least three replicas (1 master and the rest replicas)
if clustered - 3 or more replicas. and size/replicas should be a whole number
*/}}
{{- define "waas.redis.replicas" -}}
{{- $mode := include "waas.redis.mode" . }}
{{- $masters := int .Values.cluster.masters }}
{{- $replicas := int .Values.cluster.replicas }}
{{- if eq $mode "standalone" -}}
  {{- if or (ne $masters 1) (ne $replicas 0) -}}
    {{- fail "standalond configuration mandates 1 master and zero replicas" -}}
  {{- else -}}
1
  {{- end -}}
{{- else if eq $mode "ha" -}}
  {{- if or (ne $masters 1) (lt $replicas 2) -}}
    {{- fail "ha configuration mandates 1 master and at least 2 replicas" -}}
  {{- else -}}
{{ add $masters $replicas  }}
  {{- end -}}
{{- else if eq $mode "clustered" -}}
  {{- if lt $masters 3 -}}
    {{- fail "clustered configuration mandates at least 3 masters" -}}
  {{- else -}}
{{ add ( mul $masters $replicas ) $masters }}
  {{- end -}}
{{- else -}}
  {{$errmsg := printf "mode %s unsupported" $mode}}
  {{ fail $errmsg }}
{{- end -}}

{{- end -}}