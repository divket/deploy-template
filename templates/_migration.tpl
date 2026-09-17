{{- define "deploy-template.migration" -}}
{{- $m := .ctx.Values.migration | default (dict "enabled" false) -}}
{{- if $m.enabled }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .ctx.Release.Name }}-migration
  labels:
    app.kubernetes.io/name: migration
    app.kubernetes.io/instance: {{ .ctx.Release.Name }}
    app.kubernetes.io/managed-by: {{ .ctx.Release.Service }}
  annotations:
    helm.sh/hook: pre-upgrade,pre-install
    helm.sh/hook-weight: "-5"
    helm.sh/hook-delete-policy: before-hook-creation
spec:
  backoffLimit: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: migration
        app.kubernetes.io/instance: {{ .ctx.Release.Name }}
    spec:
      restartPolicy: Never
      {{- with .ctx.Values.image.pullSecrets }}
      imagePullSecrets:
        {{- range . }}
        - name: {{ . }}
        {{- end }}
      {{- end }}
      securityContext:
        {{- toYaml .ctx.Values.podSecurity | nindent 8 }}
      containers:
        - name: migration
          image: {{ printf "%s/%s:%s" .ctx.Values.image.registry $m.image ($m.tag | default .ctx.Values.image.tag) }}
          imagePullPolicy: {{ .ctx.Values.image.pullPolicy }}
          securityContext:
            {{- include "deploy-template.containerSecurity" . | nindent 12 }}
          {{- with $m.command }}
          command:
            {{- range . }}
            - {{ . | quote }}
            {{- end }}
          {{- end }}
          {{- with $m.envFrom }}
          envFrom:
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
{{- end }}
{{- end -}}
