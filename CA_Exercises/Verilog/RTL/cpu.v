module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[63:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[63:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      63:0] branch_pc,updated_pc,current_pc,jump_pc;
wire [      31:0] instruction;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      63:0] regfile_wdata,mem_data,alu_out,
                  regfile_rdata_1,regfile_rdata_2,
                  alu_operand_2;
wire [63:0] pc_IF_ID;
wire [31:0] instruction_IF_ID;
wire [63:0] immediate_extended;
wire [63:0] regfile_rdata_1_ID_EX, regfile_rdata_2_ID_EX, immediate_extended_ID_EX;
wire [ 4:0] regfile_waddr_ID_EX;
wire        reg_dst_ID_EX, alu_src_ID_EX, reg_write_ID_EX;
wire [ 3:0] alu_control_ID_EX;

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_IF_ID),
    .immediate_extended  (immediate_extended)
);
    
    
// IF/ID PIPELINE REGISTERS
reg_arstn_en #(
    .DATA_W(64)
) pc_pipe_IF_ID (
    .clk (clk),
    .arst_n (arst_n),
    .din (current_pc),
    .en (enable),
    .dout (pc_IF_ID)
);
    
reg_arstn_en #(
    .DATA_W(32)
) instruction_pipe_IF_ID (
    .clk    (clk),
    .arst_n (arst_n),
    .din    (instruction),
    .en     (enable),
    .dout   (instruction_IF_ID)
);

//ID/EX PIPELINE REGISTERS
reg_arstn_en #(
    .DATA_W(64)
) regfile_rdata_1_pipe_ID_EX (
    .clk    (clk),
    .arst_n (arst_n),
    .din    (regfile_rdata_1),
    .en     (enable),
    .dout   (regfile_rdata_1_ID_EX)
);

reg_arstn_en #(
    .DATA_W(64)
) regfile_rdata_2_pipe_ID_EX (
    .clk    (clk),
    .arst_n (arst_n),
    .din    (regfile_rdata_2),
    .en     (enable),
    .dout   (regfile_rdata_2_ID_EX)
);

reg_arstn_en #(
        .DATA_W(64)
) immediate_extended_pipe_ID_EX (
    .clk    (clk),
    .arst_n (arst_n),
    .din    (immediate_extended),
    .en     (enable),
    .dout   (immediate_extended_ID_EX)
);

reg_arstn_en #(
    .DATA_W(5)
) regfile_waddr_pipe_ID_EX (
    .clk    (clk),
    .arst_n (arst_n),
    .din    (regfile_waddr),
    .en     (enable),
    .dout   (regfile_waddr_ID_EX)
);

reg_arstn_en #(
    .DATA_W(1)
) control_signals_pipe_ID_EX (
    .clk    (clk),
    .arst_n (arst_n),
    .din    ({reg_dst, alu_src, reg_write}),
    .en     (enable),
    .dout   ({reg_dst_ID_EX, alu_src_ID_EX, reg_write_ID_EX})
);

reg_arstn_en #(
    .DATA_W(4)
) alu_control_pipe_ID_EX (
    .clk    (clk),
    .arst_n (arst_n),
    .din    (alu_control),
    .en     (enable),
    .dout   (alu_control_ID_EX)
);


pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc ),
   .jump_pc   (jump_pc   ),
   .zero_flag (zero_flag ),
   .branch    (branch    ),
   .jump      (jump      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);

sram_BW32 #(
   .ADDR_W(9 )
) instruction_memory(
   .clk      (clk           ),
   .addr     (pc_IF_ID    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

sram_BW64 #(
   .ADDR_W(10)
) data_memory(
   .clk      (clk            ),
    .addr     (alu_out_ID_EX        ),
   .wen      (mem_write      ),
   .ren      (mem_read       ),
   .wdata    (regfile_rdata_2),
   .rdata    (mem_data       ),   
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);

control_unit control_unit(
   .opcode   (instruction_IF_ID[6:0]),
   .alu_op   (alu_op          ),
   .reg_dst  (reg_dst         ),
   .branch   (branch          ),
   .mem_read (mem_read        ),
   .mem_2_reg(mem_2_reg       ),
   .mem_write(mem_write       ),
   .alu_src  (alu_src         ),
   .reg_write(reg_write       ),
   .jump     (jump            )
);
    
    

register_file #(
    .DATA_W(64)
) reg_file (
    .clk             (clk               ),
    .arst_n          (arst_n            ),
    .regfile_waddr   (regfile_waddr_ID_EX   ),
    .regfile_wdata   (regfile_wdata     ),
    .regfile_wen     (reg_write_ID_EX         ),
    .regfile_raddr_1 (instruction_IF_ID[19:15]),
    .regfile_raddr_2 (instruction_IF_ID[24:20]),
    .regfile_rdata_1 (regfile_rdata_1   ),
    .regfile_rdata_2 (regfile_rdata_2   )
);

alu_control_unit alu_control_unit(
    .funct3     (instruction_IF_ID[14:12]),
    .funct7     (instruction_IF_ID[31:25]),
    .alu_op     (alu_op                ),
    .alu_control(alu_control           )
);

alu #(
    .DATA_W(64)
) alu (
    .alu_operand_1   (regfile_rdata_1_ID_EX),
    .alu_operand_2   (alu_operand_2_ID_EX),
    .alu_control     (alu_control_ID_EX),
    .zero_flag       (zero_flag        ),
    .alu_out         (alu_out          )
);

mux_2to1 #(
    .DATA_W(64)
) mux_alu_operand_2 (
    .sel    (alu_src_ID_EX),
    .din_0  (regfile_rdata_2_ID_EX),
    .din_1  (immediate_extended_ID_EX),
    .dout   (alu_operand_2_ID_EX)
);

mux_2to1 #(
    .DATA_W(64)
) mux_regfile_wdata (
    .sel    (mem_2_reg     ),
    .din_0  (alu_out       ),
    .din_1  (mem_data      ),
    .dout   (regfile_wdata )
);

branch_unit #(
    .DATA_W(64)
) branch_unit (
    .regfile_rdata_1(regfile_rdata_1_ID_EX),
    .regfile_rdata_2(regfile_rdata_2_ID_EX),
    .zero_flag      (zero_flag         ),
    .branch         (branch            )
);

assign jump_pc = {instruction_IF_ID[31], instruction_IF_ID[19:12], instruction_IF_ID[20], instruction_IF_ID[30:21], 1'b0};

endmodule

