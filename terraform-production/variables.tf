variable "project" {
  type = string
}

variable "services" {
  type = list(string)
}

variable "services_1st_batch" {
  type = list(string)
}

variable "services_2nd_batch" {
  type = list(string)
}

variable "project_region" {
  type    = string
  default = "europe-west2"
}

variable "project_region_2char" {
  type    = string
  default = "EU"
}

variable "staging_max_ttl_ms" {
  type        = number
  default     = 604800000
  description = "The default time to live (in ms) for data in staging areas"
}

variable "staging_max_ttl_days" {
  type        = number
  default     = 7
  description = "The default time to live (in ms) for data in staging areas"
}

variable "process_max_ttl_ms" {
  type        = number
  default     = 31536000000
  description = "The default time to live (in ms) for data in process areas"
}

variable "process_max_ttl_days" {
  type        = number
  default     = 365
  description = "The default time to live (in ms) for data in process areas"
}

variable "analysis_max_ttl_ms" {
  type        = number
  default     = 7776000000
  description = "The default time to live (in days) for data in analysis areas"
}

variable "analysis_max_ttl_days" {
  type        = number
  default     = 90
  description = "The default time to live (in days) for data in analysis areas"
}

variable "data_engineering_addr" {
  type = string
}

variable "data_analysis_addr" {
  type = string
}

variable "data_consumer_addr" {
  type = string
}

variable "data_engineering_group_id" {
  type = string
}

variable "data_analysis_group_id" {
  type = string
}

variable "data_consumer_group_id" {
  type = string
}
