cmake_minimum_required(VERSION 3.10)
project(TestApi)

# Include directories
include_directories(inc ../../fsl_interp/lib ${CMAKE_SOURCE_DIR}/../../modules/mavis)

# Source files
file(GLOB ALL_SRC "src/*.cpp")

# Add executable
add_executable(test_api_exec ${ALL_SRC})
target_include_directories(test_api_exec PRIVATE ${CMAKE_SOURCE_DIR}/../common ${CMAKE_SOURCE_DIR}/../../)
target_link_libraries(test_api_exec fslinterp_lib mavis boost_program_options)

