`timescale 1ns / 1ps
module test_mips32();
    reg clk1, clk2;
    integer k;
    mips32_dhzrem mips (clk1, clk2);
    
    initial begin
        clk1 = 0; clk2 = 0;
        repeat (500) begin
            #5 clk1 = 1; #5 clk1 = 0;
            #5 clk2 = 1; #5 clk2 = 0;
        end
    end
    
    initial begin
        for (k=0; k<31; k=k+1)
            mips.RegBank[k] = k;
        
        // Instruction Encodings
        mips.Mem[0] = 32'h280a00c8; // ADDI R10,R0,200
        mips.Mem[1] = 32'h28020001; // ADDI R2,R0,1
        mips.Mem[2] = 32'h21430000; // LW R3,0(R10) 
        mips.Mem[3] = 32'h14431000; // Loop: MUL R2,R2,R3
        mips.Mem[4] = 32'h2c630001; // SUBI R3,R3,1   
        mips.Mem[5] = 32'h3460fffc; // BNEQZ R3,Loop (i.e. -4 offset)
        mips.Mem[6] = 32'h2542fffe; // SW R2,-2(R10) 
        mips.Mem[7] = 32'hfc000000; // HLT
        
        mips.Mem[200] = 10; // Calculating factorial of 10
        
        mips.PC = 0;
        mips.STOPPED = 0;
        mips.BRANCH_INSTR = 0;
        
        #2000 $display ("Mem[200] = %2d, Mem[198] = %6d", mips.Mem[200], mips.Mem[198]);
    end
    
    initial begin
        $dumpfile ("mips.vcd");
        $dumpvars (0, test_mips32);
        $monitor ("R2: %8d", mips.RegBank[2]);
        #3000 $finish;
    end
endmodule