module pool_of_gates#(
	parameter width = 32
)(
	input [ (width - 1) :0]i_not,

	input [ (width - 1) :0]i_or_0,
	input [ (width - 1) :0]i_or_1,

	input [ (width - 1) :0]i_and_0,
	input [ (width - 1) :0]i_and_1,

	output [ (width - 1) :0]o_not,
	output [ (width - 1) :0]o_or,
	output [ (width - 1) :0]o_and
);

assign o_not = ~i_not;

assign o_or = i_or_0 | i_or_1;

assign o_and = i_and_0 | i_and_1;

endmodule