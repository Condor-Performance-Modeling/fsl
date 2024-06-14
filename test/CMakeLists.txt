cmake_minimum_required(VERSION 3.10)
project(Test)

# Include subdirectories
add_subdirectory(api)
add_subdirectory(interp)

# Add test targets
add_custom_target(run_test_interp
    COMMAND ${CMAKE_COMMAND} --build ${CMAKE_CURRENT_SOURCE_DIR}/interp --target test
    COMMENT "Running interp tests"
)

add_custom_target(run_test_api
    COMMAND ${CMAKE_COMMAND} --build ${CMAKE_CURRENT_SOURCE_DIR}/api --target test
    COMMENT "Running API tests"
)

add_custom_target(run_all_tests ALL
    DEPENDS run_test_interp run_test_api
    COMMENT "Running all tests"
)

