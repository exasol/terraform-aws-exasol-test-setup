variable "owner" {
  description = "This property will be set to the exa:owner tag"
}

variable "deputy" {
  description = "This property will be set to the exa:deputy"
}

# Use a short project tag. Long tags will case the exasol cluster creation to fail (see https://github.com/exasol/cloudformation-aws-exasol/issues/3)
variable "project" {
  type        = string
  description = "project short tag. Warning: Use a short project tag. Long tags will case the exasol cluster creation to fail (see https://github.com/exasol/cloudformation-aws-exasol/issues/3)"
  validation {
    condition     = length(var.project) < 15
    error_message = "Project name was too long. Please use a shorter one."
  }
}

variable "additional_tags" {
  default     = {}
  description = "Additional resource tags"
  type        = map(string)
}

variable "datanode_count" {
  default     = 1
  description = "The number of datanodes that store data and process queries (min: 1, max: 64)."
  type        = number
}

variable "license" {
  default     = null
  description = "A path to license file that can be used with Bring Your Own License (BYOL) installation."
  type        = string
}

variable "exasol_image" {
  description = "An Exasol AMI image name. For example, 'R6.1.5-PAYG' or 'R6.2.1-BYOL'."
  type        = string
  default     = "Exasol-R7.0.11-BYOL"
}