set(RAVEN_POPULATED_PROPS
    INSTALL_DIR
    CMAKE_DIR
    CONFIG_DIR
    HEADERS_DIR
    DATA_DIR
    CMAKE_EXPORT_FILE
    CMAKE_CONFIG_FILE
    CMAKE_VERSION_FILE
    CMAKE_PKG_FILE
)

function(raven_configure_file filename)
    cmake_parse_arguments(arg
        ""
        "TARGET;DESTINATION"
        ""
        ${ARGN}
    )

    set(targetProps
        NAME
        TYPE
    )

    get_filename_component(ext ${filename} EXT)
    get_filename_component(base ${filename} NAME_WE)
    get_filename_component(path ${filename} DIRECTORY)
    string(REPLACE "." ";" ext ${ext})
    list(GET ext -1 last)

    if (last STREQUAL "in")
        list(REMOVE_AT ext -1)
        list(JOIN ext "." ext)

        if (arg_TARGET)
            foreach(prop ${targetProps})
                get_target_property(val ${arg_TARGET} ${prop})
                set(${prop} "${val}")
            endforeach()

            foreach(prop ${RAVEN_POPULATED_PROPS})
                raven_get_custom_property(val ${arg_TARGET} ${prop})
                set(${prop} "${val}")
            endforeach()
        endif()
        configure_file(${filename} ${CMAKE_CURRENT_BINARY_DIR}/${path}/${base}${ext})
    endif()
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${path}/${base}${ext} DESTINATION ${arg_DESTINATION})
endfunction()

function(raven_get_custom_property var target name)
    get_target_property(type ${target} TYPE)
    if(type STREQUAL "INTERFACE_LIBRARY")
        get_target_property(_var ${target} INTERFACE_${name})
        set(${var} ${_var} PARENT_SCOPE)
    else()
        get_target_property(_var ${target} TARGET_${name})
        set(${var} ${_var} PARENT_SCOPE)
    endif()
endfunction()

function(raven_set_custom_property target name value)
    get_target_property(type ${target} TYPE)
    if(type STREQUAL "INTERFACE_LIBRARY")
        set_target_properties(${target} PROPERTIES INTERFACE_${name} "${value}")
    else()
        set_target_properties(${target} PROPERTIES TARGET_${name} "${value}")
    endif()
endfunction()
