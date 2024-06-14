cmake_minimum_required(VERSION 3.10)
project(TestInterp)

# Include directories
include_directories(../../fsl_interp/inc)

# Input files
set(INP_FILES
    syntax_tests/_1_syntax_test.fsl
    syntax_tests/_2_syntax_test.fsl
    syntax_tests/sample1.fsl
    syntax_tests/all_comments.fsl
    syntax_tests/empty_file.fsl
    syntax_tests/syntax1.fsl
    syntax_tests/syntax2.fsl
    syntax_tests/test3.fsl
    syntax_tests/test4.fsl
)

set(INTERP_BIN ../../fsl_interp/bin/fslinterp)

# Test command
add_custom_target(run_interp_tests
    COMMAND ${INTERP_BIN} --verbose ${INP_FILES} -o output.txt
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Running interpreter tests"
)
