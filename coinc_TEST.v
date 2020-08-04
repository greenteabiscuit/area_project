module coinc_TEST;

reg clk, rst;
reg [31:0] pc;
wire [31:0] ins;

initial
	begin
		clk = 0; forever #50 clk = !clk;
	end

initial
	begin
				rst = 1;
		#10	rst = 0;
		#20	rst = 1;
	end

always @(negedge rst or posedge clk)
	begin
		if (rst == 0) pc <= 0;
		else if (clk == 1) pc <= pc + 1;
	end


fetch fetch_body (pc, ins);
endmodule