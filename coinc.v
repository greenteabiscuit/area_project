// EPM1270 WAVEFORM MEMORY
//
// NEW VERSION // WR/RD mode with flow control
//
// USB command -> LX1
//		7: normal
//		1: clear data
//		2: address counter clear
//		3: fixed pattern generation
//		4: idling (address pointer clear)
//		5: data transfer
//		6: initialization
//		8: data transfer length set (128)
//	   16: Threshold UP by +32
//    17: Threshold Down by -32
//    18: Threshold UP by +4
//		19: Threshold DOwn by -4
//		
// USB data <- UX ... ux1
//
// STATUS LED
//
//		lx1
// CLOCK 125MHz ADC CLOCK 62.5 MHz AD9214 10bits
// PHA Analysis MODE : 7  --- 8 samples averaging /peak detection

module coinc (RESD, CLK, C);
input RESD, CLK;
output [2:0] C;
reg [2:0] C;

always @(posedge CLK or negedge RESD)
	begin
		if (RESD == 1'b0) C <= 3'b000;
		else C <= C + 3'b001;
	end

endmodule



	// {{ALTERA_ARGS_BEGIN}} DO NOT REMOVE THIS LINE!
	
	// {{ALTERA_ARGS_END}} DO NOT REMOVE THIS LINE!
	// {{ALTERA_IO_BEGIN}} DO NOT REMOVE THIS LINE!
	// {{ALTERA_IO_END}} DO NOT REMOVE THIS LINE!f