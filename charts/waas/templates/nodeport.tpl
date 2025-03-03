{{/*
Include a service node port
*/}}
{{- define "waas.nodeport" }}
{{- if .Values.global.useNodePort }}
{{- $p1 := toString .Values.nodePort | int }}
{{- $p2 := toString .Values.global.nodePortRangeStart | int }}
{{- $p3 := 0 }}
{{- $port := 0 }}
{{- if .Extra }}
{{- $p3 = toString .Extra | int }}
{{- $p3 = add ( mul $p1 10) $p3 }}
{{- $port = add $p3 $p2 }}
{{- else }}
{{- $port = add $p1 $p2 }}
{{- end }}
{{- printf "nodePort: %d" $port }}
{{- end }}
{{- end }}
