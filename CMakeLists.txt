cmake_minimum_required(VERSION 3.13)
cmake_policy(VERSION 3.13)

##############################################################################################################
project(raven-cmake
    VERSION     1.0
    DESCRIPTION "Raven cmake support"
)
##############################################################################################################
include(cmake/raven-cmake.cmake)
##############################################################################################################

raven_target(interface ${PROJECT_NAME}
    CMAKE
        cmake/external.cmake
        cmake/raven-cmake.cmake
        cmake/warnings.cmake

        cmake/target/export.cmake
        cmake/target/flags.cmake
        cmake/target/resolve.cmake
        cmake/target/target.cmake
        cmake/target/uses.cmake
        cmake/target/version.cmake
        cmake/target/install.cmake
        cmake/target/properties.cmake
        cmake/target/testing.cmake
        cmake/templates/package.pc.in
        cmake/templates/external-autoconf.cmake.in
        cmake/templates/external-cmake.cmake.in

        cmake/external/*
)
