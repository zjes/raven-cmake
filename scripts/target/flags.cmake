##############################################################################################################

function(set_cppflags name flags)
    get_target_property(type ${name} TYPE)
    if (NOT "${type}" STREQUAL "INTERFACE_LIBRARY")
        target_compile_options(${name} PRIVATE -fPIC -Wall -Wextra -pedantic -Wnon-virtual-dtor -Werror
                                               -Wno-gnu-zero-variadic-macro-arguments
                                               -Wno-unused-command-line-argument)
    endif()

    if (${flags})
        target_compile_options(${name} PRIVATE ${${flags}})
    endif()
endfunction()

##############################################################################################################

function(qt_options name options)
    if (${options})
        find_package(Qt5 COMPONENTS Core)
        foreach(opt ${${options}})
            set_property(TARGET ${name} PROPERTY ${opt} ON)
        endforeach()
    endif()
endfunction()

##############################################################################################################

function(preprocessor name options)
    if (${options})
        target_compile_definitions(${name} PUBLIC ${${options}})
    endif()
endfunction()

##############################################################################################################
