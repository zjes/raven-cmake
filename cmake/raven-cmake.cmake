############################################################################################################################################
# Options and default value

option(BUILD_TESTING "Build tests" OFF)
option(BUILD_DOC "Build documentation" OFF)

set(RAVEN_CMAKE_CMAKE_DIR ${CMAKE_CURRENT_LIST_DIR})

############################################################################################################################################

# CMAKE Linux Path
include(GNUInstallDirs)

#CTest
include(CTest)

# Raven cmake
include(${CMAKE_CURRENT_LIST_DIR}/target/dump.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/export.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/testing.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/version.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/uses.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/flags.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/install.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/properties.cmake)

############################################################################################################################################

macro (cxx_project name)
    set(singleArgs
        STANDARD
    )
    set(multiArgs
        FILE
    )

    cmake_parse_arguments(args "" "${singleArgs}" "${multiArgs}" ${ARGN})

    if (args_STANDARD)
        set(CMAKE_CXX_STANDARD ${args_STANDARD})
    endif()

    if (NOT args_FILE)
        message(FATAL_ERROR "FILE is not set")
    endif()

    foreach(proj ${args_FILE})
        set(project ${CMAKE_CURRENT_SOURCE_DIR}/${proj})
        set(cmake ${CMAKE_CURRENT_BINARY_DIR}/${proj}.cmake)

        if (NOT EXISTS ${project})
            message(FATAL_ERROR "Project file '${project}' doesn't exist")
        endif()

        set_property(
            DIRECTORY
            APPEND
            PROPERTY CMAKE_CONFIGURE_DEPENDS
            ${project}
            ${RAVEN_CMAKE_CMAKE_DIR}/translate.py
            ${RAVEN_CMAKE_CMAKE_DIR}/cmake.py
        )

        set(generate TRUE)

        if (NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/raven-cmake.stat)
            set(generate TRUE)
        else()
            file(READ ${CMAKE_CURRENT_BINARY_DIR}/raven-cmake.stat stat)
        endif()

        file(MD5 ${project} newStat)

        if (NOT ${stat} STREQUAL ${newStat} OR ${generate})
            find_package(Python)

            get_property(vars DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VARIABLES)
            file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/raven-cmake.vars "")
            foreach(var ${vars})
                file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/raven-cmake.vars "${var}=${${var}}\n")
            endforeach()

            execute_process(
                COMMAND ${Python_EXECUTABLE} ${RAVEN_CMAKE_CMAKE_DIR}/translate.py ${project} ${cmake}
            )

            file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/raven-cmake.stat ${newStat})
        endif()

        include(${cmake})
    endforeach()
endmacro()


############################################################################################################################################

macro(disable_target name)
endmacro()

############################################################################################################################################
# Creates target with name [name].
############################################################################################################################################
function(raven_target name)
    set(options
        SHARED
        EXE
        STATIC
        INTERFACE
        PRIVATE             # do not export or install target
        AUTOMOC
    )
    set(singleArgs
        OUTPUT_PATH         # set runtime output
        TARGET_DESTINATION  # target installation path (override) default: /usr[lib|bin] depends on target type
        HEADERS_DESTINATION # public headers installation root path (override) default: /usr/include
        CMAKE_DESTINATION   # extra cmake installation root path (override) default: /usr/share/cmake/[target name]
    )
    set(multiArgs
        PUBLIC              # public headers
        SOURCES             # sources list
        USES_PRIVATE        # private dependencies list
        USES_PUBLIC         # public dependencies list
        INCLUDE_DIRS        # extra include directories for private use
        PREPROCESSOR        # preprocessor definitions
        FLAGS               # extra compilation flags
        CMAKE               # extra cmake scripts
        DATA                # extra data to install
    )
    cmake_parse_arguments(args "${options}" "${singleArgs}" "${multiArgs}" ${ARGN})

    if (args_USES_PRIVATE)
        resolve_libs(args_USES_PRIVATE)
    endif()

    if (args_USES_PUBLIC)
        resolve_libs(args_USES_PUBLIC)
    endif()

    resolveFiles(arg_SOURCES)
    resolveFiles(arg_PUBLIC)
    resolveFiles(arg_CMAKE)
    resolveFiles(arg_DATA)

    if (${args_INTERFACE})
        set(objName "${name}.interface")
    elseif(${args_STATIC})
        set(objName "${name}.static")
    elseif(${args_SHARED})
        set(objName "${name}.shared")
    elseif(${args_EXE})
        set(objName "${name}.exec")
    endif()

    if (NOT ${args_INTERFACE})
        add_library(${objName} OBJECT
            ${args_SOURCES}
            ${args_PUBLIC}
        )
        set_property(TARGET ${objName} PROPERTY POSITION_INDEPENDENT_CODE 1)
        set_property(TARGET ${objName} PROPERTY CXX_STANDARD 23)

        set_dependencies(${objName} "${args_USES_PRIVATE}" "${args_USES_PUBLIC}")
        set_includes(${objName} "${args_INCLUDE_DIRS}")
        set_cppflags(${objName} "${args_FLAGS}")
        set_preprocessor(${objName} "${args_PREPROCESSOR}")
        set_version(${objName} ${name})
    endif()

    if (${args_INTERFACE})
        add_library(${name} INTERFACE
            ${args_SOURCES}
            ${args_PUBLIC}
        )
    elseif(${args_SHARED})
        add_library(${name} SHARED $<TARGET_OBJECTS:${objName}>)
    elseif(${args_STATIC})
        add_library(${name} STATIC $<TARGET_OBJECTS:${objName}>)
    elseif(${args_EXE})
        add_executable(${name} $<TARGET_OBJECTS:${objName}>)
    endif()

    raven_set_custom_property(${name} OBJLIB_NAME "${objName}")
    raven_set_custom_property(${name} PRIVATE_DEPS "${args_USES_PRIVATE}")
    raven_set_custom_property(${name} PUBLIC_DEPS "${args_USES_PUBLIC}")

    set_includes(${name} "${args_INCLUDE_DIRS}")
    set_dependencies(${name} "${args_USES_PRIVATE}" "${args_USES_PUBLIC}")

    raven_set_custom_property(${name} PRIVATE "${args_PRIVATE}")

    if (NOT args_PRIVATE)
        export_target(${name})
        raven_install_target(${name}
            TARGET_DESTINATION  ${args_TARGET_DESTINATION}
            HEADERS_DESTINATION ${args_HEADERS_DESTINATION}
            CMAKE_DESTINATION   ${args_CMAKE_DESTINATION}
        )
    endif()

    dump_target(${name})
endfunction()

############################################################################################################################################
