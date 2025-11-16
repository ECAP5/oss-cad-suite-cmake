#           __        _
#  ________/ /  ___ _(_)__  ___
# / __/ __/ _ \/ _ `/ / _ \/ -_)
# \__/\__/_//_/\_,_/_/_//_/\__/
# 
# Copyright (C) Clément Chaine
# This file is part of oss-cad-suite-cmake <https://github.com/ecap5/oss-cad-suite-cmake>
# 
# oss-cad-suite-cmake is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# oss-cad-suite-cmake is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with oss-cad-suite-cmake.  If not, see <http://www.gnu.org/licenses/>.

cmake_minimum_required(VERSION 3.12)

project(oss-cad-suite-cmake-test VERSION 1.0)

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/oss-cad-suite-config.cmake)

add_synthesis_target(
  SOURCES ${CMAKE_CURRENT_LIST_DIR}/src/*
  TOP_MODULE top
  TARGET_FPGA ecp5
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/synth.json)

add_place_and_route_target(
  INPUT ${CMAKE_CURRENT_BINARY_DIR}/synth.json
  TARGET_FPGA ecp5
  PACKAGE_OPTIONS --85k --package CABGA756
  PINOUT_OPTIONS --lpf ${CMAKE_CURRENT_LIST_DIR}/pinout.lpf
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/placement.config)

add_ecp5_bitstream_target(
  INPUT ${CMAKE_CURRENT_BINARY_DIR}/placement.config
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/bitstream.bit
  COMPRESS)

add_custom_target(gen DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/bitstream.bit)
