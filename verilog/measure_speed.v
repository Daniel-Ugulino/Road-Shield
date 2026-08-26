// Calcula distancia atual e velocidade do obstaculo (cm por amostra)
// a partir de um historico circular de 4 distancias.
//
//   velocidade_cm = distancia_atual - distancia_anterior  (complemento de 2, 8 bits)
//   positivo = afastando | negativo = aproximando
//
// Saida destinada a telemetria UART -> Raspberry Pi.

module measure_speed (
    input  wire       clk,
    input  wire       rst,
    input  wire       amostra_valida,
    input  wire [7:0] distancia_cm,
    output reg  [7:0] dist_atual,
    output reg  signed [7:0] velocidade_cm
);

    reg [7:0] hist [0:3];
    reg [1:0] ptr;
    reg [7:0] dist_anterior;
    reg       tem_anterior;

    wire signed [8:0] delta_w =
        $signed({1'b0, distancia_cm}) - $signed({1'b0, dist_anterior});

    always @(posedge clk) begin
        if (rst) begin
            ptr            <= 2'd0;
            dist_anterior  <= 8'd0;
            tem_anterior   <= 1'b0;
            dist_atual     <= 8'd0;
            velocidade_cm  <= 8'sd0;
            hist[0]        <= 8'd0;
            hist[1]        <= 8'd0;
            hist[2]        <= 8'd0;
            hist[3]        <= 8'd0;
        end else if (amostra_valida) begin
            dist_atual <= distancia_cm;

            if (tem_anterior) begin
                // satura em signed 8 bits (-128..127)
                if (delta_w > 9'sd127)
                    velocidade_cm <= 8'sd127;
                else if (delta_w < -9'sd128)
                    velocidade_cm <= -8'sd128;
                else
                    velocidade_cm <= delta_w[7:0];
            end else begin
                velocidade_cm <= 8'sd0;
                tem_anterior  <= 1'b1;
            end

            dist_anterior <= distancia_cm;
            hist[ptr]     <= distancia_cm;
            ptr           <= (ptr == 2'd3) ? 2'd0 : (ptr + 2'd1);
        end
    end

endmodule
