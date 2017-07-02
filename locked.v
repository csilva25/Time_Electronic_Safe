

module lock #(parameter T_MAX, parameter T_BITS)
							  (input clk, rst_n, input[17:0] SW, action_n,
								output reg[6:0] HEX7, HEX6, HEX5, HEX4, HEX2, HEX1, HEX0,
								output[11:0] incorrect_count,
								output reg[3:0] LEDG , output reg [3:0] next_state
								);
reg prev_action_but, flag;
reg[5:0] saved_password [2:0];
reg[9:0] incorrect_count_dis;
reg[T_BITS-1:0] timer;
wire[6:0] SW_dis [5:0];
wire[6:0] wrong_dis [2:0];
wire[3:0] SW_t[2:0], SW_o[2:0];
wire[3:0] w_hund, w_tens, w_ones;


	always@(posedge clk)begin
		LEDG <= next_state;
	end

	always@(posedge clk)begin
		prev_action_but <= action_n;
		flag <= ~action_n & prev_action_but;
	end

	always@(posedge clk, negedge rst_n)begin
		if(~rst_n)
			timer <= 0;
		else if((timer == T_MAX-1 & next_state == 4'b0001) | (LEDG == 4'b0000 & next_state == 4'b0001))
			timer <= 0;
		else if(timer != T_MAX-1)
			timer <= timer + 1'b1;
	end
	always@(posedge clk, negedge rst_n)begin

		if(~rst_n)begin
			saved_password[0] <= 6'b000000;
			saved_password[1] <= 6'b000000;
			saved_password[2] <= 6'b000000;
			incorrect_count_dis <= 10'b0000000000;
			next_state <= 4'b0000;
		end
		

		else if (timer == T_MAX-1 & LEDG != 4'b0000 & LEDG != 4'b1111)begin
		 next_state <= 4'b0001;
		end

		else if(flag) begin
			
			case(LEDG)
			
				4'b0000: begin 
					saved_password[0] <= SW[17:12];
					saved_password[1] <= SW[11:6];
					saved_password[2] <= SW[5:0];
					next_state <= 4'b0001;
				end
				
				4'b0001: begin 
					if(saved_password[0] == SW[5:0])
						next_state <= 4'b0011;
					else
						incorrect_count_dis <= incorrect_count_dis + 1'b1;
				end
				
				4'b0011: begin
					if(saved_password[1] == SW[5:0])
						next_state <= 4'b0111;
					else
						incorrect_count_dis <= incorrect_count_dis + 1'b1;
				end
				
				4'b0111: begin
					if(saved_password[2] == SW[5:0])
						next_state <= 4'b1111;
					else
						incorrect_count_dis <= incorrect_count_dis + 1'b1;
				end
				
				4'b1111: begin 
					saved_password[0] <= 6'b000000;
					saved_password[1] <= 6'b000000;
					saved_password[2] <= 6'b000000;
					incorrect_count_dis <= 10'b0000000000;
					next_state <= 4'b0000;
				end
			endcase
		end
	end
	

	always@(*)begin
		case(LEDG)
			4'b0000: begin
				HEX0 = SW_dis[0];
				HEX1 = SW_dis[3];
				HEX2 = 7'b1000000;
			
				HEX4 = SW_dis[1];
				HEX5 = SW_dis[4];
				
				HEX6 = SW_dis[2];
				HEX7 = SW_dis[5];


			end
			4'b0001, 4'b0011, 4'b0111: begin
				HEX0 = wrong_dis[0];
				HEX1 = wrong_dis[1];
				HEX2 = wrong_dis[2];
				
				HEX4 = SW_dis[0];
				HEX5 = SW_dis[3];
				
				HEX6 = 7'b1000111;
				HEX7 = 7'b1111111;


			end
			4'b1111: begin
				HEX0 = wrong_dis[0];
				HEX1 = wrong_dis[1];
				HEX2 = wrong_dis[2];
				
				HEX4 = 7'b1111111;
				HEX5 = 7'b1111111;
				
				HEX6 = 7'b1000001;
				HEX7 = 7'b1111111;


			end
			default: begin
				HEX7 = 7'b1111111;
				HEX6 = 7'b1111111;
				HEX5 = 7'b1111111;
				HEX4 = 7'b1111111;
				HEX2 = 7'b1111111;
				HEX1 = 7'b1111111;
				HEX0 = 7'b1111111;

			end
		endcase
	end

	

bcd_converter bcd1(.value({4'd0,SW[5:0]}), .tens(SW_t[0]), .ones(SW_o[0]));
bcd_converter bcd2(.value({4'd0,SW[11:6]}), .tens(SW_t[1]), .ones(SW_o[1]));
bcd_converter bcd3(.value({4'd0,SW[17:12]}), .tens(SW_t[2]), .ones(SW_o[2]));
bcd_converter bcd4(.value(incorrect_count_dis), .hund(w_hund), .tens(w_tens), .ones(w_ones));
	
converter_7s con1(.a(w_ones), .display(wrong_dis[0]));
converter_7s con2(.a(w_tens), .display(wrong_dis[1]));
converter_7s con3(.a(w_hund), .display(wrong_dis[2]));

genvar i;
generate 
	for(i=0; i<3; i=i+1)begin:sw_display
		converter_7s con4(.a(SW_o[i]), .display(SW_dis[i]));   
		converter_7s con5(.a(SW_t[i]), .display(SW_dis[i+3])); 
	end
endgenerate
		
assign incorrect_count = {w_hund,w_tens,w_ones};


endmodule
