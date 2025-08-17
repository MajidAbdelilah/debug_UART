`define KEY 
module uart_test#(parameter size = 32)(
	input                        clk,
	input                        rst,
	input                        uart_rx,

	input  						 [((size * 8) - 1):0] data_o, // 0x0 markes the end of the string, this is outputed to pc.
	input						 data_o_trigger, // output if high;
	output reg						 data_o_ready,
	output reg					 [((size * 8) - 1):0] data_i, // 0x0 markes the end of the string, this is inputed from pc.
	output reg					 data_i_trigger,
	input						 data_i_ready,
	output                       uart_tx,
    output                       sample_clk,
    output                       [7:0] led
);
wire rst_n;

`ifdef KEY
assign rst_n = ~rst;
`else
assign rst_n = 1;
`endif

//internal OSC for GAO sample_clk
OSCA uut(
.OSCOUT(sample_clk),//4.2MHz
.OSCEN(1'b1)
);
defparam uut.FREQ_DIV=50;//210MHz/50=4.2Hz

localparam                       CLK_FRE  = 50;//MHz
localparam                       UART_FRE = 115200;//baudrate
localparam                       IDLE =  0;
localparam                       SEND =  1;   //send 
localparam                       RECV = 2;
localparam                       PREIDLE = 3;

reg[7:0]                         tx_data;
reg                              tx_data_valid;
wire                             tx_data_ready;
wire[7:0]                        rx_data;
wire                             rx_data_valid;
reg                              rx_data_ready;
reg[3:0]                         state;
reg[9:0] 						 data_o_cnt = 0;
reg[9:0] 						 data_i_cnt = 0;
reg 							 reset_i_count;
reg 							 reset_o_count;



    assign led = ~rx_data;

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
	begin
		tx_data <= 8'd0;
		state <= IDLE;
		tx_data_valid <= 1'b0;
		data_o_cnt <= 0;
	end
	else begin
    case(state)
		PREIDLE:
		begin
			state <= IDLE;
		end
        IDLE: 
			begin
				tx_data_valid <= 1'b0;
				rx_data_ready <= 1'b0;
				data_o_ready <= 1'b0;
			 	if (data_o_trigger) begin
					tx_data_valid <= 1'b1;
					state <= SEND;
					if (data_o_ready) begin
					data_o_ready <= 1'b0;
					end
				end else if (data_i_ready) begin
					rx_data_ready <= 1'b1;
					state <= RECV;
					if (data_i_trigger) begin
						data_i_trigger <= 0;
						data_i <= 0;
					end
				end
				
        	end
		RECV: 
		begin
			if(rx_data_ready & rx_data_valid) begin
				data_i[((data_i_cnt) * 8)+:8] <= rx_data;
				data_i_cnt <= data_i_cnt + 10'b1;
				tx_data <= rx_data;
				tx_data_valid <= 1'b1;
				if(!(rx_data ^ 8'h0D)) begin
//					data_i <= data_i << (2 * 8);
					data_i[(((data_i_cnt) ) * 8)+:16] <= 16'h0a0d;
//					data_i[(0)+:16] <= 16'h0d0a;
					data_i_trigger <= 1'b1;
					data_i_cnt <= 10'b0;
					tx_data_valid <= 1'b0;
				state <= IDLE;
				end
			end else begin
				state <= PREIDLE;
			end
			rx_data_ready <= 1'b0;
		end
		SEND:
		begin
			if (tx_data_ready & tx_data_valid & data_o_cnt < (size)) begin
				tx_data <= data_o[((data_o_cnt) * 8)+:8];
				data_o_cnt <= data_o_cnt + 10'b1;
			end else if (tx_data_ready & tx_data_valid) begin
				state <= PREIDLE;

				tx_data_valid <= 1'b0;
				data_o_cnt <= 10'b0;
				data_o_ready <= 1'b1;
			end
		end
    endcase
    end
    
end


uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_rx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.rx_data                    (rx_data                  ),
	.rx_data_valid              (rx_data_valid            ),
	.rx_data_ready              (rx_data_ready            ),
	.rx_pin                     (uart_rx                  )
);

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (uart_tx                  )
);
endmodule
