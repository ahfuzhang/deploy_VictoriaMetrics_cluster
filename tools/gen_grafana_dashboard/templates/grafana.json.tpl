{{ $labels := .Labels }}
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "description": "{{.Description}}",
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "links": [],
  "liveNow": false,
  "panels": [

    {
      "datasource": {
        "type": "prometheus",
        "uid": "${ds}"
      },
      "description": "process_cpu_seconds_total = process_cpu_seconds_system_total + \nprocess_cpu_seconds_user_total\n\nIf only 1 cpu core, max value is 100%; 2 cpu's max value is 200%.",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "normal"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "percentunit"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "process_cpu_seconds_system_total"
            },
            "properties": [
              {
                "id": "custom.fillOpacity",
                "value": 44
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "process_cpu_seconds_user_total"
            },
            "properties": [
              {
                "id": "custom.fillOpacity",
                "value": 43
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 8,
        "w": 6,
        "x": 0,
        "y": 1
      },
      "id": 19,
      "interval": "1m",
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${ds}"
          },
          "editorMode": "code",
          "expr": "(sum by ()(rate(process_cpu_seconds_system_total{{"{"}}{{$labels}}{{"}"}}[1m])))",
          "hide": false,
          "instant": false,
          "legendFormat": "process_cpu_seconds_system_total",
          "range": true,
          "refId": "B"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${ds}"
          },
          "editorMode": "code",
          "expr": "(sum by ()(rate(process_cpu_seconds_user_total{{"{"}}{{$labels}}{{"}"}}[1m])))",
          "hide": false,
          "instant": false,
          "legendFormat": "process_cpu_seconds_user_total",
          "range": true,
          "refId": "G"
        }
      ],
      "title": "CPU time (system + user)",
      "type": "timeseries"
    }

{{range $index, $item := .Counter}}
	  ,
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${ds}"
      },
      "description": "{{if $item.Description}}{{$item.Description}}{{else}}{{$item.MetricName}}{{end}}",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "{{if $item.Unit}}{{$item.Unit}}{{else}}short{{end}}"
        },
        "overrides": []
      },

      "interval": "1m",
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${ds}"
          },
          "editorMode": "code",
          "expr": "sum by () (rate({{$item.MetricName}}{{"{"}}{{$labels}}{{"}"}}[1m]))",
          "instant": false,
          "legendFormat": "{{$item.MetricName}}",
          "range": true,
          "refId": "A"
        }
      ],
	  "gridPos": {
        "h": {{$item.Pos.H}},
        "w": {{$item.Pos.W}},
        "x": {{$item.Pos.X}},
        "y": {{$item.Pos.Y}}
      },
      "title": "{{if $item.Title}}{{$item.Title}}{{else}}{{$item.MetricName}}{{end}}/s",
      "type": "timeseries"
    }
{{end}}

{{range $index, $item := .Guage}}
	  ,
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${ds}"
      },
      "description": "{{if $item.Description}}{{$item.Description}}{{else}}{{$item.MetricName}}{{end}}",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "{{if $item.Unit}}{{$item.Unit}}{{else}}short{{end}}"
        },
        "overrides": []
      },

      "interval": "1m",
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${ds}"
          },
          "editorMode": "code",
          "expr": "sum({{$item.MetricName}}{{"{"}}{{$labels}}{{"}"}})",
          "instant": false,
          "legendFormat": "{{$item.MetricName}}",
          "range": true,
          "refId": "A"
        }
      ],
	  "gridPos": {
        "h": {{$item.Pos.H}},
        "w": {{$item.Pos.W}},
        "x": {{$item.Pos.X}},
        "y": {{$item.Pos.Y}}
      },
      "title": "{{if $item.Title}}{{$item.Title}}{{else}}{{$item.MetricName}}{{end}}",
      "type": "timeseries"
    }
{{end}}

