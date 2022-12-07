"""Provides Python dependency loading function."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def org_python_lib_dependencies():
    """Declare Python library dependencies."""

    pyyaml_version = "6.0"
    maybe(
        http_archive,
        # Repository is named simply "yaml" so that Python code can "import yaml" as it normal.
        name = "yaml",
        url = "https://files.pythonhosted.org/packages/36/2b/61d51a2c4f25ef062ae3f74576b01638bebad5e045f747ff12643df63844/PyYAML-{v}.tar.gz".format(v = pyyaml_version),
        sha256 = "68fb519c14306fec9720a2a5b45bc9f0c8d1b9c72adf45c37baedfcd949c35a2",
        strip_prefix = "PyYAML-{v}/lib/yaml".format(v = pyyaml_version),
        build_file = "//bazel/third_party:BUILD.pyyaml.bazel",
    )
