############################################################################################################################################
# Options and default value

option(BUILD_TESTING "Build tests" OFF)
option(BUILD_DOC "Build documentation" OFF)
option(ENABLE_STANDALONE "Enable standalone mode" OFF)

set(RAVEN_CMAKE_CMAKE_DIR ${CMAKE_CURRENT_LIST_DIR})

############################################################################################################################################

# CMAKE Linux Path
include(GNUInstallDirs)

#CTest
include(CTest)

# Externals
include(${CMAKE_CURRENT_LIST_DIR}/external.cmake)

# Warnings
include(${CMAKE_CURRENT_LIST_DIR}/warnings.cmake)


# Raven cmake
include(${CMAKE_CURRENT_LIST_DIR}/target/testing.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/export.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/version.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/uses.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/flags.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/install.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/properties.cmake)

############################################################################################################################################

macro(disable_target Type Name)
endmacro()

############################################################################################################################################
# Creates target with name [name] and type [type].
# where type could be:
#   exe - regular executable
#   static - static library
#   shared - shared library
#   interface - non binary library, just headers, configs etc
############################################################################################################################################
function(raven_target type name)
    set(options
        PRIVATE             # do not export or install target
    )
    set(singleArgs
        OUTPUT              # set runtime output
        PUBLIC_INCLUDE_DIR  # directory of the public include
    )
    set(multiArgs
        SOURCES             # sources list
        USES                # private dependencies list
        USES_PRIVATE        # private dependencies list
        USES_PUBLIC         # public dependencies list
        INCLUDE_DIRS        # extra include directories for private use
        PUBLIC              # public headers
        PUBLIC_HEADERS      # public headers
        PREPROCESSOR        # preprocessor definitions
        FLAGS               # extra compilation flags
        CMAKE               # extra cmake scripts
        CONFIGS             # configuration files
        DATA                # extra data to install
        SYSTEMD             # systemd configuration scripts
        TARGET_DESTINATION  # target installation path (override) default: /usr[lib|bin] depends on target type
        HEADERS_DESTINATION # public headers installation root path (override) default: /usr/include
        CMAKE_DESTINATION   # extra cmake installation root path (override) default: /usr/share/cmake/[target name]
        SYSTEMD_DESTINATION # systemd scripts installation root path (override) default: /usr/lib/systemd/system/
        CONFIGS_DESTINATION # configs installation root path (override) default: /etc/[target name]
    )
    cmake_parse_arguments(args "${options}" "${singleArgs}" "${multiArgs}" ${ARGN})

    if (args_PUBLIC_HEADERS)
       set(args_PUBLIC ${args_PUBLIC_HEADERS})
    endif()

    if (args_USES_PRIVATE)
       set(args_USES ${args_USES_PRIVATE})
    endif()

    if (args_USES)
        resolve_libs(args_USES)
    endif()
    if (args_USES_PUBLIC)
        resolve_libs(args_USES_PUBLIC)
    endif()

    create_target(${name} ${type}
        OUTPUT  ${args_OUTPUT}
        SOURCES ${args_SOURCES}
        PUBLIC  ${args_PUBLIC}
        CMAKE   ${args_CMAKE}
        CONFIGS ${args_CONFIGS}
        DATA    ${args_DATA}
        SYSTEMD ${args_SYSTEMD}
        PUBLIC_INCLUDE_DIR ${args_PUBLIC_INCLUDE_DIR}
    )

    parse_using(${name} args_USES args_USES_PUBLIC)
    setup_includes(${name} args_INCLUDE_DIRS "${args_PUBLIC_INCLUDE_DIR}")
    setup_version(${name})
    set_cppflags(${name} args_FLAGS)
    preprocessor(${name} args_PREPROCESSOR)
    raven_set_custom_property(${name} PRIVATE "${args_PRIVATE}")
    if (NOT args_PRIVATE)
        export_target(${name})
        raven_install_target(${name}
            TARGET_DESTINATION  ${args_TARGET_DESTINATION}
            HEADERS_DESTINATION ${args_HEADERS_DESTINATION}
            CMAKE_DESTINATION   ${args_CMAKE_DESTINATION}
            SYSTEMD_DESTINATION ${args_SYSTEMD_DESTINATION}
            CONFIGS_DESTINATION ${args_CONFIGS_DESTINATION}
        )
    endif()

    dump_target(${name})
endfunction()

############################################################################################################################################
