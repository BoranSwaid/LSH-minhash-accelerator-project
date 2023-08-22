/*------------------------------------------------------------------------------
 * File          : test_bench.sv
 * Project       : RTL
 * Author        : epbodi
 * Creation date : Jun 15, 2023
 * Description   :
 *------------------------------------------------------------------------------*/

module test_bench #(parameter S = 4) ();
reg [2047:0] genome1;
reg [2047:0] genome2;
reg [2047:0] genome3;
reg [1023:0] read;
logic clk, reset, isOnline, flag, clk2;
logic hit;//match was found
logic [31:0] w_i_result;//matching window index
logic [31:0] gid_result;//matching genome id

//memory interface
logic[31:0] val;//key - read value
logic[31:0] w_i;//w_i to write to memory
logic[31:0] w_iO;//w_i to read from memory
logic[31:0] G_idO;//genome id to read from memory
logic [S-1:0][31:0] sig_val;//sig values to write to memory
logic [1:0] RmemFlag;//its 1 when we want to read from memory
logic WmemFlag;//its 1 when we want to write from memory
typedef struct{
	logic [31:0] w_index;
	logic [31:0] g_id;
} listType;
typedef listType valueType[$];
typedef logic[31:0] memKey;
typedef valueType assocArrayType[memKey];//associative array with key of memKey type and value is valueType (like dictionary in python)
assocArrayType memory;

logic [31:0] i, t;
logic [2047:0] genome;


controller ctrl(.clk(clk), .reset(reset), .genome(genome), .read(read), .isOnline(isOnline), .WFlag(WmemFlag),.wmemW_i(w_i), .WmemVal(sig_val),
	.RFlag(RmemFlag),.RmemVal(val), .RmemW_i(w_iO), .RGID(G_idO),.hit(hit), .index_max(w_i_result),.flag_finish(flag), .gid_result(gid_result));

