// UART RX 8N1 — recebe um byte por vez (LSB first)
//
// Frame: [start=0] [bit0..bit7] [stop=1]
//
// Em vez de contar qual bit estamos, usa um shift de 9 bits com um
// marcador (1). A cada amostra empurra o bit lido; quando o marcador
// chega na ponta, ja recebemos os 8 bits de dados.

module uart_rx #(
    parameter CLK_HZ = 27_000_000,
    parameter BAUD   = 115200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valido,
    output reg        erro
);

    localparam CLK_BIT = CLK_HZ / BAUD;

    reg [1:0]  rx_sync;
    reg [15:0] timer;
    reg [8:0]  shift;
    reg        lendo;

    always @(posedge clk)
        rx_sync <= {rx_sync[0], rx};

    always @(posedge clk) begin
        if (rst) begin
            lendo  <= 1'b0;
            valido <= 1'b0;
            erro   <= 1'b0;
            shift  <= 9'b100000000;
        end else begin
            valido <= 1'b0;
            erro   <= 1'b0;

            if (!lendo) begin
                if (rx_sync[1] == 1'b0) begin
                    lendo  <= 1'b1;
                    timer  <= (CLK_BIT / 2) - 1;
                    shift  <= 9'b100000000;
                end
            end else if (timer == 0) begin
                timer <= CLK_BIT - 1;

                if (shift[0] == 1'b0)
                    shift <= {rx_sync[1], shift[8:1]};
                else begin
                    lendo  <= 1'b0;
                    data   <= shift[8:1];
                    valido <= rx_sync[1];
                    erro   <= ~rx_sync[1];
                end
            end else
                timer <= timer - 16'd1;
        end
    end

endmodule
