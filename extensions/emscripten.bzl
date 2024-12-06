load(":revisions.bzl", "EMSCRIPTEN_TAGS")

EMSCRIPTEN_URL = "https://storage.googleapis.com/webassembly/emscripten-releases-builds/{}/{}/wasm-binaries{}.{}"

####

def _emscripten_repository_impl(ctx):
    revision = EMSCRIPTEN_TAGS[ctx.attr.version]
    # TODO support and test other OSes
    # TODO support and test sha256 for other OSes
    #path = EMSCRIPTEN_URL.format("linux", revision.hash, "", "tar.xz")
    #ctx.download_and_extract(path, sha256=revision.sha_linux)

    ctx.file("install/emscripten/emcc.py", "print('dummy compiler')")
    # these two files make it possible to `bazel run @emscripten_3_1_73//:emcc` from rules_cc
    ctx.template("BUILD.bazel", Label("toolchain.tpl"), substitutions = {
        #"hello": "world"
    })

emscripten_repository = repository_rule(
    _emscripten_repository_impl,
    attrs = {
        "version": attr.string()
    }
)

####

def _emscripten_impl(ctx):
    for module in ctx.modules:
        if len(module.tags.toolchain) != 1:
            fail("Exactly one toolchain for Emscripten must be specified")
        version = module.tags.toolchain[0].version
        repository_name = "emscripten_" + version.replace(".", "_")
        emscripten_repository(
            name = repository_name,
            version = version
        )
        # NOTE that register_toolchains takes a label, which might be pointing at a repository. Are toolchains defined
        # inside a repository? How about rules? I think maybe since 

        # next steps are to try and register the toolchain from here, I need to create some py_binaries
        # based on the downloaded archive and then register the toolchain based on those.
        # CHECK HERE: https://github.com/bazelbuild/rules_python/blob/096a04fdcd2c3ff29f485d57129a1d838f022867/python/private/python_register_toolchains.bzl#L52-L56

        # https://github.com/vvviktor/bazel-mingw-toolchain/blob/main/toolchain/toolchain_config.bzl
    
    return ctx.extension_metadata(reproducible = True)

_toolchain = tag_class(
    doc = "Tag class used to register Emscripten toolchains.",
    attrs = {
        "is_default": attr.bool(
            mandatory = False,
            doc = """\
Whether the toolchain is the default version
""",
        ),
        "version": attr.string(
            mandatory = True,
            doc = """\
The Emscripten version, in `major.minor.patch` format, e.g.
`3.1.73`), to create a toolchain for.
""",
        ),
    },
)

emscripten = module_extension(
    doc = """Bzlmod extension that is used to register Emscripten toolchains.
""",
    implementation = _emscripten_impl,
    tag_classes = {
        "toolchain": _toolchain,
    },
    os_dependent=True,
    arch_dependent=True,
)