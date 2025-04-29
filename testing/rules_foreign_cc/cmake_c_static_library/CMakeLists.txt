cmake_minimum_required(VERSION 3.15)

project(c_static_library_out
    VERSION 1.0
    LANGUAGES C
)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

add_library(${PROJECT_NAME} STATIC src/test.c)
set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "src/test.h")

install(TARGETS ${PROJECT_NAME}
    LIBRARY DESTINATION lib
    PUBLIC_HEADER DESTINATION include
)