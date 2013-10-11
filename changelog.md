# Changelog

This project uses [Semantic Versioning](http://semver.org).

## 1.5.0

* Add support for custom index and error documents

## 1.4.0

* Allow the user to store his CloudFront settings in the config file
 * Support updating configs of an existing CloudFront distribution
 * Support creating of new distros with custom CloudFront configs

## 1.3.0

* Create a CloudFront distro if the user wants to deliver his S3 website via the
  CDN

## 1.2.0

* Support configuring redirects on the S3 website

## 1.1.2

* Use UTC time when signing requests

## 1.1.1

* Do not send the location constraint XML when using the standard region

## 1.1.0

* Add support for non-standard AWS regions
