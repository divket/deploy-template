{{- define "deploy-template.env" -}}
{{- $w := index .ctx.Values.workloads .name -}}
{{- with $w.env }}
{{- range $k, $v := . }}
- name: {{ $k }}
  value: {{ $v | quote }}
{{- end }}
{{- end }}
{{- range .ctx.Values.dependencies }}
- name: {{ .env }}
  value: {{ .service }}.{{ .ns }}.svc.cluster.local:{{ .port }}
{{- end }}
{{- end -}}

{{- define "deploy-template.envFrom" -}}
{{- $w := index .ctx.Values.workloads .name -}}
{{- with $w.envFrom }}
{{- range . }}
{{- if .secretRef }}
- secretRef:
    name: {{ .secretRef }}
{{- end }}
{{- if .configMapRef }}
- configMapRef:
    name: {{ .configMapRef }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
