find_package(PkgConfig REQUIRED)

##############################################################################################################

function(compiler_search_dirs)
    execute_process(
        COMMAND ${CMAKE_CXX_COMPILER} -print-search-dirs
        OUTPUT_VARIABLE out
    )
    string(REGEX REPLACE "^.*libraries: =(.*)$" "\\1" libs ${out})
    string(REPLACE ":" ";" libs ${libs})
    set(COMPILER_PATHS ${libs} PARENT_SCOPE)
endfunction()

##############################################################################################################

macro(resolve_pkg lib)
    pkg_check_modules(${lib}_prefix REUIRED QUIET IMPORTED_TARGET ${lib})
    if (${lib}_prefix_FOUND)
        add_library(${lib} INTERFACE)
        target_link_libraries(${lib} INTERFACE PkgConfig::${lib}_prefix)
    endif()
endmacro()

##############################################################################################################

macro(resolve_lib lib)
    if (NOT ${COMPILER_PATHS})
        compiler_search_dirs()
    endif()

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
endmacro()

##############################################################################################################

macro(resolve lib)
    # try out our runtime path
    if (NOT TARGET ${lib})
        set(${lib}_DIR ${RUNTIME_PREFIX}/lib/cmake/${lib})
        find_package(${lib} QUIET PATHS ${RUNTIME_PREFIX} NO_DEFAULT_PATH)
        unset(${lib}_DIR)
    endif()
    if (NOT TARGET ${lib})
        set(${lib}_DIR ${RUNTIME_PREFIX}/lib64/cmake/${lib})
        find_package(${lib} QUIET PATHS ${RUNTIME_PREFIX} NO_DEFAULT_PATH)
        unset(${lib}_DIR)
    endif()

    # if lib is with namespace or components
    if (NOT TARGET ${lib})
        string(REPLACE "::" ";" split ${lib})
        list(LENGTH split len)

        if (len EQUAL 2)
            list(GET split 0 lname)
            list(GET split 1 lcomp)
            find_package(${lname} QUIET COMPONENTS ${lcomp} PATHS ${RUNTIME_PREFIX}/lib/ ${RUNTIME_PREFIX}/lib64/)
            if (NOT ${lname}${lcomp}_FOUND)
                find_package(${lname} QUIET PATHS ${RUNTIME_PREFIX}/lib/cmake ${RUNTIME_PREFIX}/lib64/cmake)
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
        if (NOT isnamespace EQUAL -1)
            resolve_pkg(${lib})
        endif()
    endif()

    # What the hell, try resolve as lib and create target manualy
    if (NOT TARGET ${lib})
        resolve_lib(${lib})
    endif()

    # Give up here... this package is tricky to find
    if (NOT TARGET ${lib})
        message(FATAL_ERROR "${lib} not found")
    endif()
endmacro()

##############################################################################################################

macro(resolve_libs libs)
    foreach(lib ${${libs}})
        resolve(${lib})
    endforeach()
endmacro()

##############################################################################################################
