// UART TX 8N1 — envia um byte por vez (LSB first)
//
// Espelho do uart_rx: shift + timer decrescente.
// Frame montado em shift: {stop, data[7:0], start}
// shift[0] vai para tx; a cada bit faz shift >> 1.
// Quando shift == 1, so resta o stop bit — ultimo pulso e termina.

module uart_tx #(
    parameter CLK_HZ = 27_000_000,
    parameter BAUD   = 115200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy
);

    localparam CLK_BIT = CLK_HZ / BAUD;

    reg [9:0]  shift;
    reg [15:0] timer;
    reg        enviando;

    always @(posedge clk) begin
        if (rst) begin
            enviando <= 1'b0;
            shift    <= 10'd0;
            tx       <= 1'b1;
            busy     <= 1'b0;
        end else if (!enviando) begin
            tx   <= 1'b1;
            busy <= 1'b0;

            if (start) begin
                shift    <= {1'b1, data[7:0], 1'b0};
                enviando <= 1'b1;
                timer    <= CLK_BIT - 1;
                tx       <= 1'b0;
                busy     <= 1'b1;
            end
        end else begin
            tx <= shift[0];

            if (timer == 0) begin
                timer <= CLK_BIT - 1;

                if (shift == 10'd1)
                    enviando <= 1'b0;

                shift <= shift >> 1;
            end else
                timer <= timer - 16'd1;
        end
    end

endmodule
