module MIMO( clk, rst, InData, y_req, OutData, out_valid);
    
    input clk;
    input rst;
    input [79:0] InData;
    output y_req;
    output [23:0] OutData;
    output out_valid;

    parameter signed [7:0] H11_real= 8'b00001100,
                    H11_imag= 8'b00000011,
                    H12_real= 8'b00001011,
                    H12_imag= 8'b00000100,
                    H13_real= 8'b11100111,
                    H13_imag= 8'b01111111,
                    H14_real= 8'b11111101,
                    H14_imag= 8'b10000110,

                    H21_real= 8'b01001110,
                    H21_imag= 8'b00000000,
                    H22_real= 8'b00000000,
                    H22_imag= 8'b00000000,
                    H23_real= 8'b10011101,
                    H23_imag= 8'b10110101,
                    H24_real= 8'b11111111,
                    H24_imag= 8'b00111000,

                    H31_real= 8'b11110111,
                    H31_imag= 8'b11010011,
                    H32_real= 8'b00101100,
                    H32_imag= 8'b10000001,
                    H33_real= 8'b10011011,
                    H33_imag= 8'b10110001,
                    H34_real= 8'b10001010,
                    H34_imag= 8'b00101111,

                    H41_real= 8'b11001000,
                    H41_imag= 8'b11010100,
                    H42_real= 8'b00000111,
                    H42_imag= 8'b01000001,
                    H43_real= 8'b00111000,
                    H43_imag= 8'b01011001,
                    H44_real= 8'b01111111,
                    H44_imag= 8'b01111111;
    
    parameter IDLE = 0;
    parameter CALC = 1;
    parameter OUTPUT = 2;
    parameter DONE = 3;

    integer i, j, k;

    parameter signed [7:0] ZERO = 8'b00000000;
    parameter signed [7:0] POS_1 = 8'b01000000;
    parameter signed [7:0] NEG_1 = 8'b11000000;
    parameter signed [7:0] POS_0707 = 8'b00101101;
    parameter signed [7:0] NEG_0707 = 8'b11010011;

    reg [1:0] state_r, state_w;
    reg [23:0] OutData_r, OutData_w;
    reg out_valid_r, out_valid_w;
    reg y_req_r, y_req_w;

    reg [3:0] times_r, times_w; // 計算第幾個測資
    reg [2:0] counter_r, counter_w; // 計算第幾個y
    
    reg signed [7:0] x1_real, x1_imag, x2_real, x2_imag, x3_real, x3_imag, x4_real, x4_imag;
    reg signed [17:0] y1_real_temp, y1_imag_temp, y2_real_temp, y2_imag_temp, y3_real_temp, y3_imag_temp, y4_real_temp, y4_imag_temp;
    reg signed [9:0] y1_real, y1_imag, y2_real, y2_imag, y3_real, y3_imag, y4_real, y4_imag;
    reg signed [9:0] ans1_real, ans1_imag, ans2_real, ans2_imag, ans3_real, ans3_imag, ans4_real, ans4_imag;
    reg [13:0] d;
    reg [13:0] d_dist [0:7];
    reg [2:0] id_dist [0:7];
    reg [13:0] sorted_d [0:7];
    reg [2:0] sorted_id [0:7];
    reg [13:0] temp_d;
    reg [2:0] temp_id;

    assign y_req = y_req_r;
    assign OutData = OutData_r;
    assign out_valid = out_valid_r;

    function [10:0] abs_diff;
        input signed [9:0] a;
        input signed [9:0] b;
        reg signed [11:0] a_ext;
        reg signed [11:0] b_ext;
        reg signed [11:0] diff;
        begin
            a_ext = a; 
            b_ext = b; 
            diff = a_ext - b_ext;
            abs_diff = (diff < 0) ? -diff : diff;
        end
    endfunction

    // state
    always @(*) begin
        case (state_r)
            IDLE: state_w = y_req_r ? CALC : IDLE;
            CALC: state_w = (counter_r == 7) ? OUTPUT : CALC;
            OUTPUT: state_w = (times_r == 9) ? DONE : IDLE;
            DONE: state_w = DONE;
            default: state_w = IDLE;
        endcase
    end

    // x
    always @(*) begin
        case (state_r)
            CALC: begin
                case (counter_r)
                    0: begin
                        x1_real = NEG_0707;
                        x1_imag = NEG_0707;
                        x2_real = NEG_1;
                        x2_imag = ZERO;
                        x3_real = ZERO;
                        x3_imag = POS_1;
                        x4_real = NEG_0707;
                        x4_imag = POS_0707;
                    end
                    1: begin
                        x1_real = ZERO;
                        x1_imag = NEG_1;
                        x2_real = POS_0707;
                        x2_imag = NEG_0707;
                        x3_real = POS_0707;
                        x3_imag = POS_0707;
                        x4_real = POS_1;
                        x4_imag = ZERO;
                    end
                    2: begin
                        x1_real = NEG_0707;
                        x1_imag = NEG_0707;
                        x2_real = ZERO;
                        x2_imag = POS_1;
                        x3_real = ZERO;
                        x3_imag = NEG_1;
                        x4_real = POS_0707;
                        x4_imag = POS_0707;
                    end
                    3: begin
                        x1_real = NEG_1;
                        x1_imag = ZERO;
                        x2_real = NEG_0707;
                        x2_imag = POS_0707;
                        x3_real = POS_0707;
                        x3_imag = NEG_0707;
                        x4_real = POS_1;
                        x4_imag = ZERO;
                    end
                    4: begin
                        x1_real = POS_0707;
                        x1_imag = POS_0707;
                        x2_real = NEG_0707;
                        x2_imag = POS_0707;
                        x3_real = NEG_0707;
                        x3_imag = POS_0707;
                        x4_real = NEG_0707;
                        x4_imag = NEG_0707;
                    end
                    5: begin
                        x1_real = POS_1;
                        x1_imag = ZERO;
                        x2_real = NEG_0707;
                        x2_imag = POS_0707;
                        x3_real = POS_0707;
                        x3_imag = POS_0707;
                        x4_real = POS_1;
                        x4_imag = ZERO;
                    end
                    6: begin
                        x1_real = POS_1;
                        x1_imag = ZERO;
                        x2_real = POS_1;
                        x2_imag = ZERO;
                        x3_real = POS_1;
                        x3_imag = ZERO;
                        x4_real = POS_1;
                        x4_imag = ZERO;
                    end
                    7: begin
                        x1_real = NEG_1;
                        x1_imag = ZERO;
                        x2_real = NEG_1;
                        x2_imag = ZERO;
                        x3_real = NEG_1;
                        x3_imag = ZERO;
                        x4_real = NEG_1;
                        x4_imag = ZERO;
                    end
                    default: begin
                        x1_real = 8'h00;
                        x1_imag = 8'h00;
                        x2_real = 8'h00;
                        x2_imag = 8'h00;
                        x3_real = 8'h00;
                        x3_imag = 8'h00;
                        x4_real = 8'h00;
                        x4_imag = 8'h00;
                    end
                endcase
            end
            default: begin
                x1_real = 8'h00;
                x1_imag = 8'h00;
                x2_real = 8'h00;
                x2_imag = 8'h00;
                x3_real = 8'h00;
                x3_imag = 8'h00;
                x4_real = 8'h00;
                x4_imag = 8'h00;
            end
        endcase
    end
    
    // y
    always @(*) begin
        case (state_r)
            CALC: begin
                y1_real_temp = H11_real * x1_real - H11_imag * x1_imag + H12_real * x2_real - H12_imag * x2_imag + H13_real * x3_real - H13_imag * x3_imag + H14_real * x4_real - H14_imag * x4_imag;
                y1_imag_temp = H11_real * x1_imag + H11_imag * x1_real + H12_real * x2_imag + H12_imag * x2_real + H13_real * x3_imag + H13_imag * x3_real + H14_real * x4_imag + H14_imag * x4_real;
                y2_real_temp = H21_real * x1_real - H21_imag * x1_imag + H22_real * x2_real - H22_imag * x2_imag + H23_real * x3_real - H23_imag * x3_imag + H24_real * x4_real - H24_imag * x4_imag;
                y2_imag_temp = H21_real * x1_imag + H21_imag * x1_real + H22_real * x2_imag + H22_imag * x2_real + H23_real * x3_imag + H23_imag * x3_real + H24_real * x4_imag + H24_imag * x4_real;
                y3_real_temp = H31_real * x1_real - H31_imag * x1_imag + H32_real * x2_real - H32_imag * x2_imag + H33_real * x3_real - H33_imag * x3_imag + H34_real * x4_real - H34_imag * x4_imag;
                y3_imag_temp = H31_real * x1_imag + H31_imag * x1_real + H32_real * x2_imag + H32_imag * x2_real + H33_real * x3_imag + H33_imag * x3_real + H34_real * x4_imag + H34_imag * x4_real;
                y4_real_temp = H41_real * x1_real - H41_imag * x1_imag + H42_real * x2_real - H42_imag * x2_imag + H43_real * x3_real - H43_imag * x3_imag + H44_real * x4_real - H44_imag * x4_imag;
                y4_imag_temp = H41_real * x1_imag + H41_imag * x1_real + H42_real * x2_imag + H42_imag * x2_real + H43_real * x3_imag + H43_imag * x3_real + H44_real * x4_imag + H44_imag * x4_real;
                y1_real = y1_real_temp >>> 6;
                y1_imag = y1_imag_temp >>> 6;
                y2_real = y2_real_temp >>> 6;
                y2_imag = y2_imag_temp >>> 6;
                y3_real = y3_real_temp >>> 6;
                y3_imag = y3_imag_temp >>> 6;
                y4_real = y4_real_temp >>> 6;
                y4_imag = y4_imag_temp >>> 6;
            end
            default: begin
                y1_real = 10'h000;
                y1_imag = 10'h000;
                y2_real = 10'h000;
                y2_imag = 10'h000;
                y3_real = 10'h000;
                y3_imag = 10'h000;
                y4_real = 10'h000;
                y4_imag = 10'h000;
                y1_real_temp = 18'h00000;
                y1_imag_temp = 18'h00000;
                y2_real_temp = 18'h00000;
                y2_imag_temp = 18'h00000;
                y3_real_temp = 18'h00000;
                y3_imag_temp = 18'h00000;
                y4_real_temp = 18'h00000;
                y4_imag_temp = 18'h00000;
            end
        endcase
    end

    // ans
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            ans1_real <= 10'h000;
            ans1_imag <= 10'h000;
            ans2_real <= 10'h000;
            ans2_imag <= 10'h000;
            ans3_real <= 10'h000;
            ans3_imag <= 10'h000;
            ans4_real <= 10'h000;
            ans4_imag <= 10'h000;
        end
        else if(state_r == IDLE && y_req_r == 1) begin
            ans1_real <= InData[79:70];
            ans1_imag <= InData[69:60];
            ans2_real <= InData[59:50];
            ans2_imag <= InData[49:40];
            ans3_real <= InData[39:30];
            ans3_imag <= InData[29:20];
            ans4_real <= InData[19:10];
            ans4_imag <= InData[9:0];
        end
        else begin
            ans1_real <= ans1_real;
            ans1_imag <= ans1_imag;
            ans2_real <= ans2_real;
            ans2_imag <= ans2_imag;
            ans3_real <= ans3_real;
            ans3_imag <= ans3_imag;
            ans4_real <= ans4_real;
            ans4_imag <= ans4_imag;
        end
    end

    // d
    always @(*) begin
        case (state_r)
            CALC: begin
                d = abs_diff(y1_real, ans1_real) + 
                    abs_diff(y1_imag, ans1_imag) + 
                    abs_diff(y2_real, ans2_real) + 
                    abs_diff(y2_imag, ans2_imag) + 
                    abs_diff(y3_real, ans3_real) + 
                    abs_diff(y3_imag, ans3_imag) + 
                    abs_diff(y4_real, ans4_real) + 
                    abs_diff(y4_imag, ans4_imag);
            end
            default: d = 14'h0000;
        endcase
    end

    // sorted
    always @(*) begin
        for(i = 0; i < 8; i = i + 1) begin
            sorted_d[i] = d_dist[i];
            sorted_id[i] = id_dist[i];
        end
        for(i = 0; i < 8; i = i + 1) begin
            for(j = 0; j < 7; j = j + 1) begin
                if(sorted_d[j] > sorted_d[j + 1]) begin
                    temp_d = sorted_d[j];
                    sorted_d[j] = sorted_d[j + 1];
                    sorted_d[j + 1] = temp_d;
                    temp_id = sorted_id[j];
                    sorted_id[j] = sorted_id[j + 1];
                    sorted_id[j + 1] = temp_id;
                end
            end
        end
    end

    // counter
    always @(*) begin
        case (state_r)
            CALC: begin
                if(counter_r == 7) counter_w = 0;
                else counter_w = counter_r + 1;
            end 
            default: counter_w = 0;
        endcase
    end

    // y_req
    always @(*) begin
        case (state_r)
            IDLE: y_req_w = (y_req_r == 1) ? 0 : 1;
            default: y_req_w = 0;
        endcase
    end

    // OutData
    always @(*) begin
        case (state_r)
            OUTPUT: OutData_w = {sorted_id[0], sorted_id[1], sorted_id[2], sorted_id[3], sorted_id[4], sorted_id[5], sorted_id[6], sorted_id[7]};
            default: OutData_w = 24'h0;
        endcase
    end

    // out_valid
    always @(*) begin
        case (state_r)
            OUTPUT: out_valid_w = 1;
            default: out_valid_w = 0;
        endcase
    end

    // times
    always @(*) begin
        case (state_r)
            OUTPUT: times_w = times_r + 1;
            default: times_w = times_r;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state_r <= IDLE;
            OutData_r <= 0;
            out_valid_r <= 0;
            y_req_r <= 0;
            counter_r <= 0;
            times_r <= 0;
            for(k = 0; k < 8; k = k + 1) begin
                d_dist[k] <= 14'h0000;
                id_dist[k] <= 3'h0;
            end
        end
        else begin
            state_r <= state_w;
            OutData_r <= OutData_w;
            out_valid_r <= out_valid_w;
            y_req_r <= y_req_w;
            counter_r <= counter_w;
            times_r <= times_w;
            if(state_r == CALC) begin
                d_dist[counter_r] <= d;
                id_dist[counter_r] <= counter_r;
            end
        end
    end

endmodule
