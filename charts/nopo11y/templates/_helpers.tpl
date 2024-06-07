{{- define "dashboard-uid" -}}
{{- printf "%s-%s" .Release.Name .Release.Namespace | trunc 40 -}}
{{- end -}}


{{- define "deployment.name" -}}
{{- if .Values.includeReleaseNameInMetricsLabels }}
{{- printf "%s-%s" .Release.Name .Values.deploymentName -}}
{{- else -}}
{{ printf "%s" .Values.deploymentName }}
{{- end }}
{{- end }}