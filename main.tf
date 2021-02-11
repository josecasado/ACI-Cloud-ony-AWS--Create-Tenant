#
# Provider ACI --------------------------------
#

terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}


#
# Cloud APIC ACI Provider credentials  --------------------------------
#

provider "aci" {
  username = var.user.username
  password = var.user.password
  url      = var.user.url
  insecure = true
}

#
# Define an ACI Tenant Resource  --------------------------------
#

resource "aci_tenant" "tf_tenant" {
    name        = var.tenant
    description = "This tenant is created by terraform"
}

#
# Define the credential to connect to the Tenant-User  --------------------------------
#

resource "aci_cloud_aws_provider" "Tenant-JC" {
  tenant_dn     = aci_tenant.tf_tenant.id
  access_key_id = var.tenant-user.accesskey
  account_id    = var.tenant-user.accountid
  # region            = local.aws_region
  secret_access_key = var.tenant-user.secretkey
  is_trusted        = "no"
}

#
# Define an ACI Tenant VRF Resource  --------------------------------
#
resource "aci_vrf" "vrf1" {
    tenant_dn   = aci_tenant.tf_tenant.id
    description = "VRF Created Using Terraform"
    name        = var.vrf
}

#
# Create Cloud Context Profiles: map vrf to VPC  --------------------------------
#
resource "aci_cloud_context_profile" "context-1" {
  name                     = "context-1"
  tenant_dn                = aci_tenant.tf_tenant.id
  region                   = "us-west-1"
  cloud_vendor             = "aws"
  primary_cidr             = var.cidr.addr
  relation_cloud_rs_to_ctx = aci_vrf.vrf1.id
  hub_network              = "uni/tn-infra/gwrouterp-TGW"
}

#
# Create Cloud CIDR and Subnets  --------------------------------
#

resource "aci_cloud_cidr_pool" "cidr" {
  cloud_context_profile_dn = aci_cloud_context_profile.context-1.id
  addr                     = var.cidr.addr
  name_alias               = "cidrsubnet1A"
}

resource "aci_cloud_subnet" "subnet1A" {
  cloud_cidr_pool_dn = aci_cloud_cidr_pool.cidr.id
  ip                 = var.cidr.subnet1
  zone               = "uni/clouddomp/provp-aws/region-us-west-1/zone-us-west-1a"
  scope              = "public"
  usage = "gateway"
}

resource "aci_cloud_subnet" "subnet1B" {
  cloud_cidr_pool_dn = aci_cloud_cidr_pool.cidr.id
  ip                 = var.cidr.subnet2
  zone               = "uni/clouddomp/provp-aws/region-us-west-1/zone-us-west-1b"
  usage = "gateway"
}

#
# Create Filters  --------------------------------
#

resource "aci_filter" "allow_ssh" {
	tenant_dn = aci_tenant.tf_tenant.id
	name      = "allow_ssh"   
}
resource "aci_filter" "allow_icmp" {
	tenant_dn = aci_tenant.tf_tenant.id
	name      = "allow_icmp"   
}

resource "aci_filter_entry" "ssh" {
	name        = "ssh" 
	filter_dn   = aci_filter.allow_ssh.id
	ether_t     = "ip"
	prot        = "tcp"
	d_from_port = "ssh"
	d_to_port   = "ssh"
	stateful    = "yes"
}

	resource "aci_filter_entry" "icmp" {
	name        = "icmp" 
	filter_dn   = aci_filter.allow_icmp.id
	ether_t     = "ip"
	prot        = "icmp"
	stateful    = "yes"
}

#
# Create Contracts  --------------------------------
#

resource "aci_contract" "contract_web_app" {
	tenant_dn = aci_tenant.tf_tenant.id
	name      = var.contract.contract1 
}

resource "aci_contract" "contract_internet" {
	tenant_dn = aci_tenant.tf_tenant.id
	name      = var.contract.contract2
}

resource "aci_contract_subject" "subfilter" {
	contract_dn                  = aci_contract.contract_web_app.id
	name                         = "Subject"
	relation_vz_rs_subj_filt_att = [aci_filter.allow_icmp.id, aci_filter.allow_ssh.id]
}

resource "aci_contract_subject" "subfilter1" {
	contract_dn                  = aci_contract.contract_internet.id
	name                         = "Subject"
	relation_vz_rs_subj_filt_att = [aci_filter.allow_icmp.id, aci_filter.allow_ssh.id]
}

#
# Define an ANP  --------------------------------
#
resource "aci_cloud_applicationcontainer" "anp1" {                                                  
  tenant_dn = aci_tenant.tf_tenant.id                                                    
  name      = var.anp                                                                               
}

#
# Define 3 EPG and the selectors  --------------------------------
#
resource "aci_cloud_epg" "epg-web" {                                                        
  name                             = var.epg.epg1                                      
  cloud_applicationcontainer_dn    = aci_cloud_applicationcontainer.anp1.id                 
  relation_fv_rs_prov              = [aci_contract.contract_internet.id]                   
  relation_fv_rs_cons              = [aci_contract.contract_web_app.id]                
  relation_cloud_rs_cloud_epg_ctx = aci_vrf.vrf1.id                                     
}

resource "aci_cloud_endpoint_selector" "aciepgweb" {
  cloud_epg_dn     = aci_cloud_epg.epg-web.id
  name             = var.selector-epg.selector1
  match_expression = "custom:tier=='web'"
}

resource "aci_cloud_epg" "epg-app" {                                                        
  name                             = var.epg.epg2                                     
  cloud_applicationcontainer_dn    = aci_cloud_applicationcontainer.anp1.id                 
  relation_fv_rs_prov              = [aci_contract.contract_web_app.id]                                
  relation_cloud_rs_cloud_epg_ctx = aci_vrf.vrf1.id                                     
}

resource "aci_cloud_endpoint_selector" "aciepgapp" {
  cloud_epg_dn     = aci_cloud_epg.epg-app.id
  name             = var.selector-epg.selector2
  match_expression = "custom:tier=='app'"
}

resource "aci_cloud_external_epg" "epg-internet" {
  cloud_applicationcontainer_dn   = aci_cloud_applicationcontainer.anp1.id
  name                            = var.epg.epg-external
  relation_fv_rs_cons             = [aci_contract.contract_internet.id]
  relation_cloud_rs_cloud_epg_ctx = aci_vrf.vrf1.id
  route_reachability              = "internet"
}

resource "aci_cloud_endpoint_selectorfor_external_epgs" "aciexternalepgselector" {
  cloud_external_epg_dn = aci_cloud_external_epg.epg-internet.id
  name                  = "internet"
  subnet                = "0.0.0.0/0"
}







 