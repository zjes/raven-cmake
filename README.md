# Raven cmake

Set of helpers to easy target creation, exporting and pack as debian package. Project is not finished yet.

## Target creation
Example:
```
raven_target(shared my-project
    PUBLIC
        my-project.h
    SOURCES
        my-project.cpp
    USES
        dependency
)

raven_define_component(my-project-dev
    SHLIBDEPS
    NAME    "my-project"
    TARGETS my-project
)

raven_pack(
    CONTACT     "your contact"
    COMPONENTS  my-project-dev
    DESCRIPTION "My awesome project"
)
```
Where is ```raven_target``` is target creation, ```raven_define_component``` defines component and ```raven_pack``` creates a config for package.
After that you can from build directory simple call ```cpack --config my-project-dev``` to create debian package.