
# emscripten_cache

# the problem with the prebuilt cache is that Bazel considers these as "source" files while the
# generated caches are "generated" files. These have different directory structures. E.g., source
# files are usually under external/ while generated files are usually under bazel-out/

# to solve this, create a directory that symlinks all the sources files as generated files.
# NOTE NOTE NOTE: to work with cc_arg the cache must be a DirectoryInfo

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules/directory:providers.bzl", "DirectoryInfo", "create_directory_info")

def _prefix_match(f, prefixes):
    for prefix in prefixes:
        if f.path.startswith(prefix):
            return prefix
    fail("Expected {path} to start with one of {prefixes}".format(path = f.path, prefixes = list(prefixes)))

def _choose_path(prefixes):
    filtered = {prefix: example for prefix, example in prefixes.items() if example}
    if len(filtered) > 1:
        examples = list(filtered.values())
        fail(
            "Your sources contain {} and {}.\n\n".format(
                examples[0],
                examples[1],
            ) +
            "Having both source and generated files in a single directory is " +
            "unsupported, since they will appear in two different " +
            "directories in the bazel execroot. You may want to consider " +
            "splitting your directory into one for source files and one for " +
            "generated files.",
        )

    # If there's no entries, use the source path (it's always first in the dict)
    return list(filtered if filtered else prefixes)[0][:-1]

def _emscripten_merge_cache_impl(ctx):
    # Declare a generated file so that we can get the path to generated files.
    f = ctx.actions.declare_file("_directory_rule_" + ctx.label.name)
    ctx.actions.write(f, "")

    source_prefix = ctx.label.package
    if ctx.label.workspace_root:
        source_prefix = ctx.label.workspace_root + "/" + source_prefix
    source_prefix = source_prefix.rstrip("/") + "/"

    # Mapping of a prefix to an arbitrary (but deterministic) file matching that path.
    # The arbitrary file is used to present error messages if we have both generated files and source files.
    prefixes = {
        source_prefix: None,
        f.dirname + "/": None,
    }

    root_metadata = struct(
        directories = {},
        files = [],
        relative = "",
        human_readable = str(ctx.label),
    )

    topological = [root_metadata]
    for src in ctx.files.generated_caches:
        prefix = _prefix_match(src, prefixes)
        prefixes[prefix] = src
        relative = src.path[len(prefix):].split("/")
        current_path = root_metadata
        for dirname in relative[:-1]:
            if dirname not in current_path.directories:
                dir_metadata = struct(
                    directories = {},
                    files = [],
                    relative = paths.join(current_path.relative, dirname),
                    human_readable = paths.join(current_path.human_readable, dirname),
                )
                current_path.directories[dirname] = dir_metadata
                topological.append(dir_metadata)

            current_path = current_path.directories[dirname]

        current_path.files.append(src)

    # The output DirectoryInfos. Key them by something arbitrary but unique.
    # In this case, we choose relative.
    out = {}

    root_path = _choose_path(prefixes)

    # By doing it in reversed topological order, we ensure that a child is
    # created before its parents. This means that when we create a provider,
    # we can always guarantee that a depset of its children will work.
    for dir_metadata in reversed(topological):
        directories = {
            dirname: out[subdir_metadata.relative]
            for dirname, subdir_metadata in sorted(dir_metadata.directories.items())
        }
        entries = {
            file.basename: file
            for file in dir_metadata.files
        }
        entries.update(directories)

        transitive_files = depset(
            direct = sorted(dir_metadata.files, key = lambda f: f.basename),
            transitive = [
                d.transitive_files
                for d in directories.values()
            ],
            order = "preorder",
        )
        directory = create_directory_info(
            entries = {k: v for k, v in sorted(entries.items())},
            transitive_files = transitive_files,
            path = paths.join(root_path, dir_metadata.relative) if dir_metadata.relative else root_path,
            human_readable = dir_metadata.human_readable,
        )
        out[dir_metadata.relative] = directory

    root_directory = out[root_metadata.relative]

    # hack remove this
    sysroot_install = ctx.actions.declare_file("sysroot_install.stamp")
    ctx.actions.write(sysroot_install, "x")
    
    #     # special handling for sysroot_install.stamp, we use this in OutputGroupInfo to get the full path to
    #     # the merged cache
    #     if prebuilt_asset_file.basename == "sysroot_install.stamp":
    #         

    return [
        root_directory,
        DefaultInfo(files = root_directory.transitive_files),
        OutputGroupInfo(sysroot_install_stamp = depset([sysroot_install])),
    ]



    # for entry_name, entry in ctx.attr.prebuilt_cache[DirectoryInfo].entries.items():
    #     dirs = 
    #     if type(entry) == 'struct':
    #         print('recurse!')
        
    # # how do I merge directories? I guess I can start with copying the prebuilt directory to bazel out
    # # and then use get_path to copy in the additional files in the generated caches? Similar to the original
    # # implementation, I could also just symlink everything?


    # for prebuilt_file in ctx.attr.prebuilt_cache[DirectoryInfo].transitive_files.to_list():
    #     print("prebuilt_file = {}".format(prebuilt_file))
    #     break

    # for cache in ctx.attr.generated_caches:
    #     for generated_file in cache[DirectoryInfo].transitive_files.to_list():
    #         print("generated_file = {}".format(generated_file))
    #         break
        
        
    # source file     install/emscripten/cache/sysroot/lib/wasm32-emscripten/libwebgpu_cpp-ww.a>
    #    root = ""
    # generated file external/toolchains_emscripten++emscripten+emscripten_3_1_73/sysroot/lib/wasm32-emscripten/pic/libstubs-debug.a
    #    root = ""

    # cache = []
    # sysroot_install_stamp = None
    # for prebuilt_asset in ctx.attr.prebuilt_cache.files.to_list():
    #     prebuilt_asset_file = ctx.actions.declare_file(prebuilt_asset.path)
    #     # special handling for sysroot_install.stamp, we use this in OutputGroupInfo to get the full path to
    #     # the merged cache
    #     if prebuilt_asset_file.basename == "sysroot_install.stamp":
    #         ctx.actions.write(prebuilt_asset_file, "x")
    #         sysroot_install_stamp = prebuilt_asset_file
    #     else:
    #         ctx.actions.symlink(output=prebuilt_asset_file, target_file=prebuilt_asset)
    #     cache.append(prebuilt_asset_file)
    # # Note: for some reason, the prebuilt cache must be added to `cache` first. It is unclear why, but if this
    # # is not the case, the cache is directory is wrong (debug with print in .emscripten_config)
    # for generated_cache in ctx.attr.generated_caches:
    #     for generated_asset in generated_cache.files.to_list():
    #         generated_asset_file = ctx.actions.declare_file(generated_asset.path.removeprefix(generated_asset.root.path + "/"))
    #         ctx.actions.symlink(output=generated_asset_file, target_file=generated_asset)
    #         cache.append(generated_asset_file)
            
    # return [
    #     DefaultInfo(files = depset(cache)),
    #     OutputGroupInfo(sysroot_install_stamp = depset([sysroot_install_stamp])),
    # ]

    # return [
    #     DefaultInfo(files = depset()),
    #     OutputGroupInfo(sysroot_install_stamp = depset()),
    # ]

