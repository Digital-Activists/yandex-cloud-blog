resource "yandex_monitoring_dashboard" "app" {
  name      = var.project_name
  folder_id = var.folder_id
  title     = var.project_name

  widgets {
    chart {
      title    = "DB query duration"
      chart_id = "db_query_duration"

      queries {
        target {
          query = "app.django_db_query_duration_seconds{service = custom}"
        }
      }

      visualization_settings {
        type = "VISUALIZATION_TYPE_LINE"
      }
    }
    position {
      h = 8
      w = 16
      x = 0
      y = 0
    }
  }

  widgets {
    chart {
      title    = "Трафик по эндпоинтам"
      chart_id = "qps_by_view"

      queries {
        target {
          query = "app.django_http_requests_total_by_view_transport_method_total{service = custom}"
        }
      }

      visualization_settings {
        type        = "VISUALIZATION_TYPE_LINE"
        aggregation = "SERIES_AGGREGATION_AVG"
      }
    }
    position {
      h = 8
      w = 16
      x = 17
      y = 0
    }
  }

  widgets {
    chart {
      title    = "Request latency"
      chart_id = "request_latency"

      queries {
        target {
          query = "app.django_http_requests_latency_seconds_by_view_method{service = custom}"
        }
      }

      visualization_settings {
        type        = "VISUALIZATION_TYPE_LINE"
        aggregation = "SERIES_AGGREGATION_AVG"
      }
    }
    position {
      h = 8
      w = 16
      x = 0
      y = 9
    }
  }
}
