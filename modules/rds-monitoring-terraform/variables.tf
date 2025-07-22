variable "region" {
  description = "AWS region to use"
  type        = string
}

variable "db_identifier" {
  description = "The identifier of the existing RDS DB instance"
  type        = string
}
