cmake_minimum_required(VERSION 3.4.1)

project(vvella_native)

# Define the path to the prebuilt libraries and headers
# We assume the user creates a 'libs' folder and 'includes' folder in src/main/cpp
set(libs_path ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI})
set(include_path ${CMAKE_CURRENT_SOURCE_DIR}/includes)

# Include directories
include_directories(${include_path})

# Add Sherpa ONNX shared library
add_library(sherpa-onnx-c-api SHARED IMPORTED)
set_target_properties(sherpa-onnx-c-api PROPERTIES IMPORTED_LOCATION
    ${libs_path}/libsherpa-onnx-c-api.so)

# Add OnnxRuntime shared library
add_library(onnxruntime SHARED IMPORTED)
set_target_properties(onnxruntime PROPERTIES IMPORTED_LOCATION
    ${libs_path}/libonnxruntime.so)

# Build our wrapper JNI/FFI library
add_library(vvella_native SHARED
    sherpa-wrapper.cc
)

# Link everything
target_link_libraries(vvella_native
    sherpa-onnx-c-api
    onnxruntime
    log
)
