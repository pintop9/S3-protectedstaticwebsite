# Static Website with Terraform on AWS

This project deploys a simple static website to an AWS S3 bucket in IL-central region, served via CloudFront. The infrastructure is managed using Terraform.

## Description

The website is a simple HTML page with some CSS and JavaScript. It displays a header with text and a button. Clicking the button randomizes the styles of the header text.

The infrastructure is deployed on AWS and consists of:
- An S3 bucket to host the static website files.
- A CloudFront distribution to serve the website with HTTPS.
- A WAF Web ACL to protect the CloudFront distribution.
- An Origin Access Identity to restrict direct access to the S3 bucket.

## Security Measures

This project implements several security measures to protect the static website:
- **S3 Bucket:** The S3 bucket is configured with `block_public_acls`, `block_public_policy`, `ignore_public_acls`, and `restrict_public_buckets` to prevent public access. Access to the S3 bucket is granted only through an Origin Access Identity (OAI) for the CloudFront distribution.
- **CloudFront Distribution:** The CloudFront distribution serves the website via HTTPS, encrypting data in transit. It uses an Origin Access Identity to restrict direct access to the S3 bucket, ensuring content is delivered only through CloudFront.
- **WAF Web ACL:** An AWS Web Application Firewall (WAF) Web ACL is associated with the CloudFront distribution to protect the website from common web exploits and bots. It includes managed rulesets (e.g., `AWSManagedRulesCommonRuleSet`) and rate-limiting rules to mitigate various threats.

## Prerequisites

Before you begin, ensure you have the following installed:
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

You also need to have your AWS credentials configured. You can do this by running `aws configure`.

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```bash
   cd Static_website
   ```
3. Initialize Terraform:
   ```bash
   terraform init
   ```

## Usage

To deploy the website, run the following command:
```bash
terraform apply
```
Terraform will provision the necessary AWS resources. After the apply is complete, you will see the CloudFront URL in the output. You can access the website by navigating to this URL in your browser.

To destroy the infrastructure, run:
```bash
terraform destroy
```

## Terraform Resources

The following Terraform resources are created:
- `aws_s3_bucket`
- `aws_s3_bucket_website_configuration`
- `aws_s3_bucket_public_access_block`
- `aws_s3_bucket_policy`
- `aws_s3_object`
- `aws_cloudfront_origin_access_identity`
- `aws_cloudfront_distribution`
- `aws_wafv2_web_acl`
- `null_resource` (for CloudFront invalidation)
- `random_string`
