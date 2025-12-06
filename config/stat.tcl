# Read environment variables
# --------------------------

if { [info exists ::env(TOP)] } {
  set top_module $::env(TOP)
} else {
  error "ERROR: Environment variable 'TOP' is not set."
}

if { [info exists ::env(SOURCE_FILE)] } {
  set source_file $::env(SOURCE_FILE)
} else {
  error "ERROR: Environment variable 'SOURCE_FILE' is not set."
}

if { [info exists ::env(OUT_DIR)] } {
  set out_dir $::env(OUT_DIR)
} else {
  error "ERROR: Environment variable 'OUT_DIR' is not set."
}

if { [info exists ::env(REPORT_NAME)] } {
  set report_name $::env(REPORT_NAME)
} else {
  error "ERROR: Environment variable 'REPORT_NAME' is not set."
}

if { [info exists ::env(TARGET_FPGA)] } {
  set target_fpga $::env(TARGET_FPGA)
} else {
  error "ERROR: Environment variable 'TARGET_FPGA' is not set."
}

if { [info exists ::env(USE_ABC9)] } {
  set use_abc9 1
} else {
  set use_abc9 0
}

set report_file "$out_dir/$report_name"

echo "PON"

# Setup and load
# --------------

exec mkdir -p $out_dir

# initialize report
exec echo "==============================================="> $report_file
exec echo " SYNTHESIS REPORT" >> $report_file
exec echo " TOP MODULE: $top_module" >> $report_file
exec echo " SOURCE: $source_file" >> $report_file
exec echo "===============================================">> $report_file

echo ">>> [INFO] LOADING SOURCE FILE..."
read_verilog $source_file

echo ">>> [INFO] CHECKING HIERARCHY AND CLEANING..."

# Check hierarchy starting from the top module
hierarchy -check -top $top_module

# Remove unused modules
proc; opt_clean

# Save clean state
design -save clean_design

# Auto-detect submodules
# ----------------------

echo ">>> [INFO] SCANNING DESIGN FOR SUBMODULES..."

# capture the output of the yosys 'ls' command
redirect -variable design_ls_output { ls }

set modules_to_analyze {}
foreach line [split $design_ls_output "\n"] {
  # Yosys internal module names usually start with a backslash

  if {[regexp {^\s*\\([a-zA-Z0-9_]+)} $line full_match mod_name]} {
    lappend modules_to_analyze $mod_name
  }
}

# Submodule analysis loop
# -----------------------

foreach mod $modules_to_analyze {
  echo ">>> [INFO] Analyzing submodule: $mod"

  design -load clean_design

  if { $use_abc9 == 1 } {
    synth_$target_fpga -top $mod -abc9
  } else {
    synth_$target_fpga -top $mod
  }

  exec echo "-----------------------------------------------">> $report_file
  exec echo " MODULE: $mod">> $report_file
  exec echo "-----------------------------------------------">> $report_file

  exec echo "--- [AREA / RESOURCES] ---">> $report_file
  tee -a $report_file stat -tech $target_fpga

  exec echo "">> $report_file
  exec echo "--- [TIMING / CRITICAL PATH] ---">> $report_file
  tee -a $report_file ltp -noff

  write_json $out_dir/${mod}.json
}
