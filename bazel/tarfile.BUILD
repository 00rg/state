# Build file that creates a tarfile from any external repository.

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

pkg_tar(
    name = "tarfile",
    srcs = glob(["**"]),
    extension = "tar.gz",
    mode = "0644",
    strip_prefix = ".",
    visibility = ["//visibility:public"],
)
