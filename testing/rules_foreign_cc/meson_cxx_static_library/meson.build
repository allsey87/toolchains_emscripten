project('cxx_static_library', 'cpp',
  version : '0.1.0',
  default_options : ['warning_level=3', 'cpp_std=c++17']
)

static_library(
  'cxx_static_library_out',
  ['src/test.cxx'],
  install : true,
)

install_headers('src/test.h')