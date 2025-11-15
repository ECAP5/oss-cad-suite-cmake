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

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/verilator-config.cmake)

add_executable(tests src/top.cpp)
verilate(tests
  PREFIX Vtop
  SOURCES src/top.sv
  TRACE
  PUBLIC)
