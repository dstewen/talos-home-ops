resource "uptimerobot_monitor" "plex" {
  name = "Plex"
  type = "HTTP"
  url  = "https://plex.davidstewen.com/web/index.html"

  check_ssl_errors    = true
  interval            = 300
  follow_redirections = true
  timeout             = 30
}

resource "uptimerobot_monitor" "seerr" {
  name = "Seerr"
  type = "HTTP"
  url  = "https://requests.davidstewen.com"

  check_ssl_errors    = true
  interval            = 300
  follow_redirections = true
  timeout             = 30
}

resource "uptimerobot_monitor" "gatus" {
  name = "Status Page"
  type = "HTTP"
  url  = "https://status.davidstewen.com"

  check_ssl_errors    = true
  interval            = 300
  follow_redirections = true
  timeout             = 30
}
