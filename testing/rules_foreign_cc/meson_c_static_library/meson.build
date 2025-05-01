project('c_static_library', 'c',
  version : '0.1.0',
  default_options : ['warning_level=3', 'c_std=c17']
)

static_library(
  'c_static_library_out',
  ['src/test.c'],
  install : true,
)

install_headers('src/test.h')