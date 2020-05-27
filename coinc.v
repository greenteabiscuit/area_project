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
module coinc (
	ADX,DX, CLK, CLK1, CEX, CEY, CE1, CE2, BHE, BLE,
	TRIG, LEDP, DUMMY, WMODE, STAT,RD,WR,USBX,RXF,TXE,
	WAVEX,WFSTAT,ADCLK, PWDN,DFS,OVR,DACOUT,DCLK, INSTATUS, LASTLAMP);
	
input INSTATUS; // should be able to receive button input
output LASTLAMP;

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
output [9:0] WFSTAT; // WAVEFORM DATA
output RD,WR;
input RXF,TXE,OVR;
output ADCLK, DFS;
output PWDN = 0;
output [9:0]DACOUT;
output DCLK;
reg wall;
reg [9:0] dacoutreg;
reg daclock;
reg [19:0] adrs;
reg [19:0] adrs1;
reg [19:0] adrsrd;
reg [23:0] wsum,wavp;
reg [23:0] wavg,wavg0,wavg1;
reg [9:0] wlld; // Lower Level Discriminator
reg [9:0] w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16,w17,w18,w19;
reg [9:0] w20,w21,w22,w23,w24,w25,w26,w27,w28,w29,w30,w31,w32,w33,w34,w35,w36,w37,w38,w39;
//reg [7:0] w40,w41,w42,w43,w44,w45,w46,w47,w48,w49,w50,w51,w52,w53,w54,w55,w56,w57,w58,w59;
reg [9:0] w40;
//reg [7:0] w60,w61,w62,w63,w64,w65,w66,w67,w68,w69,w70,w71,w72,w73,w74,w75,w76,w77,w78,w79;
reg [7:0] translen;
reg [15:0] dix;
reg [7:0] dox;
reg [25:0] cnt;  // resolving time ---> 10us Sep2012
reg [25:0] cntmask; // to skip data
reg [4:0] cntusb;
reg [19:0]cnt1;
reg [25:0]cnt2;
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
reg [9:0] adc;
reg ledind; // external indicator
reg [7:0] adcl;
reg [11:0] timer;
//reg [7:0] wdata;
always @(posedge RD) begin
lx2 <=USBX;
//waved <=waved+1;
end

reg [31:0] count_int = 0;
reg [9:0] out_clock = 0;
reg button_stat = 0;

parameter one_second = 125000000;
parameter two_seconds = 250000000;
parameter four_seconds = 500000000;
reg last_lamp = 0;

always @(posedge CLK) begin
	count_int = count_int + 1;
	if (last_lamp) begin
		adc <= WAVEX - 480;
	end
	else begin
		adc <= 0;
	end
	if (count_int == four_seconds) begin
		last_lamp = ~last_lamp;
		if (last_lamp == 0) begin
			// read mode
			adrs <= cnt1;// adrs for writing data
			cnt1 <= cnt1 + 1;//increment adrs
			if (cnt1 == four_seconds) begin
				cnt1 <= 0;
			end
			// for write mode, see pdf
			cea <= 0;
			ceb <= 1;
			ocy <= 0;
			bl <= 0;
			bh <= 0;
			// write data in dix, which will be sent to memory
			dix <= adc;
		end
		else begin
			adrs <= cnt2;
			cnt2 <= cnt2 + 1;
			// read mode
			cea <= 0;
			ceb <= 1;
			ocx <= 0;
			ocy <= 1;
			bl <= 0;
			bh <= 0;
			dix <= WAVEX - 480;
		end
		count_int = 0;
	end

	// Generate  clock
	if (adcl<1) begin 
		adcl <= 1;
	end
	else begin
		adcl <= 0;
	end

end


assign USBX = (wr0)?dox:8'bz;
assign ADX = adrs;

assign CEX = ocx; // OE(Output enable)
assign CEY = ocy; // WE(write enable)

assign CE1 = cea;
assign CE2 = ceb;

assign BHE = bh;
assign BLE = bl;

assign TRIG = ledind; // INDICATOR (Measurement ON)
assign LEDP = xtrig;

assign DX = (1-ocy)?dix:16'bz;

assign STAT = lstat;

assign WR = wr0;
assign RD = rd0;

assign WFSTAT = adc;
assign ADCLK = adcl;
//assign ADCLK = CLK;	
assign DACOUT= dacoutreg;
assign DCLK = daclock;

assign LASTLAMP = last_lamp;
endmodule