initial begin
	clk = 0;
	clk2 =0;
	reset = 1'b1;
	//Severe acute respiratory syndrome coronavirus 2 isolate Wuhan-Hu-1, complete genome
	genome1 = "ATTAAAGGTTTATAACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAACGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAACTAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTGTTGCAGCCGATCATCAGCACATCTAGGTTTCGTCCGGGTGTGACA";
	
	//Gorilla anellovirus isolate GorF ORF2 and ORF1 genes, complete cds; and nonfunctional ORF3 gene, complete sequence
	genome2= "AGTCAAGGGGCAATTCGGGCTGGCGAAGTCTGGAGGAACGGGCAAGTGTCTTAAATTATATATTTTGTTTTACTTTACAGATATGTCTGATAGATGGATACCTCCTAAATATGCCTGGCAGGGAAGAGAATTACAGTGGGGATTAACTCAATCCACACTACACACGATACTTGGTGTGGCTGTAGTAGTGTTATTACTCACTTCTTACGCGCTGTTTCTGCTCGCGGTGAATTTTTACCTGTTTATACACCTGCCG";
	
	//Salmonella phage Chi, complete genome
	genome3 = "GGTGCGCAGAGCCGCATTCTCGGAAAATGGGCCGGATCTGCCATAGCCCCGCTTTGCGAAATCAATAACTTAGCCGAAAAATCGAATTTCTCCCGTAGGGAGGCTCCAAAACGCGGTGGTGACGGTGAAGTGCGGGTGGAACGGCGCTTTAACCCCGCAATCGTTTGATTGTATTACGGTTTTACCCGGCGGGTGGGTGCTGCCCAAGTCGGCAGTAGCAGCGCAGGGTTACAAGTTACAGACGGGTTACAAGTTT";
	
	isOnline = 1'b0;
	t = 0;
	i = 0;
	#100
	reset = 0;
	
	//offline
	genome = genome1;
	repeat(1000) begin
		@(posedge clk);
		if(flag == 1'b1) break;
		if(WmemFlag == 1'b1) begin//hash value is ready to write to memory
			for(i = 0;i< S; i++) begin
				listType toAdd;
				toAdd.g_id = 0;
				toAdd.w_index = w_i;
				if(memory[sig_val[i]].empty() == 1'b1) memory[sig_val[i]] = {toAdd};
				else memory[sig_val[i]].push_back(toAdd);
			end
		end
					
	end
	
	genome = genome2;
	repeat(1000) begin
		@(posedge clk);
		if(flag == 1'b1) break;
		if(WmemFlag == 1'b1) begin//hash value is ready to write to memory
			for(i = 0;i< S; i++) begin
				listType toAdd;
				toAdd.g_id = 1;
				toAdd.w_index = w_i;
				if(memory[sig_val[i]].empty() == 1'b1) memory[sig_val[i]] = {toAdd};
				else memory[sig_val[i]].push_back(toAdd);
			end
		end
	end
	genome = genome3;
	repeat(1000) begin
		@(posedge clk);
			if(flag == 1'b1) break;
			if(WmemFlag == 1'b1) begin//hash value is ready to write to memory
				for(i = 0;i< S; i++) begin
					listType toAdd;
					toAdd.g_id = 2;
					toAdd.w_index = w_i;
					if(memory[sig_val[i]].empty() == 1'b1) memory[sig_val[i]] = {toAdd};
					else memory[sig_val[i]].push_back(toAdd);
				end
			end
		end
		#100;
		//runtime
		//test for opoosite read from genome 1 with match
		isOnline = 1'b1;
		//read = "ATTAAAGGTTTATAACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAACGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAG";
		read = "TAATTTCCAAATATTGGAAGGGTCCATTGTTTGGTTGGTTGAAAGCTAGAGAACATCTAGACAAGAGATTTGCTTGAAATTTTAGACACACCGACAGTGAGCCGACGTACGAATCACGTGAGTGCGTA";
		repeat(500) begin
			@(posedge clk);
			if(flag == 1'b1 ) break;
			if(WmemFlag == 1'b1) begin//hash value is ready to write to memory
				for(i = 0;i< S; i++) begin
					listType toAdd;
					toAdd.g_id = 3;
					toAdd.w_index = w_i;
					if(memory[sig_val[i]].empty() == 1'b1) memory[sig_val[i]] = {toAdd};
					else memory[sig_val[i]].push_back(toAdd);
				end
			end
			if(RmemFlag == 2'b10) begin
				w_iO = memory[val][t].w_index;
				G_idO = memory[val][t].g_id;
				break;
			end		
		end

		@(posedge flag);
			if(hit == 1'b0) begin
				$display("no match!");
			end
			else begin
				$display("found match at window index = %d and in genome id = %d", w_i_result%1024, gid_result);
			end
		#100
		isOnline = 1'b0;
		
		//test for exact read from genome 2 with match
		#100
		isOnline = 1'b1;
			read = "AGTCAAGGGGCAATTCGGGCTGGCGAAGTCTGGAGGAACGGGCAAGTGTCTTAAATTATATATTTTGTTTTACTTTACAGATATGTCTGATAGATGGATACCTCCTAAATATGCCTGGCAGGGAAGAG";
			repeat(2) begin
				//@(posedge clk);
				//if(flag == 1'b1 ) break;
				//if(WmemFlag == 1'b1) begin//hash value is ready to write to memory
				@(posedge WmemFlag);
					for(i = 0;i< S; i++) begin
						listType toAdd;
						toAdd.g_id = 4;
						toAdd.w_index = w_i;
						if(memory[sig_val[i]].empty() == 1'b1) memory[sig_val[i]] = {toAdd};
						else memory[sig_val[i]].push_back(toAdd);
					end
				//end
				if(RmemFlag == 2'b10) begin
					w_iO = memory[val][t].w_index;
					G_idO = memory[val][t].g_id;
					break;
				end		
			end

			@(posedge flag);
				if(hit == 1'b0) begin
					$display("no match!");
				end
				else begin
					$display("found match at window index = %d and in genome id = %d", w_i_result%1024, gid_result);
				end
				#100
				isOnline = 1'b0;
				
				//test for mismatch for read 
				#100
				isOnline = 1'b1;
					read = "AGTCAAGAAACAATTCGGGCTGGCGAAGTCTGGAGGAAAAAACAAGTGTCTTAAATTATATATTTTGTTTGGGGGTACAGATATGTCTGATAGATGGATACCTCCCCCCTATGCCTGGTTTTGAAGAG";
					repeat(2) begin
						//@(posedge clk);
						//if(flag == 1'b1 ) break;
						@(posedge WmemFlag);//hash value is ready to write to memory
							for(i = 0;i< S; i++) begin
								listType toAdd;
								toAdd.g_id = 5;
								toAdd.w_index = w_i;
								if(memory[sig_val[i]].empty() == 1'b1) memory[sig_val[i]] = {toAdd};
								else memory[sig_val[i]].push_back(toAdd);
							end
						//end
						if(RmemFlag == 2'b10) begin
							w_iO = memory[val][t].w_index;
							G_idO = memory[val][t].g_id;
							break;
						end		
					end

					@(posedge flag);
						if(hit == 1'b0) begin
							$display("no match!");
						end
						else begin
							$display("found match at window index = %d and in genome id = %d", w_i_result%1024, gid_result);
						end
				#100
				isOnline = 1'b0;
					
				
				//test for matching read from genome 1 with mismatch in 2 kmers that matchs for genome 2
				#100
				isOnline = 1'b1;
					read = "ATTAAAGGTTTATAACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTTTGTTTTACTTTACAGATATGTCTGATAGATGGATACCTCCTAAATATGCCTGGCAGGGAAGAG";
					repeat(2) begin
						//@(posedge clk);
						//if(flag == 1'b1 ) break;
						@(posedge WmemFlag);//hash value is ready to write to memory
							for(i = 0;i< S; i++) begin
								listType toAdd;
								toAdd.g_id = 6;
								toAdd.w_index = w_i;
								if(memory[sig_val[i]].empty() == 1'b1) memory[sig_val[i]] = {toAdd};
								else memory[sig_val[i]].push_back(toAdd);
							end
						//end
						if(RmemFlag == 2'b10) begin
							w_iO = memory[val][t].w_index;
							G_idO = memory[val][t].g_id;
							break;
						end		
					end

					@(posedge flag);
						if(hit == 1'b0) begin
							$display("no match!");
						end
						else begin
							$display("found match at window index = %d and in genome id = %d", w_i_result%1024, gid_result);
						end
						#100
						isOnline = 1'b0;
						//test for match in genome 3
						#100
						isOnline = 1'b1;
						read = "CCAAACGGTGGAACGGCGCTTTAACCCCGCAATCGTTTGATTGTATTACGGTTTTACCCGGCGGGTGGGTGCTGCCCAAGTCGGCAGTAGCAGCGCAGGGTTACAAGTTACAGACGGGTTACAAGTTT";
						repeat(2) begin
							//@(posedge clk);
							//if(flag == 1'b1 ) break;
							@(posedge WmemFlag);//hash value is ready to write to memory
								for(i = 0;i< S; i++) begin
									listType toAdd;
									toAdd.g_id = 7;
									toAdd.w_index = w_i;
									if(memory[sig_val[i]].empty() == 1'b1) memory[sig_val[i]] = {toAdd};
									else memory[sig_val[i]].push_back(toAdd);
								end
							//end
							if(RmemFlag == 2'b10) begin
								w_iO = memory[val][t].w_index;
								G_idO = memory[val][t].g_id;
								break;
							end		
						end

						@(posedge flag);
							if(hit == 1'b0) begin
								$display("no match!");
							end
							else begin
								$display("found match at window index = %d and in genome id = %d", w_i_result%1024, gid_result);
							end
							#100$finish;
				
				
	/*fd = $fopen("genome_reference", "r");

	$fgets(genome1, fd);
	genome1 <<= 1024;
	$fgets(genome1, fd);

	$fgets(genome2, fd);
	genome2 <<= 1024;
	$fgets(genome2, fd);
	
	$fgets(genome3, fd);
	genome3 <<= 1024;
	$fgets(genome3, fd);
	
	$display("genome1:%s\n", genome1);
	$display("genome2:%s\n", genome2);
	$display("genome3:%s\n", genome3);
	
	$fclose(fd);*/
	
end

always #50 clk = ~clk;
always #60 clk2 = ~clk2;


always@(posedge clk) begin
	if(RmemFlag != 2'b0) begin
		w_iO = (memory[val][t].w_index)/1024;
		G_idO = memory[val][t].g_id;
		t+=1;
		if(G_idO != 0 && G_idO != 1 && G_idO != 2) t=0;
	end
	else begin
		w_iO = w_iO;
		G_idO = G_idO;
	end
end


endmodule