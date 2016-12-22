# Changelog

This project uses [Semantic Versioning](http://semver.org).

## 2.0.0

### Breaking changes

The CloudFront integration now uses the official Ruby AWS
SDK. As a consequence, the accepted format of the
`cloudfront_distribution_config` is slightly different.

Below are some examples of changes that you have to perform, depending on the
contents of your `cloudfront_distribution_config` setting.

* Rename `min_TTL` -> `min_ttl`
* Change

    ```yaml
    aliases:
      quantity: 1
      items:
        CNAME: my.site.net
    ```

    to

    ```yaml
    aliases:
      quantity: 1
      items:
        - my.site.net
    ```

* There might be other incompatible settings in your old configuration, but
  should them exist, the AWS SDK client will print you a helpful error and then
  safely exit. If this happens, just fix the problems that the CloudFront client
  reports and try again.

Also, the arrays in hashes are now merged:

```
source = {:x => [{:y => 1}]}
dest   = {:x => [{:z => 2}]}
# merge...
Results: {:x => [{:y => 1, :z => 2}]}
```

With the help of array merging, given your config file contains the following
setting:

```yaml
cloudfront_distribution_config:
  origins:
    items:
      - origin_path: /subfolder
```

... `configure-s3-website` will include the `origin_path` setting within the
properties of the first element in the `items` array of your distribution
settings.

## 1.7.5

* Fix CreateBucket broken in 1.7.4

## 1.7.4

* Support all AWS regions

## 1.7.3

* see <https://github.com/laurilehmijoki/configure-s3-website/pull/13>

## 1.7.2

* See <https://github.com/laurilehmijoki/configure-s3-website/pull/11>

## 1.7.1

* Change CloudFront `OriginProtocolPolicy` to `http-only`

  See <https://github.com/laurilehmijoki/s3_website/issues/152> for discussion.

## 1.7.0

* Add eu-central-1 Region

## 1.6.0

* Add switches `--headless` and `--autocreate-cloudfront-dist`

## 1.5.5

* Fix bug that prevented creating new CloudFront distributions in the EU region

## 1.5.4

* Remove usage of the deprecated OpenSSL::Digest::Digest

## 1.5.3

* Do not override ERB code when adding CloudFront dist

## 1.5.2

* Support location constraint eu-west-1

## 1.5.1

* Use the S3 website domain as the Cloudfront origin

  Replace `S3OriginConfig` with `CustomOriginConfig`. This solves the issue
  https://github.com/laurilehmijoki/configure-s3-website/issues/6.

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
