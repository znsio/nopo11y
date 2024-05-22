{{- define "dashboard-uid" -}}
{{- printf "%s-%s" .Release.Name .Release.Namespace |trunc 40 -}}
{{- end -}}