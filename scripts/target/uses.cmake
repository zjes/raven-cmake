include(${CMAKE_CURRENT_LIST_DIR}/resolve.cmake)

function(parse_using name uses public)
    resolve_libs(${uses})
    get_target_property(type ${name} TYPE)

    if("${type}" STREQUAL "STATIC_LIBRARY")
        target_link_libraries(${name} PUBLIC
            ${${uses}}
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
