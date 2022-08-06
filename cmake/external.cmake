# This cmake loads the list of externals

# Standalone mode manages dependencies with externals
include(ProcessorCount)

function(getAllTargets var)
    set(targets)
    getAllTargetsRecursive(targets ${CMAKE_SOURCE_DIR})
    set(${var} ${targets} PARENT_SCOPE)
endfunction()

macro(getAllTargetsRecursive targets dir)
    get_property(subdirectories DIRECTORY ${dir} PROPERTY SUBDIRECTORIES)
    foreach(subdir ${subdirectories})
        getAllTargetsRecursive(${targets} ${subdir})
    endforeach()

    get_property(currentTargets DIRECTORY ${dir} PROPERTY BUILDSYSTEM_TARGETS)
    list(APPEND ${targets} ${currentTargets})
endmacro()


function(add_dependecy name)
    cmake_parse_arguments(args
        "AUTOCONF"
        "VERSION;GIT;NAME;SRC_PREFIX"
        "LIB_OUTPUT;HEADER_OUTPUT;DEPENDENCIES;EXTRA_ARGS"
        ${ARGN}
    )

    foreach(dep ${args_DEPENDENCIES})
        resolve(${dep})

#        unset(inc)

#        get_target_property(type ${dep} TYPE)
#        if ("${type}" STREQUAL "INTERFACE_LIBRARY")
#            if (TARGET ${dep}-props)
#                get_target_property(src ${dep}-props SOURCE_DIR)
#                get_target_property(_inc ${dep}-props INTERFACE_INCLUDE_DIR)
#            endif()
#        else()
#            get_target_property(src ${dep} SOURCE_DIR)
#            get_target_property(_inc ${dep} TARGET_INCLUDE_DIR)
#            if (src AND NOT _inc)
#                set(inc ${src})
#            endif()
#            if (_inc AND src)
#                set(inc ${src}/${_inc})
#            endif()
#        endif()
#        if (inc)
#            list(APPEND _EXTERN_CMAKE_INCLUDE -D${dep}_INCLUDE=${inc})
#        else()
#            list(APPEND _EXTERN_CMAKE_INCLUDE -D${dep}_INCLUDE=${CMAKE_BINARY_DIR}/deps-runtime/include)
#        endif()
    endforeach()

    ProcessorCount(NBJOBS)
    if(NBJOBS EQUAL 0)
        set(NBJOBS 1)
    endif()

    set(NAME           ${name})
    set(GIT            ${args_GIT})
    set(VERSION        ${args_VERSION})
    set(SRC_PREFIX     ${args_SRC_PREFIX})
    set(INSTALL_PREFIX ${CMAKE_BINARY_DIR}/deps-runtime)
    set(SRC_DIR        ${CMAKE_BINARY_DIR}/deps-src/${name})
    set(BUILD_DIR      ${CMAKE_BINARY_DIR}/deps-build/${name})
    set(DOWNLOAD_DIR   ${CMAKE_BINARY_DIR}/deps-download/${name})
    set(EXTRA_ARGS     ${args_EXTRA_ARGS})

    getAllTargets(allTargets)
    set(_EXTERN_CMAKE_FLAGS)
    set(_EXTERN_CMAKE_INCLUDE)
    set(_PKG_PATH)
    set(_EXTERN_LDFLAGS)
    set(_EXTERN_CXXFLAGS)
    foreach(tar ${allTargets})
        unset(dir)
        unset(inc)
        unset(_inc)
        unset(src)
        if(NOT (tar MATCHES "-props$" OR tar MATCHES "_build$" OR tar MATCHES "coverage"))
            get_target_property(type ${tar} TYPE)
            if ("${type}" STREQUAL "INTERFACE_LIBRARY")
                if (TARGET ${tar}-props)
                    get_target_property(dir ${tar}-props BINARY_DIR)
                    get_target_property(src ${tar}-props SOURCE_DIR)
                    get_target_property(_inc ${tar}-props INTERFACE_INCLUDE_DIR)
                endif()
            else()
                get_target_property(dir ${tar} BINARY_DIR)
                get_target_property(src ${tar} SOURCE_DIR)
                get_target_property(_inc ${tar} TARGET_INCLUDE_DIR)
                if (src AND NOT _inc)
                    set(inc ${src})
                endif()
                if (_inc AND src)
                    set(inc ${src}/${_inc})
                endif()
            endif()

            if (dir)
                list(APPEND _EXTERN_CMAKE_FLAGS -D${tar}_DIR=${dir})
                list(APPEND _EXTERN_LDFLAGS -L${dir})
                list(APPEND _PKG_PATH ${dir})
            endif()
            if (inc)
                list(APPEND _EXTERN_CXXFLAGS "-isystem ${inc}")
            endif()
        endif()
    endforeach()
    list(APPEND _EXTERN_CXXFLAGS -I${CMAKE_BINARY_DIR}/deps-runtime/include)

    list(REMOVE_DUPLICATES _EXTERN_LDFLAGS)
    string(REPLACE ";" " " EXTERN_LDFLAGS "${_EXTERN_LDFLAGS}")

    list(REMOVE_DUPLICATES _EXTERN_CXXFLAGS)
    string(REPLACE ";" " " EXTERN_CXXFLAGS "${_EXTERN_CXXFLAGS}")

    list(REMOVE_DUPLICATES _PKG_PATH)
    string(REPLACE ";" ":" PKG_PATH "${_PKG_PATH}")

    list(REMOVE_DUPLICATES _EXTERN_CMAKE_FLAGS)
    string(REPLACE ";" " " EXTERN_CMAKE_FLAGS "${_EXTERN_CMAKE_FLAGS}")

    if (EXISTS "${RAVEN_CMAKE_CMAKE_DIR}/templates/")
        set(templates "${RAVEN_CMAKE_CMAKE_DIR}/templates")
    else()
        set(templates "${CMAKE_CURRENT_LIST_DIR}/cmake/templates")
    endif()

    string(REPLACE ";" " " EXTRA_ARGS "${EXTRA_ARGS}")

    string(REGEX MATCHALL "@(.+)@" matches "${EXTRA_ARGS}")
    foreach(match ${matches})
        string(REGEX REPLACE "@(.+)@" "\\1" var "${match}")
        string(REPLACE "${match}" "${${var}}" EXTRA_ARGS "${EXTRA_ARGS}")
    endforeach()

    if (args_AUTOCONF)
        configure_file(${templates}/external-autoconf.cmake.in
            ${DOWNLOAD_DIR}/CMakeLists.txt
        )
    else()
        configure_file(${templates}/external-cmake.cmake.in
            ${DOWNLOAD_DIR}/CMakeLists.txt
        )
    endif()

    set(output)
    set(liboutput)
    set(headoutput)
    foreach(out ${args_LIB_OUTPUT})
        list(APPEND liboutput ${INSTALL_PREFIX}/${out})
        list(APPEND output ${INSTALL_PREFIX}/${out})
    endforeach()

    foreach(out ${args_HEADER_OUTPUT})
        list(APPEND headoutput ${INSTALL_PREFIX}/${out})
        list(APPEND output ${INSTALL_PREFIX}/${out})
    endforeach()

    add_custom_command(
        OUTPUT  ${output}
        COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
        COMMAND ${CMAKE_COMMAND} --build .
        WORKING_DIRECTORY ${DOWNLOAD_DIR}
    )

    string(REPLACE "::" "-" sName ${name})

    if (NOT TARGET ${sName}_build)
        add_custom_target(
            ${sName}_build
            DEPENDS ${args_DEPENDENCIES} ${output}
            WORKING_DIRECTORY ${DOWNLOAD_DIR}
        )
    endif()

    set(${name}_DIR ${INSTALL_PREFIX}/share/cmake/${name})
    find_package(${name} QUIET PATHS ${INSTALL_PREFIX} NO_DEFAULT_PATH)
    unset(${name}_DIR)

    # Add cxxtools directly to our build.
    if (NOT TARGET ${name})

        set(ENV{PKG_CONFIG_PATH} "${INSTALL_PREFIX}/lib/pkgconfig")

        pkg_check_modules(${name}_prefix QUIET IMPORTED_TARGET ${name})
        if (${name}_prefix_FOUND)
            add_library(${name} INTERFACE)
            target_link_libraries(${name} INTERFACE PkgConfig::${lib}_prefix)
        endif()


        if (NOT TARGET ${name})
            add_library(${sName} INTERFACE)
            if (NOT ${sName} STREQUAL ${name})
                add_library(${name} ALIAS ${sName})
            endif()
            add_dependencies(${sName} ${sName}_build)
            target_include_directories(${sName}
                SYSTEM INTERFACE
                    $<BUILD_INTERFACE:${INSTALL_PREFIX}/include>
            )
            if (args_LIB_OUTPUT)
                target_link_libraries(${sName} INTERFACE ${output})
            endif()
        endif()
    endif()
endfunction()

