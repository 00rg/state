"""Provides Rust crate dependency loading function."""

load("@rules_rust//crate_universe:defs.bzl", "crates_repository")

def org_rust_lib_dependencies():
    """Declare Rust library dependencies."""

    crates_repository(
        name = "crate_index",
        cargo_lockfile = "//src/rust:Cargo.lock",
        lockfile = "//src/rust:Cargo.bazel.lock",
        manifests = [
            "//src/rust:Cargo.toml",
            "//src/rust/crates/goodbye:Cargo.toml",
            "//src/rust/crates/farewell:Cargo.toml",
        ],
    )
