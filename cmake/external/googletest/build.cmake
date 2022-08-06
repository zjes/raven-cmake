# googletest.cmake
# Import Google test and mock

configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt.in
  googletest-download/CMakeLists.txt
  )

# Do not build gtest with all our warnings
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-useless-cast -Wno-pedantic -Wno-sign-conversion" )


# Download and unpack googletest at configure time
execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/googletest-download
  )
if(result)
  message(FATAL_ERROR "CMake step for googletest failed: ${result}")
endif()

execute_process(COMMAND ${CMAKE_COMMAND} --build .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/googletest-download
  )
if(result)
  message(FATAL_ERROR "Build step for googletest failed: ${result}")
endif()

# Add googletest directly to our build. This defines
# the gtest and gtest_main targets.
if (NOT TARGET gtest)
  add_subdirectory(${CMAKE_CURRENT_BINARY_DIR}/googletest-src
    ${CMAKE_CURRENT_BINARY_DIR}/googletest-build
    )
endif()
