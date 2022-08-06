##############################################################################################################

macro(create_target name type output)
    cmake_parse_arguments(arg
        ""
        "OUTPUT;PUBLIC_INCLUDE_DIR"
        "SOURCES;PUBLIC;CMAKE;CONFIGS;DATA;SYSTEMD"
        ${ARGN}
    )

    resolveFiles(arg_SOURCES)
    resolveFiles(arg_PUBLIC BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/${arg_PUBLIC_INCLUDE_DIR})
    resolveFiles(arg_CONFIGS)
    resolveFiles(arg_CMAKE)
    resolveFiles(arg_DATA)
    resolveFiles(arg_SYSTEMD)

    set(all
        ${arg_SOURCES}
        ${arg_PUBLIC}
        ${arg_CMAKE}
        ${arg_CONFIGS}
        ${arg_DATA}
        ${arg_SYSTEMD}
    )

    if ("${type}" STREQUAL "exe")
        # Setup executable target
        add_executable(${name}
            ${all}
        )
        if (arg_OUTPUT)
            set_property(TARGET ${name} PROPERTY RUNTIME_OUTPUT_DIRECTORY ${arg_OUTPUT}/bin)
        endif()
    elseif("${type}" STREQUAL "static")
        # Setup static library target
        add_library(${name} STATIC
            ${all}
        )
        set_property(TARGET ${name} PROPERTY POSITION_INDEPENDENT_CODE TRUE)
        if (arg_OUTPUT)
            set_property(TARGET ${name} PROPERTY ARCHIVE_OUTPUT_DIRECTORY ${arg_OUTPUT}/lib)
        endif()
    elseif("${type}" STREQUAL "shared")
        # Setup shared library target
        add_library(${name} SHARED
            ${all}
        )
        if (arg_OUTPUT)
            set_property(TARGET ${name} PROPERTY LIBRARY_OUTPUT_DIRECTORY ${arg_OUTPUT}/lib)
        endif()
    elseif("${type}" STREQUAL "interface")
        # Setup source library target
        add_library(${name} INTERFACE)
        add_custom_target(${name}-props
            SOURCES ${all}
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
    foreach(file ${files})
        get_filename_component(dir ${file} DIRECTORY)
        string(HEX ${file} name)
        get_filename_component(dir ${file} DIRECTORY)
        add_custom_target(copy${name} ALL
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${file}
            BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/${file}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/${dir}
            COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/${file} ${CMAKE_CURRENT_BINARY_DIR}/${file}
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

function(setup_includes name includes include_dir)
    get_target_property(type ${name} TYPE)

    target_include_directories(${name} INTERFACE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${include_dir}>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/>
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/>
        $<INSTALL_INTERFACE:include/>
    )

    if (NOT "${type}" STREQUAL "INTERFACE_LIBRARY")
        target_include_directories(${name} PRIVATE
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${include_dir}>
        )
    endif()

    if (NOT "${${includes}}" STREQUAL "")
        raven_set_custom_property(${name} PRIVATE_INCLUDE ${${includes}})
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
        message(STATUS "Target ${name} ${type} -> ${CMAKE_INSTALL_PREFIX}/[${CMAKE_INSTALL_INCLUDEDIR}, ${CMAKE_INSTALL_DATADIR}/cmake/${name}]")
    else()
        raven_get_custom_property(priv ${name} PRIVATE)
        if (priv)
            message(STATUS "Target '${name}' is ${type} (this target will not be installed)")
        else()
            raven_get_custom_property(out ${name} INSTALL_DIR)
            if (NOT out)
                if ("${type}" STREQUAL "EXECUTABLE")
                    get_target_property(out ${name} RUNTIME_OUTPUT_DIRECTORY)
                elseif ("${type}" STREQUAL "STATIC_LIBRARY")
                    get_target_property(out ${name} ARCHIVE_OUTPUT_DIRECTORY)
                else()
                    get_target_property(out ${name} LIBRARY_OUTPUT_DIRECTORY)
                endif()
            endif()
            if (NOT out)
                if ("${type}" STREQUAL "EXECUTABLE")
                    set(out ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR})
                else()
                    set(out ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
                endif()
            endif()
            message(STATUS "Target '${name}' is ${type} -> ${out}")
        endif()

        get_target_property(links ${name} LINK_LIBRARIES)
        if (links)
            message(STATUS "    Dependencies:")
            max_length(max "${links}")
            foreach(lib ${links})
                set(out)
                if (NOT TARGET ${lib})
                    resolve(${lib})
                endif()
                get_target_property(libType ${lib} TYPE)
                if ("${libType}" STREQUAL "SHARED_LIBRARY" OR "${libType}" STREQUAL "STATIC_LIBRARY" OR "${libType}" STREQUAL "UNKNOWN_LIBRARY")
                    get_target_property(out ${lib} IMPORTED_LOCATION)
                    if (CMAKE_BUILD_TYPE AND NOT out)
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
        list(REMOVE_DUPLICATES flags)
        message(STATUS "    Compile flags:")
        string(REPLACE ";" " " strflags "${flags}")
        message(STATUS "        ${strflags}")
    endif()
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
