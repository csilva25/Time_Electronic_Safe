// The basic LCD control module, which only performs the initialization
// process for the LCD. Add any ports or states you need to display the
// messages for Lab 6. Try to reuse the states that are already present.
module lcd_control (
	input clk, rst_n,
	inout [7:0] LCD_DATA,
	output reg LCD_RW, LCD_EN, LCD_RS,
	output reg [4:0] memory_address,
	input [7:0] data_in
);

//mem_rd_addr mem_rd_data

	// State definitions
	localparam S_INIT_LCD          = 5'b00000;
	localparam S_BEGIN_TRANSACTION = 5'b00001;
	localparam S_END_TRANSACTION   = 5'b00010;
	localparam S_SETUP_BUSY_READ   = 5'b00011;
	localparam S_BEGIN_BUSY_READ   = 5'b00100;
	localparam S_END_BUSY_READ     = 5'b00101;
	localparam S_LCD_ENTRY_SET     = 5'b00110;
	localparam S_LCD_CLEAR         = 5'b00111;
	localparam S_LCD_DISPLAY_ON    = 5'b01000;
	localparam S_LCD_END_INIT      = 5'b01001;

	// LCD command values
	localparam CMD_LCD_FUNCTION_SET = 8'b00111000;
	localparam CMD_LCD_DISPLAY_ON   = 8'b00001110;
	localparam CMD_LCD_CLEAR        = 8'b00000001;
	localparam CMD_LCD_ENTRY_SET    = 8'b00000110;

	// Other constants
	localparam INIT_DELAY_COUNT_MAX = 23; // Clock cycles to delay between initialization commands
	localparam LCD_INIT_COUNT_MAX   = 4;  // Number of times to perform FUNCTION SET command
	
	// Current state
	reg [4:0] state;

	// When done with transaction, return to this state
	reg [4:0] return_state;

	// Signals for inout port
	wire [7:0] LCD_DATA_IN;
	reg [7:0] LCD_DATA_OUT;

	// Signals to control INIT process
	reg init_done;
	reg [16:0] init_delay_count;
	reg [2:0] init_count;

	// Standard inout port assignments
	assign LCD_DATA = (LCD_RW) ? 8'hZZ : LCD_DATA_OUT;
	assign LCD_DATA_IN = LCD_DATA;

	reg [4:0] address_count;
	reg [5:0] address_check;
	reg flag;
	
	// Main state machine
	always @ (posedge clk) begin
		if( ~rst_n ) begin
			state <= S_INIT_LCD;
			init_done <= 0;
			init_delay_count <= 0;
			init_count <= 0;
			LCD_EN <= 0;
			LCD_RS <= 0;
			LCD_RW <= 0;
			
			
			flag <= 1'b0;
			address_count <= 5'b00000;
			address_check <= 6'b000000;
		end
		else begin
			case(state)
				/* -----------------------------------------------------
				 * Beginning of shared states that perform a transaction
				 * -----------------------------------------------------*/
				// Start the transaction by enabling the LCD
				S_BEGIN_TRANSACTION: begin
					LCD_EN <= 1;
					state <= S_END_TRANSACTION;
				end
				// End the transaction by disabling the LCD
				S_END_TRANSACTION: begin
					LCD_EN <= 0;

					// Read the busy signal by default
					if( init_done )
						state <= S_SETUP_BUSY_READ;
					// While in init the busy signal is not available
					else
						state <= return_state;
				end
				// Prepare the control lines for a read
				S_SETUP_BUSY_READ: begin
					LCD_RS <= 0;
					LCD_RW <= 1;
					state <= S_BEGIN_BUSY_READ;
				end
				// Perform the read transaction
				S_BEGIN_BUSY_READ: begin
					LCD_EN <= 1;
					state <= S_END_BUSY_READ;
				end
				// Check the busy signal
				S_END_BUSY_READ: begin
					LCD_EN <= 0;
					// LCD complete, go to the next state
					if( LCD_DATA_IN[7] == 0 ) begin
						state <= return_state;
					end
					// LCD still busy, try again
					else begin
						state <= S_SETUP_BUSY_READ;
					end
				end
				/* -----------------------------------------------------
				 * End of shared states that perform a transaction
				 * -----------------------------------------------------*/

				// Perform a FUNCTION SET command multiple times
				S_INIT_LCD: begin
					LCD_RS <= 0;
					LCD_RW <= 0;
					LCD_DATA_OUT <= CMD_LCD_FUNCTION_SET;
					return_state <= S_INIT_LCD;
					init_delay_count <= init_delay_count + 17'd1;

					// Wait for a given number of clock cycles between
					// FUNCTION SET commands
					if( init_delay_count == INIT_DELAY_COUNT_MAX ) begin
						init_delay_count <= 0;
						init_count <= init_count + 3'd1;
						state <= S_BEGIN_TRANSACTION;

						// Repeat the FUNCTION SET command multiple times
						if( init_count == LCD_INIT_COUNT_MAX ) begin
							return_state <= S_LCD_DISPLAY_ON;
							init_done <= 1;
						end
					end
				end

				// Send the DISPLAY ON command
				S_LCD_DISPLAY_ON: begin
					LCD_RS <= 0;
					LCD_RW <= 0;
					LCD_DATA_OUT <= CMD_LCD_DISPLAY_ON;
					return_state <= S_LCD_CLEAR;
					state <= S_BEGIN_TRANSACTION;
				end

				// Send the LCD CLEAR command
				S_LCD_CLEAR: begin
					LCD_RS <= 0;
					LCD_RW <= 0;
					LCD_DATA_OUT <= CMD_LCD_CLEAR;
					return_state <= S_LCD_ENTRY_SET;
					state <= S_BEGIN_TRANSACTION;
				end
				
				// Send the ENTRY SET command
				S_LCD_ENTRY_SET: begin
					LCD_RS <= 0;
					LCD_RW <= 0;
					LCD_DATA_OUT = CMD_LCD_ENTRY_SET;
					return_state <= S_LCD_END_INIT;
					state <= S_BEGIN_TRANSACTION;
				end

				// Initialization complete.
				// This state could begin to display information on the LCD.
				S_LCD_END_INIT: begin
				// simple state machine for writing to LCD
				
				
				
				
				case(flag)
					
						1'b0: begin
										if(address_check != 6'd16)begin 
											address_count <= address_count + 1'b1;
											address_check <= address_check + 1'b1;
											memory_address <= address_check+1'b1;
											LCD_RS <= 1;
											LCD_RW <= 0;
											LCD_DATA_OUT <= data_in;
											state <= S_BEGIN_TRANSACTION;
										end
										else begin
											LCD_RS <= 0;
											LCD_RW <= 0;
											LCD_DATA_OUT <= 8'hC0;
											flag <= 1'b1;
											state <= S_BEGIN_TRANSACTION;
										end
									end

					1'b1: begin
										if(address_check != 6'd32)begin 
											address_count <= address_count + 1'b1;
											address_check <= address_check + 1'b1;
											memory_address <= address_count+1'b1;
											LCD_RS <= 1;
											LCD_RW <= 0;
											LCD_DATA_OUT <= data_in;
											state <= S_BEGIN_TRANSACTION;
										end
										
										else begin
											address_count <= 5'b00000;
											address_check <= 6'b000000;
											flag <= 1'b0;
											LCD_RS <= 0;
											LCD_RW <= 0;
											LCD_DATA_OUT <= 8'h80;
											state <= S_BEGIN_TRANSACTION;
										end
									end
					endcase
				end
				default: begin
					LCD_EN <= 0;
					state <= S_INIT_LCD; // Could also define an error state
				end
			endcase
		end
	end
endmodule

