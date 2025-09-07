`timescale 1ns / 1ps

module mips32_dhzrem(clk1, clk2);
    input clk1, clk2;
    reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
    reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
    reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;
    reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
    reg EX_MEM_cond;
    reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
    reg [31:0] RegBank [0:31];
    reg [31:0] Mem     [0:1023];
    
    // Forwarding signals
    reg [31:0] forward_A, forward_B;
    
    // Hazard detection signals
    reg STALL, FLUSH;
    reg [31:0] IF_ID_IR_temp, IF_ID_NPC_temp;
    
    parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,
              SLT=6'b000100, MUL=6'b000101, HLT=6'b111111, LW=6'b001000,
              SW=6'b001001, ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100,
              BNEQZ=6'b001101, BEQZ=6'b001110; 
    
    parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011, 
              BRANCH=3'b100, HALT=3'b101;
    
    reg STOPPED;
    reg BRANCH_INSTR;

    // Hazard detection logic
    always @(*) begin
        STALL = 0;
        FLUSH = 0;
        
        // Load-use hazard detection
        if (ID_EX_type == LOAD && 
            ((ID_EX_IR[20:16] == IF_ID_IR[25:21]) ||  // rs dependency
             (ID_EX_IR[20:16] == IF_ID_IR[20:16])))   // rt dependency
        begin
            STALL = 1;
        end
        
        // Branch hazard - flush instruction after branch
        if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) ||
            ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0))) 
        begin
            FLUSH = 1;
        end
    end

    // Forwarding logic
    always @(*) begin
        forward_A = ID_EX_A;
        forward_B = ID_EX_B;
        if (EX_MEM_type != HALT && EX_MEM_IR[31:26] != HLT) begin
            if (EX_MEM_IR[31:26] >= ADD && EX_MEM_IR[31:26] <= MUL) begin
                if (EX_MEM_IR[15:11] != 0) begin
                    if (EX_MEM_IR[15:11] == ID_EX_IR[25:21]) 
                        forward_A = EX_MEM_ALUOut;
                    if (EX_MEM_IR[15:11] == ID_EX_IR[20:16]) 
                        forward_B = EX_MEM_ALUOut;
                end
            end
            else if ((EX_MEM_IR[31:26] >= ADDI && EX_MEM_IR[31:26] <= SLTI) || 
                     EX_MEM_IR[31:26] == LW) begin
                if (EX_MEM_IR[20:16] != 0) begin
                    if (EX_MEM_IR[20:16] == ID_EX_IR[25:21]) 
                        forward_A = EX_MEM_ALUOut;
                    if (EX_MEM_IR[20:16] == ID_EX_IR[20:16]) 
                        forward_B = EX_MEM_ALUOut;
                end
            end
        end
        
        
    end

    always @(posedge clk1) //IF
        if (STOPPED == 0) begin
            if (STALL) begin
                IF_ID_IR <= IF_ID_IR;
                IF_ID_NPC <= IF_ID_NPC;
                PC <= PC;
            end
            else if (FLUSH) begin
                IF_ID_IR <= 32'h00000000; 
                IF_ID_NPC <= IF_ID_NPC;
                PC <= EX_MEM_ALUOut + 1;
            end
            else if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) ||
                    ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0))) begin
                IF_ID_IR <= #2 Mem[EX_MEM_ALUOut];
                BRANCH_INSTR <= #2 1'b1;
                IF_ID_NPC <= #2 EX_MEM_ALUOut + 1;
                PC <= #2 EX_MEM_ALUOut + 1;
            end else begin
                IF_ID_IR <= #2 Mem[PC];
                IF_ID_NPC <= #2 PC + 1;
                PC <= #2 PC + 1;
            end
        end

    always @(posedge clk2) //ID
        if (STOPPED == 0) begin
            if (STALL) begin
                ID_EX_IR <= 32'h00000000;
                ID_EX_type <= RR_ALU;
                ID_EX_A <= 0;
                ID_EX_B <= 0;
                ID_EX_Imm <= 0;
                ID_EX_NPC <= ID_EX_NPC;
            end else begin
                if (IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0;
                else ID_EX_A <= #2 RegBank[IF_ID_IR[25:21]]; // "rs"
                
                if (IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0;
                else ID_EX_B <= #2 RegBank[IF_ID_IR[20:16]]; // "rt"
                
                ID_EX_NPC <= #2 IF_ID_NPC;
                ID_EX_IR <= #2 IF_ID_IR;
                ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};
                
                case (IF_ID_IR[31:26])
                    ADD,SUB,AND,OR,SLT,MUL: ID_EX_type <= #2 RR_ALU;
                    ADDI,SUBI,SLTI: ID_EX_type <= #2 RM_ALU;
                    LW: ID_EX_type <= #2 LOAD;
                    SW: ID_EX_type <= #2 STORE;
                    BNEQZ,BEQZ: ID_EX_type <= #2 BRANCH;
                    HLT: ID_EX_type <= #2 HALT;
                    default: ID_EX_type <= #2 RR_ALU; 
                endcase
            end
        end

    always @(posedge clk1) //EX
        if (STOPPED == 0) begin
            EX_MEM_type <= #2 ID_EX_type;
            EX_MEM_IR <= #2 ID_EX_IR;
            BRANCH_INSTR <= #2 0;
            
            case (ID_EX_type)
                RR_ALU: begin
                    case (ID_EX_IR[31:26]) 
                        ADD: EX_MEM_ALUOut <= #2 forward_A + forward_B;
                        SUB: EX_MEM_ALUOut <= #2 forward_A - forward_B;
                        AND: EX_MEM_ALUOut <= #2 forward_A & forward_B;
                        OR: EX_MEM_ALUOut <= #2 forward_A | forward_B;
                        SLT: EX_MEM_ALUOut <= #2 forward_A < forward_B;
                        MUL: EX_MEM_ALUOut <= #2 forward_A * forward_B;
                        default: EX_MEM_ALUOut <= #2 32'h00000000; // NOP
                    endcase
                end
                
                RM_ALU: begin
                    case (ID_EX_IR[31:26]) 
                        ADDI: EX_MEM_ALUOut <= #2 forward_A + ID_EX_Imm;
                        SUBI: EX_MEM_ALUOut <= #2 forward_A - ID_EX_Imm;
                        SLTI: EX_MEM_ALUOut <= #2 forward_A < ID_EX_Imm;
                        default: EX_MEM_ALUOut <= #2 32'h00000000; // NOP
                    endcase
                end
                
                LOAD, STORE: begin
                    EX_MEM_ALUOut <= #2 forward_A + ID_EX_Imm;
                    EX_MEM_B <= #2 forward_B;
                end
                
                BRANCH: begin
                    EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;
                    EX_MEM_cond <= #2 (forward_A == 0);
                end
                
                default: begin
                    EX_MEM_ALUOut <= #2 32'h00000000; 
                    EX_MEM_cond <= 0;
                end
            endcase
        end

    always @(posedge clk2) //MEM
        if (STOPPED == 0) begin
            MEM_WB_type <= EX_MEM_type;
            MEM_WB_IR <= #2 EX_MEM_IR;
            
            case (EX_MEM_type)
                RR_ALU, RM_ALU:
                    MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;
                LOAD: 
                    MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut];
                STORE: 
                    if (BRANCH_INSTR == 0) 
                        Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;
                default:
                    MEM_WB_ALUOut <= #2 32'h00000000; 
            endcase
        end

    always @(posedge clk1) //WB
        begin
            if (BRANCH_INSTR == 0) 
                case (MEM_WB_type)
                    RR_ALU: 
                        if (MEM_WB_IR[15:11] != 0)
                            RegBank[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut; // "rd"
                    RM_ALU: 
                        if (MEM_WB_IR[20:16] != 0)
                            RegBank[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut; // "rt"
                    LOAD: 
                        if (MEM_WB_IR[20:16] != 0)
                            RegBank[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD; // "rt"
                    HALT: STOPPED <= #2 1'b1;
                endcase
        end

endmodule