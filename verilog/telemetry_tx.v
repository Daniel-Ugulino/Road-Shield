// Pacote de telemetria FPGA -> Raspberry Pi (via uart_tx)
//
//   STX | dist_e | dist_c | dist_d | vel_e | vel_c | vel_d | chk | ETX
//
//   dist_* : distancia em cm (unsigned)
//   vel_*  : velocidade do obstaculo em cm/amostra (signed, complemento de 2)
//   chk    : XOR dos 6 bytes de payload

module telemetry_tx #(
    parameter CLK_HZ = 27_000_000,
    parameter BAUD   = 115200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       enviar,
    input  wire [7:0] dist_e,
    input  wire [7:0] dist_c,
    input  wire [7:0] dist_d,
    input  wire signed [7:0] vel_e,
    input  wire signed [7:0] vel_c,
    input  wire signed [7:0] vel_d,
    output wire       tx,
    output reg        ocupado
);

    localparam STX = 8'h02;
    localparam ETX = 8'h03;

    localparam S_IDLE  = 3'd0;
    localparam S_ARM   = 3'd1;
    localparam S_LOAD  = 3'd2;
    localparam S_SEND  = 3'd3;
    localparam S_WAIT  = 3'd4;

    reg [2:0]  estado;
    reg [3:0]  idx;
    reg [7:0]  pacote [0:8];
    reg [7:0]  byte_tx;
    reg        start_uart;
    reg        viu_busy;

    wire       uart_busy;
    wire [7:0] vel_e_b = vel_e;
    wire [7:0] vel_c_b = vel_c;
    wire [7:0] vel_d_b = vel_d;
    wire [7:0] checksum = dist_e ^ dist_c ^ dist_d ^ vel_e_b ^ vel_c_b ^ vel_d_b;

    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) uart (
        .clk   (clk),
        .rst   (rst),
        .start (start_uart),
        .data  (byte_tx),
        .tx    (tx),
        .busy  (uart_busy)
    );

    always @(posedge clk) begin
        if (rst) begin
            estado     <= S_IDLE;
            idx        <= 4'd0;
            byte_tx    <= 8'd0;
            start_uart <= 1'b0;
            viu_busy   <= 1'b0;
            ocupado    <= 1'b0;
        end else begin
            start_uart <= 1'b0;

            case (estado)
                S_IDLE: begin
                    ocupado <= 1'b0;
                    if (enviar)
                        estado <= S_ARM;
                end

                S_ARM: begin
                    pacote[0] <= STX;
                    pacote[1] <= dist_e;
                    pacote[2] <= dist_c;
                    pacote[3] <= dist_d;
                    pacote[4] <= vel_e_b;
                    pacote[5] <= vel_c_b;
                    pacote[6] <= vel_d_b;
                    pacote[7] <= checksum;
                    pacote[8] <= ETX;
                    idx        <= 4'd0;
                    ocupado    <= 1'b1;
                    estado     <= S_LOAD;
                end

                S_LOAD: begin
                    byte_tx <= pacote[idx];
                    estado  <= S_SEND;
                end

                S_SEND: begin
                    start_uart <= 1'b1;
                    viu_busy   <= 1'b0;
                    estado     <= S_WAIT;
                end

                S_WAIT: begin
                    if (uart_busy)
                        viu_busy <= 1'b1;

                    if (viu_busy && !uart_busy) begin
                        viu_busy <= 1'b0;
                        if (idx >= 4'd8)
                            estado <= S_IDLE;
                        else begin
                            idx    <= idx + 4'd1;
                            estado <= S_LOAD;
                        end
                    end
                end

                default: estado <= S_IDLE;
            endcase
        end
    end

endmodule
