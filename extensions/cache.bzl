

def _emscripten_cache_repository_impl(repository_ctx):
    repository_ctx.file("BUILD.bazel")

    if repository_ctx.attr.wasm64:
        cache_suffix = "wasm64-emscripten/"
    else:
        cache_suffix = "wasm32-emscripten/"
    if repository_ctx.attr.lto_thin:
        cache_suffix += "thinlto-pic/" if repository_ctx.attr.pic else "thinlto/"
    elif repository_ctx.attr.lto:
        cache_suffix += "lto-pic/" if repository_ctx.attr.pic else "lto/"
    elif repository_ctx.attr.pic:
        cache_suffix += "pic/"

    arguments = []
    if repository_ctx.attr.wasm64:
        arguments.append("--wasm64")
    if repository_ctx.attr.lto_thin:
        arguments.append("--lto=thin")
    elif repository_ctx.attr.lto:
        arguments.append("--lto")
    if repository_ctx.attr.pic:
        arguments.append("--pic")

    # Configure the repository build file
    declaration = "config = ({argument_list}, {cache_suffix}, {target_list})".format(
        argument_list = "[\"{}\"]".format("\", \"".join(arguments)),
        cache_suffix = "\"{}\"".format(cache_suffix),
        target_list = "[\"{}\"]".format("\", \"".join(repository_ctx.attr.targets))
    )
    repository_ctx.file("declaration.bzl", declaration)

emscripten_cache_attrs = {
    "lto": attr.bool(
        default = False,
        doc = "Build with link-time optimization",
    ),
    "lto_thin": attr.bool(
        default = False,
        doc = "Build with thin link-time optimization",
    ),
    "pic": attr.bool(
        default = False,
        doc = "Build position independent code",
    ),
    "wasm64": attr.bool(
        default = False,
        doc = "Build for wasm64-unknown-emscripten",
    ),
    "targets": attr.string_list(
        doc = "The targets to be built",
    ),
}

emscripten_cache_repository = repository_rule(
    _emscripten_cache_repository_impl,
    attrs = emscripten_cache_attrs,
)

def _emscripten_cache_impl(ctx):
    for module in ctx.modules:
        for declaration in module.tags.declare:
            # could this also be a single repo? //emscripten_cache:XXXX.bzl
            emscripten_cache_repository(
                name = declaration.name,
                lto = declaration.lto,
                lto_thin = declaration.lto_thin,
                pic = declaration.pic,
                wasm64 = declaration.wasm64,
                targets = declaration.targets
            )
    return ctx.extension_metadata(reproducible = True)

_declare = tag_class(
    doc = "Tag class used to build and cache Emscripten dependencies.",
    attrs = dict(emscripten_cache_attrs, name = attr.string(mandatory = True)),
)

emscripten_cache = module_extension(
    doc = "Bzlmod extension that is used to declare Emscripten caches",
    implementation = _emscripten_cache_impl,
    tag_classes = {
        "declare": _declare,
    },
)