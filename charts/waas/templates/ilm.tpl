{{/* Elastic storage management */}}
{{/* Elastic statefull set */}}
{{- define "waas.elasticStorageManagement.elastic" }}
    {{- $pollInterval:=""}}

    {{- if .Values.global.elasticStorageManagement.enabled }}
        {{- if eq .Values.global.elasticStorageManagement.policy "poc" }}
            {{- $pollInterval = "1s" }}
        {{- else if eq .Values.global.elasticStorageManagement.policy "small" }}
            {{- $pollInterval = "1m" }}
        {{- else if eq .Values.global.elasticStorageManagement.policy "custom" }}
            {{- $pollInterval = required "policy=custom requires setting the pollInterval value" .Values.global.elasticStorageManagement.pollInterval }}
        {{- else }}
            {{ required "policy can only be custom/poc/small" .Values.global.elasticStorageManagement.policyNotFound }}
        {{- end }}
            - name: indices.lifecycle.poll_interval
              value: {{ $pollInterval | quote }}
    {{- end }}
{{- end }}


{{/* Elastic ilm */}}
{{- define "waas.elasticStorageManagement.ilmOpts" }}
    {{- $maxSizeAcc:=""}}
    {{- $deleteAcc:=""}}
    {{- $maxSizeSec:=""}}
    {{- $deleteSec:=""}}
    {{- $maxSizeReq:=""}}
    {{- $deleteReq:=""}}
    {{- $maxSizeSys:=""}}
    {{- $deleteSys:=""}}
    {{- if .Values.global.elasticStorageManagement.enabled }}
        {{- if eq .Values.global.elasticStorageManagement.policy "poc" }}
            {{- $maxSizeAcc = "1M" }}
            {{- $deleteAcc = "1m" }}
            {{- $maxSizeSec = "1M" }}
            {{- $deleteSec = "1m" }}
            {{- $maxSizeReq = "1M" }}
            {{- $deleteReq = "1m" }}
            {{- $maxSizeSys = "1M" }}
            {{- $deleteSys = "1m" }}
        {{- else if eq .Values.global.elasticStorageManagement.policy "small" }}
            {{- $maxSizeAcc = "1000M" }}
            {{- $deleteAcc = "1h" }}
            {{- $maxSizeSec = "500M" }}
            {{- $deleteSec = "1h" }}
            {{- $maxSizeReq = "1000M" }}
            {{- $deleteReq = "1h" }}
            {{- $maxSizeSys = "100M" }}
            {{- $deleteSys = "1h" }}
        {{- else if eq .Values.global.elasticStorageManagement.policy "custom" }}
            {{- $maxSizeAcc = required "policy=custom requires setting the access.maxSize value" .Values.global.elasticStorageManagement.access.maxSize }}
            {{- $deleteAcc = required "policy=custom requires setting the access.delete value" .Values.global.elasticStorageManagement.access.delete }}
            {{- $maxSizeSec = required "policy=custom requires setting the security.maxSize value" .Values.global.elasticStorageManagement.security.maxSize }}
            {{- $deleteSec = required "policy=custom requires setting the security.delete value" .Values.global.elasticStorageManagement.security.delete }}
            {{- $maxSizeReq = required "policy=custom requires setting the requestData.maxSize value" .Values.global.elasticStorageManagement.requestData.maxSize }}
            {{- $deleteReq = required "policy=custom requires setting the requestData.delete value" .Values.global.elasticStorageManagement.requestData.delete }}
            {{- $maxSizeSys = required "policy=custom requires setting the system.maxSize value" .Values.global.elasticStorageManagement.system.maxSize }}
            {{- $deleteSys = required "policy=custom requires setting the system.delete value" .Values.global.elasticStorageManagement.system.delete }}
        {{- else }}
            {{ required "policy can only be custom/poc/small" .Values.global.elasticStorageManagement.policyNotFound }}
        {{- end -}}
ESM_ENABLED=true
ESM_MAX_SIZE_ACC={{ $maxSizeAcc }}
ESM_DELETE_ACC={{ $deleteAcc }}
ESM_MAX_SIZE_SEC={{ $maxSizeSec }}
ESM_DELETE_SEC={{ $deleteSec }}
ESM_MAX_SIZE_REQ={{ $maxSizeReq }}
ESM_DELETE_REQ={{ $deleteReq }}
ESM_MAX_SIZE_SYS={{ $maxSizeSys }}
ESM_DELETE_SYS={{ $deleteSys }}
    {{- else }}
ESM_ENABLED=false
ESM_MAX_SIZE_ACC=1m
ESM_DELETE_ACC=1m
ESM_MAX_SIZE_SEC=1m
ESM_DELETE_SEC=1m
ESM_MAX_SIZE_REQ=1m
ESM_DELETE_REQ=1m
ESM_MAX_SIZE_SYS=1m
ESM_DELETE_SYS=1m
    {{- end }}
{{- end }}