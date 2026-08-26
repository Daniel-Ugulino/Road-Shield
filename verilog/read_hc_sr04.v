module read_hc_sr04 #(
    parameter CLK_HZ      = 27_000_000,
    parameter TRIG_US     = 10,
    parameter TIMEOUT_MS  = 30
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire       echo,
    output reg        trig,
    output reg        busy,
    output reg  [7:0] distancia_cm,
    output reg        valido,
    output reg        timeout
);

    localparam TRIG_CYCLES    = (CLK_HZ / 1_000_000) * TRIG_US;
    localparam TIMEOUT_CYCLES = (CLK_HZ / 1_000) * TIMEOUT_MS;
    localparam CM_DIVISOR     = (CLK_HZ / 1_000_000) * 58;

    localparam S_IDLE      = 3'd0;
    localparam S_TRIG      = 3'd1;
    localparam S_WAIT_RISE = 3'd2;
    localparam S_MEASURE   = 3'd3;
    localparam S_DONE      = 3'd4;

    reg [2:0]  estado;
    reg [23:0] contador;

    always @(posedge clk) begin
        if (rst) begin
            estado       <= S_IDLE;
            contador     <= 24'd0;
            trig         <= 1'b0;
            busy         <= 1'b0;
            distancia_cm <= 8'd0;
            valido       <= 1'b0;
            timeout      <= 1'b0;
        end else begin
            valido  <= 1'b0;
            timeout <= 1'b0;

            case (estado)
                S_IDLE: begin
                    trig <= 1'b0;
                    busy <= 1'b0;
                    if (start) begin
                        busy     <= 1'b1;
                        contador <= 24'd0;
                        trig     <= 1'b1;
                        estado   <= S_TRIG;
                    end
                end

                S_TRIG: begin
                    if (contador >= TRIG_CYCLES - 1) begin
                        trig     <= 1'b0;
                        contador <= 24'd0;
                        estado   <= S_WAIT_RISE;
                    end else
                        contador <= contador + 24'd1;
                end

                S_WAIT_RISE: begin
                    if (echo) begin
                        contador <= 24'd0;
                        estado   <= S_MEASURE;
                    end else if (contador >= TIMEOUT_CYCLES - 1) begin
                        timeout <= 1'b1;
                        busy    <= 1'b0;
                        trig    <= 1'b0;
                        estado  <= S_IDLE;
                    end else
                        contador <= contador + 24'd1;
                end

                S_MEASURE: begin
                    if (!echo) begin
                        if (CM_DIVISOR != 0)
                            distancia_cm <= contador / CM_DIVISOR;
                        valido <= 1'b1;
                        busy   <= 1'b0;
                        trig   <= 1'b0;
                        estado <= S_IDLE;
                    end else if (contador >= TIMEOUT_CYCLES - 1) begin
                        timeout <= 1'b1;
                        busy    <= 1'b0;
                        trig    <= 1'b0;
                        estado  <= S_IDLE;
                    end else
                        contador <= contador + 24'd1;
                end

                S_DONE: begin
                    trig   <= 1'b0;
                    busy   <= 1'b0;
                    estado <= S_IDLE;
                end

                default: estado <= S_IDLE;
            endcase
        end
    end

endmodule
