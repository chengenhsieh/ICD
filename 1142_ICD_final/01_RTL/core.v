module core (
    input              i_clk,
    input              i_rst_n,
    input              i_in_valid,
    input       [31:0] i_in_data,       
    input              i_stride_mode,   // 0 = stride-1,  1 = stride-2
    input       [71:0] i_weight,        // 9 x 8-bit signed weights

    output             o_in_ready,
    output reg  [ 7:0] o_out_data1,
    output reg  [ 7:0] o_out_data2,
    output reg  [ 7:0] o_out_data3,
    output reg  [ 7:0] o_out_data4,
    output reg  [11:0] o_out_addr1,
    output reg  [11:0] o_out_addr2,
    output reg  [11:0] o_out_addr3,
    output reg  [11:0] o_out_addr4,
    output reg         o_out_valid1,
    output reg         o_out_valid2,
    output reg         o_out_valid3,
    output reg         o_out_valid4,
    output             o_exe_finish
);

parameter IDLE = 0; // 初始狀態
parameter LOAD_WEIGHT = 1; // 讀取 weight
parameter PRELOAD = 2;
parameter LOAD_DATA = 3; // 讀取 data & 計算
parameter OUTPUT = 4; // 輸出
parameter DONE = 5; // 全部結束

reg [  2:0] state_r, state_w;
reg [ 71:0] weight_r, weight_w;
reg [  3:0] counter_r, counter_w; // 計算初始存入資料次數
reg [527:0] data1_r, data1_w;
reg [527:0] data2_r, data2_w;
reg [ 47:0] in_data_r, in_data_w;
reg [  5:0] x_coord_r, x_coord_w;
reg [  5:0] y_coord_r, y_coord_w;

wire signed [7:0] W1, W2, W3, W4, W5, W6, W7, W8, W9;
assign W1 = weight_r[71:64];
assign W2 = weight_r[63:56];
assign W3 = weight_r[55:48];
assign W4 = weight_r[47:40];
assign W5 = weight_r[39:32];
assign W6 = weight_r[31:24];
assign W7 = weight_r[23:16];
assign W8 = weight_r[15: 8];
assign W9 = weight_r[ 7: 0];

assign o_in_ready = ((state_r == LOAD_WEIGHT) || (state_r == PRELOAD) ||(state_r == LOAD_DATA && x_coord_r != 63 && y_coord_r != 63));
assign o_exe_finish = (state_r == DONE);

// state
always @(*) begin
    case (state_r)
        IDLE: state_w = LOAD_WEIGHT;
        LOAD_WEIGHT: state_w = PRELOAD;
        PRELOAD: state_w = (counter_r == 15) ? LOAD_DATA : PRELOAD;
        LOAD_DATA: state_w = OUTPUT;
        OUTPUT: begin
            if (x_coord_r == 63 && y_coord_r == 63) state_w = DONE;
            else state_w = LOAD_DATA;
        end
        DONE: state_w = DONE;
        default: state_w = IDLE;
    endcase
end

// weight
always @(*) begin
    case (state_r)
        IDLE: weight_w = 72'b0;
        LOAD_WEIGHT: weight_w = i_weight;
        default: weight_w = weight_r;
    endcase
end

// counter
always @(*) begin
    case (state_r)
        IDLE: counter_w = 4'b0;
        PRELOAD: begin
            if (y_coord_r == 0 && i_in_valid) counter_w = counter_r + 1;
            else counter_w = 4'b0;
        end
        default: counter_w = 4'b0;
    endcase
end

// coord
always @(*) begin
    case (state_r)
        IDLE: begin
            x_coord_w = 6'b0;
            y_coord_w = 6'b0;
        end
        OUTPUT: begin
            if (x_coord_r == 63) begin
                y_coord_w = y_coord_r + 1;
                x_coord_w = 6'b0;
            end
            else begin
                if (x_coord_r == 60) x_coord_w = x_coord_r + 3;
                else x_coord_w = x_coord_r + 4;
                y_coord_w = y_coord_r;
            end
        end
        default: begin
            x_coord_w = x_coord_r;
            y_coord_w = y_coord_r;
        end
    endcase
end

