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


if { [info exists ::env(OUT_DIR)] } {
  set use_abc9 1
} else {
  set use_abc9 0
}

set report_file "$out_dir/stat_report.txt"

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
    synth_ecp5 -top $mod -abc9
  } else {
    synth_ecp5 -top $mod
  }

  exec echo "-----------------------------------------------">> $report_file
  exec echo " MODULE: $mod">> $report_file
  exec echo "-----------------------------------------------">> $report_file

  exec echo "--- [AREA / RESOURCES] ---">> $report_file
  tee -a $report_file stat -tech ecp5

  exec echo "">> $report_file
  exec echo "--- [TIMING / CRITICAL PATH] ---">> $report_file
  tee -a $report_file ltp -noff

  write_json $out_dir/${mod}.json
}
