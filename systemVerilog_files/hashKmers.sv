/*------------------------------------------------------------------------------
 * File          : hashKmers.sv
 * Project       : RTL
 * Author        : epbodi
 * Creation date : Jan 17, 2023
 * Description   :
 *------------------------------------------------------------------------------*/

module hashKmers 
	#(
		parameter K = 128, //16 byte
		parameter L = 1024, //128 byte
		parameter OVERLAP = 64, //8 byte
		parameter S = 4 //numbers of smallest m values - we need to change it to 8
	) 
	(
		
		input clk,//for this module
		input reset, //for this module
		input en,
		input [L-1:0] window,
		output logic [S-1:0][31:0] m_sig,
		output logic flag
		 
	);

logic [K-1:0] kmer;
logic [31:0] hash1_val;
logic [14:0][31:0] hash1_table;//need to correct size
logic [S-1:0][31:0] m_vals;
logic flag_k, flag_m1, flag_m2,flag_sm;
logic en1, en2, en3, en4;
logic [31:0] i, j;
logic [31:0] sub_vec;
logic [31:0] hash2;

enum logic [2:0] {IDLE = 3'b000, KMERS = 3'b001, MURMUR1 = 3'b010, MURMUR1_LAST = 3'b011, SMALLEST_M = 3'b100, MURMUR2 = 3'b101, FINISH = 3'b110} state, next_state;

kmers kmrs(.clk(clk), .reset(reset), .en(en1), .window(window), .kmer(kmer), .flag(flag_k));
//murmur mrmr1(.key(kmer), .len(L), .seed(123), .hash_val(hash1_val));
murmur mmr1 (.key(kmer), .len(L), .seed(123), .clk(clk), .reset(reset), .en(en2),.hash_val(hash1_val), .flag(flag_m1));
smallest_m sml_m(.clk(clk), .reset(reset),.en(en3), .hash1_table(hash1_table), .m_vals(m_vals), .flag(flag_sm));
murmur2 mrmr2(.clk(clk), .reset(reset), .en(en4), .len(32), .seed(123), .sig(sub_vec), .hash_val(hash2), .flag(flag_m2));

always_ff@(posedge clk, posedge reset)
begin
	if(reset) begin
		state <= IDLE;
	end
	
	else begin
		state <= next_state;
	end
end

always_comb
		begin 
			en1 = 1'd0;
			en2 = 1'd0;
			en3 = 1'd0;
			en4 = 1'd0;
			//i = 0;
			next_state = state;
			flag = 1'b0;

