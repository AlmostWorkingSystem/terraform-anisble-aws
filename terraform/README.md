# AWS (Terraform)

AWS resources for the ERP. Synced with live AWS on 2 November 2026 (all hand-made resources imported, plan clean).
State: S3 `tf-erp-state-bkt` (`staging/terraform.tfstate`, ap-south-1), lock table `tf-locks`.

| File | What |
|---|---|
| `main.tf` | Security groups (ap-south-2), S3 buckets and their IAM users, ECR, SES users, other IAM users |
| `cloudfront.tf` | Attachment CDNs `cdn.kiet.co.in` (prod) and `cdn.staging.kiet.co.in`, OAC, signed-URL key groups, bucket policies, CORS, ACM certs |
| `singapore.tf` | ap-southeast-1: `prod_backend` and `staging_db` EC2, EIPs, security groups, key pair |
| `rekognition.tf` | Rekognition user, role and bucket |
| `email.tf` | EduVverse email for KIET on `kiet.eduvverse.com` (SES ap-south-1): buckets, configuration set, SNS topics, receipt rule, the account's IAM key. Form values: `terraform output email_account` |

Providers: `aws` (ap-south-2, default), `aws.us_east_1` (CloudFront certs), `aws.ap_southeast_1`.
DNS for these lives in `../cloudflare`.

## Usage

```sh
terraform init
terraform plan
terraform apply
```

### Email webhook

Once the latest backend is live, subscribe both email topics to its webhook (the backend confirms them):

```sh
terraform apply -var 'email_webhook_url=https://<backend>/v1/communication_email/webhook/'
```

Keep passing the same value afterwards (or put it in a `terraform.tfvars`), otherwise the next apply removes the subscriptions.

## Not managed here (created by hand)

- WAF web ACL on the prod CDN (`CreatedByCloudFront-95e90067`), referenced by ARN
- SES identities
- Human IAM users and `admin-group`
- Leftovers that look unused: `AppRunnerECRAccessRole`, IAM policy `epoque@kiet.co.in`,
  ap-south-1 security group `web-server`, key pair `ap-south-1` and an unattached Elastic IP
