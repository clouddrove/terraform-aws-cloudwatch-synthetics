provider "aws" {
  region = "us-east-1"
}
module "canaries" {
      source                    = "../.."
      name                      = "canary"
      environment               = "test"
      label_order               = ["name", "environment"]
      schedule_expression       = "rate(5 minutes)"
      s3_artifact_bucket        = "test-bucket" # must pre-exist
      alarm_email               = "test.user@clouddrove.com" # you need to confirm this email address
      endpoints                 = { "test-example" = { url = "https://example.com" } }
      # subnet_ids                = module.subnets.private_subnet_id
      # security_group_ids        = [module.ssh.security_group_ids]    
}