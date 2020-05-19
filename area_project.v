module area_project(
	output reg lamp1, output lamp2, output lamp3, output lamp4,
	output lamp5, output lamp6, output lamp7, output lamp8,
	output lamp9, output lamp10, output lamp11, input clock
);


assign lamp2 = 1;
assign lamp3 = 1;
assign lamp4 = 1;
assign lamp5 = 1;
assign lamp6 = 1;
assign lamp7 = 1;
assign lamp8 = 1;
assign lamp9 = 1;
assign lamp10 = 1;
assign lamp11 = 1;

reg [1:0] count;

always @(posedge clock)
	begin
		count <= count + 1;
		lamp1 = 1;
	end

endmodule