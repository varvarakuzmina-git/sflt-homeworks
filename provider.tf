terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  service_account_key_file = "authorized_key.json"
  cloud_id                 = "b1gq62c936j3a4pstmgr"
  folder_id                = "b1gd4v9eig42od3u22c2"
  zone                     = "ru-central1-a"
}