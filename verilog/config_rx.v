// Recebe pacote de configuracao Pi -> FPGA via UART.
//
//   STX | TYPE_CFG | dist_free | dist_att | vel_max | CHK | ETX
//
// TYPE_CFG = 8'h10
// CHK = XOR de TYPE_CFG + 3 campos

module config_rx #(
    parameter TYPE_CFG = 8'h10,
    parameter STX      = 8'h02,
    parameter ETX      = 8'h03
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] byte_in,
    input  wire       byte_valido,
    output reg  [7:0] cfg_dist_free,
    output reg  [7:0] cfg_dist_att,
    output reg  [7:0] cfg_vel_max,
    output reg        cfg_valida,
    output reg        cfg_erro
);

    localparam S_IDLE = 2'd0;
    localparam S_DATA = 2'd1;
    localparam S_ETX  = 2'd2;

    reg [1:0]  estado;
    reg [2:0]  idx;
    reg [7:0]  campos [0:4];
    reg [7:0]  xor_acc;

    always @(posedge clk) begin
        if (rst) begin
            estado        <= S_IDLE;
            idx           <= 3'd0;
            xor_acc       <= 8'd0;
            cfg_dist_free <= 8'd100;
            cfg_dist_att  <= 8'd50;
            cfg_vel_max   <= 8'd120;
            cfg_valida    <= 1'b0;
            cfg_erro      <= 1'b0;
        end else begin
            cfg_valida <= 1'b0;
            cfg_erro   <= 1'b0;

            if (byte_valido) case (estado)
                S_IDLE: begin
                    if (byte_in == STX) begin
                        idx     <= 3'd0;
                        xor_acc <= 8'd0;
                        estado  <= S_DATA;
                    end
                end

                S_DATA: begin
                    campos[idx] <= byte_in;
                    if (idx < 3'd4)
                        xor_acc <= xor_acc ^ byte_in;

                    if (idx == 3'd4) begin
                        if (byte_in == xor_acc) begin
                            cfg_dist_free <= campos[1];
                            cfg_dist_att  <= campos[2];
                            cfg_vel_max   <= campos[3];
                            cfg_valida    <= 1'b1;
                        end else
                            cfg_erro <= 1'b1;
                        estado <= S_ETX;
                    end else
                        idx <= idx + 3'd1;
                end

                S_ETX: begin
                    if (byte_in != ETX)
                        cfg_erro <= 1'b1;
                    estado <= S_IDLE;
                end

                default: estado <= S_IDLE;
            endcase
        end
    end

endmodule
