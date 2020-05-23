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
	WAVEX,WFSTAT,ADCLK, PWDN,DFS,OVR,DACOUT,DCLK, INSTAT);
	
input [1:0] INSTAT; // should be able to receive button input

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
reg adc;
reg ledind; // external indicator
reg [7:0] adcl;
reg [11:0] timer;
//reg [7:0] wdata;
always @(posedge RD) begin
lx2 <=USBX;
//waved <=waved+1;
end

reg [31:0] count_int = 0;
reg [5:0] out_clock = 0;
reg button_stat = 0;

always @(posedge CLK) begin
	count_int = count_int + 1;
	if (count_int == 125000000) begin
		out_clock = out_clock + 1;
		if (out_clock == 16) begin
			out_clock = 0;
		end
		count_int = 0;
	end

// Generate ADC clock
if(adcl<1)begin adcl<=1;end else begin adcl<=0; end
if(daclock<1)begin daclock<=1;end else begin daclock<=0; end
//cnt2<=cnt2+1;
//if(cnt2==0)begin waved<=waved+1; end
//cnt2<=cnt2+1;
//if(cnt2==0) begin waved<=waved+1; end
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
// CHECK USB COMMAND and read into lx1
if (RXF==0) begin	// RXF LOW if FIFO buffer of FT245 from PC is available 
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
	lstat<=lx1;
	rd0<=1; wr0<=0;
renewed<=0;
cntusb<=0;
cea<=0; ceb<=1; ocr<=0;
bh<=0; bl<=0;
if (cntmask>0) begin cntmask<=cntmask-1; end
else 
begin
if(w0>wlld && wreq==0) begin // Start when w0 is over the specified threshold level
lstat<=4;
cnt<=0;
cnt2<=0;
wreq<=1;
wavg<=wavg1; // record baseline at here // wavg is calculated by adding successive 8 samples 
end
//if(wavg0<864 && wreq==0) begin // PULSE SKIP
//cntmask<=2500; //skip ~200 us // 2014 Aug 15 20 us
//end
if(wreq==1) begin // after detecting threshold level
if(wavg0>wavg) begin
if(wavp<wavg0)begin wavp<=wavg0; 
end
// wavg1>wavg
wsum<=wsum+w0-512;
//wsum<=wsum+w7-wavg/8;
end
else begin wreq<=2; 
cnt1<=wsum+wavg0; 
//adrs<=wsum/512; //killed Aug15
//waved<=wsum/512; //Killed Aug15
adrs<=(wavp-wavg)/4; // Aug15 divide into quarter since DNL is not so good for fast ADC
waved<=wavp/8-512; 
//adrs<=wavp;
//waved<=wavp/16;
end // end of pulse, next sequence
end
if (wreq==2) begin // WMODE==0 assures data 
if(cnt2<100)begin lstat<=5;end else begin lstat<=4; end
if(cnt==1)begin
	ocx<=0;ocy<=1; 
end
if(cnt==2)begin
	 wd<=DX+1; // add one 
end
if(cnt==3)begin
ocx<=1;ocy<=1; // high-Z read 
dix<=wd;
end
if(cnt==4)begin
	ocx<=1; ocy<=0;// ^OE ocx=1: high Z , ^WE ocy=0: write mode
	 // write data 
end
if(cnt==5)begin
	ocx<=0; ocy<=1;// ^OE ocx=0:  ^WE ocy=1: read mode
end
cnt<=cnt+1;
cnt2<=cnt2+1;
if(cnt2>20)begin	
	ocx<=0; ocy<=1;// ^OE ocx=0: output enable , ^WE ocy=1: read mode
   cnt1<=0;	// address increment
	cnt<=0;
	cnt2<=0;
	wreq<=0; 
	lstat<=5;
	wsum<=0;
	wavp<=0;
	ledind<=1-ledind; //indicator TOGGLE
end
end
end
end //****
// CLEAR DATA COMMAND #1
else if (lx1==1) begin
	rd0<=1; wr0<=0;
	cntusb<=0;
	lstat<=lx1;
	ledind<=1; //indicator ON
if (cnt==0)begin
cnt<=cnt+1;
adrs<=cnt1;
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
	cnt1<=cnt1+1;	// adress increment
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
	cntmask<=64000000;
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
if(w0>wlld && cntmask==0)begin
cntmask<=1000000;
end
if(timer==4095)begin
if(cntmask>0) begin
adrs<=cnt1;
ocx<=1;ocy<=0; // write mode
dix<=wavg0/8;
//wall;
waved<=w40/16; // not display data 
cnt1<=cnt1+1;
cntmask<=cntmask-1;
end
timer<=0;
end
//end
end
else if (lx1==16 && wreq==0) begin
	wlld<=wlld+32;
	wreq<=1;  // chattering free
	waved<=wlld; 
end
else if (lx1==17 && wreq==0) begin
	lstat<=7;
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
//lx4<=lx4+1;
cntmask<=cntmask-1;
end
//end
end
else if (lx1==18 && wreq==0) begin
	wlld<=wlld+4;
	wreq<=1; // chattering free
	waved<=wlld; 
end
else if (lx1==19 && wreq==0) begin
	wlld<=wlld-4;
	wreq<=1; // chattering free
	waved<=wlld; 
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
	ocx<=0;ocy<=1;
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
assign WFSTAT = out_clock;
assign ADCLK =adc;
//assign ADCLK = CLK;	
assign DACOUT= dacoutreg;
assign DCLK =daclock;
endmodule