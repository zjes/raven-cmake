find_package(PkgConfig REQUIRED)

##############################################################################################################

function(compiler_search_dirs)
    execute_process(
        COMMAND ${CMAKE_CXX_COMPILER} -print-search-dirs
        OUTPUT_VARIABLE out
    )
    string(REGEX REPLACE "^.*libraries: =(.*)$" "\\1" libs ${out})
    string(REPLACE ":" ";" libs ${libs})
    list(APPEND list /usr/lib/llvm-9/lib/clang/9.0.1/lib/linux/)
    set(COMPILER_PATHS ${libs} PARENT_SCOPE)
endfunction()

##############################################################################################################

macro(resolve_pkg lib)
    set(ENV{PKG_CONFIG_PATH} "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig")

    pkg_check_modules(${lib}_prefix QUIET IMPORTED_TARGET ${lib})
    if (${lib}_prefix_FOUND)
        add_library(${lib} INTERFACE)
        target_link_libraries(${lib} INTERFACE PkgConfig::${lib}_prefix)
    endif()
endmacro()

##############################################################################################################

macro(resolve_lib lib)
    if (NOT COMPILER_PATHS)
        compiler_search_dirs()
    endif()

    string(REPLACE "::" ";" split ${lib})
    list(LENGTH split len)

    if (NOT len EQUAL 2)
        find_library(${lib}_lib ${lib} PATHS ${COMPILER_PATHS})
        if (NOT ${lib}_lib-NOTFOUND)
            string(TOLOWER ${${lib}_lib} lolib)
            string(REGEX MATCH "(\\.dll|\\.so)$" shared ${lolib})
            string(REGEX MATCH "(\\.lib|\\.a)$" static ${lolib})
            if (shared)
                add_library(${lib} SHARED IMPORTED)
                set_target_properties(${lib} PROPERTIES
                    IMPORTED_LOCATION "${${lib}_lib}"
                    INTERFACE_LINK_LIBRARIES "${${lib}_lib}"
                )
                set(${lib}_FOUND ON)
            endif()
            if (static)
                add_library(${lib} STATIC IMPORTED)
                set_target_properties(${lib} PROPERTIES
                    IMPORTED_LOCATION "${${lib}_lib}"
                    INTERFACE_LINK_LIBRARIES "${${lib}_lib}"
                )
                set(${lib}_FOUND ON)
            endif()
        endif()
    endif()
endmacro()

##############################################################################################################

macro(resolve lib)
    cmake_parse_arguments(arg
        "NOFATAL"
        ""
        ""
        ${ARGN}
    )
    if (NOT TARGET ${lib})
        if (${lib}_DIR)
            find_package(${lib} QUIET PATHS ${CMAKE_INSTALL_PREFIX} NO_DEFAULT_PATH)
        endif()
        # try out our runtime path
        if (NOT TARGET ${lib})
            set(${lib}_DIR ${CMAKE_INSTALL_PREFIX}/lib/cmake/${lib})
            find_package(${lib} QUIET PATHS ${CMAKE_INSTALL_PREFIX} NO_DEFAULT_PATH)
            unset(${lib}_DIR)
        endif()
        if (NOT TARGET ${lib})
            set(${lib}_DIR ${CMAKE_INSTALL_PREFIX}/lib64/cmake/${lib})
            find_package(${lib} QUIET PATHS ${CMAKE_INSTALL_PREFIX} NO_DEFAULT_PATH)
            unset(${lib}_DIR)
        endif()

        # if lib is with namespace or components
        if (NOT TARGET ${lib})
            string(REPLACE "::" ";" split ${lib})
            list(LENGTH split len)

            if (len EQUAL 2)
                list(GET split 0 lname)
                list(GET split 1 lcomp)
                find_package(${lname} QUIET COMPONENTS ${lcomp} PATHS ${CMAKE_INSTALL_PREFIX}/lib/ ${CMAKE_INSTALL_PREFIX}/lib64/)
                if (NOT ${lname}${lcomp}_FOUND)
                    find_package(${lname} QUIET PATHS ${CMAKE_INSTALL_PREFIX}/lib/cmake ${CMAKE_INSTALL_PREFIX}lib64/cmake)
                endif()
            endif()
        endif()

        # try out standart search
        if (NOT TARGET ${lib})
            find_package(${lib} QUIET)
        endif()

        # Bad, very bad... try out as package
        if (NOT TARGET ${lib})
            string(FIND ${lib} "::" isnamespace)
            if (isnamespace EQUAL -1)
                resolve_pkg(${lib})
            endif()
        endif()

        # What the hell, try resolve as lib and create target manualy
        if (NOT TARGET ${lib})
            string(FIND ${lib} "::" isnamespace)
            if (isnamespace EQUAL -1)
                resolve_lib(${lib})
            endif()
        endif()
        if (NOT TARGET ${lib} AND ENABLE_STANDALONE)
            string(REPLACE "::" "-" libPath ${lib})
            if (EXISTS ${RAVEN_CMAKE_CMAKE_DIR}/external/${libPath})
                include(${RAVEN_CMAKE_CMAKE_DIR}/external/${libPath}/build.cmake)
            elseif (EXISTS ${RAVEN_CMAKE_CMAKE_DIR}/external/${libPath}.cmake)
                include(${RAVEN_CMAKE_CMAKE_DIR}/external/${libPath}.cmake)
            else()
                string(REPLACE "::" ";" split ${lib})
                list(LENGTH split len)

                if (len EQUAL 2)
                    list(GET split 0 lname)
                    list(GET split 1 lcomp)
                    if (EXISTS ${RAVEN_CMAKE_CMAKE_DIR}/external/${lname})
                        include(${RAVEN_CMAKE_CMAKE_DIR}/external/${lname}/build.cmake)
                    endif()
                endif()
            endif()
        endif()

        # Give up here... this package is tricky to find
        if (NOT TARGET ${lib} AND NOT ${arg_NOFATAL})
            message(FATAL_ERROR "${lib} not found")
        endif()

        if (TARGET ${lib})
            if("${lib}" STREQUAL "Catch2::Catch2")
                get_target_property(libType ${lib} TYPE)
                get_target_property(out ${lib} INTERFACE_INCLUDE_DIRECTORIES)
                list(GET out 0 path)
                if (EXISTS ${path}/../lib/cmake/Catch2/ParseAndAddCatchTests.cmake)
                    include(${path}/../lib/cmake/Catch2/ParseAndAddCatchTests.cmake)
                elseif(EXISTS ${RAVEN_CMAKE_CMAKE_DIR}/external/${libPath}/ParseAndAddCatchTests.cmake)
                    include(${RAVEN_CMAKE_CMAKE_DIR}/external/${libPath}/ParseAndAddCatchTests.cmake)
                endif()
            endif()
        endif()

        if (TARGET ${lib})
            get_target_property(deps ${lib} INTERFACE_LINK_LIBRARIES)
            if (deps)
                foreach(dep ${deps})
                    string(FIND ${dep} "-" pos)
                    if (NOT IS_ABSOLUTE ${dep} AND NOT ${pos} EQUAL 0)
                        resolve(${dep} NOFATAL)
                    endif()
                endforeach()
            endif()
        endif()
    endif()
endmacro()

##############################################################################################################

macro(resolve_libs libs)
    foreach(lib ${${libs}})
        resolve(${lib})
    endforeach()
endmacro()

##############################################################################################################
