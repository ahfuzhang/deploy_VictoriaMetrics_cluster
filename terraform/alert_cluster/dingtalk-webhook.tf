locals {
  dingtalk-webhook-name = "alert-cluster-dingtalk-webhook"
  log_level             = lower(var.configs.log.level)
}

resource "kubernetes_config_map" "alert-cluster-dingtalk-webhook-configs" {
  metadata {
    name      = "alert-cluster-dingtalk-webhook-configs"
    namespace = var.configs.namespace
  }

  data = {
    "webhook-dingtalk.yaml"         = <<EOF
templates:
  - /configs/vm_errors_total.tmpl
targets:
  # support only one webhook link at this example
  webhook1:
    url: "${var.configs.dingtalk_webhooks[0].url}"
    secret: "${var.configs.dingtalk_webhooks[0].secret}"
    message:
      title: '{{ template "vm_errors_total.link.title" . }}'
      text: '{{ template "vm_errors_total.link.content" . }}'
    EOF
    "vm_errors_total.tmpl"          = <<EOF

{{ define "__subject" }}[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ .GroupLabels.SortedPairs.Values | join " " }} {{ if gt (len .CommonLabels) (len .GroupLabels) }}({{ with .CommonLabels.Remove .GroupLabels.Names }}{{ .Values | join " " }}{{ end }}){{ end }}{{ end }}
{{ define "__alertmanagerURL" }}{{ .ExternalURL }}/#/alerts?receiver={{ .Receiver }}{{ end }}

{{ define "__text_alert_list_2" }}{{ range . }}
**Labels**
{{ range .Labels.SortedPairs }}> - {{ .Name }}: {{ .Value | markdown | html }}
{{ end }}
**Annotations**
{{ range .Annotations.SortedPairs }}> - {{ .Name }}: {{ .Value | markdown | html }}
{{ end }}
**Source:** [{{ .GeneratorURL }}]({{ .GeneratorURL }})
{{ end }}{{ end }}

{{ define "vm_errors_total.__text_alert_list" }}{{ range . }}
#### \[{{ .Labels.severity | upper }}\] {{ .Annotations.summary }}

**Description:** {{ .Labels.metric_name }} | {{ .Annotations.description }}


**Event Time:** {{ dateInZone "2006.01.02 15:04:05" (.StartsAt) "UTC" }}

**Graph:** [📈](http://${var.configs.realtime_cluster.domain}/d/fb6a6330-1a95-4a17-8886-374edcbf601f/golang-process-info-vm-version?orgId=1&var-ds=e8e45132-8b73-458c-b52e-c71c10a0bd4d&var-cluster={{ .Labels.cluster }}&var-region={{ .Labels.region }}&var-env={{ .Labels.env }}&var-role={{ .Labels.role }}&var-instance=All&var-container_ip={{ .Labels.container_ip }}&var-container_name=All)

**Details:**
{{ range .Labels.SortedPairs }}{{ if and (ne (.Name) "severity") (ne (.Name) "summary") (ne (.Name) "alertname") (ne (.Name) "alertgroup") }}> - {{ .Name  }} : {{ .Value | markdown | html }}
{{ end }}{{ end }}
{{ end }}{{ end }}

{{/* Default */}}
{{ define "vm_errors_total.title" }}{{ template "__subject" . }}{{ end }}
{{ define "vm_errors_total.content" }}#### \[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}\] **[{{ index .GroupLabels "alertname" }}]({{ template "__alertmanagerURL" . }})**
{{ if gt (len .Alerts.Firing) 0 -}}
**Alerts Firing**
{{ template "vm_errors_total.__text_alert_list" .Alerts.Firing }}
{{ range .AtMobiles }}@{{ . }}{{ end }}
{{- end }}
{{ if gt (len .Alerts.Resolved) 0 -}}
**Alerts Resolved**
{{ template "vm_errors_total.__text_alert_list" .Alerts.Resolved }}
{{ range .AtMobiles }}@{{ . }}{{ end }}
{{- end }}
{{- end }}

{{/* Legacy */}}
{{ define "legacy.title" }}{{ template "__subject" . }}{{ end }}
{{ define "legacy.content" }}#### \[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}\] **[{{ index .GroupLabels "alertname" }}]({{ template "__alertmanagerURL" . }})**
{{ template "__text_alert_list_2" .Alerts.Firing }}
{{- end }}

{{/* Following names for compatibility */}}
{{ define "vm_errors_total.link.title" }}{{ template "vm_errors_total.title" . }}{{ end }}
{{ define "vm_errors_total.link.content" }}{{ template "vm_errors_total.content" . }}{{ end }}


    EOF
  }
}

resource "kubernetes_deployment" "alert-cluster-dingtalk-webhook" {
  metadata {
    namespace = var.configs.namespace
    name      = local.dingtalk-webhook-name
  }

  spec {
    replicas = 2 #todo

    selector {
      match_labels = {
        kubernetes_deployment_name = local.dingtalk-webhook-name
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.dingtalk-webhook-name
        }
      }

      spec {
        container {
          image             = "ahfuzhang/dingtalk-webhook:v2.1.1"
          image_pull_policy = "IfNotPresent"
          args = [
            "--web.listen-address=:8060",
            "--web.enable-ui",
            "--config.file=/configs/webhook-dingtalk.yaml",
            "--log.level=debug", # $${local.log_level}
            "--log.format=${var.configs.log.format}",
            "--pushmetrics.extraLabel='region=\"${var.configs.region}\",env=\"${var.configs.env}\",cluster=\"alert-cluster\",role=\"dingtalk-webhook\",container_ip=\"$(CONTAINER_IP)\",container_name=\"$(CONTAINER_NAME)\"'",
            "--pushmetrics.interval=${var.push_metrics.interval}",
            "--pushmetrics.url=${var.push_metrics.addr}",
            "--maxalertcount=30", # todo: use config
          ]
          name = local.dingtalk-webhook-name

          resources {
            limits = {
              cpu    = "0.5" #todo
              memory = "256Mi"
            }
            requests = {
              cpu    = "0.1"
              memory = "128Mi"
            }
          }

          port {
            container_port = 8060
          }

          env {
            name = "CONTAINER_NAME"

            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name = "CONTAINER_IP"

            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name  = "GOMAXPROCS"
            value = "1" #todo
          }

          volume_mount {
            name       = "alert-cluster-dingtalk-webhook-configs-volume"
            mount_path = "/configs/"
          }
        } # end container
        volume {
          name = "alert-cluster-dingtalk-webhook-configs-volume"

          config_map {
            name = "alert-cluster-dingtalk-webhook-configs"
          }
        }
      }
    }
  }
}

data "external" "alert-cluster-dingtalk-webhook-status" {
  depends_on = [kubernetes_deployment.alert-cluster-dingtalk-webhook]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.dingtalk-webhook-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "alert-cluster-dingtalk-webhook-containers" {
  value = [for item in jsondecode(data.external.alert-cluster-dingtalk-webhook-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "alert-cluster-dingtalk-webhook-service" {
  depends_on = [data.external.alert-cluster-dingtalk-webhook-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.dingtalk-webhook-name}-service"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.dingtalk-webhook-name
    }

    port {
      protocol    = "TCP"
      port        = 8060
      target_port = 8060
    }

    type = "ClusterIP"
  }
}

output "alert-cluster-dingtalk-webhook-service-addr" {
  value = "${kubernetes_service.alert-cluster-dingtalk-webhook-service.spec.0.cluster_ip}:${kubernetes_service.alert-cluster-dingtalk-webhook-service.spec.0.port.0.target_port}"
}
