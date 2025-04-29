cmake_minimum_required(VERSION 3.15)

project(c_binary_out
    VERSION 1.0
    LANGUAGES C
)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

add_executable(${PROJECT_NAME} src/test.c)

install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
)