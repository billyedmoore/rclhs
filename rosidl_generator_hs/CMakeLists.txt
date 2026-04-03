cmake_minimum_required(VERSION 3.16)
project(rosidl_generator_hs)

find_package(ament_cmake REQUIRED)
find_package(rosidl_cmake REQUIRED)
find_package(rosidl_generator_c REQUIRED)
find_package(rosidl_typesupport_c REQUIRED)
find_package(Python3 REQUIRED COMPONENTS Interpreter)

install(
  DIRECTORY cmake
  DESTINATION share/${PROJECT_NAME}
)

install(
  DIRECTORY resource
  DESTINATION share/${PROJECT_NAME}
)

install(
  PROGRAMS bin/generate_hs.py
  DESTINATION lib/${PROJECT_NAME}
)

ament_export_dependencies(rosidl_cmake)
ament_export_dependencies(rosidl_generator_c)
ament_export_dependencies(rosidl_typesupport_c)

ament_index_register_resource("rosidl_generator_packages")

ament_package(
  CONFIG_EXTRAS "rosidl_generator_hs-extras.cmake"
)
