{{/*
Mọi helper nhận đúng một dict: {ctx: root context, name: tên workload}.
Không helper nào được đọc .Values trực tiếp — luôn qua .ctx.Values.
*/}}

{{- define "deploy-template.fullname" -}}
{{- printf "%s-%s" .ctx.Release.Name .name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector của Deployment là immutable sau khi tạo.
Chỉ hai nhãn này, và không bao giờ thêm.
*/}}
{{- define "deploy-template.selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
{{- end -}}

{{- define "deploy-template.labels" -}}
{{ include "deploy-template.selectorLabels" . }}
app.kubernetes.io/component: {{ (index .ctx.Values.workloads .name).kind }}
app.kubernetes.io/managed-by: {{ .ctx.Release.Service }}
{{- end -}}

{{- define "deploy-template.image" -}}
{{- $w := index .ctx.Values.workloads .name -}}
{{- $tag := $w.tag | default .ctx.Values.image.tag -}}
{{- printf "%s/%s:%s" .ctx.Values.image.registry $w.image $tag -}}
{{- end -}}

{{/* Workload đè được, ví dụ image chạy bằng uid khác 1000. */}}
{{- define "deploy-template.podSecurity" -}}
{{- $w := index .ctx.Values.workloads .name -}}
{{- toYaml (default .ctx.Values.podSecurity $w.podSecurity) -}}
{{- end -}}

{{- define "deploy-template.containerSecurity" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop:
    - ALL
{{- end }}

{{- define "deploy-template.resources" -}}
{{- $w := index .ctx.Values.workloads .name -}}
{{- toYaml (default (dict) $w.resources) -}}
{{- end -}}
