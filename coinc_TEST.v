module coinc_TEST;

reg [3:0] iIN;
wire [6:0] oOUT;

parameter STEP = 100;

coinc coinc(iIN, oOUT);

initial begin
				iIN = 4'b0000;
	#STEP    iIN = 4'b0001;
	#STEP    iIN = 4'b0010;
	#STEP    iIN = 4'b0011;
	#STEP    iIN = 4'b0100;
	#STEP    $stop;
end

endmodule