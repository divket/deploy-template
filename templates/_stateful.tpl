{{- define "deploy-template.stateful" -}}
{{- $w := index .ctx.Values.workloads .name -}}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "deploy-template.fullname" . }}
  labels:
    {{- include "deploy-template.labels" . | nindent 4 }}
spec:
  serviceName: {{ include "deploy-template.fullname" . }}
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
          ports:
            - name: tcp
              containerPort: {{ $w.port }}
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
          {{- $probes := include "deploy-template.probes" . -}}
          {{- if trim $probes }}
          {{- $probes | trim | nindent 10 }}
          {{- end }}
          {{- with $w.resources }}
          resources:
            {{- include "deploy-template.resources" $ | trim | nindent 12 }}
          {{- end }}
          {{- with $w.volume }}
          volumeMounts:
            - name: data
              mountPath: {{ .mountPath }}
          {{- end }}
  {{- with $w.volume }}
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        {{- with .storageClass }}
        storageClassName: {{ . }}
        {{- end }}
        resources:
          requests:
            storage: {{ .size }}
  {{- end }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "deploy-template.fullname" . }}
  labels:
    {{- include "deploy-template.labels" . | nindent 4 }}
spec:
  clusterIP: None
  selector:
    {{- include "deploy-template.selectorLabels" . | nindent 4 }}
  ports:
    - name: tcp
      port: {{ $w.port }}
      targetPort: tcp
{{- end -}}