emscripten_merge_cache = rule(
    implementation = _emscripten_merge_cache_impl,
    attrs = {
        "prebuilt_cache": attr.label(mandatory = True, cfg = "exec", allow_files = True),
        "generated_caches": attr.label_list(cfg = "exec", allow_files = True),
    },
    provides = [DefaultInfo, OutputGroupInfo],
)

# load("//lib:paths.bzl", "paths")
# load(":providers.bzl", "DirectoryInfo", "create_directory_info")

# def _prefix_match(f, prefixes):
#     for prefix in prefixes:
#         if f.path.startswith(prefix):
#             return prefix
#     fail("Expected {path} to start with one of {prefixes}".format(path = f.path, prefixes = list(prefixes)))

# def _choose_path(prefixes):
#     filtered = {prefix: example for prefix, example in prefixes.items() if example}
#     if len(filtered) > 1:
#         examples = list(filtered.values())
#         fail(
#             "Your sources contain {} and {}.\n\n".format(
#                 examples[0],
#                 examples[1],
#             ) +
#             "Having both source and generated files in a single directory is " +
#             "unsupported, since they will appear in two different " +
#             "directories in the bazel execroot. You may want to consider " +
#             "splitting your directory into one for source files and one for " +
#             "generated files.",
#         )

#     # If there's no entries, use the source path (it's always first in the dict)
#     return list(filtered if filtered else prefixes)[0][:-1]

# def _directory_impl(ctx):
#     # Declare a generated file so that we can get the path to generated files.
#     f = ctx.actions.declare_file("_directory_rule_" + ctx.label.name)
#     ctx.actions.write(f, "")

#     source_prefix = ctx.label.package
#     if ctx.label.workspace_root:
#         source_prefix = ctx.label.workspace_root + "/" + source_prefix
#     source_prefix = source_prefix.rstrip("/") + "/"



