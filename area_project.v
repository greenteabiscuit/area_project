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

reg [2:0] count;
integer i;

initial begin
	for (i = 0; i < 4000; i = i + 1) begin
		if (i > 4002)
			lamp1 <= 0;
		else
			lamp1 <= 1;
	end
end

endmodule