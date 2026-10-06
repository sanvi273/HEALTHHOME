cmake_minimum_required(VERSION 3.22.1)

project("healthhome_tgcalls")

add_library(
    healthhome_tgcalls
    SHARED
    healthhome_tgcalls.cpp
)

target_link_libraries(
    healthhome_tgcalls
    log
)