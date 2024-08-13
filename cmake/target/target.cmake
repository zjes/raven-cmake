##############################################################################################################

macro(create_target name)
    set(options
        EXE
        STATIC
        SHARED
        INTERFACE
    )
    set(singleArg
        OUTPUT_PATH
    )
    set(multiArgs
        PUBLIC
        SOURCES
        CMAKE
        DATA
        USES_PRIVATE
        USES_PUBLIC
    )
    cmake_parse_arguments(arg options singeArgs multiArgs ${ARGN})

    resolveFiles(arg_SOURCES)
    resolveFiles(arg_CMAKE)
    resolveFiles(arg_DATA)

    set(all
        ${arg_SOURCES}
        ${arg_PUBLIC}
        ${arg_CMAKE}
        ${arg_DATA}
    )

    if (NOT ${arg_INTERFACE})
        message("++++ interface")
    endif()

    if ("${type}" STREQUAL "exe")
        # Setup executable target
        add_executable(${name}
            ${all}
        )
        if (arg_OUTPUT)
            set_property(TARGET ${name} PROPERTY RUNTIME_OUTPUT_DIRECTORY ${arg_OUTPUT})
        endif()
    elseif("${type}" STREQUAL "static")
        # Setup static library target
        add_library(${name} STATIC
            ${all}
        )
        set_property(TARGET ${name} PROPERTY POSITION_INDEPENDENT_CODE TRUE)
        if (arg_OUTPUT)
            set_property(TARGET ${name} PROPERTY ARCHIVE_OUTPUT_DIRECTORY ${arg_OUTPUT})
        endif()
    elseif("${type}" STREQUAL "shared")
        # Setup shared library target
        add_library(${name} SHARED
            ${all}
        )
        if (arg_OUTPUT)
            set_property(TARGET ${name} PROPERTY LIBRARY_OUTPUT_DIRECTORY ${arg_OUTPUT})
        endif()
    elseif("${type}" STREQUAL "interface")
        # Setup source library target
        add_library(${name} INTERFACE)
        add_custom_target(${name}-props
            SOURCES ${all}
        )
        set_target_properties(${name}-props PROPERTIES INTERFACE_COMPILE_FEATURES -std=c++23)
        if(arg_SOURCES)
            set_target_properties(${name} PROPERTIES
                INTERFACE_HEADERS "${arg_SOURCES}"
            )
        endif()
    else()
        message(FATAL_ERROR "Unknown target type ${type}")
    endif()

    # Add public cmake scripts
    if (arg_CMAKE)
        raven_set_custom_property(${name} CMAKE "${arg_CMAKE}")
    endif()

    # Add public headers as public
    if (arg_PUBLIC_INCLUDE_DIR)
        raven_set_custom_property(${name} INCLUDE_DIR "${arg_PUBLIC_INCLUDE_DIR}")
    else()
        raven_set_custom_property(${name} INCLUDE_DIR "")
    endif()

    if (arg_PUBLIC)
        raven_set_custom_property(${name} HEADERS "${arg_PUBLIC}")
    endif()

    # Add target data
    if (arg_DATA)
        copy_files(${name} "${arg_DATA}")
        raven_set_custom_property(${name} DATA "${arg_DATA}")
    endif()

    # Add configs to install
    if (arg_CONFIGS)
        copy_files(${name} "${arg_CONFIGS}")
        raven_set_custom_property(${name} CONFIGS "${arg_CONFIGS}")
    endif()

    # Add systemd servive files to install
    if (arg_SYSTEMD)
        copy_files(${name} "${arg_SYSTEMD}")
        raven_set_custom_property(${name} SYSTEMD "${arg_SYSTEMD}")
    endif()

    if (NOT "${type}" STREQUAL "interface")
        set_target_properties(${name} PROPERTIES LINKER_LANGUAGE CXX)
    endif()

    if(NOT "${type}" STREQUAL "interface")
        target_link_options(${name} PRIVATE -z defs)
        target_link_options(${name} PRIVATE "-Wl,--disable-new-dtags")
    endif()
