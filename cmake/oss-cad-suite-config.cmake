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

find_program(ECPPLL_BIN NAMES ecppll
  HINTS ${OSS_CAD_SUITE_ROOT}/bin ENV OSS_CAD_SUITE_ROOT
  NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
if (NOT ECPPLL_BIN)
  message(FATAL_ERROR "Cannot find ecppll executable.")
endif()

set(oss_cad_suite_FOUND 1)

# Prefer SV2V_ROOT from environment
if (DEFINED ENV{SV2V_ROOT})
  set(SV2V_ROOT "$ENV{SV2V_ROOT}" CACHE PATH "SV2V_ROOT")
endif()

set(SV2V_ROOT "${CMAKE_CURRENT_LIST_DIR}" CACHE PATH "SV2V_ROOT")
if (NOT SV2V_ROOT)
  message(FATAL_ERROR "SV2V_ROOT cannot be detected. Set it to the appropriate directory (e.g. /usr/share/sv2v) as an environment variable or CMake define.")
endif()

# Search for the binaries
find_program(SV2V_BIN NAMES yosys
  HINTS ${SV2V_ROOT}/bin ENV SV2V_ROOT
  NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
if (NOT SV2V_BIN)
  message(FATAL_ERROR "Cannot find sv2v executable.")
endif()

function(get_all_sources_recursive TARGET_NAME OUTPUT_LIST)
  set(CURRENT_FILES "")

  get_target_property(RAW_SOURCES ${TARGET_NAME} INTERFACE_SOURCES)

  if(RAW_SOURCES AND NOT "${RAW_SOURCES}" MATCHES "NOTFOUND")
    list(APPEND CURRENT_FILES ${RAW_SOURCES})
  endif()

  get_target_property(RAW_LIBS ${TARGET_NAME} INTERFACE_LINK_LIBRARIES)
  if(RAW_LIBS AND NOT "${RAW_LIBS}" MATCHES "NOTFOUND")
    foreach(DEP ${RAW_LIBS})
      if(TARGET ${DEP})
        get_all_sources_recursive(${DEP} SUB_FILES_LIST)
        list(APPEND CURRENT_FILES ${SUB_FILES_LIST})
      else()
        message(FATAL_ERROR "Recursive dependency ${DEP} not found")
      endif()
    endforeach()
  endif()

  if(CURRENT_FILES)
    list(REMOVE_DUPLICATES CURRENT_FILES)
  endif()

  set(${OUTPUT_LIST} ${CURRENT_FILES} PARENT_SCOPE)
endfunction()

function(add_synthesis_target)
  cmake_parse_arguments(SYNTH "ABC9" # options
                              "LIB;OUTPUT;TARGET_FPGA;TOP_MODULE"     # one-value args
                              "DEPENDS;DEFINES" # multi-value args
                                 ${ARGN})
  if (NOT SYNTH_LIB)
    message(FATAL_ERROR "Need a source library")
  endif()

  if(NOT TARGET ${SYNTH_LIB})
    message(FATAL_ERROR "Library ${SYNTH_LIB} not defined")
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

  if(SYNTH_ABC9)
    set(ABC9_OPTION "-abc9")
  endif()

  set(FLAT_SOURCE_PATH ${CMAKE_CURRENT_BINARY_DIR}/${SYNTH_LIB}_flat.v)
  get_all_sources_recursive(${SYNTH_LIB} LIB_SOURCES)

  # Generate the define parameter string
  foreach(DEFINE IN LISTS SYNTH_DEFINES)
    list(APPEND DEFINE_PARAM_STRING "-D${DEFINE}")
  endforeach()

  add_custom_command(
    OUTPUT ${FLAT_SOURCE_PATH}
    COMMAND sv2v ${DEFINE_PARAM_STRING} ${LIB_SOURCES} > ${FLAT_SOURCE_PATH}
    DEPENDS ${LIB_SOURCES}
    DEPENDS ${SYNTH_DEPENDS}
    COMMAND_EXPAND_LISTS)

  add_custom_command(
    OUTPUT ${SYNTH_OUTPUT}
    DEPENDS ${FLAT_SOURCE_PATH}
    COMMAND ${YOSYS_BIN} -p \'read_verilog ${FLAT_SOURCE_PATH} "\;" synth_${SYNTH_TARGET_FPGA} ${ABC9_OPTION} -top ${SYNTH_TOP_MODULE} -json ${SYNTH_OUTPUT}\'
    COMMAND_EXPAND_LISTS)
endfunction()

function(add_place_and_route_target)
  cmake_parse_arguments(PNR "" # options
                            "INPUT;OUTPUT;TARGET_FPGA"     # one-value args
                            "PACKAGE_OPTIONS;PINOUT_OPTIONS;NEXTPNR_OPTIONS" # multi-value args
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

  set(NEXTPNR_COMMAND ${NEXTPNR_${TARGET_FPGA_STR}_BIN} ${PNR_PACKAGE_OPTIONS} --json ${PNR_INPUT} ${PNR_PINOUT_OPTIONS} --textcfg ${PNR_OUTPUT} --Werror ${NEXTPNR_OPTIONS})

  add_custom_command(
    OUTPUT ${PNR_OUTPUT}
    DEPENDS ${PNR_INPUT}
    COMMAND ${NEXTPNR_COMMAND}
    COMMAND_EXPAND_LISTS)
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

function(add_ecp5_pll_generation)
  cmake_parse_arguments(ARG       "" # options
                                  "INPUT_FREQ;OUTPUT_FREQ;MODULE_NAME"     # one-value args
                                  "" # multi-value args
                                  ${ARGN})
  if (NOT ARG_INPUT_FREQ)
    message(FATAL_ERROR "Need an input frequency")
  endif()

  if (NOT ARG_OUTPUT_FREQ)
    message(FATAL_ERROR "Need an output frequency")
  endif()

  if (NOT ARG_MODULE_NAME)
    message(FATAL_ERROR "Need a module name")
  endif()

  # We want it to be regenerated every time
  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${ARG_MODULE_NAME}.v
    COMMAND ${ECPPLL_BIN} -i ${ARG_INPUT_FREQ} -o ${ARG_OUTPUT_FREQ} --module ${ARG_MODULE_NAME} --file ${CMAKE_CURRENT_BINARY_DIR}/${ARG_MODULE_NAME}.v)
endfunction()
