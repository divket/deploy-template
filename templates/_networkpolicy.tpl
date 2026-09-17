{{- define "deploy-template.networkpolicy" -}}
{{- $deps := .ctx.Values.dependencies | default list -}}
{{- if $deps }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "deploy-template.fullname" . }}
  labels:
    {{- include "deploy-template.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "deploy-template.selectorLabels" . | nindent 6 }}
  policyTypes: [Ingress, Egress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: {{ (.ctx.Values.gateway | default dict).namespace | default "platform" }}
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    {{- range $d := $deps }}
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: {{ $d.ns }}
      ports:
        - protocol: TCP
          port: {{ $d.port }}
    {{- end }}
{{- end }}
{{- end -}}