			case(state) 
				IDLE: begin
					i = 0;
					if(en == 1'b1) next_state = KMERS;
					else next_state = IDLE;
				end
				KMERS: begin
					en1 = 1'b1;
					//if(flag_k == 1'b1) next_state = MURMUR1_LAST;
					next_state = MURMUR1;
				end
				MURMUR1: begin
					en2 = 1'b1;
					if(flag_m1 == 1'b1) begin
						hash1_table[i] = hash1_val;
						i = i +1;
						next_state = flag_k ? SMALLEST_M : KMERS;
					end
					else begin
						next_state = MURMUR1;
					end
				end
				MURMUR1_LAST: begin
					en2 = 1'b1;
					if(flag_m1 == 1'b1) begin
						hash1_table[i] = hash1_val;
						next_state = SMALLEST_M;
					end
					else begin
						next_state = MURMUR1_LAST;
						end
				end
				SMALLEST_M: begin
					en3 = 1'b1;
					i = 0;
					if(flag_sm == 1'b1) next_state = MURMUR2;
					else next_state = SMALLEST_M;
				end
				MURMUR2: begin
					en4 = 1'b1;
					sub_vec = m_vals[i];
					if(flag_m2 == 1'b1 & i == S-1) begin 
						m_sig[i] = hash2;
						next_state = FINISH;
						end
					else if (flag_m2 == 1'b1)begin
						m_sig[i] = hash2;
						i = i + 1;
						next_state = MURMUR2;
					end
					else next_state = MURMUR2;
				end
				
				FINISH: begin
					flag = 1'b1;
					next_state = IDLE;
				end
			endcase
			
		end

/*
always_ff@(posedge clk)//get the kmers hash1_table
	begin
		if(reset == 1'b1) begin
			i <= 32'b0;
			j <= 32'b0;
			en1 <= 1'b1;
			en2 <= 1'b0;
			en3 <= 1'b0;
			en4 <= 1'b0;
			flag <= 1'b0;
			kmers_done <= 1'b0;
			//sm_done <= 1'b0;
		end
		else begin
			if(en == 1'b1) begin
						
						if(flag_m1 != 1'b1) begin
							en1 <= 1'b0;
							if(kmers_done == 1'b1) begin
								en2 <= 1'b0;
							end
							else begin
								en2 <= 1'b1;
							end
						end
						else begin
							if(kmers_done == 1'b1) begin
								en1 <= 1'b0;
								en2 <= 1'b0;
							end
							else begin
								en1 <= 1'b1;
								en2 <= 1'b0;
								hash1_table[i] <= hash1_val;
								i <= i + 1;
							end
							
						end
						if(flag_k == 1'b1) begin
							kmers_done <= 1'b1;
							i <= 32'b0;
							en1 <= 1'b0;
							en2 <= 1'b0;
							en3 <= 1'b1;
						end
						if(flag_sm == 1'b1) begin
							en3 <= 1'b0;
							en4 <= 1'b1;
						end
						if(flag_m2 == 1'b1 ) begin
							if(j == S) begin
								en4 <= 1'b0;
								flag <= 1'b1;
							end
							else begin
								sub_vec <= m_vals[j];
								en4 <= 1'b1;
								j <= j + 1;
							end
						end
					end
				else begin
					flag <= 1'b0;
					en1 <= 1'b0;
					en2 <= 1'b0;
					en3 <= 1'b0;
					en4 <= 1'b0;
					j <= 32'b0;
					i <= 32'b0;
					kmers_done <= 1'b0;
				end
		end
		
	end*/

endmodule

module windows 
	#(
		parameter L = 1024,
		parameter G = 2048
	)
	(input clk,
	input reset,
	input en,
	//input [2**18-1:0] genome,
	input [G-1:0] genome,
	output logic [L-1:0] window,
	output logic [31:0] w_i, //index of window need to send to controller
	output logic flag);
	
	logic [31:0]shift;
	always_ff @(posedge clk, posedge reset)
		begin
			if( reset == 1'b1) begin
				shift <= 0;
				flag <= 1'b0;
				w_i <= 0;
			end
			else if (en == 1'b1) begin
				window <=  (genome >> shift);
				if(shift == ((G/L)-1)*L) begin
					w_i <= shift;
					shift <= 0;
					flag <= 1'b1; //send to controller
				end
				else begin
					//window <=  genome >> shift;
					flag <= 1'b0;
					w_i <= shift;
					shift <= shift + L;
				end
			end
			else begin
				window <= window;
				w_i <= w_i;
			end
		end


endmodule

module kmers 
	#(
		parameter K = 128, //16 byte
		parameter L = 1024, //128 byte
		parameter OVERLAP = 64 //8 byte
	) 
	(	input clk,
		input reset,
		input en,
		input [L-1:0] window,
		output logic [K-1:0] kmer,
		output logic flag
	);
	
	logic [31:0]shift;

	always_ff @(posedge clk, posedge reset)
	begin
		if( reset == 1'b1) begin
			shift <= 0;
			flag <= 1'b0;
		end
		else if( en == 1'b1 ) begin
			if(shift == (L-K)+OVERLAP) begin //we reached the last kmer
				flag <= 1'b1; //send to controller
				shift <= 0;
			end
			else begin
				flag <= 1'b0;
				shift <= shift + OVERLAP;
				kmer <= window >> shift;
			end
		end
		else begin
			//flag <= 1'b0;
			kmer <= kmer;
		end
	end

endmodule

module smallest_m 
	#(
		parameter S = 4
	)
	(	input clk,
		input reset,
		input en,
		input logic [14:0][31:0] hash1_table,
		output logic [S-1: 0][31:0] m_vals,
		output logic flag
	);
	logic [31:0] l;
	logic [31: 0] r;
	logic [14:0][31:0] sorted_table;
	logic copy;
	
	always_ff @(posedge clk, posedge reset)
		begin
			if(reset == 1'b1)
				begin
					flag <= 1'b0;
					l <= 0;
					r <= 1;
					copy <= 1'b0;
					
				end
			else begin
				
			if(en == 1'b1) begin
				if(copy != 1'b1) begin
					sorted_table <= hash1_table;
					copy <= 1'b1;
				end
				else begin
					if(sorted_table[r] < sorted_table[l] )
					begin
						sorted_table[r] <= sorted_table[l];
						sorted_table[l] <= sorted_table[r];
					end
				if(r != 9) //we didnt reach end of the table
					begin
						r <= r + 1;
					end
				else begin
					if(l + 1 != 9)
						begin
							l <= l + 1;
							r <= l + 2;
						end
					else begin
						//get smallest m and return
						m_vals <= sorted_table[S-1:0];
						flag <= 1'b1; //send flag to controller
						end
							
					end	
				
				end
			end	
			else begin
				sorted_table <= sorted_table;
				flag <= 1'b0;
				l <= 0;
				r <= 1;
				copy <= 1'b0;
			end
		end
	end
	
	
endmodule