#     # Mapping of a prefix to an arbitrary (but deterministic) file matching that path.
#     # The arbitrary file is used to present error messages if we have both generated files and source files.
#     prefixes = {
#         source_prefix: None,
#         f.dirname + "/": None,
#     }

#     root_metadata = struct(
#         directories = {},
#         files = [],
#         relative = "",
#         human_readable = str(ctx.label),
#     )

#     topological = [root_metadata]
#     for src in ctx.files.srcs:
#         prefix = _prefix_match(src, prefixes)
#         prefixes[prefix] = src
#         relative = src.path[len(prefix):].split("/")
#         current_path = root_metadata
#         for dirname in relative[:-1]:
#             if dirname not in current_path.directories:
#                 dir_metadata = struct(
#                     directories = {},
#                     files = [],
#                     relative = paths.join(current_path.relative, dirname),
#                     human_readable = paths.join(current_path.human_readable, dirname),
#                 )
#                 current_path.directories[dirname] = dir_metadata
#                 topological.append(dir_metadata)

#             current_path = current_path.directories[dirname]

#         current_path.files.append(src)

#     # The output DirectoryInfos. Key them by something arbitrary but unique.
#     # In this case, we choose relative.
#     out = {}

#     root_path = _choose_path(prefixes)

#     # By doing it in reversed topological order, we ensure that a child is
#     # created before its parents. This means that when we create a provider,
#     # we can always guarantee that a depset of its children will work.
#     for dir_metadata in reversed(topological):
#         directories = {
#             dirname: out[subdir_metadata.relative]
#             for dirname, subdir_metadata in sorted(dir_metadata.directories.items())
#         }
#         entries = {
#             file.basename: file
#             for file in dir_metadata.files
#         }
#         entries.update(directories)

#         transitive_files = depset(
#             direct = sorted(dir_metadata.files, key = lambda f: f.basename),
#             transitive = [
#                 d.transitive_files
#                 for d in directories.values()
#             ],
#             order = "preorder",
#         )
#         directory = create_directory_info(
#             entries = {k: v for k, v in sorted(entries.items())},
#             transitive_files = transitive_files,
#             path = paths.join(root_path, dir_metadata.relative) if dir_metadata.relative else root_path,
#             human_readable = dir_metadata.human_readable,
#         )
#         out[dir_metadata.relative] = directory

#     root_directory = out[root_metadata.relative]

#     return [
#         root_directory,
#         DefaultInfo(files = root_directory.transitive_files),
#     ]

# directory = rule(
#     implementation = _directory_impl,
#     attrs = {
#         "srcs": attr.label_list(
#             allow_files = True,
#         ),
#     },
#     provides = [DirectoryInfo],
# )


# load("//rules/directory/private:glob.bzl", "glob")
# load("//rules/directory/private:paths.bzl", "DIRECTORY", "FILE", "get_path")

# def _init_directory_info(**kwargs):
#     self = struct(**kwargs)
#     kwargs.update(
#         get_path = lambda path: get_path(self, path, require_type = None),
#         get_file = lambda path: get_path(self, path, require_type = FILE),
#         get_subdirectory = lambda path: get_path(self, path, require_type = DIRECTORY),
#         glob = lambda include, exclude = [], allow_empty = False: glob(self, include, exclude, allow_empty),
#     )
#     return kwargs

# # TODO: Once bazel 5 no longer needs to be supported, remove this function, and add
# # init = _init_directory_info to the provider below
# # buildifier: disable=function-docstring
# def create_directory_info(**kwargs):
#     return DirectoryInfo(**_init_directory_info(**kwargs))

# DirectoryInfo = provider(
#     doc = "Information about a directory",
#     # @unsorted-dict-items
#     fields = {
#         "entries": "(Dict[str, Either[File, DirectoryInfo]]) The entries contained directly within. Ordered by filename",
#         "transitive_files": "(depset[File]) All files transitively contained within this directory.",
#         "path": "(string) Path to all files contained within this directory.",
#         "human_readable": "(string) A human readable identifier for a directory. Useful for providing error messages to a user.",
#         "get_path": "(Function(str) -> DirectoryInfo|File) A function to return the entry corresponding to the joined path.",
#         "get_file": "(Function(str) -> File) A function to return the entry corresponding to the joined path.",
#         "get_subdirectory": "(Function(str) -> DirectoryInfo) A function to return the entry corresponding to the joined path.",
#         "glob": "(Function(include, exclude, allow_empty=False)) A function that works the same as native.glob.",
#     },
# )