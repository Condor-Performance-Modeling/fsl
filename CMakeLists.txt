cmake_minimum_required(VERSION 3.10)
project(fsl)

# Include subdirectories
add_subdirectory(modules/mavis)
add_subdirectory(fsl_interp)
add_subdirectory(fsl_api)
add_subdirectory(docs EXCLUDE_FROM_ALL)

# Custom target for building documentation
add_custom_target(docs
    COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target docs_internal
    COMMENT "Generating all documentation"
)

add_dependencies(docs docs_internal)
