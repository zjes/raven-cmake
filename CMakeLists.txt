cmake_minimum_required(VERSION 3.10)
cmake_policy(VERSION 3.10)

##############################################################################################################
project(raven-cmake VERSION 1.0)
##############################################################################################################
include(scripts/raven.cmake)
include(scripts/package.cmake)
##############################################################################################################

raven_target(interface ${PROJECT_NAME}
    CMAKE
        scripts/config.cmake
        scripts/raven.cmake
        scripts/package.cmake

        scripts/pack/target.cmake
        scripts/pack/defaults.cmake
        scripts/target/export.cmake
        scripts/target/flags.cmake
        scripts/target/resolve.cmake
        scripts/target/target.cmake
        scripts/target/uses.cmake
        scripts/target/version.cmake
        scripts/templates/*
)

##############################################################################################################

raven_define_component(${PROJECT_NAME}-dev
    TARGETS ${PROJECT_NAME}
    DEPENDS cmake pkg-config
    BUILD_DEPENDS "cmake (>= 3.10);pkg-config"
)

raven_pack(
    PKG_NAME    raven-cmake
    CONTACT     "zjes <zjesclean@gmail.com>"
    COMPONENTS  ${PROJECT_NAME}-dev
    DESCRIPTION "Simple cmake wrapper to easy target creation, packing"
)

##############################################################################################################
