module warning_stfu(
	input                        clk,
	input                        rst,
	input                        uart_rx,

	output                       uart_tx,
    output                       sample_clk,
    output                       [7:0] led
	);

	wire [((512 * 8) - 1):0] data_o = {"hello abdelilah majid", 16'h0d0a};
	wire [((512 * 8) - 1):0] data_i;
	wire trigger = 1;

uart_test debug_uart(
	clk,
	rst,
	uart_rx,
	
	data_o, // 0x0 markes the end of the string, this is outputed to pc.
	trigger,
	data_i, // 0x0 markes the end of the string, this is inputed from pc.

	uart_tx,
    sample_clk,
    led
);

endmodule