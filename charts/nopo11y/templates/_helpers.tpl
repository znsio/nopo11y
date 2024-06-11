{{- define "generate.list" -}}
{{- $service:= dict }}
{{- if not (hasKey . "deploymentName") -}}
{{- fail "deploymentName is required for each service" -}}
{{- else if eq .deploymentName "" -}}
{{- fail "deploymentName is required for each service" -}}
{{- end -}}
{{ $service = set $service "deployment" .deploymentName }}
{{- if not (hasKey . "slo") }}
{{ $service = set $service "availability" 99.9 }}
{{ $service = set $service "latency" 99 }}
{{ $service = set $service "latencyThreshold" 100 }}
{{- else if hasKey . "slo" }}
{{- if not (hasKey .slo "availability") }}
{{ $service = set $service "availability" 99.9 }}
{{- else if not .slo.availability }}
{{ $service = set $service "availability" 99.9 }}
{{- else }}
{{ $service = set $service "availability" .slo.availability }}
{{- end -}}
{{- if not (hasKey .slo "latency") }}
{{ $service = set $service "latency" 99 }}
{{- else if not .slo.latency }}
{{ $service = set $service "latency" 99 }}
{{- else }}
{{ $service = set $service "latency" .slo.latency }}
{{- end }}
{{- if not (hasKey .slo "latencyThreshold") }}
{{ $service = set $service "latencyThreshold" 100 }}
{{- else if not .slo.latencyThreshold }}
{{ $service = set $service "latencyThreshold" 100 }}
{{- else }}
{{ $service = set $service "latencyThreshold" .slo.latencyThreshold }}
{{- end }}
{{- end }}
{{- if not (hasKey . "errorRate") }}
{{ $service = set $service "rate5xx" 0.05 }}
{{ $service = set $service "rate4xx" 5 }}
{{- else if hasKey . "errorRate" }}
{{- if not (hasKey .errorRate "rate5xx") }}
{{ $service = set $service "rate5xx" 0.05 }}
{{- else if not .errorRate.rate5xx }}
{{ $service = set $service "rate5xx" 0.05 }}
{{- else }}
{{ $service = set $service "rate5xx" .errorRate.rate5xx }}
{{- end -}}
{{- if not (hasKey .errorRate "rate4xx") }}
{{ $service = set $service "rate4xx" 5 }}
{{- else if not .errorRate.rate5xx }}
{{ $service = set $service "rate4xx" 5 }}
{{- else }}
{{ $service = set $service "rate4xx" .errorRate.rate4xx }}
{{- end -}}
{{- end -}}
{{- if and (hasKey . "ingressName") (hasKey . "serviceName") }}
{{ $service = set $service "ingressName" .ingressName }}
{{ $service = set $service "serviceName" .serviceName }}
{{- end }}
{{ toJson $service }}
{{- end }}

{{- define "nopo11y.services" -}}
{{ $servicesList := list }}
{{ range .Values.services }}
{{ $servicesList = append $servicesList (include "generate.list" . |fromJson ) }}
{{- end -}}
{{ toJson $servicesList }}
{{- end -}}