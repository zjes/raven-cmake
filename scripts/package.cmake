include(${CMAKE_CURRENT_LIST_DIR}/pack/target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/pack/defaults.cmake)

##############################################################################################################

macro(${CMAKE_PRODUCT_PREFIX}_define_component component)
    cmake_parse_arguments(args
        "SHLIBDEPS"
        "PREINST;POSTINST;PRERM;POSTRM"
        "TARGETS;DEPENDS;REPLACES;PROVIDES;BREAKS;CONFLICTS;TEMPLATES;CONFFILES;ON_CONFIGURE;BUILD_DEPENDS"
        ${ARGN}
    )

    set(ravenComponent "raven_component_${component}")
    add_custom_target(${ravenComponent} GLOBAL)

    set_target_properties(${ravenComponent} PROPERTIES
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
        "PKG_ON_CONFIGURE"  "${args_ON_CONFIGURE}"
        "PKG_TARGETS"       "${args_TARGETS}"
        "PKG_BUILD_DEPENDS" "${args_BUILD_DEPENDS}"
    )

    foreach(target ${args_TARGETS})
        get_target_property(type ${target} TYPE)

        if ("${type}" STREQUAL "INTERFACE_LIBRARY")
            set_property(TARGET ${target} APPEND PROPERTY INTERFACE_COMPONENTS ${ravenComponent})
        else()
            set_property(TARGET ${target} APPEND PROPERTY COMPONENTS ${ravenComponent})
        endif()
    endforeach()
endmacro()

##############################################################################################################

