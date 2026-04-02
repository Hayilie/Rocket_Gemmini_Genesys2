module FPGA_Top (

    input  sys_clk_p,
    input  sys_clk_n,
    
    input  reset_io,    
    input  uart_0_rxd,  
    output uart_0_txd,  
    
    input  jtag_tck,
    input  jtag_tms,
    input  jtag_tdi,
    output jtag_tdo,
    
    output status_led   
);

    wire clk_inner;


    clk_wiz_0 genesystimer (
        .clk_in1_p (sys_clk_p),
        .clk_in1_n (sys_clk_n),
        .clk_out1  (clk_inner)
    );

    // Periyodik Yanan Led
    reg [25:0] led_counter; 
    always @(posedge clk_inner) begin
        led_counter <= led_counter + 1;
    end
    assign status_led = led_counter[25]; 


    ChipTop chiptop (
        .clock_uncore (clk_inner),
        .reset_io     (reset_io), 
        
        .uart_0_rxd   (uart_0_rxd),
        .uart_0_txd   (uart_0_txd),
        
        
        .jtag_TCK     (jtag_tck),
        .jtag_TMS     (jtag_tms),
        .jtag_TDI     (jtag_tdi),
        .jtag_TDO     (jtag_tdo)
        
     
    );

endmodule