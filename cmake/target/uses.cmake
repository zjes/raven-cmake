include(${CMAKE_CURRENT_LIST_DIR}/resolve.cmake)

function(parse_using name uses public)
    resolve_libs(${uses})
    resolve_libs(${public})

    foreach(lib ${${uses}})
        add_include_from_lib(${name} ${lib} PRIVATE)
    endforeach()

    foreach(lib ${${public}})
        add_include_from_lib(${name} ${lib} PUBLIC)
    endforeach()

    get_target_property(type ${name} TYPE)

    if ("${type}" STREQUAL "INTERFACE_LIBRARY")
        target_link_libraries(${name} INTERFACE
            ${${uses}}
            ${${public}}
        )
    else()
        if (NOT "${${public}}" STREQUAL "")
            target_link_libraries(${name} PUBLIC
                ${${public}}
            )
        endif()
        target_link_libraries(${name} PRIVATE
            ${${uses}}
        )
    endif()
endfunction()

function(add_include_from_lib target lib mode)
    get_target_property(type ${target} TYPE)
    get_target_property(includeDirs ${lib} INTERFACE_INCLUDE_DIRECTORIES)

    if (includeDirs)
        if ("${type}" STREQUAL "INTERFACE_LIBRARY")
            target_include_directories(${target} SYSTEM INTERFACE ${includeDirs})
        elseif ("${type}" STREQUAL "STATIC_LIBRARY")
            target_include_directories(${target} SYSTEM PUBLIC ${includeDirs})
        else()
            target_include_directories(${target} SYSTEM ${mode} ${includeDirs})
        endif()
    endif()
endfunction()
