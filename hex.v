
module converter_7s(input [3:0] a , output reg [6:0] display );
	always@(a) begin
		case (a)
			4'b0000 : display = 7'b1000000; //0
			4'b0001 : display = 7'b1111001; //1
			4'b0010 : display = 7'b0100100; //2
			4'b0011 : display = 7'b0110000; //3
			4'b0100 : display = 7'b0011001; //4
			4'b0101 : display = 7'b0010010; //5
			4'b0110 : display = 7'b0000010; //6
			4'b0111 : display = 7'b1111000; //7
			4'b1000 : display = 7'b0000000; //8
			4'b1001 : display = 7'b0010000; //9
			4'b1010 : display = 7'b0001000; //10 / A
			4'b1011 : display = 7'b0000011; //11 / B
			4'b1100 : display = 7'b1000110; //12 / C
			4'b1101 : display = 7'b0100001; //13 / D
			4'b1110 : display = 7'b0000110; //14 / E
			4'b1111 : display = 7'b0001110; //15 / F
			default : display = 7'b1111111;
		endcase
	end
endmodule