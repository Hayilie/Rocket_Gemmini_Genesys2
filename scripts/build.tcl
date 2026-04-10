# 1. SETTINGS AND DIRECTORIES
set timestamp [clock format [clock seconds] -format %Y%m%d_%H%M%S]
set part "xc7k325tffg900-2"
set top_module "FPGA_Top"
set outputDir "./outputs"
set reportDir "./reports"
set srcDir    "./src"

file mkdir $outputDir
file mkdir $reportDir

# 2. PROJECT CREATION (Temporary physical project for IP management)
create_project -force managed_proj $outputDir/managed_proj -part $part
set_property target_language Verilog [current_project]

# ------------------------------------------------------------------------------
# 3. ADDING RESOURCES 
# ------------------------------------------------------------------------------
puts "--- Adding Resources ---"

# 3.1. RTL Files (.v, .sv)
set rtl_files [glob -nocomplain $srcDir/rtl/*.v $srcDir/rtl/*.sv]
if {[llength $rtl_files] > 0} {
    add_files $rtl_files
    puts "[llength $rtl_files] local RTL file(s) added."
} else {
    puts "ERROR: No hardware files found in src/rtl!"
    exit 1
}

# 3.2. IP Files (.xci)
set ip_files [glob -nocomplain $srcDir/ip/**/*.xci $srcDir/ip/*.xci]
if {[llength $ip_files] > 0} {
    puts "Loading and updating IPs..."
    import_ip $ip_files
    upgrade_ip [get_ips]
    generate_target all [get_ips]
    export_ip_user_files -of_objects [get_ips] -no_script -sync -force -quiet
    create_ip_run [get_ips]
    launch_runs [get_runs *_synth_1]
    foreach run [get_runs *_synth_1] { wait_on_run $run }
}

# 3.3. Constraints (.xdc)
# Corrected the folder name to 'constraints'!
set xdc_files [glob -nocomplain $srcDir/constraints/*.xdc]

if {[llength $xdc_files] > 0} {
    read_xdc $xdc_files
    puts "[llength $xdc_files] constraint(s) (XDC) added and READ."
} else {
    puts "CRITICAL WARNING: No XDC file found in src/constraints/!"
}

# ------------------------------------------------------------------------------
# 4. PROCESS STEPS
# ------------------------------------------------------------------------------
set step [lindex $argv 0]

# --- SYNTHESIS ---
if { $step == "synth" } {
    puts "--- SYNTHESIS STARTING ---"
    synth_design -top $top_module -part $part
    write_checkpoint -force $outputDir/post_synth.dcp
    report_utilization -file $reportDir/utilization_synth_${timestamp}.txt
    report_timing_summary -file $reportDir/timing_synth_${timestamp}.txt
    puts "Synthesis Completed."
}

# --- SYNTHESIS TIMING REPORT (Post-Retrieval) ---
if { $step == "synth_timing" } {
    puts "--- RETRIEVING SYNTHESIS TIMING REPORT ---"
    if {[file exists $outputDir/post_synth.dcp]} {
        open_checkpoint $outputDir/post_synth.dcp
        report_timing_summary -file $reportDir/timing_synth_${timestamp}.txt
        puts "REPORT READY: $reportDir/timing_synth_${timestamp}.txt"
    } else {
        puts "ERROR: post_synth.dcp not found! You must run 'make synth' first."
        exit 1
    }
}

# --- IMPLEMENTATION ---
if { $step == "impl" } {
    puts "--- IMPLEMENTATION STARTING ---"
    if {[file exists $outputDir/post_synth.dcp]} {
        open_checkpoint $outputDir/post_synth.dcp
    } else {
        synth_design -top $top_module -part $part
    }
    
    opt_design
    place_design
    route_design
    
    report_timing_summary -file $reportDir/timing_impl_${timestamp}.txt
    report_utilization -file $reportDir/utilization_impl_${timestamp}.txt
    write_checkpoint -force $outputDir/post_route.dcp
    puts "Implementation Completed."
}

# --- BITSTREAM ---
if { $step == "bitstream" } {
    puts "--- BITSTREAM GENERATION STARTING ---"
    if {[file exists $outputDir/post_route.dcp]} {
        open_checkpoint $outputDir/post_route.dcp
    } else {
        puts "ERROR: post_route.dcp not found! You must run 'make impl' first."
        exit 1
    }
    write_bitstream -force $outputDir/${top_module}.bit
    puts "BITSTREAM READY: $outputDir/${top_module}.bit"
}

close_project
exit
