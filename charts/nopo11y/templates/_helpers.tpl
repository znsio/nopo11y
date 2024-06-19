{{- define "nopo11y.services" -}}
{{- $servicesList:= list }}
{{- $defaulAvailability:= .Values.defaults.slo.availability -}}
{{- $defaulLatency:= .Values.defaults.slo.latency -}}
{{- $defaulLatencyThreshold:= .Values.defaults.alertThresholds.latency -}}
{{- $defaul5xx:= .Values.defaults.alertThresholds.rate5xx -}}
{{- $default4xx:= .Values.defaults.alertThresholds.rate4xx -}}
{{- $release:= "" }}
{{- if .Values.prependReleaseNameToDeployment -}}
{{- $release = printf "%s-" .Release.Name }}
{{- end }}
{{- $namespace:= .Release.Namespace }}
{{- range .Values.services }}
{{- $service:= dict }}
{{- if or (not (hasKey . "deploymentName")) (not (hasKey . "serviceName")) -}}
{{- fail "deploymentName and serviceName are required for each service" -}}
{{- else if and (eq .deploymentName "") (eq .serviceName "") -}}
{{- fail "deploymentName and ServiceName are required for each service" -}}
{{- end -}}
{{ $service = set $service "deployment" (printf "%s%s" $release .deploymentName) }}
{{ $service = set $service "service" (printf "%s%s" $release .deploymentName) }}
{{- if not (hasKey . "slo") }}
{{ $service = set $service "availability" $defaulAvailability }}
{{ $service = set $service "latency" $defaulLatency }}
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
{{- end }}
{{- if not (hasKey . "alertThresholds") }}
{{ $service = set $service "rate5xx" $defaul5xx }}
{{ $service = set $service "rate4xx" $default4xx }}
{{ $service = set $service "latencyThreshold" $defaulLatencyThreshold }}
{{- else if hasKey . "alertThresholds" }}
{{- if not (hasKey .alertThresholds "rate5xx") }}
{{ $service = set $service "rate5xx" $defaul5xx }}
{{- else if not .alertThresholds.rate5xx }}
{{ $service = set $service "rate5xx" $defaul5xx }}
{{- else }}
{{ $service = set $service "rate5xx" .alertThresholds.rate5xx }}
{{- end -}}
{{- if not (hasKey .alertThresholds "rate4xx") }}
{{ $service = set $service "rate4xx" $default4xx }}
{{- else if not .alertThresholds.rate5xx }}
{{ $service = set $service "rate4xx" $default4xx }}
{{- else }}
{{ $service = set $service "rate4xx" .alertThresholds.rate4xx }}
{{- end -}}
{{- if not (hasKey .alertThresholds "latency") }}
{{ $service = set $service "latencyThreshold" $defaulLatencyThreshold }}
{{- else if not .alertThresholds.latency }}
{{ $service = set $service "latencyThreshold" $defaulLatencyThreshold }}
{{- else }}
{{ $service = set $service "latencyThreshold" .alertThresholds.latency }}
{{- end }}
{{- end }}
{{ $service = set $service "dashboarduid" (printf "%s-%s" .serviceName $namespace) }}
{{ $servicesList = append $servicesList $service }}
{{- end }}
{{- toJson $servicesList }}
{{- end }}