// data
always @(*) begin
    case (state_r)
        IDLE: begin
            data1_w = 528'b0;
            data2_w = 528'b0;
            in_data_w = 48'b0;
        end
        PRELOAD: begin
            data1_w = 528'b0;
            in_data_w = 48'b0;
            if (counter_r == 0) data2_w = {496'b0, i_in_data};
            else data2_w = {data2_r[495:0], i_in_data};
        end
        LOAD_DATA: begin
            if (x_coord_r == 0 && y_coord_r == 0) begin
                data1_w = 528'b0;
                data2_w = data2_r;
                in_data_w = {16'b0, i_in_data};
            end
            else if (y_coord_r == 63) begin
                if (x_coord_r == 0) begin
                    data1_w = {data1_r[487:0], data2_r[527:488]};
                    data2_w = {data2_r[487:0], in_data_r[47:8]};
                    in_data_w = 48'b0;
                end
                else if(x_coord_r == 63) begin
                    data1_w = {data1_r[519:0], data2_r[527:520]};
                    data2_w = {data2_r[519:0], in_data_r[47:40]};
                    in_data_w = 48'b0;
                end
                else begin
                    data1_w = {data1_r[495:0], data2_r[527:496]};
                    data2_w = {data2_r[495:0], in_data_r[47:16]};
                    in_data_w = 48'b0;
                end
            end
            else begin
                if (x_coord_r == 0) begin
                    data1_w = {data1_r[487:0], data2_r[527:488]};
                    data2_w = {data2_r[487:0], in_data_r[47:8]};
                    in_data_w = {16'b0, i_in_data};
                end
                else if(x_coord_r == 63) begin
                    data1_w = {data1_r[519:0], data2_r[527:520]};
                    data2_w = {data2_r[519:0], in_data_r[47:40]};
                    in_data_w = {in_data_r[39:0], 8'b0};
                end
                else begin
                    data1_w = {data1_r[495:0], data2_r[527:496]};
                    data2_w = {data2_r[495:0], in_data_r[47:16]};
                    in_data_w = {in_data_r[15:0], i_in_data};
                end
            end
        end
        default: begin
            data1_w = data1_r;
            data2_w = data2_r;
            in_data_w = in_data_r;
        end
    endcase
end

reg signed [ 8:0] D11, D12, D13, D14, D15, D16;
reg signed [ 8:0] D21, D22, D23, D24, D25, D26;
reg signed [ 8:0] D31, D32, D33, D34, D35, D36;
reg signed [19:0] calc1, calc2, calc3, calc4;

// Convolution
always @(*) begin
    D11 = $signed({1'b0, data1_r[527:520]}); D12 = $signed({1'b0, data1_r[519:512]}); D13 = $signed({1'b0, data1_r[511:504]});
    D14 = $signed({1'b0, data1_r[503:496]}); D15 = $signed({1'b0, data1_r[495:488]}); D16 = $signed({1'b0, data1_r[487:480]});
    D21 = $signed({1'b0, data2_r[527:520]}); D22 = $signed({1'b0, data2_r[519:512]}); D23 = $signed({1'b0, data2_r[511:504]});
    D24 = $signed({1'b0, data2_r[503:496]}); D25 = $signed({1'b0, data2_r[495:488]}); D26 = $signed({1'b0, data2_r[487:480]});
    D31 = $signed({1'b0, in_data_r[47:40]}); D32 = $signed({1'b0, in_data_r[39:32]}); D33 = $signed({1'b0, in_data_r[31:24]});
    D34 = $signed({1'b0, in_data_r[23:16]}); D35 = $signed({1'b0, in_data_r[15: 8]}); D36 = $signed({1'b0, in_data_r[ 7: 0]});
    calc1 = W1 * D11 + W2 * D12 + W3 * D13 + W4 * D21 + W5 * D22 + W6 * D23 + W7 * D31 + W8 * D32 + W9 * D33;
    calc2 = W1 * D12 + W2 * D13 + W3 * D14 + W4 * D22 + W5 * D23 + W6 * D24 + W7 * D32 + W8 * D33 + W9 * D34;
    calc3 = W1 * D13 + W2 * D14 + W3 * D15 + W4 * D23 + W5 * D24 + W6 * D25 + W7 * D33 + W8 * D34 + W9 * D35;
    calc4 = W1 * D14 + W2 * D15 + W3 * D16 + W4 * D24 + W5 * D25 + W6 * D26 + W7 * D34 + W8 * D35 + W9 * D36;
end

wire signed [19:0] shifted1 = (calc1 + 20'sd64) >>> 7;
wire signed [19:0] shifted2 = (calc2 + 20'sd64) >>> 7;
wire signed [19:0] shifted3 = (calc3 + 20'sd64) >>> 7;
wire signed [19:0] shifted4 = (calc4 + 20'sd64) >>> 7;

wire [7:0] conv1 = (shifted1 < 0) ? 8'd0 : (shifted1 > 255) ? 8'd255 : shifted1[7:0];
wire [7:0] conv2 = (shifted2 < 0) ? 8'd0 : (shifted2 > 255) ? 8'd255 : shifted2[7:0];
wire [7:0] conv3 = (shifted3 < 0) ? 8'd0 : (shifted3 > 255) ? 8'd255 : shifted3[7:0];
wire [7:0] conv4 = (shifted4 < 0) ? 8'd0 : (shifted4 > 255) ? 8'd255 : shifted4[7:0];

function [7:0] get_cupid_root;
    input [7:0] i_x;
    
    reg [15:0] n;
    reg [6:0] lo, hi, mid;
    reg [16:0] m, mid3;
    integer i;
    
    begin
        n = {8'd0, i_x} * {8'd0, i_x};
        
        lo = 7'd0;
        hi = 7'd40;
        for (i = 0; i < 6; i = i + 1) begin
            mid = (lo + hi + 7'd1) >> 1;
            m   = {10'd0, mid};
            mid3 = m * m * m;
            
            if (mid3 <= {1'b0, n})
                lo = mid;
            else if (mid != 7'd0)
                hi = mid - 7'd1;
            else
                hi = 7'd0;
        end
        
        get_cupid_root = {1'b0, lo};
    end
endfunction

wire [7:0] out1 = get_cupid_root(conv1);
wire [7:0] out2 = get_cupid_root(conv2);
wire [7:0] out3 = get_cupid_root(conv3);
wire [7:0] out4 = get_cupid_root(conv4);

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_out_addr1 <= 12'b0;
        o_out_addr2 <= 12'b0;
        o_out_addr3 <= 12'b0;
        o_out_addr4 <= 12'b0;
        o_out_data1 <= 8'b0;
        o_out_data2 <= 8'b0;
        o_out_data3 <= 8'b0;
        o_out_data4 <= 8'b0;
        o_out_valid1 <= 0;
        o_out_valid2 <= 0;
        o_out_valid3 <= 0;
        o_out_valid4 <= 0;
    end
    else begin
        case (state_r)
            OUTPUT: begin
                if (i_stride_mode == 0) begin
                    if (x_coord_r == 0) begin
                        o_out_valid1 <= 0;
                        o_out_valid2 <= 1;
                        o_out_valid3 <= 1;
                        o_out_valid4 <= 1;
                        o_out_addr1 <= 12'b0;
                        o_out_addr2 <= {y_coord_r, x_coord_r};
                        o_out_addr3 <= {y_coord_r, x_coord_r} + 1;
                        o_out_addr4 <= {y_coord_r, x_coord_r} + 2;
                        o_out_data1 <= 8'b0;
                        o_out_data2 <= out2;
                        o_out_data3 <= out3;
                        o_out_data4 <= out4;
                    end
                    else if (x_coord_r == 63) begin
                        o_out_valid1 <= 0;
                        o_out_valid2 <= 0;
                        o_out_valid3 <= 0;
                        o_out_valid4 <= 1;
                        o_out_addr1 <= 12'b0;
                        o_out_addr2 <= 12'b0;
                        o_out_addr3 <= 12'b0;
                        o_out_addr4 <= {y_coord_r, x_coord_r};
                        o_out_data1 <= 8'b0;
                        o_out_data2 <= 8'b0;
                        o_out_data3 <= 8'b0;
                        o_out_data4 <= out4;
                    end
                    else begin
                        o_out_valid1 <= 1;
                        o_out_valid2 <= 1;
                        o_out_valid3 <= 1;
                        o_out_valid4 <= 1;
                        o_out_addr1 <= {y_coord_r, x_coord_r} - 1;
                        o_out_addr2 <= {y_coord_r, x_coord_r};
                        o_out_addr3 <= {y_coord_r, x_coord_r} + 1;
                        o_out_addr4 <= {y_coord_r, x_coord_r} + 2;
                        o_out_data1 <= out1;
                        o_out_data2 <= out2;
                        o_out_data3 <= out3;
                        o_out_data4 <= out4;
                    end
                end
                else begin
                    if (y_coord_r[0] == 0)
                        if (x_coord_r == 0) begin
                            o_out_valid1 <= 0;
                            o_out_valid2 <= 1;
                            o_out_valid3 <= 0;
                            o_out_valid4 <= 1;
                            o_out_addr1 <= 12'b0;
                            o_out_addr2 <= ({(y_coord_r >> 1), x_coord_r}) >> 1;
                            o_out_addr3 <= 12'b0;
                            o_out_addr4 <= ({(y_coord_r >> 1), x_coord_r} + 2) >> 1;
                            o_out_data1 <= 8'b0;
                            o_out_data2 <= out2;
                            o_out_data3 <= 8'b0;
                            o_out_data4 <= out4;
                        end
                        else if (x_coord_r == 63) begin
                            o_out_addr1 <= 12'b0;
                            o_out_addr2 <= 12'b0;
                            o_out_addr3 <= 12'b0;
                            o_out_addr4 <= 12'b0;
                            o_out_data1 <= 8'b0;
                            o_out_data2 <= 8'b0;
                            o_out_data3 <= 8'b0;
                            o_out_data4 <= 8'b0;
                            o_out_valid1 <= 0;
                            o_out_valid2 <= 0;
                            o_out_valid3 <= 0;
                            o_out_valid4 <= 0;
                        end
                        else begin
                            o_out_valid1 <= 0;
                            o_out_valid2 <= 1;
                            o_out_valid3 <= 0;
                            o_out_valid4 <= 1;
                            o_out_addr1 <= 12'b0;
                            o_out_addr2 <= ({(y_coord_r >> 1), x_coord_r}) >> 1;
                            o_out_addr3 <= 12'b0;
                            o_out_addr4 <= ({(y_coord_r >> 1), x_coord_r} + 2) >> 1;
                            o_out_data1 <= 8'b0;
                            o_out_data2 <= out2;
                            o_out_data3 <= 8'b0;
                            o_out_data4 <= out4;
                        end
                    else begin
                        o_out_addr1 <= 12'b0;
                        o_out_addr2 <= 12'b0;
                        o_out_addr3 <= 12'b0;
                        o_out_addr4 <= 12'b0;
                        o_out_data1 <= 8'b0;
                        o_out_data2 <= 8'b0;
                        o_out_data3 <= 8'b0;
                        o_out_data4 <= 8'b0;
                        o_out_valid1 <= 0;
                        o_out_valid2 <= 0;
                        o_out_valid3 <= 0;
                        o_out_valid4 <= 0;
                    end 
                end
            end 
            default: begin
                o_out_addr1 <= 12'b0;
                o_out_addr2 <= 12'b0;
                o_out_addr3 <= 12'b0;
                o_out_addr4 <= 12'b0;
                o_out_data1 <= 8'b0;
                o_out_data2 <= 8'b0;
                o_out_data3 <= 8'b0;
                o_out_data4 <= 8'b0;
                o_out_valid1 <= 0;
                o_out_valid2 <= 0;
                o_out_valid3 <= 0;
                o_out_valid4 <= 0;
            end
        endcase
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= IDLE;
        weight_r <= 72'b0;
        in_data_r <= 48'b0;
        counter_r <= 4'b0;
        data1_r <= 528'b0;
        data2_r <= 528'b0;
        x_coord_r <= 6'b0;
        y_coord_r <= 6'b0;
    end
    else begin
        state_r <= state_w;
        weight_r <= weight_w;
        in_data_r <= in_data_w;
        counter_r <= counter_w;
        data1_r <= data1_w;
        data2_r <= data2_w;
        x_coord_r <= x_coord_w;
        y_coord_r <= y_coord_w;
    end
end

endmodule