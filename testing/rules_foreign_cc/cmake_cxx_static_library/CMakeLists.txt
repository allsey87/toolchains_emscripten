cmake_minimum_required(VERSION 3.15)

project(cxx_static_library_out
    VERSION 1.0
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(${PROJECT_NAME} STATIC src/test.cxx)
set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "src/test.h")

install(TARGETS ${PROJECT_NAME}
    LIBRARY DESTINATION lib
    PUBLIC_HEADER DESTINATION include
)