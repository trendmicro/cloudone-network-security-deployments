# variables.tf

variable "prefix" {
  description = "Prefix for resources"
  default     = "<REPLACE_WITH_PREFIXT>"
}
variable "location" {
  description = "Region to deploy resources"
  default     = "<REPLACE_WITH_REGION>"
}

/* variable "boot_diagnostics_sa_type" {
  description = "Storage account type for boot diagnostics"
  default     = "Standard_LRS"
} */

variable "demoenv" {
  description = "Demo Environment"
  default     = "<REPLACE_WITH_DEMO_ENVIRONMENT>"
}

variable "sub_id" {
  description = "Subscription_ID"
  default     = "<REPLACE_WITH_SUBSCRIPTION_ID>"
}

variable "client_id" {
  description = "Client_ID"
  default     = "<REPLACE_WITH_CLIENT_ID>"
}

variable "client_secret" {
  description = "Client_Secret"
  default     = "<REPLACE_WITH_CLIENT_SECRET>"
}

variable "tenant_id" {
  description = "Tenant_ID"
  default     = "<REPLACE_WITH_TENANT_ID>"
}

variable "admin_username" {
  description = "Admin Username Webserver"
  default     = "<REPLACE_WITH_USERNAME_WEBSERVER>"
}

variable "admin_password" {
  description = "Admin Password Webserver"
  default     = "<REPLACE_WITH_ADMIN_PASSWORD_WEBSERVER>" 
}
