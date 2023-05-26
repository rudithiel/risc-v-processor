//Module: CPU
//Function: CPU is the top design of the RISC-V processor

//Inputs:
//	clk: main clock
//	arst_n: reset
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



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
                  alu_operand_1,
                  alu_operand_2;

wire signed [63:0] immediate_extended;

// PIPELINE WIRES

// IF/ID
wire [63:0] pc_IF_ID, updated_pc_IF_ID;
wire [31:0] instruction_IF_ID;

// ID/EX
wire [63:0] pc_ID_EX, updated_pc_ID_EX;
wire [31:0] instruction_ID_EX;
wire [1:0] alu_op_ID_EX;
wire [63:0] immediate_extended_ID_EX;
wire [63:0] regfile_rdata_1_ID_EX, regfile_rdata_2_ID_EX;
wire reg_dst_ID_EX, mem_read_ID_EX, mem_2_reg_ID_EX, mem_write_ID_EX, alu_src_ID_EX, reg_write_ID_EX;

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_IF_ID),
    .immediate_extended  (immediate_extended)
);
// EX/MEM
wire [4:0] instruction_11_7_EX_MEM;
wire [63:0] regfile_rdata_2_EX_MEM, alu_out_EX_MEM;
wire [63:0] branch_pc_EX_MEM, jump_pc_EX_MEM;
wire zero_flag_EX_MEM;
wire reg_dst_EX_MEM, mem_read_EX_MEM, mem_2_reg_EX_MEM, mem_write_EX_MEM, reg_write_EX_MEM, jump_EX_MEM, branch_EX_MEM;

// MEM/WB
wire [4:0] instruction_11_7_MEM_WB;
wire [63:0] alu_out_MEM_WB;
wire [63:0] mem_data_MEM_WB;
wire mem_2_reg_MEM_WB;
wire reg_write_MEM_WB;
// PIPELINE REGISTERS

// IF/ID
reg_arstn_en #(
    .DATA_W(64)
) pc_pipe_IF_ID (
    .clk (clk),
    .arst_n (arst_n),
    .din(current_pc),
    .en (enable),
    .dout(pc_IF_ID)
);

reg_arstn_en #(
    .DATA_W(64)
) updated_pc_pipe_IF_ID (
    .clk (clk),
    .arst_n (arst_n),
    .din(updated_pc),
    .en (enable),
    .dout(updated_pc_IF_ID)
);

reg_arstn_en #(
    .DATA_W(32)
) instruction_pipe_IF_ID (
    .clk (clk),
    .arst_n (arst_n),
    .din(instruction),
    .en (enable),
    .dout(instruction_IF_ID)
);

// ID/EX
reg_arstn_en #(
    .DATA_W(32)
) instruction_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(instruction_IF_ID),
    .en (enable),
    .dout(instruction_ID_EX)
);

reg_arstn_en #(
    .DATA_W(64)
) immediate_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(immediate_extended),
    .en (enable),
    .dout(immediate_extended_ID_EX)
);

reg_arstn_en #(
    .DATA_W(64)
) updated_pc_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(updated_pc_IF_ID),
    .en (enable),
    .dout(updated_pc_ID_EX)
);

reg_arstn_en #(
    .DATA_W(1)
) reg_write_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(reg_write),
    .en (enable),
    .dout(reg_write_ID_EX)
);

reg_arstn_en #(
    .DATA_W(1)
) mem_write_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(mem_write),
    .en (enable),
    .dout(mem_write_ID_EX)
);

reg_arstn_en #(
    .DATA_W(1)
) reg_dst_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(reg_dst),
    .en (enable),
    .dout(reg_dst_ID_EX)
);

reg_arstn_en #(
    .DATA_W(1)
) mem_read_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(mem_read),
    .en (enable),
    .dout(mem_read_ID_EX)
);

reg_arstn_en #(
    .DATA_W(1)
) mem_2reg_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(mem_2_reg),
    .en (enable),
    .dout(mem_2_reg_ID_EX)
);

reg_arstn_en #(
    .DATA_W(1)
) alu_src_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(alu_src), //From control unit output
    .en (enable),
    .dout(alu_src_ID_EX) //To reg output wire
);

reg_arstn_en #(
    .DATA_W(2)
) alu_op_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(alu_op),
    .en (enable),
    .dout(alu_op_ID_EX)
);


reg_arstn_en #(
    .DATA_W(64)
) pc_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(pc_IF_ID), //From control unit output
    .en (enable),
    .dout(pc_ID_EX) //To reg output wire
);

