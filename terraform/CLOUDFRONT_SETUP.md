# CloudFront Setup for erp3-attachments

## Overview

A CloudFront distribution has been configured in front of the `erp3-attachments` S3 bucket to cache images and improve performance.

## What's Been Created

1. **CloudFront Module** (`modules/cloudfront/`)

   - Reusable Terraform module for creating CloudFront distributions
   - Includes Origin Access Identity (OAI) for secure S3 access
   - Optimized cache behaviors for image formats

2. **CloudFront Distribution** for `erp3-attachments`
   - Configured in `main.tf`
   - Cache TTL: 1 day (default), up to 1 year (max)
   - Automatic HTTPS redirect
   - Compression enabled
   - Price Class: PriceClass_100 (North America & Europe)

## Deployment

To deploy the CloudFront distribution:

```bash
cd /Users/pranjal/Documents/terraform-anisble-aws/terraform

# Review the changes
terraform plan

# Apply the changes
terraform apply
```

**Note**: CloudFront distributions take 15-20 minutes to fully deploy.

## Getting the CloudFront URL

After deployment, get the CloudFront domain name:

```bash
terraform output erp3_attachments_cloudfront_domain
```

This will output something like: `d1234567890abc.cloudfront.net`

## Using CloudFront in Your Application

### Before (Direct S3 Access)

```
https://erp3-attachments.s3.amazonaws.com/images/photo.jpg
```

### After (CloudFront CDN)

```
https://d1234567890abc.cloudfront.net/images/photo.jpg
```

Replace `d1234567890abc.cloudfront.net` with your actual CloudFront domain.

## Benefits

1. **Faster Load Times**: Images are cached at edge locations closer to users
2. **Reduced S3 Costs**: Fewer direct S3 requests
3. **Better Performance**: Content delivery from AWS edge network
4. **Automatic Compression**: Images are compressed for faster delivery
5. **HTTPS by Default**: Secure content delivery

## Cache Invalidation

If you need to invalidate cached content (e.g., after updating an image):

```bash
# Get the distribution ID
DIST_ID=$(terraform output -raw erp3_attachments_cloudfront_id)

# Invalidate specific files
aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/path/to/image.jpg"

# Invalidate all files (use sparingly, costs apply)
aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*"
```

**Note**: The first 1,000 invalidation paths per month are free, additional paths cost $0.005 each.

## Monitoring

View CloudFront metrics in AWS Console:

1. Go to CloudFront service
2. Select your distribution
3. Click on "Monitoring" tab

Key metrics to watch:

- **Requests**: Number of requests to CloudFront
- **Data Transfer**: Amount of data served
- **Error Rate**: 4xx and 5xx errors
- **Cache Hit Rate**: Percentage of requests served from cache

## Configuration Details

### Cache Behavior

- **Default TTL**: 86400 seconds (1 day)
- **Maximum TTL**: 31536000 seconds (1 year)
- **Minimum TTL**: 0 seconds

### Supported Image Formats

The distribution has optimized cache behaviors for:

- JPEG (`.jpg`, `.jpeg`)
- PNG (`.png`)
- GIF (`.gif`)
- WebP (`.webp`)
- SVG (`.svg`)

### Security

- Origin Access Identity (OAI) ensures only CloudFront can access the S3 bucket
- S3 bucket policy automatically configured
- HTTPS enforced (HTTP redirects to HTTPS)

## Costs

CloudFront pricing is based on:

1. **Data Transfer Out**: ~$0.085/GB (first 10TB in North America)
2. **HTTP/HTTPS Requests**: ~$0.0075 per 10,000 requests
3. **Invalidation Requests**: First 1,000 paths/month free, then $0.005 per path

With PriceClass_100, you only pay for North America and Europe edge locations, reducing costs.

## Troubleshooting

### Images not loading through CloudFront

1. Check distribution status: `terraform output erp3_attachments_cloudfront_id`
2. Verify distribution is deployed (status should be "Deployed")
3. Check S3 bucket policy allows CloudFront OAI access

### Cache not working

1. Verify cache headers are set correctly
2. Check CloudFront cache statistics in AWS Console
3. Ensure TTL values are appropriate for your use case

### Need to update immediately

Create a cache invalidation (see Cache Invalidation section above)

## Next Steps

1. **Deploy the infrastructure**: Run `terraform apply`
2. **Update your application**: Change image URLs to use CloudFront domain
3. **Monitor performance**: Check CloudFront metrics after deployment
4. **Optional**: Set up a custom domain using Route 53 and ACM certificate

## Custom Domain (Optional)

To use a custom domain like `cdn.yourdomain.com`:

1. Request an ACM certificate in `us-east-1` region
2. Update the CloudFront module to include:
   ```hcl
   aliases = ["cdn.yourdomain.com"]
   viewer_certificate {
     acm_certificate_arn = "arn:aws:acm:us-east-1:..."
     ssl_support_method  = "sni-only"
   }
   ```
3. Create a Route 53 CNAME record pointing to CloudFront domain

## Support

For issues or questions:

- Check AWS CloudFront documentation
- Review Terraform module README at `modules/cloudfront/README.md`
- Check CloudWatch logs for errors