{{range $index, $item := .Heatmap}}
    ,
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${ds}"
      },
      "description": "{{if $item.Description}}{{$item.Description}}{{else}}{{$item.MetricName}}{{end}}",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "scaleDistribution": {
              "type": "linear"
            }
          }
        },
        "overrides": []
      },
      "interval": "1m",
      "options": {
        "calculate": false,
        "cellGap": 1,
        "cellValues": {
          "decimals": 2,
          "unit": "{{if $item.Unit}}{{$item.Unit}}{{else}}short{{end}}"
        },
        "color": {
          "exponent": 0.5,
          "fill": "dark-orange",
          "mode": "scheme",
          "reverse": false,
          "scale": "exponential",
          "scheme": "Oranges",
          "steps": 64
        },
        "exemplars": {
          "color": "rgba(255,0,255,0.7)"
        },
        "filterValues": {
          "le": 1e-9
        },
        "legend": {
          "show": true
        },
        "rowsFrame": {
          "layout": "le",
          "value": "spend"
        },
        "tooltip": {
          "show": true,
          "yHistogram": false
        },
        "yAxis": {
          "axisPlacement": "left",
          "reverse": false,
          "unit": "{{if $item.Unit}}{{$item.Unit}}{{else}}short{{end}}"
        }
      },
      "pluginVersion": "10.2.2",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${ds}"
          },
          "editorMode": "code",
          "expr": "sum(increase(label_replace({{$item.MetricName}}{{"{"}}{{$labels}}{{"}"}}, \"le\", \"$1\", \"vmrange\", \"([^\\\\n]+)\\\\.\\\\.\\\\.([^\\\\n]+)\")[1m])) by (le)",
          "format": "heatmap",
          "legendFormat": "{{"{{"}}le{{"}}"}}",
          "range": true
        }
      ],
	  "gridPos": {
        "h": {{$item.Pos.H}},
        "w": {{$item.Pos.W}},
        "x": {{$item.Pos.X}},
        "y": {{$item.Pos.Y}}
      },
      "title": "{{if $item.Title}}{{$item.Title}}{{else}}{{$item.MetricName}}{{end}}",
      "type": "heatmap"
    }

{{end}}

{{range $index, $item := .Value}}
	,
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${ds}"
      },
      "description": "{{if $item.Description}}{{$item.Description}}{{else}}{{$item.MetricName}}{{end}}",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "{{if $item.Unit}}{{$item.Unit}}{{else}}short{{end}}"
        },
        "overrides": []
      },

      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "10.2.2",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${ds}"
          },
          "editorMode": "code",
          "exemplar": false,
          "expr": "sum({{$item.MetricName}}{instance=~\"$instance\",container_name=~\"$container_name\"})",
          "format": "table",
          "instant": true,
          "legendFormat": "__auto",
          "range": false,
          "refId": "A"
        }
      ],
	  "gridPos": {
        "h": {{$item.Pos.H}},
        "w": {{$item.Pos.W}},
        "x": {{$item.Pos.X}},
        "y": {{$item.Pos.Y}}
      },
      "title": "{{if $item.Title}}{{$item.Title}}{{else}}{{$item.MetricName}}{{end}}",
      "type": "stat"
    }
{{end}}

{{range $index, $item := .TimestampValue}}
    ,
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${ds}"
      },
      "description": "{{if $item.Description}}{{$item.Description}}{{else}}{{$item.MetricName}}{{end}}",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "s"
        },
        "overrides": []
      },

      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "10.2.2",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${ds}"
          },
          "editorMode": "code",
          "exemplar": false,
          "expr": "time()-min({{$item.MetricName}}{instance=~\"$instance\",container_name=~\"$container_name\"})",
          "format": "table",
          "instant": true,
          "legendFormat": "__auto",
          "range": false,
          "refId": "A"
        }
      ],
	  "gridPos": {
        "h": {{$item.Pos.H}},
        "w": {{$item.Pos.W}},
        "x": {{$item.Pos.X}},
        "y": {{$item.Pos.Y}}
      },
      "title": "{{if $item.Title}}{{$item.Title}}{{else}}{{$item.MetricName}}{{end}}",
      "type": "stat"
    }
{{end}}


