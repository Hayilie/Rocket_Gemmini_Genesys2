
# 1. AYARLAR VE KLASORLER
set timestamp [clock format [clock seconds] -format %Y%m%d_%H%M%S]
set part "xc7k325tffg900-2"
set top_module "FPGA_Top"
set outputDir "./outputs"
set reportDir "./reports"
set srcDir    "./src"

file mkdir $outputDir
file mkdir $reportDir

# 2. PROJE OLUŞTURMA (IP yonetimi icin gecici fiziksel proje)
create_project -force managed_proj $outputDir/managed_proj -part $part
set_property target_language Verilog [current_project]

# ------------------------------------------------------------------------------
# 3. KAYNAKLARI EKLEME 
# ------------------------------------------------------------------------------
puts "--- Kaynaklar Ekleniyor ---"

# 3.1. RTL Dosyalari (.v, .sv)
set rtl_files [glob -nocomplain $srcDir/rtl/*.v $srcDir/rtl/*.sv]
if {[llength $rtl_files] > 0} {
    add_files $rtl_files
    puts "[llength $rtl_files] adet yerel RTL dosyasi eklendi."
} else {
    puts "HATA: src/rtl icinde donanim dosyasi bulunamadi!"
    exit 1
}

# 3.2. IP Dosyalari (.xci)
set ip_files [glob -nocomplain $srcDir/ip/**/*.xci $srcDir/ip/*.xci]
if {[llength $ip_files] > 0} {
    puts "IP'ler yukleniyor ve guncelleniyor..."
    import_ip $ip_files
    upgrade_ip [get_ips]
    generate_target all [get_ips]
    export_ip_user_files -of_objects [get_ips] -no_script -sync -force -quiet
    create_ip_run [get_ips]
    launch_runs [get_runs *_synth_1]
    foreach run [get_runs *_synth_1] { wait_on_run $run }
}

# 3.3. Kisitlamalar (.xdc)
# Klasor adini 'constraints' olarak duzelttik!
set xdc_files [glob -nocomplain $srcDir/constraints/*.xdc]

if {[llength $xdc_files] > 0} {
    read_xdc $xdc_files
    puts "[llength $xdc_files] adet kisitlama (XDC) eklendi ve OKUNDU."
} else {
    puts "KRITIK UYARI: src/constraints/ icinde XDC dosyasi bulunamadi!"
}

# ------------------------------------------------------------------------------
# 4. İŞLEM ADIMLARI
# ------------------------------------------------------------------------------
set step [lindex $argv 0]

# --- SENTEZ ---
if { $step == "synth" } {
    puts "--- SENTEZ BASLIYOR ---"
    synth_design -top $top_module -part $part
    write_checkpoint -force $outputDir/post_synth.dcp
    report_utilization -file $reportDir/utilization_synth_${timestamp}.txt
    report_timing_summary -file $reportDir/timing_synth_${timestamp}.txt
    puts "Sentez Tamamlandi."
}

# --- SENTEZ ZAMANLAMA RAPORU (Sonradan Alma) ---
if { $step == "synth_timing" } {
    puts "--- SENTEZ ZAMANLAMA RAPORU ALINIYOR ---"
    if {[file exists $outputDir/post_synth.dcp]} {
        open_checkpoint $outputDir/post_synth.dcp
        report_timing_summary -file $reportDir/timing_synth_${timestamp}.txt
        puts "RAPOR HAZIR: $reportDir/timing_synth_${timestamp}.txt"
    } else {
        puts "HATA: post_synth.dcp bulunamadi! Once 'make synth' yapmalisiniz."
        exit 1
    }
}

# --- IMPLEMENTASYON ---
if { $step == "impl" } {
    puts "--- IMPLEMENTASYON BASLIYOR ---"
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
    puts "Implementasyon Tamamlandi."
}

# --- BITSTREAM ---
if { $step == "bitstream" } {
    puts "--- BITSTREAM URETIMI BASLIYOR ---"
    if {[file exists $outputDir/post_route.dcp]} {
        open_checkpoint $outputDir/post_route.dcp
    } else {
        puts "HATA: post_route.dcp bulunamadi! Once 'make impl' yapmalisiniz."
        exit 1
    }
    write_bitstream -force $outputDir/${top_module}.bit
    puts "BITSTREAM HAZIR: $outputDir/${top_module}.bit"
}

close_project
exit
