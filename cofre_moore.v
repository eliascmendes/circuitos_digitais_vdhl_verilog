`timescale 1ns/1ps

module cofre_moore #(
    parameter integer BLINK_PERIOD = 8
) (
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] digit,
    input  logic       digit_valid,
    output logic       led_red,
    output logic       led_yellow,
    output logic       led_green,
    output logic       lock_engaged,
    output logic       alarm
);

    typedef enum logic [2:0] {
        S_LOCKED  = 3'd0,
        S_DIG1_OK = 3'd1,
        S_DIG2_OK = 3'd2,
        S_OPEN    = 3'd3,
        S_ERROR   = 3'd4
    } state_t;

    state_t state, state_next;

    logic blink_toggle;
    logic [$clog2(BLINK_PERIOD)-1:0] blink_counter;

    localparam logic [3:0] DIG1 = 4'd1;
    localparam logic [3:0] DIG2 = 4'd2;
    localparam logic [3:0] DIG3 = 4'd3;

    // Blink generator for flashing LEDs
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            blink_counter <= '0;
            blink_toggle  <= 1'b0;
        end else begin
            if (blink_counter == BLINK_PERIOD - 1) begin
                blink_counter <= '0;
                blink_toggle  <= ~blink_toggle;
            end else begin
                blink_counter <= blink_counter + 1'b1;
            end
        end
    end

    // State register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_LOCKED;
        end else begin
            state <= state_next;
        end
    end

    // Next-state logic
    always_comb begin
        state_next = state;
        unique case (state)
            S_LOCKED: begin
                if (digit_valid) begin
                    if (digit == DIG1) state_next = S_DIG1_OK;
                    else state_next = S_ERROR;
                end
            end
            S_DIG1_OK: begin
                if (digit_valid) begin
                    if (digit == DIG2) state_next = S_DIG2_OK;
                    else state_next = S_ERROR;
                end
            end
            S_DIG2_OK: begin
                if (digit_valid) begin
                    if (digit == DIG3) state_next = S_OPEN;
                    else state_next = S_ERROR;
                end
            end
            S_OPEN: begin
                // permanece aberto até reset
                state_next = state;
            end
            S_ERROR: begin
                // permanece em erro até reset
                state_next = state;
            end
            default: state_next = S_LOCKED;
        endcase
    end

    // Moore outputs: dependem apenas do estado (e do oscilador de blink)
    always_comb begin
        led_red      = 1'b0;
        led_yellow   = 1'b0;
        led_green    = 1'b0;
        lock_engaged = 1'b1;
        alarm        = 1'b0;

        unique case (state)
            S_LOCKED: begin
                led_red = 1'b1; // LED vermelho fixo
            end
            S_DIG1_OK: begin
                led_yellow = 1'b1; // LED amarelo fixo
            end
            S_DIG2_OK: begin
                led_yellow = blink_toggle; // LED amarelo piscando
            end
            S_OPEN: begin
                led_green    = 1'b1; // LED verde
                lock_engaged = 1'b0; // trava desligada
            end
            S_ERROR: begin
                led_red = blink_toggle; // LED vermelho piscando
                alarm   = 1'b1;         // alarme ligado
            end
            default: begin
                led_red = 1'b1;
            end
        endcase
    end
endmodule

