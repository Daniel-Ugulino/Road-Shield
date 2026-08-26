module speed_control (
    input  wire        clk,
    input  wire        btn1,
    input  wire        btn2,
    input  wire [7:0]  max_speed,
    output wire [7:0]  speed
);

    localparam [7:0] STEP = 8'd5;

    reg [7:0] speed_reg = 8'd0;
    reg       btn1_d, btn2_d;

    wire btn1_n = ~btn1;
    wire btn2_n = ~btn2;
    wire btn1_up = btn1_n & ~btn1_d;
    wire btn2_up = btn2_n & ~btn2_d;

    always @(posedge clk) begin
        btn1_d <= btn1_n;
        btn2_d <= btn2_n;

        if (speed_reg > max_speed)
            speed_reg <= max_speed;
        else if (btn1_up && speed_reg < max_speed)
            speed_reg <= speed_reg + STEP;
        else if (btn2_up && speed_reg > 8'd0)
            speed_reg <= speed_reg - STEP;
    end

    assign speed = speed_reg;

endmodule
