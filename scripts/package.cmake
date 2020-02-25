include(${CMAKE_CURRENT_LIST_DIR}/pack/target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/pack/defaults.cmake)

##############################################################################################################

macro(${CMAKE_PRODUCT_PREFIX}_define_component component)
    cmake_parse_arguments(args
        "SHLIBDEPS"
        "NAME;PREINST;POSTINST;PRERM;POSTRM"
        "TARGETS;DEPENDS;REPLACES;PROVIDES;BREAKS;CONFLICTS;TEMPLATES;CONFFILES;ON_CONFIGURE"
        ${ARGN}
    )

    if(NOT args_NAME)
        message(FATAL_ERROR "No package name was specified")
    endif()

    prepare_targets(${args_NAME} ${component} args_TARGETS)

    # prepare input for shlibs
    if(args_SHLIBDEPS)
        set(shlibs_cnt)
        foreach(target ${args_TARGETS})
            if(PROJECT_PREFIX)
                set(target "${NORM_PROJECT_PREFIX}-${target}")
            endif()
            set(shlibsCnt "${shlibsCnt}lib${target} ${PROJECT_VERSION_MAJOR} ${args_NAME} (>=${PROJECT_VERSION})\n")
        endforeach()
        message("?????${CMAKE_CURRENT_BINARY_DIR}/${component}/shlibs")
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${component}/shlibs" ${shlibsCnt})
    endif()

    set(ravenComponent "raven_component_${component}")
    add_custom_target(${ravenComponent} GLOBAL)

    set_target_properties(${ravenComponent} PROPERTIES
        "PKG_NAME"          "${args_NAME}"
        "PKG_COMPONENT"     "${component}"
        "PKG_DEPENDS"       "${args_DEPENDS}"
        "PKG_PKGCONFIG"     "${args_PKGCONFIG}"
        "PKG_REPLACES"      "${args_REPLACES}"
        "PKG_PROVIDES"      "${args_PROVIDES}"
        "PKG_BREAKS"        "${args_BREAKS}"
        "PKG_CONFLICTS"     "${args_CONFLICTS}"
        "PKG_PREINST"       "${args_PREINST}"
        "PKG_POSTINST"      "${args_POSTINST}"
        "PKG_PRERM"         "${args_PRERM}"
        "PKG_POSTRM"        "${args_POSTRM}"
        "PKG_TEMPLATES"     "${args_TEMPLATES}"
        "PKG_CONFFILES"     "${args_CONFFILES}"
        "PKG_SHLIBDEPS"     "${args_SHLIBDEPS}"
        "PKG_LDPATHES"      "${ldpathes}"
        "PKG_ON_CONFIGURE"  "${args_ON_CONFIGURE}"
    )
endmacro()

##############################################################################################################

macro(${CMAKE_PRODUCT_PREFIX}_pack)
    cmake_parse_arguments(args
        ""
        "CONTACT;GENERATOR;LD_LIBRARY_PATH"
        "COMPONENTS;DESCRIPTION"
        ${ARGN}
    )

    if (NOT args_COMPONENTS)
        message(FATAL_ERROR "No components were specified")
    endif()

    if(NOT args_DESCRIPTION)
        message(FATAL_ERROR "Description is not set")
    endif()

    if(NOT args_CONTACT)
        message(FATAL_ERROR "Contact is not set")
    endif()

    if(args_GENERATOR)
        set(CPACK_GENERATOR ${args_GENERATOR})
    endif()

    if(NOT CPACK_GENERATOR)
        set(CPACK_GENERATOR "DEB")
    endif()

    set(_CPACK_GENERATOR ${CPACK_GENERATOR})

    set(LD_LIBRARY_PATH)
    if(args_LD_LIBRARY_PATH)
        set(LD_LIBRARY_PATH ${args_LD_LIBRARY_PATH})
    endif()

    foreach(comp ${args_COMPONENTS})
        get_target_property(pkgname   "raven_component_${comp}" "PKG_NAME")
        get_target_property(default   "raven_component_${comp}" "PKG_DEFAULT")
        get_target_property(pkgconf   "raven_component_${comp}" "PKG_PKGCONFIG")
        get_target_property(shlibdeps "raven_component_${comp}" "PKG_SHLIBDEPS")
        get_target_property(ldpath    "raven_component_${comp}" "PKG_LDPATHES")

        set(FULL_PROJECT_VERSION ${PROJECT_VERSION})
        if(VERSION_EXTRA)
            set(FULL_PROJECT_VERSION ${PROJECT_VERSION}-${VERSION_EXTRA})
        endif()

        if(${comp} MATCHES "^.*[\\-]?dev$")
            set(isDev true)
        endif()

        if(isDev)
            set(CPACK_PACKAGE_FILE_NAME "${pkgname}_${FULL_PROJECT_VERSION}")
            message(STATUS "Configure devel (${comp}) version of the package ${CPACK_PACKAGE_FILE_NAME}")
        else()
            set(CPACK_PACKAGE_FILE_NAME "${pkgname}_${FULL_PROJECT_VERSION}_${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}")
            message(STATUS "Configure runtime (${comp}) version of the package ${CPACK_PACKAGE_FILE_NAME}")
        endif()

        set_default(${comp})

        set(description ${args_DESCRIPTION})

        if (EXISTS "${RAVEN_CMAKE_DIR}/scripts/templates/component.cmake.in")
            set(componentin "${RAVEN_CMAKE_DIR}/scripts/templates/component.cmake.in")
        else()
            set(componentin "${CMAKE_CURRENT_LIST_DIR}/scripts/templates/component.cmake.in")
        endif()

        if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${comp}/shlibs")
            list(APPEND CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${CMAKE_CURRENT_BINARY_DIR}/${comp}/shlibs")
        endif()

        configure_file(${componentin} "${CMAKE_CURRENT_BINARY_DIR}/${comp}.cmake" @ONLY)

    endforeach()

endmacro()

##############################################################################################################

macro(prepare_description component)
    list(GET args_DESCRIPTION 0 summary_description)
    string(REPLACE ";" "\n" description "${args_DESCRIPTION}")

    message("+++${CPACK_PACKAGE_DESCRIPTION_FILE}")
    if(CPACK_PACKAGE_DESCRIPTION_FILE)
        install(FILES
            ${CPACK_PACKAGE_DESCRIPTION_FILE}
            DESTINATION ${DOCS_INSTALL_DIR}/${pkgname}
            COMPONENT "${component}"
        )
    endif()
endmacro()
