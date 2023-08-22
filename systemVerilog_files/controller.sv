/*------------------------------------------------------------------------------
 * File          : controller.sv
 * Project       : RTL
 * Author        : epbodi
 * Creation date : Apr 25, 2023
 * Description   :
 *------------------------------------------------------------------------------*/

module controller 
#(	parameter G = 2048,//genome length
	parameter L = 1024,//window length
	parameter S = 4,//number of smallest S signatures
	parameter N = 3//number of different genomes
) 
(
input clk,
input reset,
input logic [G-1:0] genome,
input logic [L-1:0] read,
input logic isOnline,
output logic hit,//found candidate pairs
output logic [31:0] index_max,//the final result- the matching window index
output logic [31:0] gid_result,//gid of the matching genome
output logic flag_finish,//control is done

//memory interface 
output logic[31:0] RmemVal,//key val to read content from memory
input logic[31:0] RmemW_i,//read window index from memory
input logic [31:0] RGID,//read genome id from memory
output logic [31:0] wmemW_i,//write window index to memory
output logic [S-1:0][31:0] WmemVal,//write value to memory
output logic WFlag,//to tell tb that hash2Val is ready to add to sigTable-write to memory
output logic [1:0] RFlag//flag to read from memory

);

logic en_w, en_hk1, en_hk2, flag_w, flag_hk1, flag_hk2, en_max, flag_max, en_max2, flag_max2, en_opp, flag_opp, isOppRead , zeroed, hit_tmp, hit_tmp_read;

logic [31:0] j, c, count;
logic [L-1:0] window;
logic [S-1:0][31:0]readTable;//saves the hash vals of the read
logic [N-1:0][G/L-1:0][31:0] windows_counter;//counter for number of hits in each window in each genome
logic [G/L-1:0][31:0] counter;//counter to send to max
logic [N-1:0][1:0][31:0] max_counters;//contains the max counters of all genomes
logic [S-1:0][31:0] m_sig1;//contains the smallest S values for window in genome
logic [S-1:0][31:0] m_sig2;//contains the smallest S values for window in read
logic [31:0]max_w_i;//saves the max index in specific genome
logic [31:0] max_i;//saves window index of the max counter in read and opp read
logic [31:0] max_gid;//saves genome id of the max counter in read and opp read
logic [L-1:0] opp_read;//saves the opposite of the read
logic [L-1:0] hash_read;//saves the read that we send to hash kmers
logic [0:2][31:0] max_count_read, max_count_oppRead;//saves the window index and gid and counter of the max counter from read and opp read

enum logic [3:0] {IDLE = 4'b0000, WINDOWS = 4'b0001, HASH_KMERS = 4'b0010, CANDIDATE_PAIRS = 4'b0011, FINISH = 4'b0100, HASH_KMERS_READ = 4'b0101,
	MAX = 4'b0110, MAX_COUNTERS = 4'b0111, INC_COUNT = 4'b1000, CHECK_GID = 4'b1001, INC_J = 4'b1010, OPP_READ = 4'b1011, MAX_OPPR_R = 4'b1100} state, next_state;

windows wnds(.clk(clk), .reset(reset), .en(en_w), .genome(genome), .window(window), .w_i(wmemW_i), .flag(flag_w));
hashKmers hashK1(.clk(clk), .reset(reset), .en(en_hk1), .window(window), .m_sig(m_sig1), .flag(flag_hk1));//hash kmrs of the genome
hashKmers hashK2(.clk(clk), .reset(reset), .en(en_hk2), .window(hash_read), .m_sig(m_sig2), .flag(flag_hk2));//hash kmers of the read
MAX1 max_i_inst(.myTable(counter), .clk(clk), .en(en_max), .reset(reset), .max_index(max_w_i), .flag(flag_max));
MAX2 max_count(.myTable(max_counters), .clk(clk), .en(en_max2), .reset(reset), .max_index(max_i), .table_index(max_gid), .flag(flag_max2));
OPP_READ opp_inst(.clk(clk), .reset(reset), .en(en_opp), .read(read), .opp_read(opp_read), .flag(flag_opp));

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
			en_w = 1'd0;
			en_hk1 = 1'd0;
			en_hk2 = 1'd0;
			en_max = 1'd0;
			en_max2 = 1'b0;
			en_opp = 1'b0;
			next_state = state;
			WFlag = 1'b0;
			RFlag = 2'b0;
			flag_finish = 1'b0;

