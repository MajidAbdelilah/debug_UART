`define KEY 
module uart_test(
	input                        clk,
	input                        rst,
	input                        uart_rx,
	
	input						 [((512 * 8) - 1):0] data_o, // 0x0 markes the end of the string, this is outputed to pc.
	input						 data_o_trigger, // output if high;
	output						 [((512 * 8) - 1):0] data_i, // 0x0 markes the end of the string, this is inputed from pc.

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

parameter                        CLK_FRE  = 50;//MHz
parameter                        UART_FRE = 115200;//baudrate
localparam                       IDLE =  0;
localparam                       SEND =  1;   //send 
localparam                       RECV = 2;
reg[7:0]                         tx_data;
reg                              tx_data_valid;
wire                             tx_data_ready;
wire[7:0]                        rx_data;
wire                             rx_data_valid;
reg                              rx_data_ready;
reg[3:0]                         state;
reg[9:0] 						 data_o_cnt = 512;

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
        IDLE: 
				
			begin
			 	state <= RECV;
        	end
		RECV: begin
			rx_data_ready <= 1'b1;
			
			if(rx_data_valid) begin
				tx_data_valid <= 1'b1;
				tx_data <= rx_data;
			end else if(tx_data_valid & tx_data_ready) tx_data_valid <= 8'b0;
			else  state <= SEND;
        end
        SEND: begin
			
//			if( & ) begin
//				if()
//				tx_data_valid <= 1'b1;
//				tx_data <= data_o[(8 * data_o_cnt)+:8];
//				data_o_cnt = data_o_cnt + 10'b1;
//			end else begin
//				
//				state <= RECV;
//			end

			tx_data <= data_o[(8 * data_o_cnt)+:8];

			if(tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && data_o_cnt > 0)//Send 12 bytes data
			begin
				data_o_cnt <= data_o_cnt - 10'd1; //Send data counter
			end
			else if(tx_data_valid && tx_data_ready)//last byte sent is complete
			begin
				data_o_cnt <= 10'd512;
				tx_data_valid <= 1'b0;
				state <= IDLE;
			end
			else if(~tx_data_valid)
			begin
				tx_data_valid <= 1'b1;
			end

		end
		default: state <= IDLE;
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
