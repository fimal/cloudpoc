{{/*
Include a component registry with option to override
*/}}
{{- define "waas.signatures-image.registry" }}
{{- if .Values.image.registry }}
{{- .Values.image.registry }}
{{- else if .Values.global.signaturesImage.registry }}
{{- .Values.global.signaturesImage.registry }}
{{- else }}
{{- .Values.global.image.registry }}
{{- end }}
{{- end }}
