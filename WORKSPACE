workspace(name = "org")

load("//bazel:deps.bzl", "local_dependencies")

local_dependencies()

load("@rules_python//python:repositories.bzl", "python_register_toolchains")

python_register_toolchains(
    name = "python3_9",
    # For available versions, see:
    # https://github.com/bazelbuild/rules_python/blob/main/python/versions.bzl
    python_version = "3.10.6",
)
