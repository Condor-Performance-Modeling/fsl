cmake_minimum_required(VERSION 3.10)
project(Docs)

# Custom targets for documentation
add_custom_target(docs_interp
    COMMAND ${CMAKE_COMMAND} -E make_directory docs_interp
    COMMAND ${DOXY} DoxyInterp
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Generating docs_interp"
)

add_custom_target(docs_api
    COMMAND ${CMAKE_COMMAND} -E make_directory docs_api
    COMMAND ${DOXY} DoxyApi
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Generating docs_api"
)

add_custom_target(docs ALL
    DEPENDS docs_interp docs_api
    COMMENT "Generating all documentation"
)

## Custom clean target
#add_custom_target(custom_clean
#    COMMAND ${CMAKE_COMMAND} -E remove_directory docs_interp
#    COMMAND ${CMAKE_COMMAND} -E remove_directory docs_api
#    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
#    COMMENT "Cleaning up generated files"
#)
#
