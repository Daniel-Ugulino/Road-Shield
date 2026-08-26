module number_control (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [13:0] value_a,
    input  wire [13:0] value_b,
    output reg         number_din,
    output reg         number_clk,
    output reg         number_cs
);

    function [3:0] digit_at;
        input [13:0] value;
        input [1:0]  pos;
        begin
            case (pos)
                2'd0: digit_at = value % 10;
                2'd1: digit_at = (value / 10) % 10;
                2'd2: digit_at = (value / 100) % 10;
                2'd3: digit_at = (value / 1000) % 10;
                default: digit_at = 4'd0;
            endcase
        end
    endfunction

    wire [3:0] digit_data [1:8];
    assign digit_data[1] = digit_at(value_a, 2'd0);
    assign digit_data[2] = digit_at(value_a, 2'd1);
    assign digit_data[3] = digit_at(value_a, 2'd2);
    assign digit_data[4] = digit_at(value_a, 2'd3);
    assign digit_data[5] = digit_at(value_b, 2'd0);
    assign digit_data[6] = digit_at(value_b, 2'd1);
    assign digit_data[7] = digit_at(value_b, 2'd2);
    assign digit_data[8] = digit_at(value_b, 2'd3);

    reg [15:0] init_table [0:3];
    initial begin
        init_table[0] = {8'h09, 8'hFF};  // decode mode BCD
        init_table[1] = {8'h0B, 8'h07};  // scan limit 8 digitos
        init_table[2] = {8'h0A, 8'h08};  // intensidade media
        init_table[3] = {8'h0C, 8'h01};  // sai do shutdown
    end

    localparam INIT = 1'b0, RUN = 1'b1;
    localparam PH_SETUP = 2'd0, PH_RISE = 2'd1, PH_FALL = 2'd2;

    reg        phase;
    reg [1:0]  init_idx;
    reg [3:0]  digit_index;   // 1..8
    reg [15:0] shift_reg;
    reg [4:0]  bit_cnt;       // 0..16
    reg [15:0] clk_div;
    reg        sending;
    reg [1:0]  clk_phase;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase       <= INIT;
            init_idx    <= 0;
            digit_index <= 4'd1;
            number_cs  <= 1'b1;
            number_clk <= 1'b0;
            number_din <= 1'b0;
            clk_div     <= 0;
            sending     <= 1'b0;
            bit_cnt     <= 0;
            clk_phase   <= PH_SETUP;
        end else begin
            clk_div <= clk_div + 1;

            if (clk_div == 16'd50) begin
                clk_div <= 0;

                if (!sending) begin
                    if (phase == INIT)
                        shift_reg <= init_table[init_idx];
                    else
                        shift_reg <= {4'h0, digit_index, 4'h0, digit_data[digit_index]};

                    bit_cnt     <= 5'd16;
                    number_cs  <= 1'b0;
                    sending     <= 1'b1;
                    clk_phase   <= PH_SETUP;
                    number_clk <= 1'b0;
                end else if (bit_cnt == 0) begin
                    number_cs  <= 1'b1;
                    number_clk <= 1'b0;
                    sending     <= 1'b0;

                    if (phase == INIT) begin
                        if (init_idx == 2'd3)
                            phase <= RUN;
                        else
                            init_idx <= init_idx + 2'd1;
                    end else begin
                        if (digit_index == 4'd8)
                            digit_index <= 4'd1;
                        else
                            digit_index <= digit_index + 4'd1;
                    end
                end else begin
                    case (clk_phase)
                        PH_SETUP: begin
                            number_din <= shift_reg[15];
                            number_clk <= 1'b0;
                            clk_phase   <= PH_RISE;
                        end
                        PH_RISE: begin
                            number_clk <= 1'b1;   // MAX7219 amostra aqui
                            clk_phase   <= PH_FALL;
                        end
                        PH_FALL: begin
                            number_clk <= 1'b0;
                            shift_reg   <= shift_reg << 1;
                            bit_cnt     <= bit_cnt - 1;
                            clk_phase   <= PH_SETUP;
                        end
                    endcase
                end
            end
        end
    end

endmodule