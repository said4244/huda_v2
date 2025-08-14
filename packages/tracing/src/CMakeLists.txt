# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(tracing_game_library VERSION 0.0.1 LANGUAGES C)

add_library(tracing_game SHARED
  "tracing_game.c"
)

set_target_properties(tracing_game PROPERTIES
  PUBLIC_HEADER tracing_game.h
  OUTPUT_NAME "tracing_game"
)

target_compile_definitions(tracing_game PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(tracing_game PRIVATE "-Wl,-z,max-page-size=16384")
endif()