			case(state) 
				IDLE: begin
					if(isOnline == 1'b1) begin
							next_state = HASH_KMERS_READ;
					end
					else next_state = WINDOWS;
					j=0;
					c=0;
					count = 0;
					isOppRead = 1'b0;
					zeroed = 1'b0;
					max_count_read = {0,0,0};
					max_count_oppRead = {0,0,0};
					for (int k = 0; k < N; k++) begin
						for(int m = 0; m < G/L; m++) begin
							windows_counter[k][m] = 0;
						end
						max_counters[k][0] = 0;
						max_counters[k][1] = 0;
						
					end
					hit_tmp_read = 1'b0;
					hit = 1'b0;
					
				end
				
				WINDOWS: begin
					en_w = 1'd1;
					next_state = HASH_KMERS;
				end
				
				HASH_KMERS: begin
					en_hk1 = 1'b1;
					if(flag_hk1 == 1'b1) begin
						next_state = flag_w ? FINISH : WINDOWS;
						WmemVal = m_sig1;//write the smallest S vals to memory
						WFlag = 1'b1;
					end
					else begin
						next_state = HASH_KMERS;
					end
				end
				
				HASH_KMERS_READ: begin
					if(isOnline == 1'b1) begin
						if(isOppRead == 1'b0) hash_read = read;
						else hash_read = opp_read;
						en_hk2 = 1'b1;
						if(flag_hk2 == 1'b1) begin
							readTable = m_sig2;//copy the list of the read hash values
							WmemVal = m_sig2;//write the smallest S vals to memory
							WFlag = 1'b1;//its the time to write to memory
							next_state = CANDIDATE_PAIRS;
						end
						hit_tmp = 1'b0;
					end
					else begin
							en_hk1 = 1'b1;
							if(flag_hk1 == 1'b1) begin
								next_state =FINISH;
								WmemVal = m_sig1;//write the smallest S vals to memory
								WFlag = 1'b1;//its the time to write to memory
							end
							else begin
								next_state = HASH_KMERS_READ;
							end
					end
				end
				
				CANDIDATE_PAIRS: begin
						RmemVal = readTable[j];
						if(isOppRead == 1'b0) RFlag = 2'b1;
						else RFlag = 2'b10;
						next_state = CHECK_GID;						
				end
				
				CHECK_GID: begin
					if(RGID == 0 || RGID == 1 || RGID == 2) begin //if it is the genome id (0)
						next_state = INC_COUNT;
						count =  windows_counter[RGID][RmemW_i];
					end
					else next_state = INC_J;
				end
				
				INC_COUNT: begin
					windows_counter[RGID][RmemW_i] = count + 1;
					hit_tmp = 1'b1;
					next_state = CANDIDATE_PAIRS;
				end
				
				INC_J: begin
					if(j != S-1)begin
						j+=1;
						next_state = CANDIDATE_PAIRS;
					end
					
					else begin
						next_state = MAX;
					end
				end
				
				MAX: begin
					if(hit_tmp == 1'b1 && !flag_max) begin //keep en_max=1 as long as it didn't finish finding the max
						counter = windows_counter[c];
						en_max = 1'b1;
						next_state = MAX;
						if(isOppRead == 1'b0) hit_tmp_read = 1'b1;
					end
					else if(hit_tmp == 1'b0 && isOppRead == 1'b1) begin
							next_state =(hit_tmp_read) == 1'b1 ? MAX_OPPR_R : FINISH;
					end
					else if(hit_tmp == 1'b0 && isOppRead == 1'b0) begin
							next_state = OPP_READ;
							isOppRead = 1'b1;
					end
					else if(c != N) begin
						max_counters[c][0] = max_w_i;
						max_counters[c][1] = windows_counter[c][max_w_i];
						c += 1;
						next_state = MAX;
					end
					else next_state =MAX_COUNTERS;//we reached the last genome counters
					
				end
				
				MAX_COUNTERS: begin
					en_max2 = 1'b1;
					if(flag_max2 == 1'b1) begin
						if(isOppRead == 1'b0)  begin 
							max_count_read = {max_i, max_gid, max_counters[max_gid][1]};
							next_state = OPP_READ;
						end
						else begin
							max_count_oppRead = {max_i, max_gid, max_counters[max_gid][1]};
							next_state = MAX_OPPR_R;
						end
					end
					else next_state = MAX_COUNTERS;
				end
				
				OPP_READ: begin
					isOppRead = 1'b1;
					en_opp = 1'b1;
					j=0;
					c=0;
					count = 0;
					if(zeroed == 1'b0) begin
						for (int k = 0; k < N; k++) begin
							for(int m = 0; m < G/L; m++) begin
								windows_counter[k][m] = 0;
							end
							max_counters[k][0] = 0;
							max_counters[k][1] = 0;
						end
						zeroed = 1'b1;
					end
					if(flag_opp == 1'b1) next_state = HASH_KMERS_READ;
					else next_state = OPP_READ;
				end
				
				MAX_OPPR_R: begin
					if(max_count_read[2] > max_count_oppRead[2]) begin
						index_max = max_count_read[0];
						gid_result = max_count_read[1];
						if(max_count_read[2] > 2) hit = 1'b1;
					end
					else begin
						index_max = max_count_oppRead[0];
						gid_result = max_count_oppRead[1];
						if(max_count_oppRead[2] > 2) hit = 1'b1;
					end
					next_state = FINISH;
				end
						
				
				FINISH: begin
					if(isOnline == 1'b0) begin
						flag_finish = 1'b1;
						next_state = IDLE;
					end
					else begin
						flag_finish = 1'b1;
						next_state = FINISH;
					end
				end
				
			endcase
			
		end


endmodule

module MAX1 #(parameter G =2048,
parameter L = 1024)
(
input logic [G/L-1:0][31:0] myTable,
input clk,
input logic en,
input logic reset,
output logic [31:0] max_index,
output logic flag
);

logic [31:0] max;

always_ff@(posedge clk) begin
	if(reset == 1'b1) flag = 1'b0;
	if(en == 1'b1) begin
		flag = 1'b0;
		max = myTable[0];
		max_index = 0;
		for(int i = 1; i < G/L; i++) begin
			if(myTable[i] > max) begin
				max = myTable[i];
				max_index = i;
				end
		end
		flag = 1'b1;
	end
	else begin
		flag = 1'b0;
		max_index = max_index;
	end
end
endmodule

module MAX2 #(parameter N = 3)
	(
	input logic [N-1:0][1:0][31:0] myTable,
	input logic en,
	input clk,
	input logic reset,
	output logic [31:0] max_index,//window index
	output logic [31:0] table_index,//genome index
	output logic flag
	);

	logic [31:0] max;

	always_ff@(posedge clk) 
		begin
			if(reset == 1'b1) flag = 1'b0;
			if(en == 1'b1) begin
				flag = 1'b0;
				max = myTable[0][1];
				max_index = myTable[0][0];
				table_index = 0;
				
				for(int i = 1; i < N; i++) begin
					if(myTable[i][1] > max) begin
						max = myTable[i][1];
						max_index = myTable[i][0];
						table_index = i;
						end
				end
				flag = 1'b1;
			end
			else begin
				flag = flag;
				max_index = max_index;
				table_index = table_index;
			end
		end
endmodule

//this module return the opposite read
module OPP_READ #(parameter L = 1024) (
		input clk,
		input reset,
		input en,
		input logic [L-1:0] read,//the input read
		output logic [L-1:0] opp_read,//the opposite returned
		output logic flag
	);
logic copied;
logic [31:0] i;

always_ff@(posedge clk) begin
	if(reset == 1'b1) begin
		flag = 0;
		opp_read = 0;
		copied = 1'b0;
		i = 0;
	end
	if(en == 1'b1) begin
		if(flag == 1'b0) begin
			if(copied == 1'b0) begin
					opp_read = read;
					copied = 1'b1;
					end
			else begin
				if(opp_read[i+: 8] == "A") opp_read[i+: 8] = "T";
				else if(opp_read[i+: 8] == "T") opp_read[i+: 8] = "A";
				else if(opp_read[i+: 8] == "C") opp_read[i+: 8] = "G";
				else opp_read[i+: 8] = "C";
				if(i == L-8) flag = 1'b1;
				else i += 8 ;
			end
		end
	end
	else begin
		flag = 1'b0;
		copied = 1'b0;
		i = 0;
	end
end
endmodule
