include(${CMAKE_CURRENT_LIST_DIR}/config.cmake)

include(${CMAKE_CURRENT_LIST_DIR}/target/target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/export.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/version.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/uses.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/target/flags.cmake)

##############################################################################################################

macro(disable_${CMAKE_PRODUCT_PREFIX}_target Type Name)
endmacro()

##############################################################################################################

macro(${CMAKE_PRODUCT_PREFIX}_target type name)
    cmake_parse_arguments(args
        ""
        "OUTPUT"
        "SOURCES;USES;INCLUDE_DIRS;PUBLIC;PREPROCESSOR;FLAGS;CMAKE;CONFIGS;USES_PUBLIC"
        ${ARGN}
    )

    if (NOT args_OUTPUT)
        set(args_OUTPUT ${RUNTIME_PREFIX})
    endif()

    create_target(${name} ${type} OUTPUT ${args_OUTPUT} SOURCES ${args_SOURCES} PUBLIC ${args_PUBLIC} CMAKE ${args_CMAKE} CONFIGS ${args_CONFIGS})
    setup_includes(${name} args_INCLUDE_DIRS)
    setup_version(${name})
    parse_using(${name} args_USES args_USES_PUBLIC)
    set_cppflags(${name} args_FLAGS)
    qt_options(${name} args_QT_OPTIONS)
    preprocessor(${name} args_PREPROCESSOR)
    export_target(${name})

    dump_target(${name})
endmacro()

##############################################################################################################
