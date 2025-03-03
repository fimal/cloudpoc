{{/*
add the volume per the deployment type: none, azure, aws, google, openshift, longhorn or kind
*/}}
{{- define "waas.elasticsearch.volumes" }}
{{- if eq .Values.persistentStorage.type "none" }}
        - name: data-volume
          emptyDir:
            sizeLimit: {{ .Values.persistentStorage.size }}
{{- end }}
{{- if eq .Values.persistentStorage.type "azure" }}
  volumeClaimTemplates:
  - metadata:
      name: data-volume
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "waas-elasticsearch-azure-disk"
      resources:
        requests:
          storage: {{ .Values.persistentStorage.size }}
{{- end }}
{{- if eq .Values.persistentStorage.type "aws" }}
  volumeClaimTemplates:
  - metadata:
      name: data-volume
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "waas-elasticsearch-aws-disk"
      resources:
        requests:
          storage: {{ .Values.persistentStorage.size }}
{{- end }}
{{- if eq .Values.persistentStorage.type "google" }}
  volumeClaimTemplates:
  - metadata:
      name: data-volume
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "waas-elasticsearch-google-disk"
      resources:
        requests:
          storage: {{ .Values.persistentStorage.size }}
{{- end }}
{{- if eq .Values.persistentStorage.type "openshift" }}
  volumeClaimTemplates:
  - metadata:
      name: data-volume
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: {{ .Values.persistentStorage.size }}
{{- end }}
{{- if eq .Values.persistentStorage.type "longhorn" }}
  volumeClaimTemplates:
  - metadata:
      name: data-volume
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: longhorn
      resources:
        requests:
          storage: {{ .Values.persistentStorage.size }}
{{- end }}
{{- if eq .Values.persistentStorage.type "kind" }}
  volumeClaimTemplates:
  - metadata:
      name: data-volume
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: standard
      resources:
        requests:
          storage: {{ .Values.persistentStorage.size }}
{{- end }}
{{- if eq .Values.persistentStorage.type "custom" }}
  volumeClaimTemplates:
  - metadata:
      name: data-volume
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: {{ .Values.persistentStorage.className | default "standard" }}
      resources:
        requests:
          storage: {{ .Values.persistentStorage.size }}
{{- end }}
{{- end }}
