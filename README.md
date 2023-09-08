# cloud-code-hosts-reference

This is a collection of reference implementations of common code hosts for Sourcegraph Cloud customersl, so we can:

- test and verify that Sourcegraph Cloud works with these code hosts configurations
- help Cloud customers to understand how to configure their code host to work with Sourcegraph Cloud

It is not intended to be a production-ready or secure way of running a code host anywhere, but rather minimal examples that can be used to achieve our goal.

## Convention

The project is structured as a collection of directories. The top-level directories are the cloud providers, and each code host and its variants are in a subdirectory.

Each sub-directory is one or more self-contained Terraform module(s).

All resources names should be randomised to avoid collisions, and make reproducibility easier.

## Notes

If you have any question, please reach out to your account manager or support@sourcegraph.com
