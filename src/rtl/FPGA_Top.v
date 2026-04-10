module FPGA_Top (
    // Differential System Clock Inputs (Genesys2 200MHz)
    input  sys_clk_p,
    input  sys_clk_n,
    
    // External System Reset and UART IO
    input  reset_io,    
    input  uart_0_rxd,  
    output uart_0_txd,  
    
    // JTAG Interface for Debugging
    input  jtag_tck,
    input  jtag_tms,
    input  jtag_tdi,
    output jtag_tdo,
    
    // Diagnostic Output
    output status_led   
);

    // Internal Signal Declarations
    wire clk_inner;     // Main SoC clock (25 MHz)

    // Clock Wizard Instance
    // Generates 25MHz from 200MHz Differential Input
    // Note: reset and locked signals are intentionally disabled
    clk_wiz_0 genesystimer (
        .clk_in1_p (sys_clk_p),
        .clk_in1_n (sys_clk_n),
        .clk_out1  (clk_inner)
    );

    // Heartbeat LED Logic
    // Periodic counter to visually verify clock operation
    reg [25:0] led_counter; 
    always @(posedge clk_inner) begin
        led_counter <= led_counter + 1;
    end
    assign status_led = led_counter[25]; 

    // SoC Top Level Instance (Rocket Chip + Gemmini)
    ChipTop chiptop (
        .clock_uncore (clk_inner),
        .reset_io     (reset_io), // Directly connected to external button
        
        .uart_0_rxd   (uart_0_rxd),
        .uart_0_txd   (uart_0_txd),
        
        .jtag_TCK     (jtag_tck),
        .jtag_TMS     (jtag_tms),
        .jtag_TDI     (jtag_tdi),
        .jtag_TDO     (jtag_tdo)
    );

endmodule
