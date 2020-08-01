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

module coinc (CLK, DX, cea, ceb, bh, bl, ocx, ocy, cnt);
inout [15:0] DX;
input CLK;

reg [17:0]cnt1;
output cea, ceb, bh, bl;
reg cea, ceb, bh, bl;
output ocx, ocy;
reg ocx, ocy;
reg [19:0] adrs;
input [3:0] cnt;
reg [15:0] dx0, dx1;
reg [15:0] dix;

always @(posedge CLK)
	begin
		cea <= 0;
		ceb <= 1;
		bh <= 0;
		bl <= 0;
		ocx <= 0;
		ocy <= 1;
		adrs <= cnt1;
		if(cnt==1'b0) begin
			ocx <= 0;
		end
		else if(cnt==1) begin
			dx0 <= DX + 300;
		end
		else if(cnt==2) begin
			ocx <= 1; ocy <= 1;
		end
		else if(cnt==3) begin
			ocx<=1;ocy<=0;
		end
		else if (cnt==4) begin
			ocx <= 0;ocy <= 1;
		end
	end

endmodule



	// {{ALTERA_ARGS_BEGIN}} DO NOT REMOVE THIS LINE!
	
	// {{ALTERA_ARGS_END}} DO NOT REMOVE THIS LINE!
	// {{ALTERA_IO_BEGIN}} DO NOT REMOVE THIS LINE!
	// {{ALTERA_IO_END}} DO NOT REMOVE THIS LINE!f