# cosign-experiment

[Sigstore](https://www.sigstore.dev/) can generate short term x509 certificates that are
suitable for signing artifacts like docker images and git commits. A common way
to use Sigstore is in "keyless" mode, where the short term certificate is
linked to an OIDC token. The OIDC token can identify a human (often with an
identity from Google, Microsoft or Github), or sometimes an ontinuous
Integration (CI) provider workflow (like Buildkite, GitHub Actions, Gitlab, or
CircleCI).

[cosign](https://github.com/sigstore/cosign) is a program that uses keyless
Sigstore to sign docker images with an OIDC identity.

Cosign [v2.0.1 added support for signing with a OIDC token in a standard ENV var
token](https://github.com/sigstore/cosign/releases/tag/v2.0.1), and this is me
experimenting with it on Buildkite.

