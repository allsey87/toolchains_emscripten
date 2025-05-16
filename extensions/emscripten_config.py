# This script generates Emscripten configuration files which are essentially Python scripts. Note
# that this code is used as a py_binary and executes under run_binary. The resulting/generated
# Python script is then used by Emscripten

import os
import sys

ABSOLUTIZE_ENV_PATHS = """
if (em_config := os.getenv('EM_CONFIG')) is not None:
    os.environ.update(EM_CONFIG=os.path.realpath(em_config))
if (em_cache := os.getenv('EM_CACHE')) is not None:
    os.environ.update(EM_CACHE=os.path.realpath(em_cache))
"""

# Create the configuration file
with open(sys.argv[1], 'w') as config_script:
    # Absolutize and update EM_CONFIG environment variable
    config_script.write('import os')
    config_script.write(ABSOLUTIZE_ENV_PATHS)
    
    # Write the path of NodeJS
    node_path = os.path.realpath(os.getenv('NODE_PATH'))
    config_script.write("NODE_JS = '{}'\n".format(node_path))
    
    # Write the path to the various roots
    build_file_path = os.path.realpath(os.getenv('BUILD_FILE_PATH'))
    build_dir = os.path.dirname(build_file_path)
    config_script.write("BINARYEN_ROOT = '{}'\n".format(os.path.join(build_dir, 'install')))
    config_script.write("LLVM_ROOT = '{}'\n".format(os.path.join(build_dir, 'install/bin')))
    config_script.write("EMSCRIPTEN_ROOT = '{}'\n".format(os.path.join(build_dir, 'install/emscripten')))
    
    # Set the cache path if provided, and if so, set frozen cache as true
    if (sysroot_install_stamp_file_path := os.getenv('SYSTEMROOT_INSTALL_STAMP_PATH')) is not None:
        cache_dir = os.path.dirname(os.path.realpath(sysroot_install_stamp_file_path))
        config_script.write("CACHE = '{}'\n".format(cache_dir))
        config_script.write("FROZEN_CACHE = True")
