cmake_minimum_required(VERSION 3.15)

project(cxx_side_module_out
    VERSION 1.0
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(${PROJECT_NAME} MODULE src/test.cxx)
#target_link_libraries(${PROJECT_NAME} PRIVATE crash)

install(TARGETS ${PROJECT_NAME}
    LIBRARY DESTINATION lib
)