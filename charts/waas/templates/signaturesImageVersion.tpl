{{/*
Include a component version with option to override
*/}}
{{- define "waas.signatures-image.version" }}
{{- if .Values.image.version }}
{{- .Values.image.version }}
{{- else if .Values.global.signaturesImage.version }}
{{- .Values.global.signaturesImage.version }}
{{- else }}
{{- .Values.global.image.version }}
{{- end }}
{{- end }}
