{{- define "prometheus-url" -}}
{{- $port:= (index .Values "kube-prometheus-stack" "prometheus" "service" "port") |int }}
{{- printf "http://%s-prometheus:%d%s" (include "kube-prometheus-stack.fullname" (index .Subcharts "kube-prometheus-stack")) $port (index .Values "kube-prometheus-stack" "prometheus" "prometheusSpec" "routePrefix") -}}
{{- end }}

{{- define "kuberhealthy-url" -}}
{{ $port:= .Values.kuberhealthy.service.externalPort |int }}
{{- printf "%s:%d"  (include "kuberhealthy.name" .Subcharts.kuberhealthy) $port -}}
{{- end -}}