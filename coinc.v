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

module coinc (ADX,DX, CLK, CLK1, CEX, CEY, CE1, CE2, BHE, BLE, TRIG, LEDP, DUMMY, WMODE, STAT,RD,WR,USBX,RXF,TXE,WAVEX,WFSTAT,ADCLK, PWDN,DFS,OVR,DACOUT,DCLK,SWIN0,SWIN1,SWIN2);
input [9:0]WAVEX;
inout [7:0] USBX;
output [19:0]ADX;
inout [15:0] DX;
input CLK, CLK1;
input [3:0]DUMMY;
input WMODE;
output CEX,CEY; // OutputEnable WriteEnable
output CE1,CE2,BHE,BLE; // ChipEnable1&2, Bit High Enable, Bit Low Enable
output TRIG; // Triggered signal
output LEDP;
output [3:0] STAT; // LED OUTPUT
output [7:0] WFSTAT; // WAVEFORM DATA
output RD,WR;
input RXF,TXE,OVR;
output ADCLK,PWDN,DFS;
output [9:0]DACOUT;
output DCLK;
input SWIN0,SWIN1,SWIN2;
reg wall;
reg [9:0] dacoutreg;
reg daclock;
reg [19:0] adrs;
reg [19:0] adrs1;
reg [19:0] adrsrd;
reg [23:0] sum; // to be compared with the discrimination level for the ID
reg [23:0] wavg0,wavg1;
reg [9:0] wlld; // Lower Level Discriminator
reg [9:0] w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16,w17,w18,w19;
reg [9:0] w20,w21,w22,w23,w24,w25,w26,w27,w28,w29,w30,w31,w32,w33,w34,w35,w36,w37,w38,w39;
reg [9:0] w40;
reg [7:0] translen;
reg [15:0] dix;
reg [7:0] dox;
reg [15:0] dx0,dx1;

reg [7:0] cnt; // was 25:0 before  
reg [12:0] cntmask; // to skip data
reg [4:0] cntusb;
reg [17:0]cnt1; // changed to 1/4   to utilize quarter of the whole memory for each
reg [17:0]cnt_round;
reg [19:0]cnt2; // for clear command
reg [15:0] wd;
reg [7:0] ux1;
reg [7:0] lx1,lx2,lx3,lx4;
reg [3:0] lstat;
reg [2:0] wreq;
reg [9:0] waved; // waveform data
reg ocx,ocy,xtrig,outp,wm,renewed;
reg ocr; // readmode/writemode & normalmode
reg cea,ceb,bh,bl;
reg wr0,rd0;
reg adc;
reg ledind; // external indicator
reg [7:0] adcl;
reg [12:0] timer;
reg [11:0] i; // for loop 0~4095 
reg [7:0] j; // for loop 0~255 
reg [7:0] k; 
reg [1:0] even;
reg [7:0] phase;
reg [9:0] round; // length of reference data
//reg [7:0] wdata;

always @(posedge RD) begin
lx2 <=USBX;
//waved <=waved+1;
end

