##############################################################################################################

function(raven_install_target target)
    cmake_parse_arguments(args
        ""
        "TARGET_DESTINATION;HEADERS_DESTINATION;CMAKE_DESTINATION;SYSTEMD_DESTINATION;CONFIGS_DESTINATION;DATA_DESTINATION"
        ""
        ${ARGN}
    )

    set(headersDir ${CMAKE_INSTALL_FULL_INCLUDEDIR})
    set(cmakeDir   ${CMAKE_INSTALL_FULL_DATADIR}/cmake/${target})
    set(systemdDir /usr/lib/systemd/system/)
    set(configsDir ${CMAKE_INSTALL_FULL_SYSCONFDIR}/${target})
    set(dataDir    ${CMAKE_INSTALL_FULL_DATADIR}/${target})

    if (args_HEADERS_DESTINATION)
        set(headersDir ${args_TARGET_DESTINATION})
    endif()

    if (args_CMAKE_DESTINATION)
        set(cmakeDir ${args_CMAKE_DESTINATION})
    endif()

    if (args_SYSTEMD_DESTINATION)
        set(systemdDir ${args_SYSTEMD_DESTINATION})
    endif()

    if (args_CONFIGS_DESTINATION)
        set(configsDir ${args_CONFIGS_DESTINATION})
    endif()

    if (args_DATA_DESTINATION)
        set(dataDir ${args_DATA_DESTINATION})
    endif()

    get_target_property(type ${target} TYPE)
    if(type STREQUAL "STATIC_LIBRARY")
        set(dir ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
        if (args_TARGET_DESTINATION)
            set(dir ${args_TARGET_DESTINATION})
        endif()
        install(
            TARGETS ${target}
            EXPORT  ${target}-targets
            ARCHIVE DESTINATION ${dir}
        )
        raven_set_custom_property(${target} INSTALL_DIR "${dir}")
    elseif(type STREQUAL "EXECUTABLE")
        set(dir ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR})
        if (args_TARGET_DESTINATION)
            set(dir ${args_TARGET_DESTINATION})
        endif()
        install(
            TARGETS ${target}
            EXPORT  ${target}-targets
            RUNTIME DESTINATION ${dir}
        )
        raven_set_custom_property(${target} INSTALL_DIR "${dir}")
    else()
        set(dir ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
        if (args_TARGET_DESTINATION)
            set(dir ${args_TARGET_DESTINATION})
        endif()
        install(
            TARGETS ${target}
            EXPORT  ${target}-targets
            DESTINATION ${dir}
        )
        raven_set_custom_property(${target} INSTALL_DIR "${dir}")
        raven_get_custom_property(out ${target} INSTALL_DIR)
    endif()

    raven_get_custom_property(include_dir ${target} INCLUDE_DIR)
    install_from_target(HEADERS ${headersDir} ${target} BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${include_dir}")
    install_from_target(CMAKE   ${cmakeDir}   ${target})
    install_from_target(CONFIGS ${configsDir} ${target})
    install_from_target(DATA    ${dataDir}    ${target})
    install_from_target(SYSTEMD ${systemdDir} ${target})

    # install cmake configs
    raven_get_custom_property(exportFile ${target} CMAKE_EXPORT_FILE)
    raven_get_custom_property(confFile   ${target} CMAKE_CONFIG_FILE)
    raven_get_custom_property(verFile    ${target} CMAKE_VERSION_FILE)
    raven_get_custom_property(pkgFile    ${target} CMAKE_PKG_FILE)

    #we do not install cmake package and pkgconfig if target is EXECUTABLE
    if (NOT type STREQUAL "EXECUTABLE")

        if (NOT "${confFile}" STREQUAL "")
            install(FILES
                ${confFile}
                ${verFile}
                DESTINATION ${CMAKE_INSTALL_DATADIR}/cmake/${target}
            )
        endif()
    
        if (NOT "${exportFile}" STREQUAL "")
            install(
                EXPORT ${target}-targets
                DESTINATION ${CMAKE_INSTALL_DATADIR}/cmake/${target}
                FILE ${exportFile}
            )
        endif()
    
        # install pkg config
        if (NOT "${pkgFile}" STREQUAL "")
            install(FILES
                ${pkgFile}
                DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig/
            )
        endif()
    endif()

    raven_set_custom_property(${target} CMAKE_DIR   "${cmakeDir}")
    raven_set_custom_property(${target} CONFIG_DIR  "${configsDir}")
    raven_set_custom_property(${target} HEADERS_DIR "${headersDir}")
    raven_set_custom_property(${target} DATA_DIR    "${dataDir}")
endfunction()

##############################################################################################################

function(install_from_target propname destination target)

    cmake_parse_arguments(arg
        ""
        "BASE_DIR"
        ""
        ${ARGN}
    )

    if(NOT arg_BASE_DIR)
        set(arg_BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()

    raven_get_custom_property(what ${target} ${propname})

    if(what)
        foreach(file ${what})
            if (propname STREQUAL "CONFIGS")
                install(FILES ${file} DESTINATION ${destination})
            else()
                file(RELATIVE_PATH buildDirRelFilePath "${arg_BASE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/${file}")
                get_filename_component(dir ${buildDirRelFilePath} DIRECTORY)
                install(FILES ${file} DESTINATION ${destination}/${dir})
            endif()
        endforeach()
    endif()
endfunction()

##############################################################################################################
