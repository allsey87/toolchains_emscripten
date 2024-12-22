load(":revisions.bzl", "EMSCRIPTEN_TAGS")

EMSCRIPTEN_URL = "https://storage.googleapis.com/webassembly/emscripten-releases-builds/{}/{}/wasm-binaries{}.{}"

EMSCRIPTEN_CONFIG = """
BINARYEN_ROOT = '{install_dir}'
LLVM_ROOT = '{install_dir}' + '/bin'
EMSCRIPTEN_ROOT = '{install_dir}' + '/emscripten'
CACHE = '{install_dir}' + '/emscripten/cache'
FROZEN_CACHE = True
"""
####

def _emscripten_repository_impl(ctx):
    revision = EMSCRIPTEN_TAGS[ctx.attr.version]
    # TODO support and test other OSes
    # TODO support and test sha256 for other OSes
    #path = EMSCRIPTEN_URL.format("linux", revision.hash, "", "tar.xz")
    #ctx.download_and_extract(path, sha256=revision.sha_linux)
    # TODO hack to speed up local development
    #ctx.download_and_extract("http://127.0.0.1:8000/wasm-binaries-hack.tar.xz", sha256="8c3f19c7a154f04bcdc744ba1b4264bd17f106512018ec629220ba5c18cec488")
    ctx.download_and_extract("http://127.0.0.1:8000/wasm-binaries.tar.xz", sha256="4f3bc91cffec9096c3d3ccb11c222e1c2cb7734a0ff9a92d192e171849e68f28")

    #print("ctx.path('install') = {}".format(ctx.path('install')))

    #print("XXXX = {}".format(ctx.attr.nodejs.relative("//:emcc")))
    install_dir = ctx.path('install')

    ctx.file("install/emscripten/.emscripten", EMSCRIPTEN_CONFIG.format(install_dir = install_dir))


    #ctx.execute(EMBUILDER!)
    # This should pick up the args from the config file, overriding frozen cache so that embuilder can do its thing
    # repository_ctx.execute(
    #     embuilder_args,
    #     quiet=True,
    #     environment = {
    #         "EM_IGNORE_SANITY": "1",
    #         "EM_NODE_JS": "/bin/false",
    #         "EM_FROZEN_CACHE": "0",
    #     }
    # )

    ctx.template("BUILD.bazel", Label("toolchain.tpl"), substitutions = {
        "@@INSTALL_DIR@@": str(install_dir)
    })

emscripten_repository = repository_rule(
    _emscripten_repository_impl,
    attrs = {
        "version": attr.string(),
    }
)


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