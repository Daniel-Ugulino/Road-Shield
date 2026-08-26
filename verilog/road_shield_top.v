module road_shield_top #(
    parameter CLK_HZ     = 27_000_000,
    parameter BAUD       = 115200,
    parameter GAP_MS     = 60,
    parameter TRIG_US    = 10,
    parameter TIMEOUT_MS = 30
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       btn1,
    input  wire       btn2,
    input  wire       iniciar,
    input  wire       echo_e,
    input  wire       echo_c,
    input  wire       echo_d,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire       trig_e,
    output wire       trig_c,
    output wire       trig_d,
    output wire [7:0] dist_e,
    output wire [7:0] dist_c,
    output wire [7:0] dist_d,
    output wire signed [7:0] vel_e,
    output wire signed [7:0] vel_c,
    output wire signed [7:0] vel_d,
    output wire [7:0] vel_rec,
    output wire [1:0] dir_fuga,
    output wire       ciclo_pronto,
    output wire [3:0] estado_fsm,
    output wire       telemetria_ocupada,
    output wire       cfg_valida,
    output wire       max7219_din,
    output wire       max7219_clk,
    output wire       max7219_cs
);

    wire [7:0] rx_byte;
    wire       rx_valido;

    wire [7:0] cfg_dist_free;
    wire [7:0] cfg_dist_att;
    wire [7:0] cfg_vel_max;
    wire       cfg_erro;
    wire [7:0] vel_atual;

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

    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) rx (
        .clk    (clk),
        .rst    (rst),
        .rx     (uart_rx),
        .data   (rx_byte),
        .valido (rx_valido),
        .erro   ()
    );

    config_rx u_cfg (
        .clk           (clk),
        .rst           (rst),
        .byte_in       (rx_byte),
        .byte_valido   (rx_valido),
        .cfg_dist_free (cfg_dist_free),
        .cfg_dist_att  (cfg_dist_att),
        .cfg_vel_max   (cfg_vel_max),
        .cfg_valida    (cfg_valida),
        .cfg_erro      (cfg_erro)
    );

    speed_control u_speed (
        .clk       (clk),
        .btn1      (btn1),
        .btn2      (btn2),
        .max_speed (cfg_vel_max),
        .speed     (vel_atual)
    );

    assist_control u_dec (
        .dist_e        (dist_e),
        .dist_c        (dist_c),
        .dist_d        (dist_d),
        .vel_e         (vel_e),
        .vel_c         (vel_c),
        .vel_d         (vel_d),
        .cfg_dist_free (cfg_dist_free),
        .cfg_dist_att  (cfg_dist_att),
        .cfg_vel_max   (vel_atual),
        .vel_rec       (vel_rec),
        .dir_fuga      (dir_fuga)
    );

    telemetry_dec_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) telemetria (
        .clk      (clk),
        .rst      (rst),
        .enviar   (ciclo_pronto),
        .dist_e   (dist_e),
        .dist_c   (dist_c),
        .dist_d   (dist_d),
        .dir_fuga (dir_fuga),
        .tx       (uart_tx),
        .ocupado  (telemetria_ocupada)
    );

    // Display MAX7219: digitos 1-4 = vel_max (Pi), 5-8 = velocidade atual (botoes)
    number_control u_display (
        .clk         (clk),
        .rst_n       (~rst),
        .value_a     ({6'd0, vel_atual}),
        .value_b     ({6'd0, vel_rec}),
        .max7219_din (max7219_din),
        .max7219_clk (max7219_clk),
        .max7219_cs  (max7219_cs)
    );

endmodule
