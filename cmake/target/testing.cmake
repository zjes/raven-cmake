macro(raven_test_target target)
    cmake_parse_arguments(args "" "SUBDIR;NAME" "SOURCES;USES;PREPROCESSOR;FLAGS;CONFIGS;INCLUDE_DIRS" ${ARGN})
    if (BUILD_TESTING)
        include(CTest)
        enable_testing()

        resolve(Catch2::Catch2)

        # create target
        get_target_property(type ${target} TYPE)
        if (type STREQUAL "INTERFACE_LIBRARY")
            add_executable(${args_NAME}
                ${args_SOURCES}
            )
        else()
            raven_get_custom_property(objName ${target} OBJLIB_NAME)
            add_executable(${args_NAME} $<TARGET_OBJECTS:${objName}>
                ${args_SOURCES}
            )
        endif()

        # set deps
        raven_get_custom_property(privateDeps ${target} PRIVATE_DEPS)
        raven_get_custom_property(publicDeps ${target} PRIVATE_DEPS)
        target_link_libraries(${args_NAME} PRIVATE Catch2::Catch2WithMain)
        if (NOT "${privateDeps}" STREQUAL "")
            target_link_libraries(${args_NAME} PRIVATE ${privateDeps})
        endif()
        if (NOT "${publicDeps}" STREQUAL "")
            target_link_libraries(${args_NAME} PRIVATE ${publicDeps})
        endif()

        target_include_directories(${args_NAME} PRIVATE
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/>
            $<INSTALL_INTERFACE:include/>
        )

        raven_get_custom_property(flags ${objName} FLAGS)
        if (flags)
            set_cppflags(${args_NAME} "${flags}")
        endif()

        dump_target(${args_NAME})
    endif()
endmacro()

