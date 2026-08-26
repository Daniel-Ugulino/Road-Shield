// Decisao de assistencia na FPGA.
// dist_free, dist_att e vel_max vem do Pi via UART; reducoes fixas em hardware.

module assist_control #(
    parameter REDUC_ATENCAO = 8'd20,
    parameter REDUC_CRITICO = 8'd40
) (
    input  wire [7:0] dist_e,
    input  wire [7:0] dist_c,
    input  wire [7:0] dist_d,
    input  wire [7:0] vel_e,
    input  wire [7:0] vel_c,
    input  wire [7:0] vel_d,
    input  wire [7:0] cfg_dist_free,
    input  wire [7:0] cfg_dist_att,
    input  wire [7:0] cfg_vel_max,
    output reg  [7:0] vel_rec,
    output reg  [1:0] dir_fuga
);

    wire [1:0] zona_e;
    wire [1:0] zona_c;
    wire [1:0] zona_d;

    function automatic [1:0] classificar;
        input [7:0] dist;
        input [7:0] lim_livre;
        input [7:0] lim_atencao;
        begin
            if (dist > lim_livre)
                classificar = 2'b00;
            else if (dist >= lim_atencao)
                classificar = 2'b01;
            else
                classificar = 2'b10;
        end
    endfunction

    assign zona_e = classificar(dist_e, cfg_dist_free, cfg_dist_att);
    assign zona_c = classificar(dist_c, cfg_dist_free, cfg_dist_att);
    assign zona_d = classificar(dist_d, cfg_dist_free, cfg_dist_att);

    wire [7:0] reducao =
        (zona_c == 2'b10) ? REDUC_CRITICO :
        (zona_c == 2'b01) ? REDUC_ATENCAO :
        8'd0;

    wire signed [8:0] vel_tmp = cfg_vel_max - reducao;
    wire [7:0] vel_clamped =
        (vel_tmp <= 9'sd0) ? 8'd0 : vel_tmp[7:0];

    always @(*) begin
        vel_rec = vel_clamped;

        if (zona_c == 2'b00) begin
            dir_fuga = 2'b00;
        end else if (zona_e == 2'b00) begin
            dir_fuga = 2'b01;
        end else if (zona_d == 2'b00) begin
            dir_fuga = 2'b10;
        end else begin
            dir_fuga = 2'b11;
        end
    end

endmodule
