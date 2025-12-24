terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_container" "flutter_web" {
  name  = "flutter_web_container"
  image = "nginx:alpine"

  ports {
    internal = 80
    external = 9090
  }

  volumes {
    host_path      = "${path.cwd}/build/web"
    container_path = "/usr/share/nginx/html"
    read_only      = true
  }
}
