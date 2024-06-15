cmake_minimum_required(VERSION 3.10)
project(fsl)

# Check if FSL_MAVIS_PATH is set
if(DEFINED FSL_MAVIS_PATH)
  set(FSL_MAVIS_DIR ${FSL_MAVIS_PATH})
else()
  set(FSL_MAVIS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/modules/mavis")
endif()

if(NOT TARGET mavis)
  add_subdirectory(${FSL_MAVIS_DIR})
endif()
  
# Include subdirectories
#add_subdirectory(modules/mavis)
add_subdirectory(fsl_interp)
add_subdirectory(fsl_api)
add_subdirectory(docs EXCLUDE_FROM_ALL)

# Custom target for building documentation
add_custom_target(docs
    COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR}
                             --target docs_internal
    COMMENT "Generating all documentation"
)

add_dependencies(docs docs_internal)