// RDATA OUT FROM REG FILE
reg_arstn_en #(
    .DATA_W(64)
) regfile_rdata_1_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(regfile_rdata_1), //From control unit output
    .en (enable),
    .dout(regfile_rdata_1_ID_EX) //To reg output wire
);

reg_arstn_en #(
    .DATA_W(64)
) regfile_rdata_2_pipe_ID_EX (
    .clk (clk),
    .arst_n (arst_n),
    .din(regfile_rdata_2), //From control unit output
    .en (enable),
    .dout(regfile_rdata_2_ID_EX) //To reg output wire
);


// EX/MEM
reg_arstn_en #(
    .DATA_W(5)
) instruction_11_7_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(instruction_ID_EX[11:7]), //From control unit output
    .en (enable),
    .dout(instruction_11_7_EX_MEM) //To reg output wire
);

reg_arstn_en #(
    .DATA_W(64)
) regfile_rdata_2_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(regfile_rdata_2_ID_EX), //From control unit output
    .en (enable),
    .dout(regfile_rdata_2_EX_MEM) //To reg output wire
);

reg_arstn_en #(
    .DATA_W(64)
) alu_out_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(alu_out), //From control unit output
    .en (enable),
    .dout(alu_out_EX_MEM) //To reg output wire
);

reg_arstn_en #(
    .DATA_W(1)
) zero_flag_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(zero_flag), //From control unit output
    .en (enable),
    .dout(zero_flag_EX_MEM) //To reg output wire
);

reg_arstn_en #(
    .DATA_W(64)
) branch_pc_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(branch_pc), //From control unit output
    .en (enable),
    .dout(branch_pc_EX_MEM) //To reg output wire
);

reg_arstn_en #(
    .DATA_W(64)
) jump_pc_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(jump_pc), //From control unit output
    .en (enable),
    .dout(jump_pc_EX_MEM) //To reg output wire
);

reg_arstn_en #(
    .DATA_W(1)
) mem_write_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(mem_write_ID_EX),
    .en (enable),
    .dout(mem_write_EX_MEM)
);

reg_arstn_en #(
    .DATA_W(1)
) reg_dst_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(reg_dst_ID_EX),
    .en (enable),
    .dout(reg_dst_EX_MEM)
);

reg_arstn_en #(
    .DATA_W(1)
) mem_read_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(mem_read_ID_EX),
    .en (enable),
    .dout(mem_read_EX_MEM)
);

reg_arstn_en #(
    .DATA_W(1)
) mem_2reg_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(mem_2_reg_ID_EX),
    .en (enable),
    .dout(mem_2_reg_EX_MEM)
);

reg_arstn_en #(
    .DATA_W(1)
) reg_write_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(reg_write_ID_EX),
    .en (enable),
    .dout(reg_write_EX_MEM)
);

reg_arstn_en #(
    .DATA_W(1)
) jump_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(jump),
    .en (enable),
    .dout(jump_EX_MEM)
);

reg_arstn_en #(
    .DATA_W(1)
) branch_pipe_EX_MEM (
    .clk (clk),
    .arst_n (arst_n),
    .din(branch),
    .en (enable),
    .dout(branch_EX_MEM)
);

// MEM/WB
reg_arstn_en #(
    .DATA_W(5)
) instruction_11_7_pipe_MEM_WB (
    .clk (clk),
    .arst_n (arst_n),
    .din(instruction_11_7_EX_MEM),
    .en (enable),
    .dout(instruction_11_7_MEM_WB)
);

reg_arstn_en #(
    .DATA_W(64)
) alu_out_pipe_MEM_WB (
    .clk (clk),
    .arst_n (arst_n),
    .din(alu_out_EX_MEM),
    .en (enable),
    .dout(alu_out_MEM_WB)
);

reg_arstn_en #(
    .DATA_W(64)
) mem_data_pipe_MEM_WB (
    .clk (clk),
    .arst_n (arst_n),
    .din(mem_data),
    .en (enable),
    .dout(mem_data_MEM_WB)
);

reg_arstn_en #(
    .DATA_W(1)
) mem_2reg_pipe_MEM_WB (
    .clk (clk),
    .arst_n (arst_n),
    .din(mem_2_reg_EX_MEM),
    .en (enable),
    .dout(mem_2_reg_MEM_WB)
);

