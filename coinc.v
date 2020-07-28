module coinc(
	input [3:0] iIN,
	output reg [6:0] oOUT
);

	always @(*)
	begin
		case(iIN)
			4'b0000: oOUT <= 7'b1000000; //0
			4'b0001: oOUT <= 7'b1111001; //1
			4'b0010: oOUT <= 7'b0100100; //2
			4'b0011: oOUT <= 7'b0110000; //3
			4'b0100: oOUT <= 7'b0011001; //4
			4'b0101: oOUT <= 7'b0010010; //5
			4'b0110: oOUT <= 7'b0000010; //6
			4'b0111: oOUT <= 7'b1111000; //7
			4'b1000: oOUT <= 7'b0000000; //8
			4'b1001: oOUT <= 7'b0010000; //9
			default: oOUT <= 7'bxxxxxxx;
		endcase
	end

endmodule