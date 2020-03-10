include(CMakePackageConfigHelpers)

##############################################################################################################

function(prepare_targets name component targets)
    foreach(target ${${targets}})
        install_target(${name} ${component} ${target})

        get_target_property(exported ${target} INTERFACE_EXPORT_CMAKE_FILE)
        set_property(TARGET ${target} APPEND PROPERTY INTERFACE_EXPORTED_TARGETS ${exported})
    endforeach()
endfunction()

##############################################################################################################

function(install_target name component target)
    if(${component} MATCHES "^.*[\\-]?(dev)$")
        get_target_property(confFile ${target} INTERFACE_CONF_FILE)
        get_target_property(verFile  ${target} INTERFACE_VERSION_FILE)

        install(FILES
            ${confFile}
            ${verFile}
            DESTINATION ${CMAKE_INSTALL_DIR}/${target}
            COMPONENT ${component}
        )

        get_target_property(type ${target} TYPE)

        install(TARGETS ${target}
            ARCHIVE DESTINATION ${ARCHIVE_INSTALL_DIR} COMPONENT ${component}
            LIBRARY DESTINATION ${LIB_INSTALL_DIR}     COMPONENT ${component} NAMELINK_ONLY
            #RUNTIME DESTINATION ${BIN_INSTALL_DIR}     COMPONENT ${component}
        )

        # install target output
#        install(TARGETS ${target}
#            EXPORT  "${target}-targets"
#            ARCHIVE DESTINATION ${ARCHIVE_INSTALL_DIR}
#            LIBRARY DESTINATION ${LIB_INSTALL_DIR}
#            RUNTIME DESTINATION ${BIN_INSTALL_DIR}
#            COMPONENT ${component}
#        )
        install(TARGETS ${target}
            EXPORT  "${target}-targets"
            ARCHIVE DESTINATION ${ARCHIVE_INSTALL_DIR} COMPONENT ${component}
            LIBRARY DESTINATION ${LIB_INSTALL_DIR}  NAMELINK_COMPONENT ${component}
            #RUNTIME DESTINATION ${BIN_INSTALL_DIR}
            #COMPONENT ${component}
        )

        # install export cmake target
        install(EXPORT ${target}-targets
            DESTINATION ${CMAKE_INSTALL_DIR}/${target}
            COMPONENT   ${component}
        )

        if ("${type}" STREQUAL "INTERFACE_LIBRARY")
            install_from_target(INTERFACE_HEADERS ${INCLUDE_INSTALL_DIR} ${target} ${component})
            install_from_target(INTERFACE_CMAKE   ${CMAKE_INSTALL_DIR}/${target} ${target} ${component})
        else()
            install_from_target(PUBLIC_HEADERS ${INCLUDE_INSTALL_DIR} ${target} ${component})
        endif()
    else()
        install(
            TARGETS ${target}
            LIBRARY DESTINATION ${LIB_INSTALL_DIR}     COMPONENT ${component} NAMELINK_SKIP
            RUNTIME DESTINATION ${RUNTIME_INSTALL_DIR} COMPONENT ${component}
        )
    endif()
endfunction()

##############################################################################################################

function(install_from_target propname destination target component )
    get_target_property(what ${target} ${propname})
    if(what)
        foreach(file ${what})
            get_filename_component(dir ${file} DIRECTORY)
            install(FILES ${file} DESTINATION ${destination}/${dir} COMPONENT ${component})
        endforeach()
    endif()
endfunction()


