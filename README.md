# raven-cmake
The goal of this project is to store common files used by the 42ity projects with the new cmake structure

## CMAKE
The cmake common settings will:

- include GNUInstallDirs variables 
- include CTest
- create a target memcheck which run the test with valgrind
- set differents warnings
- define macros (more information bellow on each macro)
- define the following options:
```
option(BUILD_TESTING "Build tests" OFF)
option(BUILD_DOC "Build documentation" OFF)
```

To use it you have to add the following into your CMakeLists.txt file:

```
# Use common cmake settings
find_package(raven-cmake)

```

### Dependency management
Dependency management is managed using the [ExternalProject_add](https://cmake.org/cmake/help/v3.13/module/ExternalProject.html) feature of `CMake`.

The [external](cmake/external) directory provides the cmake files to download and build dependencies.

To build the dependencies you need to use the cmake option "ENABLE_STANDALONE=ON"

### Target creation

Target has follow syntax:
```
raven_target([type] [target name] 
    SOURCES 
        [sources list] (relative path from CMakeList folder / absolute path)
    USES / USES_PRIVATE
        [private dependencies list] 
    USES_PUBLIC 
        [public dependencies]
    PUBLIC_INCLUDE_DIR
        [directory of the public include] (relative path from CMakeList folder)
    PUBLIC / PUBLIC_HEADERS 
        [public headers] (relative path from PUBLIC_INCLUDE_DIR folder or from CMakeList folder if PUBLIC_INCLUDE_DIR is not defined)
    INCLUDE_DIRS 
        [extra include directories for private use]
    PREPROCESSOR 
        [preprocessor definitions]
    FLAGS 
        [extra compilation flags]
    CMAKE 
        [extra cmake scripts]
    CONFIGS 
        [configs]
```

Where type could be:
 * `exe` - regular executable
 * `static` - static library
 * `shared` - shared library
 * `interface` - non binary library, just headers, configs etc

`USES`/`USES_PRIVATE` are dependencies of the project for building only.   
`USES_PUBLIC` are dependencies of the project with are going to be propagated to the projects which use our project.  
Firstly system will try to find dependency in the system. 
If it will not found and ENABLE_STANDALONE is ON then will try to find it in `external` projects and will add it to compilation process.

### Example of the projects

#### Executable
A simple executable where src is a subdirectory with the sources and private headers.
```
raven_target(exe ${PROJECT_NAME}
    SOURCES
        src/daemon.cpp
        src/include.hpp
    USES
        tntdb
)
```
The executable named from the variable "${PROJECT_NAME}" will be install in ${CMAKE_INSTALL_PREFIX}/bin/${PROJECT_NAME}.

#### Shared library
A shared library where src is a subdirectory with the sources and private headers, and public_includes/proj the path to the public headers.
```
raven_target(shared ${PROJECT_NAME}
    SOURCES
        src/myPrivateClass.cpp
        src/myPrivateClass.h
        src/myPublicClass.cpp
    PUBLIC_INCLUDE_DIR
        public_includes
    PUBLIC_HEADERS
        proj/myPublicClass.hpp
    USES_PRIVATE
        common-log
    USES_PUBLIC
        utils
)
```
The shared library named "lib${PROJECT_NAME}.so" will be install in "${CMAKE_INSTALL_PREFIX}/lib/${PROJECT_NAME}lib${PROJECT_NAME}.so"  
The public header named "myPublicClass.hpp" will be install in "${CMAKE_INSTALL_PREFIX}/lib/**proj**/myPublicClass.hpp"  
All the cmake package information files will be installed in ${CMAKE_INSTALL_PREFIX}/shared/cmake/..    
