terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "wapp" {
 name     = var.resource_group_name_primary
 location = var.location-primary
 tags     = var.tags
}

resource "azurerm_resource_group" "wapp-sec" {
 name     = var.resource_group_name_secondary
 location = var.location-secondary
 tags     = var.tags
}


resource "azurerm_virtual_network" "wapp" {
 name                = "wapp-vnet"
 address_space       = ["10.0.0.0/16"]
 location            = var.location-primary
 resource_group_name = azurerm_resource_group.wapp.name
 tags                = var.tags
}

resource "azurerm_subnet" "wapp" {
 name                 = "wapp-subnet"
 resource_group_name  = azurerm_resource_group.wapp.name
 virtual_network_name = azurerm_virtual_network.wapp.name
 address_prefixes       = ["10.0.2.0/24"]
}

#VNET in Secondary region
resource "azurerm_virtual_network" "wapp-sec" {
 name                = "wapp-vnet-sec"
 address_space       = ["10.0.0.0/16"]
 location            = var.location-secondary
 resource_group_name = azurerm_resource_group.wapp-sec.name
 tags                = var.tags
}

resource "azurerm_subnet" "wapp-sec" {
 name                 = "wapp-subnet"
 resource_group_name  = azurerm_resource_group.wapp-sec.name
 virtual_network_name = azurerm_virtual_network.wapp-sec.name
 address_prefixes       = ["10.0.2.0/24"]
}

#Azure Storage account

resource "azurerm_storage_account" "wappstorage-primary" {
  name                     = "wappbkpstorageeastus2"
  resource_group_name      = var.resource_group_name_primary
  location = var.location-primary
  account_tier             = "Standard"
  account_replication_type = "GRS"
    depends_on = [azurerm_resource_group.wapp]

  tags = {
    environment = "storageaccount-primary"
  }
}

resource "azurerm_storage_account" "wappstorage-secondary" {
  name                     = "wappbkpstoragecentralus"
  resource_group_name      = var.resource_group_name_secondary
  location = var.location-secondary
  account_tier             = "Standard"
  account_replication_type = "GRS"

  depends_on = [azurerm_resource_group.wapp-sec]

  tags = {
    environment = "storageaccount-secondary"
  }
}


#App Plans


resource "azurerm_app_service_plan" "webappplan" {
  name                = "webapp-plan"
  location            = var.location-primary
  resource_group_name = azurerm_resource_group.wapp.name
  kind = "Linux"
  reserved = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "webapp" {
  name                = "web-app-helloworld"
  location            = var.location-primary
  resource_group_name = azurerm_resource_group.wapp.name
  app_service_plan_id = azurerm_app_service_plan.webappplan.id

  site_config {
   linux_fx_version = "PYTHON|3.9"
  }
}

resource "azurerm_app_service_slot" "webapp-staging" {
  name                = "stage"
  app_service_name    = azurerm_app_service.webapp.name
  location            = var.location-primary
  resource_group_name = azurerm_resource_group.wapp.name
  app_service_plan_id = azurerm_app_service_plan.webappplan.id

  site_config {
   linux_fx_version = "PYTHON|3.9"
}
}

#WebApp in Secondary Zone

resource "azurerm_app_service_plan" "webappplan-sec" {
  name                = "webapp-plan-sec"
  location            = var.location-secondary
  resource_group_name = azurerm_resource_group.wapp-sec.name
  kind = "Linux"
  reserved = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "webapp-sec" {
  name                = "web-app-helloworld-sec"
  location            = var.location-secondary
  resource_group_name = azurerm_resource_group.wapp-sec.name
  app_service_plan_id = azurerm_app_service_plan.webappplan-sec.id

  site_config {
   linux_fx_version = "PYTHON|3.9"
  }
}

resource "azurerm_app_service_slot" "webapp-staging-sec" {
  name                = "stage"
  app_service_name    = azurerm_app_service.webapp-sec.name
  location            = var.location-secondary
  resource_group_name = azurerm_resource_group.wapp-sec.name
  app_service_plan_id = azurerm_app_service_plan.webappplan-sec.id

  site_config {
   linux_fx_version = "PYTHON|3.9"
}
}

#Azure front door

resource "azurerm_frontdoor" "webappfrontdoor" {
      name                                         = "webapp-frontdoor-endpoint-dr"
      resource_group_name                          = azurerm_resource_group.wapp-sec.name
      enforce_backend_pools_certificate_name_check = true
    
      routing_rule {
        name               = "routingrule"
        accepted_protocols = ["Http", "Https"]
        patterns_to_match  = ["/*"]
        frontend_endpoints = ["webapp-frontdoor-endpoint-dr"]
        forwarding_configuration {
          forwarding_protocol = "MatchRequest"
          backend_pool_name   = "webapp-backend-pool-dr"
        }
      }
    
      backend_pool_load_balancing {
        name = "loadbalancingsettings"
      }
    
      backend_pool_health_probe {
        name    = "healthprobesettings"
        enabled = true
        probe_method = "HEAD"
      }
    
      backend_pool {
        name = "webapp-backend-pool-dr"
        backend {
          host_header = "web-app-helloworld-sec.azurewebsites.net"
          address = "web-app-helloworld-sec.azurewebsites.net"
 #         address     = azurerm_app_service.webapp-sec.name.azurewebsites.net
          http_port   = 80
          https_port  = 443
          priority = 2
        }

        backend {
          host_header = "web-app-helloworld.azurewebsites.net"
          address = "web-app-helloworld.azurewebsites.net"
 #         address     = azurerm_app_service.webapp-sec.name.azurewebsites.net
          http_port   = 80
          https_port  = 443
          priority = 1
        }
        load_balancing_name = "loadbalancingsettings"
        health_probe_name   = "healthprobesettings"
      }
    
      frontend_endpoint {
        name      = "webapp-frontdoor-endpoint-dr"
        host_name = "webapp-frontdoor-endpoint-dr.azurefd.net"
        session_affinity_enabled = false
        session_affinity_ttl_seconds = 0
      }
    }

