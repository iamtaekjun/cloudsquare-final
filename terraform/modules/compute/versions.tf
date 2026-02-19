terraform {
  required_providers {
    ncloud = {
      source  = "navercloudplatform/ncloud"
      version = "~> 3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}
