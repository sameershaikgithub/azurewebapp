output "resource_group_name" {
  value = azurerm_resource_group.wapp.name
}

output "resource_group_location" {
  value = azurerm_resource_group.wapp.location
}

output "asp_id" {
  value = azurerm_app_service_plan.webappplan.id
}

output "app_id" {
  value = azurerm_app_service.webapp.id
}

output "app_name" {
  value = azurerm_app_service.webapp.name
}

output "app_staging_url" {
  value = azurerm_app_service_slot.webapp-staging.default_site_hostname
}

output "frontdoor_url" {
  value = azurerm_frontdoor.webappfrontdoor.frontend_endpoint[0].host_name
}
