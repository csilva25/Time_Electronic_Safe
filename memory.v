

module memory(input clk, rst_n,
                   input[3:0] next_state,
						 input[11:0] tries,
						 output reg mem_wr_en,
						 output reg[4:0] mem_wr_addr,
						 output reg[7:0] mem_wr_data
						 );
reg[3:0] state;
reg[11:0] saved_tries;
reg[4:0] adress_counter;
reg[5:0] address_check;

	localparam enter = "Enter Combo                     ";
	localparam lock = "Locked              Attempts    ";
	localparam unlock = "Unlocked                        ";

always@(posedge clk, negedge rst_n)begin

	if(~rst_n)begin
		state <= 4'b0000;
		saved_tries <= 12'h000;
	end
	
	else begin
		state <= next_state;
		saved_tries <= tries;
	end
end
	

always@(posedge clk, negedge rst_n)begin
	if(~rst_n)begin
		adress_counter <= 5'b00000;
		address_check <= 6'b000000;
		mem_wr_en <= 1'b0;
	end
	
	
	else if(state != next_state | saved_tries != tries)begin
		adress_counter <= 5'b00000;
		address_check <= 6'b000000;
		mem_wr_en <= 1'b0;
	end
	
	
	else if(address_check != 6'd32)begin
			adress_counter <= adress_counter + 1'b1;
			address_check <= address_check + 1'b1;
			mem_wr_en <= 1'b1;
			mem_wr_addr <= adress_counter;
			
			
		case(state)
			4'b0000: begin
						mem_wr_data <= enter[8*(5'd31-adress_counter) +: 8];
						end
						
			4'b0001,4'b0011,4'b0111: begin			
							if(adress_counter < 5'd16)
								mem_wr_data <= lock[8*(5'd31-adress_counter) +: 8];
								
							else begin
							
								case(adress_counter)
									5'd16: 	mem_wr_data <= {4'h3,tries[11:8]};
									5'd17: 	mem_wr_data <= {4'h3,tries[7:4]};
									5'd18: 	mem_wr_data <= {4'h3,tries[3:0]};
									default: mem_wr_data <= lock[8*(5'd31-adress_counter) +: 8];
								endcase
							end
						end	
			4'b1111: begin
							mem_wr_data <= unlock[8*(5'd31-adress_counter) +: 8];
						end
		endcase
	end
	else
		mem_wr_en <= 1'b0;
	end
endmodule
