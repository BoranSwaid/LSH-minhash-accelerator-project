/*------------------------------------------------------------------------------
 * File          : murmur.sv
 * Project       : RTL
 * Author        : epbodi
 * Creation date : Apr 15, 2023
 * Description   :
 *------------------------------------------------------------------------------*/

module murmur #() (input [127:0] key,
	input logic [31:0] len,
	input logic [31:0] seed,
	input clk,
	input reset,
	input en,
	output logic [31:0] hash_val,
	output logic flag);

logic [31:0] hash_res;
logic [31:0] new_seed;
logic [31:0] chunk;//updated in each state
logic [31:0] seed_val;//updates in every state
logic en1, en2;

enum logic[3:0] {IDLE = 4'b0000, STATE1 = 4'b0001, STATE2_1 = 4'b0010,  STATE2_2 = 4'b0011, STATE3_1 = 4'b0100,
	STATE3_2 = 4'b0101, STATE4_1 = 4'b0110, STATE4_2 = 4'b0111, SHIFT_XOR = 4'b1000, FINISH = 4'b1001} state, next_state;

four_byte_chunk inst1(.chunk(chunk), .seed(seed_val),.en(en1), .hash_res(hash_res));
shift_xor inst2(.hash(hash_res), .len(len),.en(en2), .hash_result(hash_val));

always_ff@(posedge clk, posedge reset)
	begin
		if(reset) begin
			state <= IDLE;
		end
		
		else if(en == 1'b1) begin
			state <= next_state;
		end
		else begin
			state <= state;
		end
	end


always_comb
	begin
		//default
		flag = 1'b0;
		seed_val = 0;
		chunk = 0;
		next_state = state;
		en1 = 1'b0;
		en2 = 1'b0;
		//new_seed = hash_res;
		
		case(state)
			IDLE: begin
				//hash_val = 0;
				//hash_res = 0;
				next_state = STATE1;
				
			end
			STATE1: begin
				en1 = 1'b1;
				chunk = key[127:96];
				seed_val = seed;
				new_seed = hash_res;
				next_state = STATE2_1;
			end
			STATE2_1: begin//stuck here maybe becuz of hash res
				en1 = 1'b1;
				chunk = key[95:64];
				seed_val = new_seed;
				new_seed = hash_res;
				next_state = STATE3_1;
				
			end
			/*STATE2_2: begin
				new_seed = hash_res;
				next_state = STATE3_1;
			end*/
			STATE3_1: begin
				en1 = 1'b1;
				chunk = key[63:32];
				seed_val = new_seed;
				new_seed = hash_res;
				next_state = STATE4_1;
			end
			/*STATE3_2: begin
				new_seed = hash_res;
				next_state = STATE4_1;
			end*/
			STATE4_1: begin
				en1 = 1'b1;
				chunk = key[31:0];
				seed_val = new_seed;
				new_seed = hash_res;
				next_state = SHIFT_XOR;
			end
			/*STATE4_2: begin
				new_seed = hash_res;
				next_state = SHIFT_XOR;
			end*/
			SHIFT_XOR: begin
				en2 = 1'b1;
				flag = 1'b1;
				next_state = IDLE;

			end
			
		endcase
	end

endmodule

module murmur2 #() (
input clk,
input reset,
input en,
input logic [31:0] len,
input logic [31:0] seed,
input logic[31:0] sig,
output logic [31:0] hash_val,
output logic flag

);
logic en1, en2;
logic [31:0] hash_res;
enum logic[1:0] {IDLE = 2'b00, STATE1 = 2'b01, SHIFT_XOR = 2'b10} state, next_state;

four_byte_chunk inst1(.chunk(sig), .seed(seed),.en(en1), .hash_res(hash_res));
shift_xor inst2(.hash(hash_res), .len(len),.en(en2), .hash_result(hash_val));

always_ff@(posedge clk, posedge reset)
begin
	if(reset) begin
		state <= IDLE;
	end
	
	else if(en == 1'b1) begin
		state <= next_state;
	end
	else begin
		state <= state;
	end
end

always_comb
	begin
	//default
	flag = 1'b0;
	next_state = state;
	en1 = 1'b0;
	en2 = 1'b0;
	//new_seed = hash_res;
	
	case(state)
		IDLE: begin
			//hash_val = 0;
			//hash_res = 0;
			next_state = STATE1;
			
		end
		STATE1: begin
			en1 = 1'b1;
			next_state = SHIFT_XOR;
		end		
		SHIFT_XOR: begin
			en2 = 1'b1;
			flag = 1'b1;
			next_state = IDLE;

		end
		
	endcase
end
endmodule

module four_byte_chunk #()(input logic [31:0] chunk,
	input logic [31:0] seed,
	input en,
	output logic [31:0] hash_res);

logic [31:0] k1, k2, k3, hash_q1, hash_q2;
localparam [31:0] c1 = 'hcc9e2d51;
localparam [31:0] c2 = 'h1b873593;
localparam [31:0] m = 'h5;
localparam [31:0] n = 'he6546b64;


always_comb
	begin
		if( en == 1'b1) begin
			
			k1 = chunk * c1;
			k2 = {k1[16:0], k1[31:17]};//rol15
			k3 = k2 * c2;
						
			hash_q1 = k3 ^ seed;
			hash_q2 = {hash_q1[18:0], hash_q1[31:19]};//rol13
			hash_res = hash_q2 * m + n;
		end
		else begin
			hash_res = hash_res;//32'b0;
		end
	end

endmodule

module shift_xor(input [31:0] hash,
	input [31:0] len,
	input en,
	output logic[31:0] hash_result);

logic [31:0] hash_shx1, hash_shx2, hash_shx3, hash_shx4, hash_shx5; 


always_comb
	begin
		if(en == 1'b1) begin
			hash_shx1 = hash ^ len;
			hash_shx2 = hash_shx1 ^ (hash_shx1 >> 16);
			hash_shx3 = hash_shx2 * 'h58ebca6b;
			hash_shx4 = hash_shx3 ^ (hash_shx3 >> 13);
			hash_shx5 = hash_shx4 * 'hc2b2ae35;
			hash_result = hash_shx5 ^ (hash_shx5 >> 16);
		end
		else begin
			hash_result = hash_result;//32'b0;
		end

	end


endmodule