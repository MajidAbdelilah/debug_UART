module get_n_gate#(
parameter pool_width = 32,
parameter n_of_gates = 1
)(
	input clk,
	input rst,
	input [pool_width-1:0] i_pool_lock, // 8'b11111110
	output reg [(32 * n_of_gates - 1):0] o_gates_idx,
	output reg o_job_done
);

	integer i;
	integer j;
	reg [n_of_gates-1:0] n_gates_lock = 0;
	reg [(pool_width >> 1)-1:0]index = 0;
	reg [31:0]gates_idx[(n_of_gates- 1 ):0];
	reg [(n_of_gates - 1):0] is_ready = 0;

	initial begin
		for(i = 0; i < (n_of_gates); i = i + 1) begin
			gates_idx[i] = {32{1'b1}};
		end
	end

	always@(posedge clk or posedge rst) begin
		if(rst) begin
			n_gates_lock <= 0;
			index <= 0;
			is_ready <= 0;
			for(i = 0; i < (n_of_gates); i = i + 1) begin
				gates_idx[i] <= {32{1'b1}};
			end
		end else begin
			if(!(is_ready ^ {n_of_gates{1'b1}}))
				o_job_done <= 1;

			for(j = 0; j < n_of_gates; j = j + 1) begin
				if( ~(!(gates_idx[j] ^ {32{1'b1}})) ) begin // if not equal to -1
					o_gates_idx[(32 * j)+:32] <= gates_idx[j][31:0];
					is_ready[j] <= 1;
				end
			end

			for(i = 0; i < (pool_width >> 1); i = i + 1) begin

				if(i_pool_lock[i * 2 + index[i]] & !index[i]) index[i] <= index[i] + 1'b1;
				else if(!i_pool_lock[i * 2 + index[i]]) begin
					
					for(j = 0; j < n_of_gates; j = j + 1) begin
						if(!n_gates_lock[j]) begin
							n_gates_lock[j] <= 1;
							if(!(gates_idx[j] ^ {32{1'b1}})) begin
								gates_idx[j] <= i * 2 + index[i];
							end
						end
					end
				end
				
			end
		end
	end

endmodule