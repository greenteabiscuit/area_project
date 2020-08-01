module coinc_TEST;

reg CLK;
wire [15:0] DX;
wire cea, ceb, bh, bl, ocx, ocy;
reg [3:0] cnt;

coinc tcounter4 (CLK, DX, cea, ceb, bh, bl, ocx, ocy, cnt);


initial
	begin
		CLK = 0;
		forever #50 CLK = !CLK;
	end

initial
	begin
		cnt = 0;
		#50 cnt = 1;
		#50 cnt = 2;
		#50 cnt = 3;
		#50 cnt = 4;
		#50 cnt = 0;
		#50 cnt = 1;
		#50 cnt = 2;
		#50 cnt = 3;
		#50 cnt = 4;
	end
	
initial
	$monitor ("%3d, %d, %d", $stime, CLK, ocx);

endmodule