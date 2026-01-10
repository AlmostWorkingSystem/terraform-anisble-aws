# CloudFront Module

This module creates an AWS CloudFront distribution to serve content from an S3 bucket with caching capabilities.

## Features

- **Origin Access Identity (OAI)**: Securely access S3 bucket content through CloudFront
- **Automatic S3 Bucket Policy**: Grants CloudFront permission to read from the S3 bucket
- **Image-Optimized Caching**: Separate cache behaviors for different image formats (jpg, jpeg, png, gif, webp, svg)
- **Compression**: Automatic content compression for faster delivery
- **HTTPS**: Redirect HTTP to HTTPS for secure content delivery
- **Configurable TTL**: Control how long content is cached at edge locations

## Usage

```hcl
module "my_cloudfront" {
  source = "./modules/cloudfront"

  bucket_name                 = "my-bucket-name"
  bucket_regional_domain_name = module.my_s3_bucket.bucket_regional_domain_name
  bucket_arn                  = module.my_s3_bucket.bucket_arn

  distribution_comment = "CloudFront CDN for my application"

  # Cache settings
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0

  # Enable compression
  compress = true

  # Redirect HTTP to HTTPS
  viewer_protocol_policy = "redirect-to-https"

  # Price class (cost optimization)
  price_class = "PriceClass_100"

  tags = {
    Name        = "my-cdn"
    Environment = "production"
  }
}
```

## Inputs

| Name                        | Description                                         | Type           | Default                                   | Required |
| --------------------------- | --------------------------------------------------- | -------------- | ----------------------------------------- | :------: |
| bucket_name                 | Name of the S3 bucket to use as CloudFront origin   | `string`       | n/a                                       |   yes    |
| bucket_regional_domain_name | Regional domain name of the S3 bucket               | `string`       | n/a                                       |   yes    |
| bucket_arn                  | ARN of the S3 bucket                                | `string`       | n/a                                       |   yes    |
| distribution_comment        | Comment for the CloudFront distribution             | `string`       | `"CloudFront distribution for S3 bucket"` |    no    |
| price_class                 | Price class for CloudFront distribution             | `string`       | `"PriceClass_100"`                        |    no    |
| enabled                     | Whether the distribution is enabled                 | `bool`         | `true`                                    |    no    |
| default_ttl                 | Default TTL for cached objects (in seconds)         | `number`       | `86400`                                   |    no    |
| max_ttl                     | Maximum TTL for cached objects (in seconds)         | `number`       | `31536000`                                |    no    |
| min_ttl                     | Minimum TTL for cached objects (in seconds)         | `number`       | `0`                                       |    no    |
| allowed_methods             | HTTP methods that CloudFront processes and forwards | `list(string)` | `["GET", "HEAD", "OPTIONS"]`              |    no    |
| cached_methods              | HTTP methods for which CloudFront caches responses  | `list(string)` | `["GET", "HEAD"]`                         |    no    |
| compress                    | Whether CloudFront automatically compresses content | `bool`         | `true`                                    |    no    |
| viewer_protocol_policy      | Protocol policy for viewers                         | `string`       | `"redirect-to-https"`                     |    no    |
| tags                        | Tags to apply to CloudFront distribution            | `map(string)`  | `{}`                                      |    no    |

## Outputs

| Name                           | Description                                      |
| ------------------------------ | ------------------------------------------------ |
| distribution_id                | ID of the CloudFront distribution                |
| distribution_arn               | ARN of the CloudFront distribution               |
| distribution_domain_name       | Domain name of the CloudFront distribution       |
| distribution_hosted_zone_id    | CloudFront Route 53 zone ID                      |
| origin_access_identity_iam_arn | IAM ARN of the CloudFront origin access identity |
| origin_access_identity_path    | CloudFront origin access identity path           |

## Price Classes

- `PriceClass_All`: Use all edge locations (best performance)
- `PriceClass_200`: Use edge locations in North America, Europe, Asia, Middle East, and Africa
- `PriceClass_100`: Use edge locations in North America and Europe only (most cost-effective)

## Cache Behaviors

The module creates optimized cache behaviors for the following image formats:

- `.jpg` / `.jpeg`
- `.png`
- `.gif`
- `.webp`
- `.svg`

All image formats are cached with the same TTL settings and compression enabled.

## Security

- **Origin Access Identity**: CloudFront uses OAI to access S3, preventing direct public access to the bucket
- **HTTPS**: By default, HTTP requests are redirected to HTTPS
- **Bucket Policy**: Automatically created to allow only CloudFront OAI to read from the bucket

## Example: Using CloudFront URL

After deployment, you can access your S3 objects through CloudFront:

```
# Original S3 URL
https://my-bucket-name.s3.amazonaws.com/path/to/image.jpg

# CloudFront URL (use this in your application)
https://d1234567890abc.cloudfront.net/path/to/image.jpg
```

The CloudFront domain name is available in the `distribution_domain_name` output.

## Notes

- CloudFront distributions can take 15-20 minutes to deploy
- Changes to the distribution can take several minutes to propagate to all edge locations
- Consider using Route 53 with a custom domain for a better user experience
