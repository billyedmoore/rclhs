# The python file is put at lib/rosidl_generator_hs/generate_hs.py
set(_python_script "${rosidl_generator_hs_DIR}/../../../lib/rosidl_generator_hs/generate_hs.py")
get_filename_component(_python_script "${_python_script}" ABSOLUTE)

if(NOT EXISTS "${_python_script}")
  message(FATAL_ERROR "Haskell generator script not found at: ${_python_script}")
endif()

# Prepare args
set(_output_path "${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_hs/${PROJECT_NAME}")
set(_generated_cabal_file "${_output_path}/${PROJECT_NAME}_hs.cabal")
set(_idl_files ${rosidl_generate_interfaces_ABS_IDL_FILES})

find_package(Python3 REQUIRED COMPONENTS Interpreter)

add_custom_command(
  OUTPUT ${_generated_cabal_file}
  COMMAND ${CMAKE_COMMAND} -E make_directory ${_output_path}
  COMMAND Python3::Interpreter "${_python_script}"
    --package-name ${PROJECT_NAME}
    --output-dir ${_output_path}
    --idl-files ${_idl_files}
  DEPENDS ${_idl_files} "${_python_script}"
  COMMENT "Generating Haskell interfaces for ${PROJECT_NAME}"
  VERBATIM
)

set(_target_name "${PROJECT_NAME}__rosidl_generator_hs")
add_custom_target(${_target_name} DEPENDS ${_generated_cabal_file})

add_dependencies(
  ${rosidl_generate_interfaces_TARGET}
  ${_target_name}
)
