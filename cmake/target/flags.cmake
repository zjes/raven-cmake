##############################################################################################################

function(set_cppflags name flags)
    get_target_property(type ${name} TYPE)
    if (NOT "${type}" STREQUAL "INTERFACE_LIBRARY")
        if (${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
            target_compile_options(${name} PRIVATE
                -Wall
                -Wextra # reasonable and standard
                -Wshadow # warn the user if a variable declaration shadows one from a parent context
                -Wnon-virtual-dtor # warn the user if a class with virtual functions has a non-virtual destructor. This helps catch hard to track down memory errors
                -Wold-style-cast # warn for c-style casts
                -Wcast-align # warn for potential performance problem casts
                -Wunused # warn on anything being unused
                -Woverloaded-virtual # warn if you overload (not override) a virtual function
                -Wpedantic # warn if non-standard C++ is used
                -Wconversion # warn on type conversions that may lose data
                -Wsign-conversion # warn on sign conversions
                -Wdouble-promotion # warn if float is implicit promoted to double
                -Wformat=2 # warn on security issues around functions that format output (ie printf)
                -Wno-redundant-move
                -Wno-unused-local-typedefs
            )
        elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
            target_compile_options(${name} PRIVATE
                -Wall
                -Wextra
                -Weverything
                -Wno-c++98-compat
                -Wno-c++98-compat-pedantic
                -Wno-padded
                #-Wno-exit-time-destructors
                #-Wno-weak-vtables
                #-Wno-gnu-zero-variadic-macro-arguments
                -Wno-unused-macros
                -Wno-global-constructors
                -Wno-unused-local-typedef
                -Wno-reserved-identifier
                -Wno-switch-default
                -Wno-unsafe-buffer-usage
                -Wno-unused-member-function
            )
        elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL "MSVC")
        endif()
        if (NOT "${flags}" STREQUAL "")
            target_compile_options(${name} PRIVATE ${flags})
            target_link_options(${name} PRIVATE ${flags})
            raven_set_custom_property(${name} FLAGS "${flags}")
        endif()
        if (${type} STREQUAL "SHARED_LIBRARY")
            target_link_options(${name} PRIVATE "-Wl, --no-undefined")
        endif()
    endif()
endfunction()

##############################################################################################################

function(set_preprocessor name options)
    if (NOT "${options}" STREQUAL "")
        target_compile_definitions(${name} PUBLIC ${options})
    endif()
endfunction()

##############################################################################################################
