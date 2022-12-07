"""Provides base container image dependency loading function."""

load("@io_bazel_rules_docker//container:container.bzl", "container_pull")

def org_base_container_dependencies():
    """Declare base image container dependencies."""

    container_pull(
        name = "alpine_linux_amd64",
        digest = "sha256:954b378c375d852eb3c63ab88978f640b4348b01c1b3456a024a81536dafbbf4",
        registry = "index.docker.io",
        repository = "library/alpine",
    )

    container_pull(
        name = "httpbin_linux_amd64",
        digest = "sha256:599fe5e5073102dbb0ee3dbb65f049dab44fa9fc251f6835c9990f8fb196a72b",
        registry = "index.docker.io",
        repository = "kennethreitz/httpbin",
    )
