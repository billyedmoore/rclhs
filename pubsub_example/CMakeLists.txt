cmake_minimum_required(VERSION 3.8)
project(pubsub_example NONE)

find_package(ament_cmake REQUIRED)
# includes the macro, "generate_cabal_project_local"
find_package(rclhs REQUIRED) 
find_package(example_types REQUIRED)

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
  example_types
  rclhs
)

get_filename_component(EXAMPLE_TYPES_SHARE "${example_types_DIR}/.." ABSOLUTE)
set(TYPE_GEN_DIR "${EXAMPLE_TYPES_SHARE}/haskell" "../rclhs")

generate_cabal_project_local(ROS_DEPS TYPE_GEN_DIR)

file(GLOB_RECURSE HS_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/*.hs")
set(BIN_NAME "pubsub-example")
set(OUTPUT_BIN "${CMAKE_CURRENT_BINARY_DIR}/${BIN_NAME}")

add_custom_command(
    OUTPUT ${OUTPUT_BIN}
    COMMAND cabal install exe:${BIN_NAME} 
            --installdir=${CMAKE_CURRENT_BINARY_DIR}
            --install-method=copy
            --overwrite-policy=always
    DEPENDS ${HS_SOURCES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Building `pubsub_example` via Cabal"
)

add_custom_target(${PROJECT_NAME}_build ALL DEPENDS ${OUTPUT_BIN})

install(
    PROGRAMS ${OUTPUT_BIN}
    DESTINATION lib/${PROJECT_NAME}
    RENAME pubsub_example
)

ament_package()
