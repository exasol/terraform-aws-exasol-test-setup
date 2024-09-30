# terraform-aws-exasol-test-setup 2.0.0, released 2024-09-30

Code name: Fix NodeJS version in CloudFormation template

## Summary

This release upgrades to base module `terraform-aws-exasol` version 2.0.0 to fix issues with a deprecated NodeJS version used in CloudFormation template.

### Breaking Change

The "Bring your Own License" (BYOL) AMI images are deprecated and not available any more. Specifying your own license file is not possible any more. Please use the "Pay as you go" (PAYG) AMI images, e.g. Exasol-R7.1.26-PAYG.

## Bugfixes

* #23: Fixed NodeJS version in CloudFormation template
