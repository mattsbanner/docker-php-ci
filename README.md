# PHP Craft

PHP Craft is a Docker image used to build, test and deploy Craft CMS and Laravel sites within a CI environment.

:warning: This image is not designed to be compact, it to packages everything we need into a single image. Please see the Dockerfile for the exact contents.

## Contributing

All commits / pull requests should be made to the develop branch. This will build automatically within DockerHub to the develop Docker tag.

Once tested, develop should be merged into master. A release then needs to be made off of master with the version number incrementing from the previous (e.g. `v1.2.0` :arrow_right: `v1.2.1`). DockerHub will build this tag and the latest branch will be re-built to match the master branch.