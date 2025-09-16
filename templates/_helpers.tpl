{{/*
Expand the name of the chart.
*/}}
{{- define "openbao.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openbao.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openbao.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openbao.labels" -}}
helm.sh/chart: {{ include "openbao.chart" . }}
{{ include "openbao.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: {{ .Values.labels.app }}
component: {{ .Values.labels.component }}
vault: {{ .Values.vault.name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openbao.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openbao.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openbao.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openbao.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate namespace name - dedicated namespace for vault
*/}}
{{- define "openbao.namespace" -}}
{{- if .Values.namespace.name }}
{{- .Values.namespace.name }}
{{- else }}
{{- printf "%s-vault-dedicated" .Values.vault.name }}
{{- end }}
{{- end }}

{{/*
Generate ingress hostname
*/}}
{{- define "openbao.hostname" -}}
{{- if .Values.ingress.host }}
{{- .Values.ingress.host }}
{{- else }}
{{- printf "%s.%s" .Values.dns.subdomain .Values.dns.domain }}
{{- end }}
{{- end }}

{{/*
Generate TLS secret name
*/}}
{{- define "openbao.tlsSecretName" -}}
{{- if .Values.ingress.tls.secretName }}
{{- .Values.ingress.tls.secretName }}
{{- else }}
{{- printf "%s-vault-tls" .Values.vault.name }}
{{- end }}
{{- end }}

{{/*
Generate NFS server name
*/}}
{{- define "openbao.nfsServerName" -}}
{{- printf "nfs-server-%s" .Values.vault.name }}
{{- end }}
