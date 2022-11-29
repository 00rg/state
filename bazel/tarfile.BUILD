# Build file that creates a tarfile from any external repository.

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

filegroup(
    name = "all_files",
    srcs = glob(["**"]),
)

pkg_tar(
    name = "tarfile",
    srcs = [":all_files"],
    mode = "0644",
    strip_prefix = "./",
    visibility = ["//visibility:public"],
)
