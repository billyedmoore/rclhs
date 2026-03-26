find_package(ament_cmake_core QUIET REQUIRED)

ament_register_extension(
  "rosidl_generate_idl_interfaces"
  "rosidl_generator_hs"
  "rosidl_generator_hs_generate_interfaces.cmake"
)
