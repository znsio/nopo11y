{{- define "generate.list" -}}
{{- $service:= dict }}
{{- $defaulAvailability:= 99.9 -}}
{{- $defaulLatency:= 99 -}}
{{- $defaulLatencyThreshold:= 100 -}}
{{- $defaul5xx:= 0.05 -}}
{{- $default4xx:= 5 -}}
{{- if not (hasKey . "deploymentName") -}}
{{- fail "deploymentName is required for each service" -}}
{{- else if eq .deploymentName "" -}}
{{- fail "deploymentName is required for each service" -}}
{{- end -}}
{{ $service = set $service "deployment" .deploymentName }}
{{- if not (hasKey . "slo") }}
{{ $service = set $service "availability" $defaulAvailability }}
{{ $service = set $service "latency" $defaulLatency }}
{{ $service = set $service "latencyThreshold" $defaulLatencyThreshold }}
{{- else if hasKey . "slo" }}
{{- if not (hasKey .slo "availability") }}
{{ $service = set $service "availability" $defaulAvailability }}
{{- else if not .slo.availability }}
{{ $service = set $service "availability" $defaulAvailability }}
{{- else }}
{{ $service = set $service "availability" .slo.availability }}
{{- end -}}
{{- if not (hasKey .slo "latency") }}
{{ $service = set $service "latency" $defaulLatency }}
{{- else if not .slo.latency }}
{{ $service = set $service "latency" $defaulLatency }}
{{- else }}
{{ $service = set $service "latency" .slo.latency }}
{{- end }}
{{- if not (hasKey .slo "latencyThreshold") }}
{{ $service = set $service "latencyThreshold" $defaulLatencyThreshold }}
{{- else if not .slo.latencyThreshold }}
{{ $service = set $service "latencyThreshold" $defaulLatencyThreshold }}
{{- else }}
{{ $service = set $service "latencyThreshold" .slo.latencyThreshold }}
{{- end }}
{{- end }}
{{- if not (hasKey . "errorRate") }}
{{ $service = set $service "rate5xx" $defaul5xx }}
{{ $service = set $service "rate4xx" $default4xx }}
{{- else if hasKey . "errorRate" }}
{{- if not (hasKey .errorRate "rate5xx") }}
{{ $service = set $service "rate5xx" $defaul5xx }}
{{- else if not .errorRate.rate5xx }}
{{ $service = set $service "rate5xx" $defaul5xx }}
{{- else }}
{{ $service = set $service "rate5xx" .errorRate.rate5xx }}
{{- end -}}
{{- if not (hasKey .errorRate "rate4xx") }}
{{ $service = set $service "rate4xx" $default4xx }}
{{- else if not .errorRate.rate5xx }}
{{ $service = set $service "rate4xx" $default4xx }}
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