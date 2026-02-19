terraform {
  required_version = ">= 1.5.0"

  required_providers {
    ncloud = {
      source  = "navercloudplatform/ncloud"
      version = "~> 3.2"
    }
  }

  # 팀 협업을 위한 원격 상태 저장 (NCP Object Storage 사용)
  # backend "s3" {
  #   bucket                      = "hoseo-lms-tfstate"
  #   key                         = "terraform.tfstate"
  #   region                      = "kr-standard"
  #   endpoint                    = "https://kr.object.ncloudstorage.com"
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   skip_region_validation      = true
  #   force_path_style            = true
  # }
}

provider "ncloud" {
  access_key  = var.ncloud_access_key
  secret_key  = var.ncloud_secret_key
  region      = var.region
  site        = "public"
  support_vpc = true
}
