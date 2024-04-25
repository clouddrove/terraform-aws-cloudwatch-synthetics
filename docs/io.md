## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alarm\_email | Email address to send alarms to | `string` | n/a | yes |
| endpoints | n/a | <pre>map(object({<br>    url = string<br>  }))</pre> | n/a | yes |
| environment | Environment (e.g. `prod`, `dev`, `staging`). | `string` | `""` | no |
| label\_order | Label order, e.g. `name`,`application`. | `list(any)` | `[]` | no |
| managedby | ManagedBy, eg 'CloudDrove'. | `string` | `"hello@clouddrove.com"` | no |
| name | Name  (e.g. `app` or `cluster`). | `string` | `""` | no |
| repository | Terraform current module repo | `string` | `"https://github.com/clouddrove/terraform-aws-cloudwatch-alarms"` | no |
| s3\_artifact\_bucket | Location in Amazon S3 where Synthetics stores artifacts from the test runs of this canary | `string` | n/a | yes |
| schedule\_expression | Expression defining how often the canary runs | `string` | n/a | yes |
| security\_group\_ids | IDs of the security groups for this canary | `list(string)` | `null` | no |
| subnet\_ids | IDs of the subnets where this canary is to run | `list(string)` | `null` | no |

## Outputs

No output.

