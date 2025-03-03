{{/*
fluentbit container manifest
reads enforcer logs (security + access) and sends over http(s) to logstash
*/}}
{{ define "waas.fluent-bit-container" }}
- name: fluentbit
  image: {{ include "waas.image.registry" . | coalesce .Values.containers.fluentbit.registry }}/waas-fluentbit{{ include "waas.image.version" . | coalesce .Values.containers.fluentbit.version }}
  imagePullPolicy: {{ .Values.global.image.pullPolicy }}
  env:
  - name: FB_LS_HOST
    {{- if .Values.alternateLogstashHost }}
    value: {{ .Values.alternateLogstashHost | quote }}
    {{- else }}
    value : waas-logstash.{{ .Release.Namespace }}.svc
    {{- end }}
  - name: FB_LS_PORT
    {{- if .Values.global.logstash.servicePort }}
    value: {{ .Values.global.logstash.servicePort | quote }}
    {{- else }}
    value: "2020"
    {{- end }}
  - name: FB_PREFIX
    value: "{{ .Chart.Name }}.{{ .Release.Namespace }}"
  - name: FB_LOG_LEVEL
    value: info
  - name: FB_FLUSH
    value: "1"
  - name: FB_HTTP_PORT
    {{- if .Values.global.fluentbit.httpPort }}
    value: {{ .Values.global.fluentbit.httpPort | quote }}
    {{- else }}
    value: "2025"
    {{- end }}
  - name: FB_LOGS_PATH
    value: "/logs"
  - name: FB_MEM_BUF_LIMIT
    value: 100m
  - name: FB_HTTP_LISTEN
    {{- if .Values.global.ipv6Support }}
    value: "::"
    {{- else }}
    value: "0.0.0.0"
    {{- end }}
  - name: FB_STATSD_PORT
    value: "{{ .Values.statsdPort | default "8125" }}"
  - name: FB_STATSD_LISTEN
    {{- if .Values.global.ipv6Support }}
    value: "::1"
    {{- else }}
    value: "127.0.0.1"
    {{- end }}
{{- with .Values.tls.clients.fluentbit }}
  {{- if .enabled }}
  - name: FB_TLS
    value: "On"
  - name: FB_TLS_MTLS
    {{- if .clientAuth }}
    value: "On"
    {{- else }}
    value: "Off"
    {{- end }}
  - name: FB_TLS_VERIFY
    {{- if .verify }}
    value: "On"
    {{- else }}
    value: "Off"
    {{- end }}
   {{- if ne .ca "" }}
  - name: FB_TLS_CA_FILE
    value: {{ .ca }}
   {{- end }}
   {{- if ne .clientCertificate "" }}
  - name: FB_TLS_CRT_FILE
    value: {{ .clientCertificate }}
   {{- end }}
   {{- if ne .clientKey "" }}
  - name: FB_TLS_KEY_FILE
    value: {{ .clientKey }}
   {{- end }}
  {{- else }}
  - name: FB_TLS
    value: "Off"
  {{- end}}
{{- end }}
  resources:
    {{- toYaml .Values.containers.fluentbit.resources | nindent 4 }}
  {{- with .Values.containers.fluentbit.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
{{- /* fluentbit client TLS mounts */}}
{{- with .Values.tls.clients.fluentbit }}
  {{- if eq .enabled true -}}
    {{- with .mounts}}
      {{- toYaml . | nindent 2 }}
    {{- end }}
  {{- end }}
{{- end }}
  - name: logs-volume
    mountPath: /logs
{{- end -}}
