cmake_minimum_required(VERSION 3.15)

project(c_side_module_out
    VERSION 1.0
    LANGUAGES C
)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

add_library(${PROJECT_NAME} MODULE src/test.c)

install(TARGETS ${PROJECT_NAME}
    LIBRARY DESTINATION lib
)