{{- define "deploy-template.probes" -}}
{{- $w := index .ctx.Values.workloads .name -}}
{{- with $w.health }}
{{- $h := . -}}
{{- with $h.ready }}
readinessProbe:
  httpGet:
    path: {{ . }}
    port: {{ $h.port }}
{{- end }}
{{- with $h.live }}
livenessProbe:
  httpGet:
    path: {{ . }}
    port: {{ $h.port }}
{{- end }}
{{- with $h.startup }}
startupProbe:
  httpGet:
    path: {{ . }}
    port: {{ $h.port }}
{{- end }}
{{- end }}
{{- end -}}
