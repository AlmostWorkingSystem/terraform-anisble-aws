# AWS (Terraform)

AWS resources for the ERP. Synced with live AWS on 2 November 2026.
State: S3 `tf-erp-state-bkt` (`staging/terraform.tfstate`, ap-south-1), lock table `tf-locks`.

| File | What |
|---|---|
| `main.tf` | Security groups (ap-south-2), S3 buckets and their IAM users, ECR, SES users, other IAM users |
| `cloudfront.tf` | Attachment CDNs `cdn.kiet.co.in` (prod) and `cdn.staging.kiet.co.in`, OAC, signed-URL key groups, bucket policies, CORS, ACM certs |
| `singapore.tf` | ap-southeast-1: `prod_backend` and `staging_db` EC2, EIPs, security groups, key pair |
| `rekognition.tf` | Rekognition user, role and bucket |
| `imports.tf` | One-off imports of resources created by hand. Delete after the first apply. |

Providers: `aws` (ap-south-2, default), `aws.us_east_1` (CloudFront certs), `aws.ap_southeast_1`.
DNS for these lives in `../cloudflare`.

## Usage

```sh
terraform init
terraform plan
terraform apply
```

### First apply after the 2 November 2026 sync

Three IAM access keys were rotated by hand, so state still points at deleted keys.
Drop them from state first, otherwise Terraform creates new keys:

```sh
terraform apply -refresh-only   # review: should only remove the 3 deleted access keys and refresh attributes
terraform plan                  # expect: imports + tag-only updates, 0 to add, 0 to destroy
terraform apply
```

Then delete `imports.tf`.

## Not managed here (created by hand)

- WAF web ACL on the prod CDN (`CreatedByCloudFront-95e90067`), referenced by ARN
- SES identities
- Human IAM users and `admin-group`
- Leftovers that look unused: `AppRunnerECRAccessRole`, IAM policy `epoque@kiet.co.in`,
  ap-south-1 security group `web-server`, key pair `ap-south-1` and an unattached Elastic IP
