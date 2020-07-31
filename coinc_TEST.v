module coinc_TEST;

reg RESD, CLK;
wire [2:0] C;

coinc tcounter4 (RESD, CLK, C);


initial
	begin
		CLK = 0;
		forever #50 CLK = !CLK;
	end

initial
	begin
		RESD = 1;
		#10 RESD = 0;
		#20 RESD = 1;
	end

initial
	$monitor (" %3d, %d, %d, %d", $stime, RESD, CLK, C);

endmodule