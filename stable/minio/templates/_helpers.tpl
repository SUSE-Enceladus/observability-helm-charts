{{/* vim: set filetype=mustache: */}}

{{- define "she.bang" -}}
{{- printf "#!/bin/sh" }}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "minio.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "minio.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "minio.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "minio.networkPolicy.apiVersion" -}}
{{- if semverCompare ">=1.4-0, <1.7-0" .Capabilities.KubeVersion.Version -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "minio.deployment.apiVersion" -}}
{{- if semverCompare "<1.9-0" .Capabilities.KubeVersion.Version -}}
{{- print "apps/v1beta2" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for statefulset.
*/}}
{{- define "minio.statefulset.apiVersion" -}}
{{- if semverCompare "<1.16-0" .Capabilities.KubeVersion.Version -}}
{{- print "apps/v1beta2" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "minio.ingress.apiVersion" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Determine secret name.
*/}}
{{- define "minio.secretName" -}}
{{- if .Values.existingSecret -}}
{{- .Values.existingSecret }}
{{- else -}}
{{- include "minio.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Determine service account name for deployment or statefulset.
*/}}
{{- define "minio.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "minio.fullname" .) .Values.serviceAccount.name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Determine name for scc role and rolebinding
*/}}
{{- define "minio.sccRoleName" -}}
{{- printf "%s-%s" "scc" (include "minio.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Properly format optional additional arguments to Minio binary
*/}}
{{- define "minio.extraArgs" -}}
{{- range .Values.extraArgs -}}
{{ " " }}{{ . }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}

{{/*
Formats volumeMount for Minio tls keys and trusted certs
*/}}
{{- define "minio.tlsKeysVolumeMount" -}}
{{- if .Values.tls.enabled }}
- name: cert-secret-volume
  mountPath: {{ .Values.certsPath }}
{{- end }}
{{- if or .Values.tls.enabled (ne .Values.trustedCertsSecret "") }}
{{- $casPath := printf "%s/CAs" .Values.certsPath | clean }}
- name: trusted-cert-secret-volume
  mountPath: {{ $casPath }}
{{- end }}
{{- end -}}

{{/*
Formats volume for Minio tls keys and trusted certs
*/}}
{{- define "minio.tlsKeysVolume" -}}
{{- if .Values.tls.enabled }}
- name: cert-secret-volume
  secret:
    secretName: {{ .Values.tls.certSecret }}
    items:
    - key: {{ .Values.tls.publicCrt }}
      path: public.crt
    - key: {{ .Values.tls.privateKey }}
      path: private.key
{{- end }}
{{- if or .Values.tls.enabled (ne .Values.trustedCertsSecret "") }}
{{- $certSecret := eq .Values.trustedCertsSecret "" | ternary .Values.tls.certSecret .Values.trustedCertsSecret }}
{{- $publicCrt := eq .Values.trustedCertsSecret "" | ternary .Values.tls.publicCrt "" }}
- name: trusted-cert-secret-volume
  secret:
    secretName: {{ $certSecret }}
    {{- if ne $publicCrt "" }}
    items:
    - key: {{ $publicCrt }}
      path: public.crt
    {{- end }}
{{- end }}
{{- end -}}


{{/*
Return the image registry for the container-tools containers
*/}}
{{- define "minio.image.registry" -}}
{{- $context := .context }}
{{- if $context.Values.global -}}
    {{- $context.Values.global.imageRegistry | default .image.registry -}}
  {{- else -}}
    {{- .image.registry -}}
  {{- end -}}
{{- end -}}


{{/*
Renders a value that contains a template.
Usage:
{{ include "minio.tplvalue.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "minio.tplvalue.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}


{{/*
Return the proper Docker Image Registry Secret Names evaluating values as templates
{{ include "minio.image.pullSecret.name" ( dict "images" (list .Values.path.to.the.image1, .Values.path.to.the.image2) "context" $) }}
*/}}
{{- define "minio.image.pullSecret.name" -}}
  {{- $pullSecrets := list }}
  {{- $context := .context }}

  {{- if $context.Values.global }}
    {{- range $context.Values.global.imagePullSecrets -}}
      {{- $pullSecrets = append $pullSecrets (include "minio.tplvalue.render" (dict "value" . "context" $context)) -}}
    {{- end -}}
  {{- end -}}
  {{- range $context.Values.imagePullSecrets -}}
    {{- $pullSecrets = append $pullSecrets (include "minio.tplvalue.render" (dict "value" .name "context" $context)) -}}
  {{- end -}}
  {{- range .images -}}
    {{- if .pullSecretName -}}
      {{- $pullSecrets = append $pullSecrets (include "minio.tplvalue.render" (dict "value" .pullSecretName "context" $context)) -}}
    {{- else if (or .pullSecretUsername .pullSecretDockerConfigJson) -}}
      {{- $pullSecrets = append $pullSecrets ((list (include "common.fullname.short" $context ) "pull-secret") | join "-")  -}}
    {{- end -}}
  {{- end -}}

  {{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
    {{- range $pullSecrets | uniq }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}
