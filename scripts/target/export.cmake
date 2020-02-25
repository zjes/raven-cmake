include(CMakePackageConfigHelpers)

##############################################################################################################

function(export_target target)
    set(exportCmakeFile   ${target}-targets.cmake)
    set(exportCmakeConfig ${target}-config.cmake)
    set(exportVersionFile ${CMAKE_CURRENT_BINARY_DIR}/${target}-config-version.cmake)

    export(TARGETS ${target} FILE ${exportCmakeFile})

    if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${exportCmakeConfig}.in)
        set(exportCmakeConfigIn ${CMAKE_CURRENT_BINARY_DIR}/${target}-config.cmake.in)
        set(exportCmakeConfig ${CMAKE_CURRENT_BINARY_DIR}/${target}-config.cmake)
        file(WRITE ${exportCmakeConfigIn} "@PACKAGE_INIT@")
    else()
        set(exportCmakeConfigIn ${CMAKE_CURRENT_SOURCE_DIR}/${exportCmakeConfig}.in)
        set(exportCmakeConfig ${CMAKE_CURRENT_BINARY_DIR}/${target}-config.cmake)
    endif()

    configure_package_config_file(
        ${exportCmakeConfigIn}
        ${exportCmakeConfig}
        INSTALL_DESTINATION ${CMAKE_INSTALL_DIR}/${target}
        PATH_VARS CMAKE_INSTALL_DIR BIN_INSTALL_DIR LIB_INSTALL_DIR INCLUDE_INSTALL_DIR ARCHIVE_INSTALL_DIR
    )

    write_basic_package_version_file(
        ${exportVersionFile}
        VERSION ${PACKAGE_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    set_target_properties(${target} PROPERTIES
        INTERFACE_CONF_FILE ${exportCmakeConfig}
        INTERFACE_VERSION_FILE ${exportVersionFile}
    )
endfunction()

##############################################################################################################
