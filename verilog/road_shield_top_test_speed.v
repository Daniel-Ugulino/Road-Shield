// Top simplificado: controle de velocidade (botoes) + display MAX7219
//
// clk = cristal onboard Tang Nano 9K (27 MHz, pin 52).

module road_shield_top_test_speed #(
    parameter CLK_HZ    = 27_000_000,
    parameter MAX_SPEED = 8'd100
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       btn1,
    input  wire       btn2,
    output wire       max7219_din,
    output wire       max7219_clk,
    output wire       max7219_cs
);

    wire [7:0] speed;

    speed_control u_speed (
        .clk       (clk),
        .btn1      (btn1),
        .btn2      (btn2),
        .max_speed (MAX_SPEED),
        .speed     (speed)
    );


    // Display MAX7219: digitos 1-4 e 5-8 = velocidade atual (botoes)
    number_control u_display (
        .clk         (clk),
        .rst_n       (~rst),
        .value_a     ({6'd0, speed}),
        .value_b     ({6'd0, speed}),
        .max7219_din (max7219_din),
        .max7219_clk (max7219_clk),
        .max7219_cs  (max7219_cs)
    );

endmodule