endmacro()

##############################################################################################################

function(copy_files target files)
    get_target_property(type ${target} TYPE)
    if ("${type}" STREQUAL "EXECUTABLE")
        get_target_property(out ${name} RUNTIME_OUTPUT_DIRECTORY)
    elseif ("${type}" STREQUAL "STATIC_LIBRARY")
        get_target_property(out ${name} ARCHIVE_OUTPUT_DIRECTORY)
    else()
        get_target_property(out ${name} LIBRARY_OUTPUT_DIRECTORY)
    endif()

    if (NOT out)
        set(out ${CMAKE_CURRENT_BINARY_DIR})
    endif()

    foreach(file ${files})
        get_filename_component(dir ${file} DIRECTORY)
        string(HEX ${file} name)
        get_filename_component(dir ${file} DIRECTORY)
        add_custom_target(copy${name} ALL
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${file}
            BYPRODUCTS ${out}/${file}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${out}/${dir}
            COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/${file} ${out}/${file}
            COMMENT "Copy file ${file}"
        )
    endforeach()
endfunction()

##############################################################################################################

function(copy_filesA target)
    foreach(fileOrMask ${ARGN})
        resolveFiles(fileOrMask)
        foreach(file ${fileOrMask})
            get_filename_component(dir ${file} DIRECTORY)
            add_custom_command(
                OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${file}
                MAIN_DEPENDENCY ${CMAKE_CURRENT_SOURCE_DIR}/${file}
                DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${file}
                COMMAND echo "copy"
                VERBATIM
            )
        endforeach()
    endforeach()
endfunction()

##############################################################################################################

function(set_includes name includes)
    get_target_property(type ${name} TYPE)

    target_include_directories(${name} INTERFACE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/>
        $<INSTALL_INTERFACE:include/>
    )

    if(NOT "${type}" STREQUAL "INTERFACE_LIBRARY")
        target_include_directories(${name} PRIVATE
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/>
            $<INSTALL_INTERFACE:include/>
        )
    endif()

    if (NOT "${includes}" STREQUAL "")
        raven_set_custom_property(${name} PRIVATE_INCLUDE ${includes})
        target_include_directories(${name} PRIVATE
            ${includes}
        )
    endif()
endfunction()

##############################################################################################################
function(pad_string out length value)
    string(LENGTH "${value}" val_length)
    math(EXPR pads "${length} - ${val_length}")
    set(_out ${value})
    if(pads GREATER 0)
        foreach(pad RANGE 1 ${pads})
            set(_out "${_out} ")
        endforeach()
    endif()
    set(${out} "${_out}" PARENT_SCOPE)
endfunction()

function(max_length max links)
    set(_max 0)
    foreach(it ${links})
        string(LENGTH "${it}" length)
        if (length GREATER _max)
            set(_max ${length})
        endif()
    endforeach()
    set(${max} "${_max} " PARENT_SCOPE)
endfunction()


function(resolveFiles list)
    cmake_parse_arguments(arg
        ""
        "BASE_DIR"
        ""
        ${ARGN}
    )

    if(NOT arg_BASE_DIR)
        set(arg_BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    if (NOT "${${list}}" STREQUAL "")
        set(rfiles)
        foreach(mask ${${list}})
            if (NOT IS_ABSOLUTE ${mask})
                set(mask ${arg_BASE_DIR}/${mask})
            endif()
            file(GLOB_RECURSE files ${mask})
            # message( "  ${mask} >>>> ${files}")
            foreach(file ${files})
                file(RELATIVE_PATH file ${CMAKE_CURRENT_SOURCE_DIR} ${file})
                list(APPEND rfiles ${file})
            endforeach()
        endforeach()
        set(${list} ${rfiles} PARENT_SCOPE)
    endif()
endfunction()
