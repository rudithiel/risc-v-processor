module forwarding_unit(
    input wire[4:0]  rs1,  // Source register 1
    input wire[4:0]  rs2,  // Source register 2
    input wire[4:0]  rd_MEM_WB,  // MEM/WB pipeline register destination register
    input wire[4:0]  rd_EX_MEM, // EX/MEM pipeline register destination register
    input wire       reg_write_MEM_WB, // MEM/WB pipeline register regwrite signal
    input wire       reg_write_EX_MEM, // EX/MEM pipeline register regwrite signal
    output reg[1:0]  rs1_forward,  // Forwarding control signal for rs1
    output reg[1:0]  rs2_forward   // Forwarding control signal for rs2
    );

    always @(*) begin
        // Default: No forwarding.
        rs1_forward = 2'b00; 
        rs2_forward = 2'b00;

        // Forwarding from EX/MEM stage.
        if ((reg_write_EX_MEM == 1'b1 && rd_EX_MEM == rs1) && 
            !(reg_write_MEM_WB == 1'b1 && rd_MEM_WB == rs1))
            rs1_forward = 2'b10;
        else
            rs1_forward = 2'b00;

        if ((reg_write_EX_MEM == 1'b1 && rd_EX_MEM == rs2) && 
            !(reg_write_MEM_WB == 1'b1 && rd_MEM_WB == rs2))
            rs2_forward = 2'b10;
        else 
            rs2_forward = 2'b00;

        // Forwarding from MEM/WB stage.
        if (reg_write_MEM_WB && (rd_MEM_WB != 5'b0000) && (rd_MEM_WB == rs1)) 
            rs1_forward = 2'b01;
        if (reg_write_MEM_WB && (rd_MEM_WB != 5'b0000) && (rd_MEM_WB == rs2)) 
            rs2_forward = 2'b01;
        
    end
endmodule