always @(posedge CLK) begin
	// Generate ADC clock
	if(adcl<1)begin adcl<=1;end else begin adcl<=0; end
	if(daclock<1)begin daclock<=1;end else begin daclock<=0; end


	if(adc==0 && adcl==0) begin
	// FADC DATA REFRESH
		w40<=w39;w39<=w38;w38<=w37;w37<=w36;w36<=w35;w35<=w34;w34<=w33;w33<=w32;w32<=w31;w31<=w30;
		w30<=w29;w29<=w28;w28<=w27;w27<=w26;w26<=w25;w25<=w24;w24<=w23;w23<=w22;w22<=w21;w21<=w20;w20<=w19;
		w19<=w18;w18<=w17;w17<=w16;w16<=w15;w15<=w14;w14<=w13;w13<=w12;w12<=w11;w11<=w10;
		w10<=w9;w9<=w8;w8<=w7;w7<=w6;w6<=w5;w5<=w4;w4<=w3;w3<=w2;w2<=w1;w1<=w0;
		wavg1<=(w39+w38+w37+w36+w35+w34+w33+w32);
		wavg0<=( w7+ w6+ w5+ w4+ w3+ w2+ w1+ w0);
		w0<=WAVEX; 
	end
	else if(adcl==1)begin 
		adc<=1-adc;			// ADC Clock = 62.5MHz
	end
	//overrides the command input
	if (SWIN0==0) begin waved<=255; end 
	// CHECK USB COMMAND and read into lx1
	else if (RXF==0) begin	// RXF LOW if FIFO buffer of FT245 from PC is available 
		if (cntusb==0)begin	// counter clock to manipulate the data read
			cntusb<=cntusb+1;			// even if data is already read, some delay might exist
			rd0<=0; // read request
		end
		else if(cntusb==5)begin
			rd0<=1; 
			cntusb<=cntusb+1;
			lx1<=USBX; // read from FIFO after 50ns of rd signal
		end
		else if(cntusb==7)begin
			cntusb<=0; 
		end
		else begin
			cntusb<=cntusb+1; // wait until the cnt becomes zero.
		end
	end // RXF==0

	// READ transfer len set command #8
	else if (lx1==8) begin
		lstat<=lx1;
		rd0<=1; wr0<=0;
		translen <=128; cnt<=0; cntusb<=0;
	end

	else if (lx1 ==7) begin //**** NORMAL MODE #7
		lstat<=2;
		rd0<=1; wr0<=0;
		renewed<=0;

	end //****

	// CLEAR DATA COMMAND #1
	else if (lx1==1) begin
		rd0<=1; wr0<=0;
		cntusb<=0;
		lstat<=lx1;
		ledind<=1; //indicator ON
		if (cnt==0)begin
			cnt<=cnt+1;
			adrs<=cnt2;
		end
		else if(cnt==1)begin
			cnt<=cnt+1;
			ocx<=1;ocy<=1; // high-Z read
			dix<=0;
		end
		else if(cnt==2)begin
			cnt<=cnt+1;
			ocx<=1; ocy<=0;// ^OE ocx=1: high Z , ^WE ocy=0: write mode
			// write data 
		end
		else if(cnt>2)begin
			//	ocx<=0; ocy<=1;// ^OE ocx=0: output enable , ^WE ocy=1: read mode
			cnt2<=cnt2+1;	// adress increment
			cnt<=0;
		end
		else begin
			cnt<=cnt+1; // wait until the cnt becomes zero.
		end
		wlld<=540; // trigger level initialization ~30/512 6% of full scale

	end //**** LX=1

	// ADDRESS COUNTER CLEAR -> #2
	else if (lx1==2) begin
		lstat<=lx1;
		rd0<=1; wr0<=0;
		cntusb<=0;
		renewed<=0;
		adrs<=0;
		adrsrd<=0;
		cnt1<=0;
		cnt<=0;
		ocx<=0; ocy<=1;
		wd<=0;
		cea<=0; ceb<=1;
		bh<=0; bl<=0;
		wreq<=0; // for measurement
		ledind<=0; //indicator OFF
		waved<=0; // DEBUG DATA LED CLEAR
		cntmask<=0; // for waveform record
	end

	// READ INITIALIZATION command #4
	else if (lx1==4) begin
		lstat<=lx1;
		rd0<=1; wr0<=0;
		cntusb<=0;
		ocr<=1; // slave mode address is set to the USB read
		adrsrd<=0; translen<=0; adrs<=0; cnt<=0;cnt1<=0;wreq<=0; // for measurement
		//   cntmask<=0; // skip mask
		cntmask<=8191;
	end



	////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////
	// Waveform measurement #3
	else if(lx1==3)begin	
		lstat<=lx1;
		rd0<=1; wr0<=0;
		cntusb<=0;
		ledind<=1; // LED INDICATOR ON
		timer<=timer+1;
		// record at every 8 ns x 8192 = 64 us .. 16kHz sampling
		if(timer==8191)begin
			adrs<=cnt1;
			ocx<=1;ocy<=0; // write mode
			dix<=wavg0/8 - 100;
			//wall;
			waved<=w40/16; // not display data 
			cnt1<=cnt1+1;
			cntmask<=cntmask-1;
			timer<=0;
		end
		//end
	end
		///// Getting the reference data
	else if (lx1==16 && wreq==0) begin
		lstat<=7;
		rd0<=1; wr0<=0;
		cntusb<=0;
		ledind<=1; // LED INDICATOR ON
		timer<=timer+1;
		// record at every 8 ns x 8192 = 64 us .. 16kHz sampling
		if(timer==8191)begin
			adrs<=cnt1+262144; // put data in the 2nd part of the quad memories
			ocx<=1;ocy<=0; // write mode
			dix<=wavg0/8;
			//wall;
			waved<=w40/16; // not display data 
			cnt1<=cnt1+1;
			cntmask<=cntmask-1;
			timer<=0;
		end

	end
	// DAC OUTPUT
	else if (lx1==18 && wreq==0) begin
		lstat<=6;
		rd0<=1; 
		cntusb<=0;
		ocx<=0; ocy<=1;// ^OE ocx=0: output enable , ^WE ocy=1: read mode
		cntusb<=0;
		ledind<=1; // LED INDICATOR ON
		dacoutreg<=DX;
		waved<=DX/16;

		//if (adc==1)begin

		if(cntmask>0) begin
			adrs<=cnt1;
			cnt1<=cnt1+1;

			cntmask<=cntmask-1;
		end
		//end
	 
	end
	// 2020-06-30 change so that matching is 18

	
	else if (lx1==17 && wreq==0) begin
		cea <= 0; ceb <= 1; bh <= 0; bl <= 0;
		if(cnt==0) begin 
			ocx <= 0; ocy <= 1;
			adrs <= cnt1;
			cnt <= cnt+1;
		end
		else if(cnt==1) begin
			//dx0 <= adrs + 300;
			cnt<=cnt+1;
			dx0 <= DX + 300;
		end
		else if(cnt==2) begin
			cnt <= cnt + 1;
			ocx <= 1; ocy <= 1;
			adrs<=cnt1;
			dix <= dx0;
			cnt1<=cnt1+1;
		end
		else if(cnt==3) begin
			cnt <= cnt + 1;
			ocx<=1;ocy<=0;
		end
		else if (cnt==4) begin
			cnt <= cnt + 1;
			ocx <= 0;ocy <= 1;
		end

		else if (cnt == 5) begin
			cnt <= 0;
		end
		else begin
			cnt <= cnt + 1;
		end

	end
	else if (lx1==19 && wreq==0) begin
		adrs<=262144; // reference area 
	end
	// IDLING #6 
	else if (lx1==6) begin
		lstat<=lx1;
		rd0<=1; wr0<=0;
		cntusb<=0;
		ocx<=0; ocy<=1;// ^OE ocx=0: output enable , ^WE ocy=1: read mode
		renewed <=0;
		cnt<=0;
		cea<=0; ceb<=1;
		bh<=0; bl<=0;
		wd<=0;
		wr0<=1;
		rd0<=1;
	end


	// READ FIFO DATA by 128 command #5
	// memory read, memory load
	else if (lx1==5 && translen>0 && TXE==0)begin
		lstat<=lx1;
		// This routine controls wr0

		if (cnt==0)begin
			wr0<=1;		// T7 must be > 50ns
			dox<=DX;
			cnt<=cnt+1;
		end
		else if(cnt==4)begin //5
			wr0<=0;					// T8 must be > 50ns
			cnt<=cnt+1;
			// status check
			//if (dox==33) begin lstat<=1; end else if (dox==97) begin lstat<=7; end else begin lstat<=0; end
		end
		else if (cnt==11)begin		// T12 must be >80ns 11
			//wr0<=1;
			dox<=(DX>>8);
			cnt<=cnt+1;
		end
		else if(cnt==12)begin //12
			wr0<=1;					// T7 must be > 50ns
			cnt<=cnt+1;
		end
		else if(cnt==17)begin //17
			wr0<=0;					// T7 must be > 50ns 
			cnt<=cnt+1;
		end
		else if(cnt==23)begin // 23
			adrs<=adrs+1;
			cnt<=cnt+1; 
		end
		else if(cnt==24)begin //24
			translen<=translen-2;	// repeat until 128 bytes are tranfered to the FIFO
			cnt<=0; 				// T8 must be > 50ns
		end
		else begin
			cnt<=cnt+1; // wait until the cnt becomes zero.
		end
	end

	else begin
		cntusb<=0;
		// read from mode below
		ocx<=0;ocy<=1; //ocx is OE, ocy is WE;
		cea<=0; ceb<=1;
		bh<=0; bl<=0;
		rd0<=1; wr0<=0;
	end

end

assign USBX = (wr0)?dox:8'bz;
assign ADX =adrs;
assign CEX = ocx;
assign CEY = ocy; // WE
assign TRIG = ledind; // INDICATOR (Measurement ON)
assign LEDP = xtrig;
assign DX = (1-ocy)?dix:16'bz;
assign CE1 = cea;
assign CE2 = ceb;
assign BHE = bh;
assign BLE = bl;
assign STAT = lstat;
assign WR = wr0;
assign RD = rd0;
assign WFSTAT =waved;
assign ADCLK =adc;
//assign ADCLK = CLK;	
assign DACOUT= dacoutreg;
assign DCLK =daclock;

endmodule



	// {{ALTERA_ARGS_BEGIN}} DO NOT REMOVE THIS LINE!
	
	// {{ALTERA_ARGS_END}} DO NOT REMOVE THIS LINE!
	// {{ALTERA_IO_BEGIN}} DO NOT REMOVE THIS LINE!
	// {{ALTERA_IO_END}} DO NOT REMOVE THIS LINE!f