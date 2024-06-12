{{- define "nopo11y.services" -}}
{{- $servicesList:= list }}
{{- $defaulAvailability:= .Values.global.defaults.availability -}}
{{- $defaulLatency:= .Values.global.defaults.latency -}}
{{- $defaulLatencyThreshold:= .Values.global.defaults.latencyThreshold -}}
{{- $defaul5xx:= .Values.global.defaults.rate5xx -}}
{{- $default4xx:= .Values.global.defaults.rate4xx -}}
{{- $release:= "" }}
{{- if .Values.prependReleaseNameToDeployment -}}
{{- $release = printf "%s-" .Release.Name }}
{{- end }}
{{- $namespace:= .Release.Namespace }}
{{- range .Values.services }}
{{- $service:= dict }}
{{- if not (hasKey . "deploymentName") -}}
{{- fail "deploymentName is required for each service" -}}
{{- else if eq .deploymentName "" -}}
{{- fail "deploymentName is required for each service" -}}
{{- end -}}
{{ $service = set $service "deployment" (printf "%s%s" $release .deploymentName) }}
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
{{ $service = set $service "dashboarduid" (printf "%s-%s" .deploymentName $namespace) }}
{{ $servicesList = append $servicesList $service }}
{{- end }}
{{- toJson $servicesList }}
{{- end }}