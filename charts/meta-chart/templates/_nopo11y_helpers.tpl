{{/*
ODA related names/tags
*/}}

{{- define "npl.svc.name" -}}
{{- printf "%s-%s" .Release.Name .Values.api.service.name | lower | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "npl.svc.namespace" -}}
{{- printf "%s" (default .Values.api.namespace .Release.Namespace) | trimSuffix "-" }}
{{- end }}

{{- define "npl.svc.portRef" -}}
{{- printf "%s-prt" (.Values.api.service.nameGenerated.short | trunc 10) | lower | trunc 14 | trimSuffix "-" }}
{{- end }}

{{- define "npl.svc.metricsName" -}}
{{- printf "%s-%s" (.Values.api.service.nameGenerated.readable | trunc 60) "sm" | lower | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "npl.svc.metricsPortRef" -}}
{{- printf "%s-%s-prt" (.Values.api.service.nameGenerated.short | trunc 7) "sm" | lower | trunc 14 | trimSuffix "-" }}
{{- end }}

{{- define "npl.crdName" -}}
{{- printf "%s-%s" .Release.Name .Values.api.service.name | lower | trunc 63 | trimSuffix "-" }}
{{- end }}
