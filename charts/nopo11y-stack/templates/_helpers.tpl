{{- define "prometheus-url" -}}
{{- $port:= (index .Values "kube-prometheus-stack" "prometheus" "service" "port") |int }}
{{- printf "http://%s-prometheus:%d%s" (include "kube-prometheus-stack.fullname" (index .Subcharts "kube-prometheus-stack")) $port (index .Values "kube-prometheus-stack" "prometheus" "prometheusSpec" "routePrefix") -}}
{{- end }}

{{- define "kuberhealthy-url" -}}
{{ $port:= .Values.kuberhealthy.service.externalPort |int }}
{{- printf "%s:%d"  (include "kuberhealthy.name" .Subcharts.kuberhealthy) $port -}}
{{- end -}}

{{- define "nopo11y.services" -}}

    {{- if .Values.nopo11y_ingress.enabled }}
        {{- $servicesList:= list }}

        {{- $prometheus:= dict }}
        {{- $prometheus = set $prometheus "name" (printf "%s-prometheus" (include "kube-prometheus-stack.fullname" (index .Subcharts "kube-prometheus-stack"))) }}
        {{- $port:= (index .Values "kube-prometheus-stack" "prometheus" "service" "port") |int }}
        {{- $path:= (index .Values "kube-prometheus-stack" "prometheus" "prometheusSpec" "routePrefix") }}
        {{- $prometheus = set $prometheus "port" $port }}
        {{- if ne $path "/" }}
            {{- $prometheus = set $prometheus "path" $path }}
            {{- $servicesList = append $servicesList $prometheus }}
        {{- end }}

        {{- if (index .Values "kube-prometheus-stack" "grafana" "enabled" ) }}
            {{- $grafana:= dict }}
            {{- $path:= "" }}
            {{- if (index .Values "kube-prometheus-stack" "grafana" "env") }}
                {{- range $key, $val := (index .Values "kube-prometheus-stack" "grafana" "env") }}
                    {{- if eq $key "GF_SERVER_ROOT_URL" }}
                        {{- $path = (urlParse $val).path }}
                    {{- end }}
                {{- end }}
            {{- else if hasKey (index .Values "kube-prometheus-stack" "grafana" "grafana.ini" "server") "root_url" }}
                {{- $path = (urlParse (index .Values "kube-prometheus-stack" "grafana" "grafana.ini" "server" "root_url")).path }}
            {{- end }}
            {{- $port:= (index .Values "kube-prometheus-stack" "grafana" "service" "port") |int }}
            {{- $grafana = set $grafana "name" (printf "%s" (include "grafana.fullname" (index .Subcharts "kube-prometheus-stack").Subcharts.grafana)) }}
            {{- $grafana = set $grafana "port" (printf "%d" $port) }}
            {{- if ne $path "" }}
                {{- $grafana = set $grafana "path" (trimSuffix "/" $path) }}
                {{- $servicesList = append $servicesList $grafana }}
            {{- end }}
        {{- end }}

        {{- if (index .Values "kube-prometheus-stack" "alertmanager" "enabled" ) }}
            {{- $alertmanager:= dict }}
            {{- $alertmanager = set $alertmanager "name" (printf "%s-alertmanager" (include "kube-prometheus-stack.fullname" (index .Subcharts "kube-prometheus-stack"))) }}
            {{- $port:= (index .Values "kube-prometheus-stack" "alertmanager" "service" "port") |int }}
            {{- $path:= (index .Values "kube-prometheus-stack" "alertmanager" "alertmanagerSpec" "routePrefix") }}
            {{- $alertmanager = set $alertmanager "port" (printf "%d" $port) }}
            {{- if ne $path "/" }}
                {{- $alertmanager = set $alertmanager "path" $path }}
                {{- $servicesList = append $servicesList $alertmanager }}
            {{- end }}
        {{- end }}

        {{- if and .Values.thanos.enabled .Values.thanos.query.enabled }}
            {{- $query:= dict }}
            {{- $query = set $query "name" (printf "%s-query" (include "common.names.fullname" .Subcharts.thanos)) }}
            {{- $query = set $query "port" .Values.thanos.query.service.ports.http }}
            {{- $path:= "" }}
            {{- if .Values.thanos.query.extraFlags }}
                {{- range .Values.thanos.query.extraFlags }}
                    {{- if contains "--web.route-prefix" . }}
                        {{- $path = (trimPrefix "--web.route-prefix=" . ) }}
                    {{- end }}
                {{- end }}
            {{- end }}
            {{- if and (ne $path "") (ne $path "/") }}
                {{- $query = set $query "path" $path }}
                {{- $servicesList = append $servicesList $query }}
            {{- end }}
        {{- end }}

        {{- if (index .Values "kube-prometheus-stack" "thanosRuler" "enabled" ) }}
            {{- $thanosruler:= dict }}
            {{- $thanosruler = set $thanosruler "name" (printf "%s" (include "kube-prometheus-stack.thanosRuler.name" (index .Subcharts "kube-prometheus-stack"))) }}
            {{- $port:= (index .Values "kube-prometheus-stack" "thanosRuler" "service" "port") |int }}
            {{- $path:= (index .Values "kube-prometheus-stack" "thanosRuler" "thanosRulerSpec" "routePrefix") }}
            {{- $thanosruler = set $thanosruler "port" (printf "%d" $port) }}
            {{- if ne $path "/" }}
                {{- $thanosruler = set $thanosruler "path" $path }}
                {{- $servicesList = append $servicesList $thanosruler }}
            {{- end }}
        {{- else if and .Values.thanos.enabled .Values.thanos.ruler.enabled }}
            {{- $thanosruler:= dict }}
            {{- $thanosruler = set $thanosruler "name" (printf "%s-ruler" (include "common.names.fullname" .Subcharts.thanos)) }}
            {{- $thanosruler = set $thanosruler "port" .Values.thanos.ruler.service.ports.http }}
            {{- $path:= "" }}
            {{- if .Values.thanos.query.extraFlags }}
                {{- range .Values.thanos.ruler.extraFlags }}
                    {{- if contains "--web.route-prefix" . }}
                        {{- $path = (trimPrefix "--web.route-prefix=" . ) }}
                    {{- end }}
                {{- end }}
            {{- end }}
            {{- if and (ne $path "") (ne $path "/") }}
                {{- $thanosruler = set $thanosruler "path" $path }}
                {{- $servicesList = append $servicesList $thanosruler }}
            {{- end }}
        {{- end }}

        {{- if (index .Values "kiali-server" "enabled") }}
            {{- $kiali:= dict }}
            {{- $kiali = set $kiali "name" (printf "%s" (include "kiali-server.fullname" (index .Subcharts "kiali-server"))) }}
            {{- $kiali = set $kiali "port" (index .Values "kiali-server" "server" "port") }}
            {{- if (index .Values "kiali-server" "server" "web_root") }}
                {{- if ne (index .Values "kiali-server" "server" "web_root") "/" }}
                    {{- $kiali = set $kiali "path" (index .Values "kiali-server" "server" "web_root") }}
                    {{- $servicesList = append $servicesList $kiali }}
                {{- end }}
            {{- else }}
                {{- $kiali = set $kiali "path" "/kiali" }}
                {{- $servicesList = append $servicesList $kiali }}
            {{- end }}
        {{- end }}

        {{- if .Values.jaeger.enabled}}
            {{- $jaeger:= dict }}
            {{- $jaeger = set $jaeger "name" (printf "%s-tracing" .Release.Name) }}
            {{- $jaeger = set $jaeger "port" 80 }}
            {{- $jaeger = set $jaeger "path" .Values.jaeger.jaeger.pathPrefix }}
            {{- $servicesList = append $servicesList $jaeger }}
        {{- end }}

        {{- if .Values.kuberhealthy.enabled }}
            {{- $kuberhealthy:= dict }}
            {{- $kuberhealthy = set $kuberhealthy "name" (printf "%s" (include "kuberhealthy.name" .Subcharts.kuberhealthy)) }}
            {{- $kuberhealthy = set $kuberhealthy "port" .Values.kuberhealthy.service.externalPort }}
            {{- $kuberhealthy = set $kuberhealthy "path" "/nopo11y-health-check" }}
            {{- $kuberhealthy = set $kuberhealthy "rewritePath" "/" }}
            {{- $servicesList = append $servicesList $kuberhealthy }}
        {{- end }}

        {{- toJson $servicesList }}

    {{- end }}

{{- end -}}