`timescale 1ns/10ps
`define PERIOD    10.0
`define End_CYCLE  100000

`ifdef APR
    `define SDFFILE "../04_APR/output/MIMO_APR.sdf"
`elsif GATE
    `define SDFFILE "../02_SYN/Netlist/MIMO_syn.sdf"
`endif

module tb();
    parameter test_num = 10;
    integer num_Y, num_Result;
    integer error;

    reg clk, rst;
    reg [79:0] InData;
    wire [23:0] OutData;
    wire y_req;
    wire out_valid;

    reg [79:0] y [0:test_num-1];
    reg [23:0] golden_mem [0:test_num-1];

    initial $readmemb("../00_TB/input.dat", y);
    initial $readmemb("../00_TB/golden.dat", golden_mem);

    initial clk = 1'b0;
    always begin #(`PERIOD/2) clk = ~clk; end

    MIMO MIMO(
        .clk(clk),
        .rst(rst),
        .InData(InData),
        .y_req(y_req),
        .OutData(OutData),
        .out_valid(out_valid)
    );

    initial begin
        rst = 1'b0;
        #(`PERIOD/4) rst = 1'b1;
        #(`PERIOD/2) rst = 1'b0;
    end

    initial begin
        num_Y = 0;
        num_Result = 0;
        error = 0;
    end

    always@(negedge clk)begin
        if((num_Y < test_num) && (y_req))begin
            InData = y[num_Y];
            num_Y = num_Y + 1;
        end
        else begin
            InData = 80'b0;
        end
    end

    
    always@(negedge clk)begin
        if((num_Result<test_num) && (out_valid))begin
            if(OutData !== golden_mem[num_Result])begin
                $display("There is a error in input %d, your answer is %b, but golden is %b",num_Result+1,OutData,golden_mem[num_Result]);
                error = error + 1;
            end
            num_Result = num_Result + 1;
        end
        if(num_Result === test_num)begin
            if(error !== 0)begin
                $display("-----------------------------------------------------\n");
	            $display("Error!!! There is something wrong with your code ...!\n");
 	            $display("------The test result is .....FAIL ------------------\n");
 	            $display("-----------------------------------------------------\n");
 	            $finish;
            end
            else begin
                $display("-----------------------------------------------------\n");
	            $display("                Pass!!!!!!!!!!!!!!!                  \n");
 	            $display("------The test result is .....Correct ------------------\n");
 	            $display("-----------------------------------------------------\n");
 	            $finish;
            end
        end
    end

    initial begin
        $fsdbDumpfile("MIMO.fsdb");
        $fsdbDumpvars(0, tb, "+mda");
    end

    initial begin
	#(`End_CYCLE*(`PERIOD));
	$display("-----------------------------------------------------\n");
	$display("Error!!! There is something wrong with your code ...!\n");
 	$display("------The test result is .....FAIL ------------------\n");
 	$display("-----------------------------------------------------\n");
 	$finish;
    end

    `ifdef SDF
        initial $sdf_annotate(`SDFFILE, MIMO);
        initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
    `endif
    
endmodule