macro(${CMAKE_PRODUCT_PREFIX}_pack)
    cmake_parse_arguments(args
        ""
        "PKG_NAME;CONTACT;GENERATOR;LD_LIBRARY_PATH"
        "COMPONENTS;DESCRIPTION"
        ${ARGN}
    )

    if(NOT args_PKG_NAME)
        message(FATAL_ERROR "No package name was specified")
    endif()

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

    set(CPACK_PACKAGE_CONTACT             ${args_CONTACT})
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${args_DESCRIPTION})
    set(PKG_NAME                          ${args_PKG_NAME})
    set(PKG_COMPONENTS)
    set(PKG_RUN_CPACK)
    set(PKG_CPACK_CONFIGS)

    foreach(comp ${args_COMPONENTS})
        set(ravenComponent "raven_component_${comp}")

        get_target_property(default   "${ravenComponent}" "PKG_DEFAULT")
        get_target_property(pkgconf   "${ravenComponent}" "PKG_PKGCONFIG")
        get_target_property(shlibdeps "${ravenComponent}" "PKG_SHLIBDEPS")
        get_target_property(ldpath    "${ravenComponent}" "PKG_LDPATHES")
        get_target_property(targets   "${ravenComponent}" "PKG_TARGETS")
        get_target_property(buildDep  "${ravenComponent}" "PKG_BUILD_DEPENDS")
        get_target_property(depends   "${ravenComponent}" "PKG_DEPENDS")

        set(FULL_PROJECT_VERSION ${PROJECT_VERSION})
        if(VERSION_EXTRA)
            set(FULL_PROJECT_VERSION ${PROJECT_VERSION}-${VERSION_EXTRA})
        endif()

        set(isDev FALSE)
        if(${comp} MATCHES "^.*[\\-]?dev$")
            set(isDev TRUE)
        endif()

        execute_process(
            COMMAND dpkg --print-architecture
            OUTPUT_VARIABLE CPACK_DEBIAN_PACKAGE_ARCHITECTURE
        )
        string(STRIP ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE} CPACK_DEBIAN_PACKAGE_ARCHITECTURE)

        if(isDev)
            set(CPACK_PACKAGE_FILE_NAME "${args_PKG_NAME}-dev")
            message(STATUS "Configure devel (${comp}) version of the package ${CPACK_PACKAGE_FILE_NAME}")
            set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "any")
        else()
            set(CPACK_PACKAGE_FILE_NAME "${args_PKG_NAME}-${FULL_PROJECT_VERSION}_${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}")
            message(STATUS "Configure runtime (${comp}) version of the package ${CPACK_PACKAGE_FILE_NAME}")
        endif()

        set_default(${comp})

        if(shlibdeps)
            set(shlibsCnt)
            foreach(target ${targets})
                foreach(target ${targets})
                    set(shlibsCnt "${shlibsCnt}lib${target} ${PROJECT_VERSION_MAJOR} ${args_PKG_NAME} (>=${PROJECT_VERSION})\n")
                endforeach()
                file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${ravenComponent}/shlibs" ${shlibsCnt})
                list(APPEND CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${CMAKE_CURRENT_BINARY_DIR}/${ravenComponent}/shlibs")
                file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/debian/shlibs" ${shlibsCnt})
            endforeach()
        endif()

        if (EXISTS "${RAVEN_CMAKE_DIR}/scripts/templates/component.cmake.in")
            set(templates "${RAVEN_CMAKE_DIR}/scripts/templates")
        else()
            set(templates "${CMAKE_CURRENT_LIST_DIR}/scripts/templates")
        endif()

        set(PKG_BUILD_DEPENDS           ${buildDep})
        set(PKG_DEPENDS                 ${depends})
        set(CPACK_DEB_COMPONENT_INSTALL ${ravenComponent})
        set(PKG_PACK_DIR                "${args_PKG_NAME}-${FULL_PROJECT_VERSION}")
        set(PKG_PACK_CONFIG_NAME        "${comp}.cmake")

        configure_file(${templates}/component.cmake.in "${CMAKE_CURRENT_BINARY_DIR}/${PKG_PACK_CONFIG_NAME}" @ONLY)
        configure_file(${templates}/component.py.in "${CMAKE_CURRENT_BINARY_DIR}/${comp}.py" @ONLY)
        configure_file(${templates}/component-cpack.py.in "${CMAKE_CURRENT_BINARY_DIR}/${comp}-cpack.py" @ONLY)

        list(APPEND PKG_CPACK_CONFIGS "cpack --config ${CMAKE_CURRENT_BINARY_DIR}/${PKG_PACK_CONFIG_NAME}")

        file(READ "${CMAKE_CURRENT_BINARY_DIR}/${comp}.py" pack)
        set(PKG_COMPONENTS "${PKG_COMPONENTS}\"\\n\"\n${pack}")

        file(READ "${CMAKE_CURRENT_BINARY_DIR}/${comp}-cpack.py" pack)
        set(PKG_RUN_CPACK "${PKG_RUN_CPACK}\n${pack}")
    endforeach()

    configure_file(${templates}/source-pack.py.in "${CMAKE_CURRENT_BINARY_DIR}/source-pack.py" @ONLY)
    add_custom_target("srcpack-${args_PKG_NAME}"
        COMMAND ${CMAKE_COMMAND} -E make_directory ${PKG_PACK_DIR}
        COMMAND python3 source-pack.py
        COMMAND cd ${PKG_PACK_DIR} && dpkg-buildpackage -S
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )

    string(REPLACE ";" " && " PKG_CPACK_CONFIGS "${PKG_CPACK_CONFIGS}")
    separate_arguments(PKG_CPACK_CONFIGS NATIVE_COMMAND ${PKG_CPACK_CONFIGS})
    add_custom_target("pack-${args_PKG_NAME}"
        COMMAND ${PKG_CPACK_CONFIGS}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

    install_component(args_COMPONENTS)
endmacro()

##############################################################################################################


macro(install_component comps)
    set(installTargets)
    foreach(comp ${${comps}})
        set(ravenComponent "raven_component_${comp}")
        get_target_property(targets ${ravenComponent} "PKG_TARGETS")
        list(APPEND installTargets ${targets})
    endforeach()
    list(REMOVE_DUPLICATES installTargets)

    foreach(target ${installTargets})
        get_target_property(type ${target} TYPE)

        if ("${type}" STREQUAL "INTERFACE_LIBRARY")
            get_target_property(targetComps ${target} INTERFACE_COMPONENTS)
        else()
            get_target_property(targetComps ${target} COMPONENTS)
        endif()

        foreach(cname ${targetComps})
            string(REGEX REPLACE "^.*\\-([^\\-]+)$" "\\1" name ${cname})
            set(${name} ${cname})
        endforeach()

        if (dev)
            get_target_property(confFile ${target} INTERFACE_CONF_FILE)
            get_target_property(verFile  ${target} INTERFACE_VERSION_FILE)
            get_target_property(pkgFile  ${target} INTERFACE_PKG_TEMPLATE)

            configure_file(${pkgFile} ${CMAKE_CURRENT_BINARY_DIR}/${target}.pc @ONLY)

            install(FILES
                ${confFile}
                ${verFile}
                DESTINATION ${CMAKE_INSTALL_DIR}/${target}
                COMPONENT ${dev}
            )

            install(FILES
                ${CMAKE_CURRENT_BINARY_DIR}/${target}.pc
                DESTINATION ${LIB_INSTALL_DIR}/pkgconfig/${target}
                COMPONENT ${dev}
            )

            if ("${type}" STREQUAL "INTERFACE_LIBRARY")
                install_from_target(INTERFACE_HEADERS ${INCLUDE_INSTALL_DIR} ${target} ${dev})
                install_from_target(INTERFACE_CMAKE   ${CMAKE_INSTALL_DIR}/${target} ${target} ${dev})
            else()
                install_from_target(PUBLIC_HEADERS ${INCLUDE_INSTALL_DIR} ${target} ${dev})
                install_from_target(PUBLIC_CMAKE   ${CMAKE_INSTALL_DIR}/${target} ${target} ${dev})
            endif()

        endif()

        install(TARGETS ${target}
            ARCHIVE DESTINATION ${ARCHIVE_INSTALL_DIR}
                COMPONENT ${dev}
            LIBRARY DESTINATION ${LIB_INSTALL_DIR}
                COMPONENT          ${runtime}
                NAMELINK_COMPONENT ${dev}
            RUNTIME DESTINATION ${BIN_INSTALL_DIR}
                COMPONENT ${runtime}
        )

        install(TARGETS ${target}
            EXPORT  "${target}-targets"
            ARCHIVE DESTINATION ${ARCHIVE_INSTALL_DIR}
                COMPONENT ${dev}
            LIBRARY DESTINATION ${LIB_INSTALL_DIR}
                COMPONENT          ${runtime}
                NAMELINK_COMPONENT ${dev}
            RUNTIME DESTINATION ${BIN_INSTALL_DIR}
                COMPONENT ${runtime}
        )
    endforeach()

endmacro()

function(install_from_target propname destination target component )
    get_target_property(what ${target} ${propname})
    if(what)
        foreach(file ${what})
            get_filename_component(dir ${file} DIRECTORY)
            install(FILES ${file} DESTINATION ${destination}/${dir} COMPONENT ${component})
        endforeach()
    endif()
endfunction()

