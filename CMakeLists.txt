# CMAKE wrapper for cabal!

# Allows the library to be run with "colcon build"
# and tested with "colcon test".

cmake_minimum_required(VERSION 3.8)
project(rclhs NONE) # no C compiler

# Ament CMake is ROS2 build system
find_package(ament_cmake REQUIRED) 

set(ROS_DEPS
  rcl
  rcutils
  rmw
  rmw_implementation
  rosidl_runtime_c
  rosidl_typesupport_c
  rosidl_typesupport_introspection_c
  std_msgs
  service_msgs
)

set(CABAL_INCLUDE_ARGS "")
set(CABAL_LIB_ARGS "")

foreach(dep IN LISTS ROS_DEPS)
  find_package(${dep} REQUIRED)
  
  foreach(inc_dir IN LISTS ${dep}_INCLUDE_DIRS)
    list(APPEND CABAL_INCLUDE_ARGS "--extra-include-dirs=${inc_dir}")
  endforeach()

  foreach(lib IN LISTS ${dep}_LIBRARIES)
    if(IS_ABSOLUTE "${lib}")
      get_filename_component(lib_dir "${lib}" DIRECTORY)
      list(APPEND CABAL_LIB_ARGS "--extra-lib-dirs=${lib_dir}")
    endif()
  endforeach()
endforeach()

list(REMOVE_DUPLICATES CABAL_INCLUDE_ARGS)
list(REMOVE_DUPLICATES CABAL_LIB_ARGS)

add_custom_target(${PROJECT_NAME}_cabal_build ALL
  COMMAND cabal build -v3 ${CABAL_INCLUDE_ARGS} ${CABAL_LIB_ARGS}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMENT "Building Haskell package via Cabal... (${CABAL_INCLUDE_ARGS}, ${CABAL_LIB_ARGS})"
)

if(BUILD_TESTING)
  add_test(
    NAME rclhs_test_suite
    COMMAND cabal test ${CABAL_INCLUDE_ARGS} ${CABAL_LIB_ARGS}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
endif()

ament_package()
