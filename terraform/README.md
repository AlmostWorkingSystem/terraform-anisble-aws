# Terraform AWS EC2 and Route53 Example

This project provisions an AWS EC2 instance with SSH, HTTP, and HTTPS access, and creates a Route53 DNS record pointing to the instance's public IP.

## Project Structure

- `main.tf` – Defines EC2 instance, security groups, and key pair.
- `provider.tf` – AWS provider configuration.
- `variables.tf` – Input variables (region, AMI).
- `outputs.tf` – Outputs for instance public IP and ID.
- `dns.tf` – Route53 DNS record for a subdomain.
- `user_data.sh` – User data script for EC2 initialization.
- `keys/` – SSH key pair (excluded from git).
- `.gitignore` – Ignores Terraform state, keys, and local files.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- AWS credentials configured (via environment variables or AWS CLI)
- An existing Route53 hosted zone (update `zone_id` in `dns.tf`)
- A valid SSH key pair in the `keys/` directory (`tf_key` and `tf_key.pub`)

## Usage

1. **Initialize Terraform:**

   ```sh
   terraform init
   ```

2. **Review the plan:**

   ```sh
   terraform plan
   ```

3. **Apply the configuration:**

   ```sh
   terraform apply
   ```

4. **Outputs:**
   - Public IP and instance ID will be shown after apply.

## Customization

- Change the AWS region or AMI in [`variables.tf`](variables.tf).
- Update the subdomain and zone ID in [`dns.tf`](dns.tf).
- Modify the user data script in [`user_data.sh`](user_data.sh).

## Cleanup

To destroy all resources:

```sh
terraform destroy
```

## Security

- Do **not** commit your private keys or sensitive files.
- Security groups allow SSH (22), HTTP (80), and HTTPS (443) from anywhere. Restrict
