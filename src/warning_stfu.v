module warning_stfu(
	input                        clk,
	input                        rst,
	input                        uart_rx,

	output                       uart_tx,
	output                       sample_clk,
	output                       [7:0] led
	);
localparam size = 32;
localparam Pog_width = 8;
localparam n_of_gates = 1;
	reg [((size * 8) - 1):0] data_o = 0;
	wire [((10 * 8) - 1):0] data_o_int;

	wire [((size * 8) - 1):0] data_i;
	reg trigger_o = 1;
	wire trigger_i;
	wire data_o_ready;
	reg data_i_ready = 1'b1;
	

	wire [ (Pog_width - 1) :0]i_not;

	wire [ (Pog_width - 1) :0]i_or_0;
	wire [ (Pog_width - 1) :0]i_or_1;

	wire [ (Pog_width - 1) :0]i_and_0;
	wire [ (Pog_width - 1) :0]i_and_1;

	wire [ (Pog_width - 1) :0]o_not;
	wire [ (Pog_width - 1) :0]o_or;
	wire [ (Pog_width - 1) :0]o_and;

	wire [ (Pog_width - 1) :0]o_not_lock;
	wire [ (Pog_width - 1) :0]o_or_lock;
	wire [ (Pog_width - 1) :0]o_and_lock;
	wire [(32 * n_of_gates - 1):0] o_gates_idx;
	wire o_job_done;
	reg rst_data_o_int = 0;

str_to_binary#(
	.width(Pog_width)
) str_b(
	.clk(clk),
	.str(data_i[0+:Pog_width*8]),
	.o_binary(o_not_lock)
);

integer_to_str int_to_str(
	.clk(clk),
	.input_int(o_not_lock),
	.rst(rst_data_o_int),
	.str(data_o_int)
);


	always@(posedge clk) begin
		if(trigger_o & data_o_ready) begin
			trigger_o <= 1'b0;
			data_i_ready <= 1'b1;
			rst_data_o_int <= 1'b0; 
		end else if (data_i_ready & trigger_i) begin
			data_o <= {16'h0d0a, data_o_int, 16'h0d0a};
			trigger_o <= 1'b1;
			data_i_ready <= 1'b0;
			rst_data_o_int <= 1'b1;
		end
	end


get_n_gate#(.pool_width(Pog_width), .n_of_gates(1)) test(
	.clk(clk),
	.rst(data_o_ready),
	.i_pool_lock(o_not_lock),
	.o_gates_idx(o_gates_idx),
	.o_job_done(o_job_done)
);


pool_of_gates#(.width(Pog_width)) Pog(
	.i_not(i_not),

	.i_or_0(i_or_0),
	.i_or_1(i_or_1),

	.i_and_0(i_and_0),
	.i_and_1(i_and_1),

	.o_not(o_not),
	.o_or(o_or),
	.o_and(o_and)
);


uart_test#(.size(size)) debug_uart(
	.clk(clk),
	.rst(rst),
	.uart_rx(uart_rx),
	
	.data_o(data_o), // 0x0 markes the end of the string, this is outputed to pc.
	.data_o_trigger(trigger_o),
	.data_o_ready(data_o_ready),

	.data_i(data_i), // 0x0 markes the end of the string, this is inputed from pc.
	.data_i_trigger(trigger_i),
	.data_i_ready(data_i_ready),

	.uart_tx(uart_tx),
    .sample_clk(sample_clk),
    .led(led)
);

endmodule

module integer_to_str(
	input clk,
	input rst,
	input [31:0] input_int,
	output reg [(10 * 8 - 1):0] str
);
	reg [3:0] index = 0;
	integer int_tmp;
//	reg [31:0] int_tmp2;


	initial begin
		int_tmp = input_int;
	end

	always@(posedge clk) begin
		if(rst) begin
			str = 0;
			index <= 4'b0; 
//			int_tmp <= input_int; 
		end else if(int_tmp) begin
			str[(index*8)+:8] <= (int_tmp % 32'd10) + 32'd48;
			int_tmp <= int_tmp / 32'd10;

			index <= index + 4'b1;
		end
 else begin 
			index <= 4'b0;
			int_tmp <= input_int;
			if(!input_int) begin
				str <= 8'd48;
			end
		end
	end
endmodule

module str_to_binary#(
	parameter width = 8
)(
	input clk,
	input [(width * 8)-1:0] str,
	output reg [width-1:0] o_binary
);

	integer index = 0;

	always@(posedge clk) begin
		if(index < width) begin
			o_binary[index] = str[(index)*8+:8] - 8'd48;
			index = index + 1;
		end else begin 
			index <= 0;
		end
	end


endmodule