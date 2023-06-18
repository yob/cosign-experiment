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

## Why

Buildkite pipelines are very often used to build docker images that are pushed
to container registries and then run in production.

Signing opens options for verifying images were built by trusted users,
pipelines or automation before allowing them to run.

## How it works

from v2.0.1 cosign looks for the SIGSTORE_ID_TOKEN environment variable. If
found, the OIDC token in the value is used as the identity to fetch an x509
certificate and sign the image.

The signature is **not** stored as part of the image or image metadata. It's a
distinct file and is pushed to a container registry as a new tag of the same
repository.

For example, if I have a docker image with the digest 123abc:

    ghcr.io/yob/cosign-experiment:1@sha256:abc123

Then the cosign signature will be pushed to:

    ghcr.io/yob/cosign-experiment:sha256-abc123.sig


Signing:

1. login to the container registry. In my case I'm testing with GitHub Container Registry:

    echo "${GITHUB_TOKEN}" | docker login -u "${GITHUB_USERNAME}" --password-stdin ghcr.io

2. Build a new docker image and push it to the registry. This should use
   buildx, and not the older style `docker build` or `docker push`. These old
   style commands make it impossible to sign the known-good digest locally.

    IMAGE_NAME="ghcr.io/${GITHUB_USERNAME}/cosign-experiment:${BUILDKITE_BUILD_NUMBER}"

    docker buildx build --metadata-file metadata.json --push -t "${IMAGE_NAME}" .

    IMAGE_DIGEST=$(cat metadata.json | jq -r '."containerimage.digest"')

3. Use cosign to create the signature and push it to the regstry:

    cosign sign --yes --output-certificate fulcio.crt "${IMAGE_NAME}@${IMAGE_DIGEST}"
 

## What does the certificate look like?

When signing an image with cosign, we can use `--output-certificate` to get a
copy of the certificate, then use `openssl` to inspect it.  A few noteworthy
things it includes:

* the subject Alternative Name is the Buildkite Pipeline URL
* the issuer identity is https://agent.buildkite.com

Also, the certificate is signed by sigstore.dev. This Certificate Authority is
**NOT** one that's trusted by defualt in any browser or operating system.

```
$ openssl x509 -in fulcio.crt -text -noout

Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            40:33:bb:a7:27:84:88:c2:7e:22:c6:3b:fa:1d:bf:7f:44:64:41:b7
        Signature Algorithm: ecdsa-with-SHA384
        Issuer: O = sigstore.dev, CN = sigstore-intermediate
        Validity
            Not Before: Jun 13 15:46:56 2023 GMT
            Not After : Jun 13 15:56:56 2023 GMT
        Subject:
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:dc:db:1c:f0:a7:9a:63:60:62:da:b6:5e:b3:03:
                    24:1f:4e:43:0f:c7:a1:9c:32:e9:fb:da:96:b8:2a:
                    0a:c6:17:60:6e:0d:86:89:45:83:17:ee:9d:0e:ac:
                    26:cc:43:e5:bd:ee:22:eb:5d:dd:8b:04:55:d2:96:
                    2f:1c:08:b0:2f
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature
            X509v3 Extended Key Usage:
                Code Signing
            X509v3 Subject Key Identifier:
                27:77:7D:3B:F3:8A:77:EB:38:7E:A1:25:2C:6A:5B:3E:14:2B:36:68
            X509v3 Authority Key Identifier:
                DF:D3:E9:CF:56:24:11:96:F9:A8:D8:E9:28:55:A2:C6:2E:18:64:3F
            X509v3 Subject Alternative Name: critical
                URI:https://buildkite.com/yob-opensource/cosign-experiment
            1.3.6.1.4.1.57264.1.1:
                https://agent.buildkite.com
            1.3.6.1.4.1.57264.1.8:
                ..https://agent.buildkite.com
            CT Precertificate SCTs:
                Signed Certificate Timestamp:
                    Version   : v1 (0x0)
                    Log ID    : DD:3D:30:6A:C6:C7:11:32:63:19:1E:1C:99:67:37:02:
                                A2:4A:5E:B8:DE:3C:AD:FF:87:8A:72:80:2F:29:EE:8E
                    Timestamp : Jun 13 15:46:56.564 2023 GMT
                    Extensions: none
                    Signature : ecdsa-with-SHA256
                                30:44:02:20:31:E2:F8:F0:7F:B2:48:E6:6A:48:3A:F6:
                                A8:9B:C6:8A:9F:54:66:26:55:12:57:B9:EC:1E:70:4D:
                                3D:B6:26:64:02:20:3B:97:1F:88:E1:7A:69:FC:14:1A:
                                58:4A:FD:CE:A7:A4:E1:12:CA:24:E3:D7:FA:50:71:9D:
                                FC:52:60:C7:FE:06
    Signature Algorithm: ecdsa-with-SHA384
    Signature Value:
        30:66:02:31:00:f5:05:b8:8d:7f:04:47:3c:23:70:ee:6b:ea:
        43:75:f0:fe:d6:47:03:b4:d2:a8:50:f8:12:01:a6:09:36:fc:
        ad:75:c5:ad:fc:99:57:45:f7:20:bc:53:b9:72:16:61:1c:02:
        31:00:e2:ab:2a:22:e2:9a:b5:28:37:8e:b0:91:2e:cc:31:03:
        92:6c:0f:33:5b:dc:1e:d2:e5:00:c3:56:ab:f3:4a:e2:80:f7:
        4d:bb:65:00:20:b0:4c:55:4c:3d:4e:43:32:96
```

## Verifying an image was created in a Buildkite build

To verify that a commit was created in a specific Buildkite pipeline, use:

* the Buildkite Pipeline URL as the certificate identity
* "https://agent.buildkite.com" as the OIDC issuer

```
$ cosign verify ghcr.io/yob/cosign-experiment:27 \
    --certificate-identity https://buildkite.com/yob-opensource/cosign-experiment \
    --certificate-oidc-issuer https://agent.buildkite.com

Verification for ghcr.io/yob/cosign-experiment:27 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
    - Existence of the claims in the transparency log was verified offline
      - The code-signing certificate was verified using trusted certificate authority certificates

      [{"critical":{"identity":{"docker-re ... }}}]
```

With no signature the output looks like:

```
$ cosign verify ghcr.io/yob/cosign-experiment:27 \
    --certificate-identity https://buildkite.com/yob-opensource/cosign-experiment \
    --certificate-oidc-issuer https://agent.buildkite.com
Error: no signatures found for image
main.go:69: error during command execution: no signatures found for image
```

When the expected issuer doesn't match, the output looks like this:

```
$ cosign verify ghcr.io/yob/cosign-experiment:27 --certificate-identity https://buildkite.com/yob-opensource/cosign-experiment --certificate-oidc-issuer https://example.com
Error: no matching signatures:
none of the expected identities matched what was in the certificate, got subjects [https://buildkite.com/yob-opensource/cosign-experiment] with issuer https://agent.buildkite.com
main.go:69: error during command execution: no matching signatures:
none of the expected identities matched what was in the certificate, got subjects [https://buildkite.com/yob-opensource/cosign-experiment] with issuer https://agent.buildkite.com
```

## Rekor

Signatures created by cosign are also written to a public transparency log call
rekor. This is to provide public proof that the signature was created at the
time it said it was, and during the valid period for the short lived keypair
created with the OIDC identity.

You can see the rekor log in a webbrowser. Part of the `cosign sign` output looks like this:

    tlog entry created with index: 24154069

The log index can be converted to a URL: https://search.sigstore.dev/?logIndex=24154069
