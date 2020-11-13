provider "azurerm" {
  
  client_id = "9890ee8d-be3d-46cc-bbda-f6c5447bcbbf"
  client_secret = "zVCmJwYIyGw1x1jCndT97Fq_v278k53-Xu"
  subscription_id = "c47e4145-2dd5-4656-86c2-d20af6b4ac4f"
  tenant_id = "69267f4b-9464-4d8c-8e45-aa884219cfa8"
  features {}

}

############### Create a resource group ###########################
resource "azurerm_resource_group" "PureGymRG" {
  name     = "PureGymRG"
  location = "east us"
}
 
################ Create Front Door ################################
module "front-door" {
  source                                            = "./modules/frontdoor"   
  tags                                              = { Department = "Ops"}
  frontdoor_resource_group_name                     = azurerm_resource_group.instance.name
  frontdoor_name                                    = "my-frontdoor"
  frontdoor_loadbalancer_enabled                    = true
  backend_pools_send_receive_timeout_seconds        = 240
     
  frontend_endpoint      = [{
      name                                    = "my-frontdoor-frontend-endpoint"
      host_name                               = "my-frontdoor.azurefd.net"
      custom_https_provisioning_enabled       = false
      custom_https_configuration              = { certificate_source = "FrontDoor"}
      session_affinity_enabled                = false
      session_affinity_ttl_seconds            = 0
      waf_policy_link_id                      = ""
  }]
 
  frontdoor_routing_rule = [{
      name               = "my-routing-rule"
      accepted_protocols = ["Http", "Https"] 
      patterns_to_match  = ["/*"]
      enabled            = true             
      configuration      = "Forwarding"
      forwarding_configuration = [{
        backend_pool_name                     = "backendBing"
        cache_enabled                         = false      
        cache_use_dynamic_compression         = false      
        cache_query_parameter_strip_directive = "StripNone"
        custom_forwarding_path                = ""
        forwarding_protocol                   = "MatchRequest"  
      }]      
  }]
 
  frontdoor_loadbalancer =  [{      
      name                            = "loadbalancer"
      sample_size                     = 4
      successful_samples_required     = 2
      additional_latency_milliseconds = 0
  }]
 
  frontdoor_health_probe = [{      
      name                = "healthprobe"
      enabled             = true
      path                = "/"
      protocol            = "Http"
      probe_method        = "HEAD"
      interval_in_seconds = 60
  }]
 
  frontdoor_backend =  [{
      name               = "backendBing"
      loadbalancing_name = "loadbalancer"
      health_probe_name  = "healthprobe"
      backend = [{
        enabled     = true
        host_header = "www.bing.com"
        address     = "www.bing.com"
        http_port   = 80
        https_port  = 443
        priority    = 1
        weight      = 50
      }]
  }]
}

