{{- define "deploy-template.route" -}}
{{- $ctx := .ctx -}}
{{- $gw := $ctx.Values.gateway | default dict -}}
{{- range $i, $r := ($ctx.Values.routes | default list) }}
{{- $svc := include "deploy-template.fullname" (dict "ctx" $ctx "name" $r.workload) -}}
{{- $port := (index $ctx.Values.workloads $r.workload).port | default 80 -}}
{{- if eq ($r.protocol | default "http") "grpc" }}
---
apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
metadata:
  name: {{ $ctx.Release.Name }}-{{ $r.workload }}-{{ $i }}
  labels:
    app.kubernetes.io/instance: {{ $ctx.Release.Name }}
    app.kubernetes.io/managed-by: {{ $ctx.Release.Service }}
spec:
  parentRefs:
    - name: {{ $gw.name }}
      namespace: {{ $gw.namespace }}
  {{- with $r.hostname }}
  hostnames:
    - {{ . }}
  {{- end }}
  rules:
    - matches:
        - method:
            service: {{ $r.workload }}
      backendRefs:
        - name: {{ $svc }}
          port: {{ $port }}
{{- else }}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $ctx.Release.Name }}-{{ $r.workload }}-{{ $i }}
  labels:
    app.kubernetes.io/instance: {{ $ctx.Release.Name }}
    app.kubernetes.io/managed-by: {{ $ctx.Release.Service }}
spec:
  parentRefs:
    - name: {{ $gw.name }}
      namespace: {{ $gw.namespace }}
  {{- with $r.hostname }}
  hostnames:
    - {{ . }}
  {{- end }}
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: {{ $r.path }}
      backendRefs:
        - name: {{ $svc }}
          port: {{ $port }}
{{- end }}
{{- end }}
{{- end -}}
