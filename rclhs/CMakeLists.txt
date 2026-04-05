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

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/rclhs-extras.cmake)

generate_cabal_project_local(ROS_DEPS)

add_custom_target(${PROJECT_NAME}_cabal_build ALL
  COMMAND cabal build -v3
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

ament_package(
  CONFIG_EXTRAS cmake/rclhs-extras.cmake
)