reg_arstn_en #(
    .DATA_W(1)
) reg_write_pipe_MEM_WB (
    .clk (clk),
    .arst_n (arst_n),
    .din(reg_write_EX_MEM),
    .en (enable),
    .dout(reg_write_MEM_WB)
);

//////////////////////////

pc #(
   .DATA_W(64)
) program_counter (
    .clk       (clk       ),
    .arst_n    (arst_n    ),
    .branch_pc (branch_pc_EX_MEM ),
    .jump_pc   (jump_pc_EX_MEM   ),
    .zero_flag (zero_flag_EX_MEM ),
    .branch    (branch_EX_MEM    ),
    .jump      (jump_EX_MEM      ),
    .current_pc(current_pc),
    .enable    (enable    ),
    .updated_pc(updated_pc)
);

sram_BW32 #(
   .ADDR_W(9 )
) instruction_memory(
   .clk      (clk           ),
    .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction),
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
    .addr     (alu_out_EX_MEM        ),
    .wen      (mem_write_EX_MEM      ),
    .ren      (mem_read_EX_MEM       ),
    .wdata    (regfile_rdata_2_EX_MEM),
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
) register_file(
   .clk       (clk               ),
   .arst_n    (arst_n            ),
   .reg_write (reg_write_MEM_WB         ),
   .raddr_1   (instruction_IF_ID[19:15]),
   .raddr_2   (instruction_IF_ID[24:20]),
   .waddr     (instruction_11_7_MEM_WB),
   .wdata     (regfile_wdata     ),
   .rdata_1   (regfile_rdata_1   ),
   .rdata_2   (regfile_rdata_2   )
);

alu_control alu_ctrl(
    .func7_5        (instruction_ID_EX[30]   ),
    .func7_0        (instruction_ID_EX[25]),
    .func3          (instruction_ID_EX[14:12]),
    .alu_op         (alu_op_ID_EX            ),
    .alu_control    (alu_control       )
);

wire [63:0] mux_2_out;

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
    .input_a (immediate_extended_ID_EX),
    .input_b (mux_3_2_out    ),
    .select_a(alu_src_ID_EX           ),
    .mux_out (alu_operand_2     )
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (alu_operand_1 ),
   .alu_in_1 (alu_operand_2   ),
   .alu_ctrl (alu_control     ),
   .alu_out  (alu_out         ),
   .zero_flag(zero_flag       ),
   .overflow (                )
);

mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
    .input_a  (mem_data_MEM_WB     ),
    .input_b  (alu_out_MEM_WB      ),
    .select_a (mem_2_reg_MEM_WB    ),
    .mux_out  (regfile_wdata)
);

branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (updated_pc_ID_EX        ),
   .immediate_extended (immediate_extended_ID_EX),
   .branch_pc          (branch_pc         ),
   .jump_pc            (jump_pc           )
);

// Declare the forwarding unit.
wire [1:0] rs1_forward;
wire [1:0] rs2_forward;

// Instantiate the forwarding unit.
forwarding_unit fu(
    .rs1(instruction_ID_EX[19:15]),  // Rs field from ID/EX pipeline register
    .rs2(instruction_ID_EX[24:20]),  // Rt field from ID/EX pipeline register
    .rd_MEM_WB(instruction_11_7_MEM_WB), // Rd field from MEM/WB pipeline register
    .rd_EX_MEM(instruction_11_7_EX_MEM), // Rd field from EX/MEM pipeline register
    .reg_write_MEM_WB(reg_write_MEM_WB), // RegWrite field from MEM/WB pipeline register
    .reg_write_EX_MEM(reg_write_EX_MEM), // RegWrite field from EX/MEM pipeline register
    .rs1_forward(rs1_forward), // Forwarding control for Rs
    .rs2_forward(rs2_forward) // Forwarding control for Rt
);

mux_3 #(
  .DATA_W(64)
) mux_3_inst1 (
  .select    (rs1_forward),
  .input_a    (regfile_rdata_1_ID_EX),
  .input_b    (regfile_wdata),
  .input_c    (alu_out_EX_MEM),
  .mux_out    (alu_operand_1)
);

wire [63:0] mux_3_2_out;

mux_3 #(
  .DATA_W(64)
) mux_3_inst2 (
  .select    (rs2_forward),
  .input_a    (regfile_rdata_2_ID_EX),
  .input_b    (regfile_wdata),
  .input_c    (alu_out_EX_MEM),
  .mux_out    (mux_3_2_out)
);

endmodule


