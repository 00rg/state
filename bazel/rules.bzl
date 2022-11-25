"""Common rules used by this repository."""

def helm_template(name, tarball, values_file, release_name, namespace):
    cmd = """
        $(location @helm//:helm) template \
            {release_name} $(location {tarball}) \
            --values $(location {values_file}) \
            --namespace {namespace} > $@
    """.format(
        release_name = release_name,
        tarball = tarball,
        values_file = values_file,
        namespace = namespace,
    )

    native.genrule(
        name = name,
        srcs = [tarball, values_file],
        outs = ["{}.yaml".format(name)],
        tools = ["@helm//:helm"],
        cmd = cmd,
    )

def kustomize_build(name, tarball, dirs):
    cmd = """
        tar zxf $(location {tarball})
        for dir in {dirs}; do
            $(location @kustomize//:kustomize) build $$dir
        done > $@
    """.format(
        tarball = tarball,
        dirs = " ".join(dirs),
    )

    native.genrule(
        name = name,
        srcs = [tarball],
        outs = ["{}.yaml".format(name)],
        tools = ["@kustomize//:kustomize"],
        cmd = cmd,
    )

def istio_operator(name):
    cmd = "$(location @istioctl//:istioctl) operator dump > $@"

    native.genrule(
        name = name,
        srcs = [],
        outs = ["{}.yaml".format(name)],
        tools = ["@istioctl//:istioctl"],
        cmd = cmd,
    )
