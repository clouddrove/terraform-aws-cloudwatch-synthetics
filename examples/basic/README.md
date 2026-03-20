# terraform-aws-cloudwatch-synthetics basic example

This is a basic example of the `terraform-aws-cloudwatch-synthetics` module.

## Usage

```hcl
module "cloudwatch_synthetics" {
  source      = "clouddrove/cloudwatch-synthetics/aws"
  name        = "cloudwatch-synthetics"
  environment = "test"
}
```
