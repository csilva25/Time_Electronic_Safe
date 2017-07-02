
module main(
	// Ports identical to Lab 5
	input clk_in, rst_n, action_n,
	input [17:0] SW,
	output [6:0] HEX7, HEX6, HEX5, HEX4, HEX2, HEX1, HEX0,
	output [3:0] LEDG,

	// New LCD ports
	inout [7:0] LCD_DATA,
	output LCD_RW, LCD_EN, LCD_RS, LCD_ON
);

wire[11:0] incorrect_count;
wire[3:0] next_state;
lock #(.T_MAX(16'd45_800), .T_BITS(16)) // .T_MAX(10'd750), .T_BITS(10) originally
		lock1(.clk(safe_clk), .rst_n(rst_n), .SW(SW), .action_n(action_n),
			 .HEX7(HEX7), .HEX6(HEX6), .HEX5(HEX5), .HEX4(HEX4), .HEX2(HEX2), .HEX1(HEX1), .HEX0(HEX0),
			  .incorrect_count(incorrect_count), .LEDG(LEDG), .next_state(next_state));

memory memory1(.clk(safe_clk), .rst_n(rst_n), .next_state(next_state),
 .tries(incorrect_count), .mem_wr_en(mem_wr_en), .mem_wr_addr(mem_wr_addr), .mem_wr_data(mem_wr_data));


	// This signal is always high to keep the LCD powered
	assign LCD_ON = 1'b1;

	// Setup the two clocks
	//  - lcd_clk should drive all logic on the output side of the RAM block
	//  - safe_clk should drive all logic on the input side of the RAM block
	wire lcd_clk, safe_clk;
	clk_divider #(.BITS(15)) lcd_clk_divider(.clk_in(clk_in), .clk_out(lcd_clk));
	clk_divider #(.BITS(21)) safe_clk_divider(.clk_in(clk_in), .clk_out(safe_clk));

	// Signals that interface to the dual-port RAM block. One port only writes
	// to the memory (mem_wr_??? signals) and the other port only reads from
	// the memory (mem_rd_??? signals).
	// You may need to change the size of these signals if you adjust the RAM
	// block size.
	wire [4:0] mem_rd_addr, mem_wr_addr; // Read and write addresses
	wire [7:0] mem_rd_data, mem_wr_data; // Read and write data
	wire mem_wr_en; // Write enable signal. A write occurs on every safe_clk rising
	                // edge where mem_wr_en is asserted. You may write on 
					// consecutive clock edges.

	// Instantiate the RAM block
	ram memory (.data(mem_wr_data), .rdaddress(mem_rd_addr), .rdclock(lcd_clk), .wraddress(mem_wr_addr), .wrclock(safe_clk), .wren(mem_wr_en), .q(mem_rd_data));

	// Instantiate the LCD control state machine
	lcd_control lcd(.clk(lcd_clk), .rst_n(rst_n), .LCD_DATA(LCD_DATA), .LCD_RW(LCD_RW), .LCD_EN(LCD_EN), .LCD_RS(LCD_RS), .memory_address(mem_rd_addr), .data_in(mem_rd_data));
	
endmodule

module clk_divider #(parameter BITS = 21) (input clk_in, output clk_out);
	reg [BITS-1:0] cnt;
	
	always @ (posedge clk_in) begin
		cnt <= cnt + {{BITS-1{1'b0}},1'b1};
	end
	
	assign clk_out = cnt[BITS-1];
endmodule

