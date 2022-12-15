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
