// Top simplificado: sensores HC-SR04 + assist_control + setas no MAX7219
//
// clk = cristal onboard Tang Nano 9K (27 MHz, pin 52).

module road_shield_top_test_hc #(
    parameter CLK_HZ      = 27_000_000,
    parameter GAP_MS      = 60,
    parameter TRIG_US     = 10,
    parameter TIMEOUT_MS  = 30,
    parameter DIST_FREE   = 8'd100,
    parameter DIST_ATT    = 8'd50,
    parameter VEL_MAX     = 8'd100
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       iniciar,
    input  wire       echo_e,
    input  wire       echo_c,
    input  wire       echo_d,
    output wire       trig_e,
    output wire       trig_c,
    output wire       trig_d,
    output wire [7:0] dist_e,
    output wire [7:0] dist_c,
    output wire [7:0] dist_d,
    output wire signed [7:0] vel_e,
    output wire signed [7:0] vel_c,
    output wire signed [7:0] vel_d,
    output wire       ciclo_pronto,
    output wire [3:0] estado_fsm,
    output wire [7:0] vel_rec,
    output wire [1:0] dir_fuga,
    output wire       max7219_din,
    output wire       max7219_clk,
    output wire       max7219_cs
);

    road_sensores #(
        .CLK_HZ(CLK_HZ),
        .GAP_MS(GAP_MS),
        .TRIG_US(TRIG_US),
        .TIMEOUT_MS(TIMEOUT_MS)
    ) sensores (
        .clk           (clk),
        .rst           (rst),
        .iniciar       (iniciar),
        .echo_e        (echo_e),
        .echo_c        (echo_c),
        .echo_d        (echo_d),
        .trig_e        (trig_e),
        .trig_c        (trig_c),
        .trig_d        (trig_d),
        .dist_e        (dist_e),
        .dist_c        (dist_c),
        .dist_d        (dist_d),
        .ciclo_pronto  (ciclo_pronto),
        .estado_fsm    (estado_fsm),
        .vel_e         (vel_e),
        .vel_c         (vel_c),
        .vel_d         (vel_d)
    );

    assist_control u_dec (
        .dist_e        (dist_e),
        .dist_c        (dist_c),
        .dist_d        (dist_d),
        .vel_e         (vel_e),
        .vel_c         (vel_c),
        .vel_d         (vel_d),
        .cfg_dist_free (DIST_FREE),
        .cfg_dist_att  (DIST_ATT),
        .cfg_vel_max   (VEL_MAX),
        .vel_rec       (vel_rec),
        .dir_fuga      (dir_fuga)
    );

    arrow_display u_setas (
        .clk       (clk),
        .rst_n     (~rst),
        .direction (dir_fuga),
        .arrow_din (max7219_din),
        .arrow_clk (max7219_clk),
        .arrow_cs  (max7219_cs)
    );

endmodule
