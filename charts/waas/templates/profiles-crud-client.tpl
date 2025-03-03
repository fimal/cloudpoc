{{/* Profiles Crud Client */}}
{{/* Environment Variables */}}
{{- define "waas.profile-crud-client.env" -}}
    - name: POLICIES_SERVICE
      value: "waas-profiles-crud.{{ .Release.Namespace }}.svc:{{ .Values.global.profilesCrud.servicePort | default 443 }}"
    {{- /* TLS settings for profiles-crud client */}}
    {{- with .Values.tls.clients.profiles }}
    - name: PC_CLIENT_TLS_ENABLED
      value: {{ .enabled | quote }}
    - name: PC_CLIENT_TLS_CLIENT_AUTH
      value: {{ .clientAuth | quote }}
    - name: PC_CLIENT_TLS_VERIFY
      value: {{ .verify | quote }}
    {{- if eq .enabled true }}
    {{- if eq .clientAuth true }}
    - name: PC_CLIENT_TLS_CERT_FILE
      value: {{ .clientCertificate | quote }}
    - name: PC_CLIENT_TLS_KEY_FILE
      value: {{ .clientKey | quote }}
    {{- end }}
    {{- if eq .verify true }}
    - name: PC_CLIENT_TLS_CA_FILE
      value: {{ .ca | quote }}
    {{- end }}
    {{- end }}
    {{- end }}
{{- end }}


{{/* Volume Mount */}}
{{- define "waas.profile-crud-client.mounts" -}}
    {{- with .Values.tls.clients.profiles }}
    {{- if eq .enabled true -}}
    {{- with .mounts}}
        {{- toYaml .  -}}
    {{- end }}
    {{- end }}
    {{- end }}
{{- end }}

{{- define "waas.profile-crud-client.volumes" }}
    {{- with .Values.tls.clients.profiles }}
    {{- if eq .enabled true -}}
    {{- with .volumes}}
    {{- toYaml . -}}
    {{- end }}
    {{- end }}
    {{- end }}
{{- end }}
