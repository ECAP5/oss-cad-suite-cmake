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

######################################################################
#
# DESCRIPTION: CMake configuration file for the oss-cad-suite
#
# Include it in your CMakeLists.txt using:
#
#     find_package(oss-cad-suite)
#
######################################################################

cmake_minimum_required(VERSION 3.13)

# Prefer OSS_CAD_SUITE_ROOT from environment
if (DEFINED ENV{OSS_CAD_SUITE_ROOT})
  set(OSS_CAD_SUITE_ROOT "$ENV{OSS_CAD_SUITE_ROOT}" CACHE PATH "OSS_CAD_SUITE_ROOT")
endif()

set(OSS_CAD_SUITE_ROOT "${CMAKE_CURRENT_LIST_DIR}" CACHE PATH "OSS_CAD_SUITE_ROOT")
if (NOT OSS_CAD_SUITE_ROOT)
  message(FATAL_ERROR "OSS_CAD_SUITE_ROOT cannot be detected. Set it to the appropriate directory (e.g. /usr/share/oss-cad-suite) as an environment variable or CMake define.")
endif()

# Search for the binaries
find_program(YOSYS_BIN NAMES yosys
  HINTS ${OSS_CAD_SUITE_ROOT}/bin ENV OSS_CAD_SUITE_ROOT
  NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
if (NOT YOSYS_BIN)
  message(FATAL_ERROR "Cannot find yosys executable.")
endif()

find_program(NEXTPNR_ECP5_BIN NAMES nextpnr-ecp5
  HINTS ${OSS_CAD_SUITE_ROOT}/bin ENV OSS_CAD_SUITE_ROOT
  NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
if (NOT NEXTPNR_ECP5_BIN)
  message(FATAL_ERROR "Cannot find nextpnr-ecp5 executable.")
endif()

find_program(ECPPACK_BIN NAMES ecppack
  HINTS ${OSS_CAD_SUITE_ROOT}/bin ENV OSS_CAD_SUITE_ROOT
  NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
if (NOT ECPPACK_BIN)
  message(FATAL_ERROR "Cannot find ecppack executable.")
endif()

set(oss_cad_suite_FOUND 1)

function(add_synthesis_target)
  cmake_parse_arguments(SYNTH "" # options
                              "OUTPUT;TARGET_FPGA;TOP_MODULE"     # one-value args
                              "SOURCES" # multi-value args
                                 ${ARGN})
  if (NOT SYNTH_SOURCES)
    message(FATAL_ERROR "Need at least one source")
  endif()

  if (NOT SYNTH_OUTPUT)
    message(FATAL_ERROR "Need an output file")
  endif()

  if (NOT SYNTH_TARGET_FPGA)
    message(FATAL_ERROR "Need an FPGA target")
  endif()

  if (NOT SYNTH_TOP_MODULE)
    message(FATAL_ERROR "Need a top module")
  endif()

  add_custom_command(
    OUTPUT ${SYNTH_OUTPUT}
    DEPENDS ${SYNTH_SOURCES}
    COMMAND ${YOSYS_BIN} -p \'read -sv ${SYNTH_SOURCES} \; synth_${SYNTH_TARGET_FPGA} -top ${SYNTH_TOP_MODULE} -json ${SYNTH_OUTPUT}\')
endfunction()

function(add_place_and_route_target)
  cmake_parse_arguments(PNR "" # options
                            "INPUT;OUTPUT;TARGET_FPGA"     # one-value args
                            "PACKAGE_OPTIONS;PINOUT_OPTIONS" # multi-value args
                            ${ARGN})
  if (NOT PNR_INPUT)
    message(FATAL_ERROR "Need an input file")
  endif()

  if (NOT PNR_OUTPUT)
    message(FATAL_ERROR "Need an output file")
  endif()

  if (NOT PNR_TARGET_FPGA)
    message(FATAL_ERROR "Need an FPGA target")
  endif()

  string (TOUPPER ${PNR_TARGET_FPGA} TARGET_FPGA_STR)

  set(NEXTPNR_COMMAND ${NEXTPNR_${TARGET_FPGA_STR}_BIN} ${PACKAGE_OPTIONS_STR} --json ${PNR_INPUT} ${PINOUT_OPTIONS_STR} --textcfg ${PNR_OUTPUT})

  add_custom_command(
    OUTPUT ${PNR_OUTPUT}
    DEPENDS ${PNR_INPUT}
    COMMAND ${NEXTPNR_COMMAND})
endfunction()

function(add_ecp5_bitstream_target)
  cmake_parse_arguments(BITSTREAM "COMPRESS" # options
                                  "INPUT;OUTPUT"     # one-value args
                                  "" # multi-value args
                                  ${ARGN})
  if (NOT BITSTREAM_INPUT)
    message(FATAL_ERROR "Need an input file")
  endif()

  if (NOT BITSTREAM_OUTPUT)
    message(FATAL_ERROR "Need an output file")
  endif()

  if (BITSTREAM_COMPRESS)
    list(APPEND COMMAND_ARGS --compress)
  endif()

  add_custom_command(
    OUTPUT ${BITSTREAM_OUTPUT}
    DEPENDS ${BITSTREAM_INPUT}
    COMMAND ${ECPPACK_BIN} ${COMMAND_ARGS} --bit ${BITSTREAM_OUTPUT} ${BITSTREAM_INPUT})
endfunction()