{{range $index, $item := .Text}}
  ,
  {
      "datasource": {
        "type": "datasource",
        "uid": "grafana"
      },
	  "gridPos": {
        "h": {{$item.Pos.H}},
        "w": {{$item.Pos.W}},
        "x": {{$item.Pos.X}},
        "y": {{$item.Pos.Y}}
      },
      "options": {
        "code": {
          "language": "plaintext",
          "showLineNumbers": false,
          "showMiniMap": false
        },
        "content": {{$item.Description}},
        "mode": "markdown"
      },
      "pluginVersion": "10.2.2",
      "title": "{{if $item.Title}}{{$item.Title}}{{else}}{{$item.MetricName}}{{end}}",
      "type": "text"
    }
{{end}}

  ],






  "refresh": "",
  "schemaVersion": 38,
  "tags": [],
  "templating": {
    "list": [
      {
        "current": {

        },
        "hide": 0,
        "includeAll": false,
        "label": "data source",
        "multi": false,
        "name": "ds",
        "options": [],
        "query": "prometheus",
        "queryValue": "",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "type": "datasource"
      },
      {
        "allValue": ".*",
        "current": {

        },
        "datasource": {
          "type": "prometheus",
          "uid": "${ds}"
        },
        "definition": "label_values(flag, cluster)",
        "hide": 0,
        "includeAll": true,
        "label": "Cluster",
        "multi": true,
        "name": "cluster",
        "options": [],
        "query": {
          "query": "label_values(flag, cluster)",
          "refId": "StandardVariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 5,
        "type": "query"
      },
      {
        "allValue": ".*",
        "current": {
          "selected": true,
          "text": [
            "All"
          ],
          "value": [
            "$__all"
          ]
        },
        "datasource": {
          "type": "prometheus",
          "uid": "${ds}"
        },
        "definition": "label_values(flag{cluster=~\"$cluster\"}, region)",
        "hide": 0,
        "includeAll": true,
        "label": "Region",
        "multi": true,
        "name": "region",
        "options": [],
        "query": {
          "query": "label_values(flag{cluster=~\"$cluster\"}, region)",
          "refId": "StandardVariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 5,
        "type": "query"
      },
      {
        "allValue": ".*",
        "current": {
          "selected": true,
          "text": [
            "All"
          ],
          "value": [
            "$__all"
          ]
        },
        "datasource": {
          "type": "prometheus",
          "uid": "${ds}"
        },
        "definition": "label_values(flag{cluster=~\"$cluster\",region=~\"$region\"}, env)",
        "hide": 0,
        "includeAll": true,
        "label": "Env",
        "multi": true,
        "name": "env",
        "options": [],
        "query": {
          "query": "label_values(flag{cluster=~\"$cluster\",region=~\"$region\"}, env)",
          "refId": "StandardVariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 5,
        "type": "query"
      },
      {
        "allValue": ".*",
        "current": {
          "selected": true,
          "text": [
            "All"
          ],
          "value": [
            "$__all"
          ]
        },
        "datasource": {
          "type": "prometheus",
          "uid": "${ds}"
        },
        "definition": "label_values(flag{cluster=~\"$cluster\",region=~\"$region\",env=~\"$env\"}, role)",
        "hide": 0,
        "includeAll": true,
        "label": "Role",
        "multi": true,
        "name": "role",
        "options": [],
        "query": {
          "query": "label_values(flag{cluster=~\"$cluster\",region=~\"$region\",env=~\"$env\"}, role)",
          "refId": "StandardVariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 5,
        "type": "query"
      },
      {
        "allValue": ".*",
        "current": {
          "selected": true,
          "text": [
            "All"
          ],
          "value": [
            "$__all"
          ]
        },
        "datasource": {
          "type": "prometheus",
          "uid": "${ds}"
        },
        "definition": "label_values(flag{cluster=~\"$cluster\",region=~\"$region\",env=~\"$env\",role=~\"$role\"}, instance)",
        "hide": 0,
        "includeAll": true,
        "label": "Instance",
        "multi": true,
        "name": "instance",
        "options": [],
        "query": {
          "query": "label_values(flag{cluster=~\"$cluster\",region=~\"$region\",env=~\"$env\",role=~\"$role\"}, instance)",
          "refId": "StandardVariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 5,
        "type": "query"
      },
      {
        "allValue": ".*",
        "current": {
          "selected": true,
          "text": [
            "All"
          ],
          "value": [
            "$__all"
          ]
        },
        "datasource": {
          "type": "prometheus",
          "uid": "${ds}"
        },
        "definition": "label_values(flag{cluster=~\"$cluster\",region=~\"$region\",env=~\"$env\",role=~\"$role\"}, container_ip)",
        "hide": 0,
        "includeAll": true,
        "label": "Container IP",
        "multi": true,
        "name": "container_ip",
        "options": [],
        "query": {
          "query": "label_values(flag{cluster=~\"$cluster\",region=~\"$region\",env=~\"$env\",role=~\"$role\"}, container_ip)",
          "refId": "StandardVariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 5,
        "type": "query"
      },
      {
        "allValue": ".*",
        "current": {
          "selected": false,
          "text": "All",
          "value": "$__all"
        },
        "datasource": {
          "type": "prometheus",
          "uid": "${ds}"
        },
        "definition": "label_values(flag{cluster=~\"$cluster\",region=~\"$region\",env=~\"$env\",role=~\"$role\"}, container_name)",
        "hide": 0,
        "includeAll": true,
        "label": "Container Name",
        "multi": true,
        "name": "container_name",
        "options": [],
        "query": {
          "query": "label_values(flag{cluster=~\"$cluster\",region=~\"$region\",env=~\"$env\",role=~\"$role\"}, container_name)",
          "refId": "StandardVariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 5,
        "type": "query"
      }
    ]
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "{{.Title}}",
  "uid": "{{.UID}}",
  "version": 13,
  "weekStart": ""
}
