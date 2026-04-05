cmake_minimum_required(VERSION 3.20)

project(example_types)

find_package(ament_cmake REQUIRED)
find_package(builtin_interfaces REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(rosidl_generator_hs REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "srv/Text.srv"
  "msg/Counter.msg"
)

ament_export_dependencies(rosidl_default_runtime)

ament_package()
