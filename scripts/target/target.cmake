##############################################################################################################

macro(create_target name type output)
    cmake_parse_arguments(arg
        ""
        "OUTPUT"
        "SOURCES;PUBLIC;CMAKE;CONFIGS"
        ${ARGN}
    )

    if (NOT arg_OUTPUT)
        set(arg_OUTPUT ${RUNTIME_PREFIX})
    endif()

    resolveFiles(arg_SOURCES)
    resolveFiles(arg_PUBLIC)
    resolveFiles(arg_CONFIGS)
    resolveFiles(arg_CMAKE)

    if ("${type}" STREQUAL "exe")
        # Setup executable target
        add_executable(${name}
            ${arg_SOURCES}
            ${arg_PUBLIC}
            ${arg_CMAKE}
            ${arg_CONFIGS}
        )
        set_property(TARGET ${name} PROPERTY RUNTIME_OUTPUT_DIRECTORY ${arg_OUTPUT}/bin)
    elseif("${type}" STREQUAL "static")
        # Setup static library target
        add_library(${name} STATIC
            ${arg_SOURCES}
            ${arg_PUBLIC}
            ${arg_CMAKE}
            ${arg_FILES}
            ${arg_CONFIGS}
        )
        set_property(TARGET ${name} PROPERTY ARCHIVE_OUTPUT_DIRECTORY ${arg_OUTPUT}/lib)
    elseif("${type}" STREQUAL "shared")
        # Setup shared library target
        add_library(${name} SHARED
            ${arg_SOURCES}
            ${arg_PUBLIC}
            ${arg_CMAKE}
            ${arg_CONFIGS}
        )
        set_property(TARGET ${name} PROPERTY LIBRARY_OUTPUT_DIRECTORY ${arg_OUTPUT}/lib)
    elseif("${type}" STREQUAL "interface")
        # Setup source library target
        add_library(${name} INTERFACE)
        add_custom_target(${name}-props
            SOURCES ${arg_SOURCES}
                    ${arg_PUBLIC}
                    ${arg_CMAKE}
                    ${arg_CONFIGS}
        )
        set_target_properties(${name}-props PROPERTIES INTERFACE_COMPILE_FEATURES -std=c++17)
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
        if ("${type}" STREQUAL "interface")
            set_target_properties(${name} PROPERTIES
                INTERFACE_CMAKE "${arg_CMAKE}"
            )
        else()
            set_target_properties(${name} PROPERTIES
                PUBLIC_CMAKE "${arg_CMAKE}"
            )
        endif()
    endif()

    # Add public headers as public
    if (arg_PUBLIC)
        if ("${type}" STREQUAL "interface")
            set_target_properties(${name} PROPERTIES
                INTERFACE_HEADERS "${arg_PUBLIC}"
            )
        else()
            set_target_properties(${name} PROPERTIES
                PUBLIC_HEADERS "${arg_PUBLIC}"
            )
        endif()
    endif()

    # Add configs to install
    if (arg_CONFIGS)
        foreach(file ${arg_CONFIGS})
            get_filename_component(dir ${file} DIRECTORY)
            add_custom_command(
                TARGET ${name}
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${arg_OUTPUT}/bin/${dir}
                COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/${file} ${arg_OUTPUT}/bin/${file}
            )
        endforeach()
        if ("${type}" STREQUAL "interface")
            set_target_properties(${name} PROPERTIES
                INTERFACE_CONFIGS "${arg_CONFIGS}"
            )
        else()
            set_target_properties(${name} PROPERTIES
                PUBLIC_CONFIGS "${arg_CONFIGS}"
            )
        endif()
    endif()

    if (NOT "${type}" STREQUAL "interface")
        set_target_properties(${name} PROPERTIES LINKER_LANGUAGE CXX)
    endif()
endmacro()

##############################################################################################################

function(setup_includes name includes)
    get_target_property(type ${name} TYPE)

    target_include_directories(${name} INTERFACE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/>
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/>
        $<INSTALL_INTERFACE:include/${name}>
    )

    if (NOT "${type}" STREQUAL "INTERFACE_LIBRARY")
        target_include_directories(${name} PRIVATE
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/>
        )
    endif()

    if (NOT "${${includes}}" STREQUAL "")
        target_include_directories(${name} PRIVATE
            ${${includes}}
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

function(dump_target name)
    message(STATUS "------------------------------------------------------------------------------")
    get_target_property(type ${name} TYPE)
    if ("${type}" STREQUAL "INTERFACE_LIBRARY")
        message(STATUS "Target ${name} ${type}")
    else()
        if ("${type}" STREQUAL "EXECUTABLE")
            get_target_property(out ${name} RUNTIME_OUTPUT_DIRECTORY)
        elseif ("${type}" STREQUAL "STATIC_LIBRARY")
            get_target_property(out ${name} ARCHIVE_OUTPUT_DIRECTORY)
        else()
            get_target_property(out ${name} LIBRARY_OUTPUT_DIRECTORY)
        endif()
        message(STATUS "Target ${name} ${type} -> ${out}")

        get_target_property(links ${name} LINK_LIBRARIES)
        if (links)
            message(STATUS "    Dependencis:")
            max_length(max "${links}")
            foreach(lib ${links})
                if (NOT TARGET ${lib})
                    resolve(${lib})
                endif()
                get_target_property(libType ${lib} TYPE)
                if ("${libType}" STREQUAL "SHARED_LIBRARY" OR "${libType}" STREQUAL "STATIC_LIBRARY")
                    get_target_property(out ${lib} IMPORTED_LOCATION)
                    if (NOT out)
                        string(TOUPPER ${CMAKE_BUILD_TYPE} up_type)
                        get_target_property(out ${lib} IMPORTED_LOCATION_${up_type})
                    endif()
                    if (NOT out)
                        get_target_property(conf ${lib} IMPORTED_CONFIGURATIONS)
                        if (conf)
                            get_target_property(out ${lib} IMPORTED_LOCATION_${conf})
                        endif()
                    endif()
                endif()
                if ("${libType}" STREQUAL "INTERFACE_LIBRARY")
                    get_target_property(out ${lib} INTERFACE_INCLUDE_DIRECTORIES)
                    if (NOT out)
                        get_target_property(out ${lib} INTERFACE_LINK_LIBRARIES)
                        if (out)
                            set(libs)
                            foreach(l ${out})
                                if (TARGET ${l})
                                    get_target_property(out ${l} INTERFACE_LINK_LIBRARIES)
                                    list(APPEND libs ${out})
                                endif()
                            endforeach()
                            set(out, "${libs}")
                        endif()
                    endif()
                endif()

                if (NOT out)
                    set(out "Own project, not found yet")
                endif()

                pad_string(str ${max} ${lib})
                message(STATUS "        ${str} : ${out}")
            endforeach()
        endif()

        get_target_property(flags ${name} COMPILE_OPTIONS)
        message(STATUS "    Compile flags:")
        string(REPLACE ";" " " strflags "${flags}")
        message(STATUS "        ${strflags}")
    endif()
endfunction()

function(resolveFiles list)
    if (NOT "${${list}}" STREQUAL "")
        set(rfiles)
        foreach(mask ${${list}})
            file(GLOB_RECURSE files ${mask})
            foreach(file ${files})
                file(RELATIVE_PATH file ${CMAKE_CURRENT_SOURCE_DIR} ${file})
                list(APPEND rfiles ${file})
            endforeach()
        endforeach()
        set(${list} ${rfiles} PARENT_SCOPE)
    endif()
endfunction()
