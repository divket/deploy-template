{{- define "deploy-template.worker" -}}
{{- $w := index .ctx.Values.workloads .name -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "deploy-template.fullname" . }}
  labels:
    {{- include "deploy-template.labels" . | nindent 4 }}
spec:
  replicas: {{ $w.replicas | default 1 }}
  selector:
    matchLabels:
      {{- include "deploy-template.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "deploy-template.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .ctx.Values.image.pullSecrets }}
      imagePullSecrets:
        {{- range . }}
        - name: {{ . }}
        {{- end }}
      {{- end }}
      securityContext:
        {{- include "deploy-template.podSecurity" . | nindent 8 }}
      containers:
        - name: {{ .name }}
          image: {{ include "deploy-template.image" . }}
          imagePullPolicy: {{ .ctx.Values.image.pullPolicy }}
          securityContext:
            {{- include "deploy-template.containerSecurity" . | nindent 12 }}
          {{- with $w.command }}
          command:
            {{- range . }}
            - {{ . | quote }}
            {{- end }}
          {{- end }}
          {{- with $w.args }}
          args:
            {{- range . }}
            - {{ . | quote }}
            {{- end }}
          {{- end }}
          {{- $env := include "deploy-template.env" . -}}
          {{- if trim $env }}
          env:
            {{- $env | trim | nindent 12 }}
          {{- end }}
          {{- $envFrom := include "deploy-template.envFrom" . -}}
          {{- if trim $envFrom }}
          envFrom:
            {{- $envFrom | trim | nindent 12 }}
          {{- end }}
          {{- with $w.resources }}
          resources:
            {{- include "deploy-template.resources" $ | trim | nindent 12 }}
          {{- end }}
{{- end -}}
