
EmscriptenCacheInfo = provider(doc = "Location of the Emscripten cache", fields = ['path'])

def _emscripten_combine_cache_impl(ctx):
    cache = []
    for prebuilt_asset in ctx.attr.prebuilt_cache.files.to_list():
        prebuilt_asset_link = ctx.actions.declare_file(prebuilt_asset.path)
        ctx.actions.symlink(output=prebuilt_asset_link, target_file=prebuilt_asset)
        cache.append(prebuilt_asset_link)
    # Note: for some reason, the prebuilt cache must be added to `cache` first. It is unclear why, but if this
    # is not the case, the cache is directory is wrong (debug with print in .emscripten_config)
    for generated_cache in ctx.attr.generated_caches:
        for generated_asset in generated_cache.files.to_list():
            generated_asset_link = ctx.actions.declare_file(generated_asset.path.removeprefix(generated_asset.root.path + "/"))
            ctx.actions.symlink(output=generated_asset_link, target_file=generated_asset)
            cache.append(generated_asset_link)
    return [
        DefaultInfo(files = depset(cache)),
        EmscriptenCacheInfo(path = ctx.genfiles_dir.path)
    ]

emscripten_combine_cache = rule(
    implementation = _emscripten_combine_cache_impl,
    attrs = {
        "prebuilt_cache": attr.label(mandatory = True, cfg = "exec"),
        "generated_caches": attr.label_list(cfg = "exec"),
    },
    provides = [DefaultInfo, EmscriptenCacheInfo],
)