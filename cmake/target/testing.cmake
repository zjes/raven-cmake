macro(raven_test_target target)
    if (BUILD_TESTING)
        include(CTest)
        enable_testing()

        find_package(Catch2 REQUIRED)
        include(Catch)

        get_target_property(type ${target} TYPE)
        if (type STREQUAL "INTERFACE_LIBRARY")
            get_target_property(_sourceFiles ${target}-props SOURCES)
            get_target_property(linkLibs ${target} INTERFACE_LINK_LIBRARIES)
            get_target_property(compileDefinitions ${target}-props COMPILE_DEFINITIONS)
            get_target_property(compileOptions ${target}-props COMPILE_OPTIONS)
            get_target_property(_srcDir ${target}-props SOURCE_DIR)
            get_target_property(_inc ${target}-props INTERFACE_INCLUDE_DIR)
        else()
            get_target_property(_sourceFiles ${target} SOURCES)
            get_target_property(linkLibs ${target} LINK_LIBRARIES)
            get_target_property(compileDefinitions ${target} COMPILE_DEFINITIONS)
            get_target_property(compileOptions ${target} COMPILE_OPTIONS)
            get_target_property(_srcDir ${target} SOURCE_DIR)
            get_target_property(_inc ${target} TARGET_INCLUDE_DIR)
        endif()

        if (_srcDir AND NOT _inc)
            set(inc ${_srcDir})
        endif()
        if (_inc AND _srcDir)
            set(inc ${_srcDir}/${_inc})
        endif()

        file(RELATIVE_PATH mainSourceDir ${CMAKE_CURRENT_SOURCE_DIR} ${_srcDir})
        set(sourceFiles)
        foreach(src ${_sourceFiles})
            list(APPEND sourceFiles ${mainSourceDir}${src})
        endforeach()

        set(includeDirs)
        raven_get_custom_property(privLibs ${target} PRIVATE_INCLUDE)
        if (privLibs)
            foreach(inc ${privLibs})
                message(${inc})
                list(APPEND includeDirs ${inc})
            endforeach()
        endif()
        if (includeDirs)
            list(REMOVE_DUPLICATES includeDirs)
        endif()

        cmake_parse_arguments(args "" "SUBDIR" "SOURCES;USES;PREPROCESSOR;FLAGS;CONFIGS;INCLUDE_DIRS" ${ARGN})

        # create unit test
        message(STATUS "Creating ${target}-test target")
        raven_target(exe ${target}-test PRIVATE
            CONFIGS
                ${args_CONFIGS}
            SOURCES
                ${args_SOURCES}
                ${sourceFiles}
            USES
                ${args_USES}
                Catch2::Catch2
            FLAGS
                ${args_FLAGS}
                ${compileOptions}
            PREPROCESSOR
                ${args_PREPROCESSOR}
                ${compileDefinitions}
            INCLUDE_DIRS
                ${args_INCLUDE_DIRS}
                ${CMAKE_CURRENT_BINARY_DIR}
                ${includeDirs}
                ${inc}
        )

        if (linkLibs)
            target_link_libraries(${target}-test PRIVATE ${linkLibs})
        endif()

        catch_discover_tests(${target}-test)
    endif()
endmacro()

