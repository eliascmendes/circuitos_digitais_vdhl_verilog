`timescale 1ns/1ps

module cofre_moore_tb;
    localparam integer BLINK_PERIOD = 4;

    logic clk;
    logic reset;
    logic [3:0] digit;
    logic digit_valid;
    logic led_red;
    logic led_yellow;
    logic led_green;
    logic lock_engaged;
    logic alarm;

    cofre_moore #(.BLINK_PERIOD(BLINK_PERIOD)) dut (
        .clk(clk),
        .reset(reset),
        .digit(digit),
        .digit_valid(digit_valid),
        .led_red(led_red),
        .led_yellow(led_yellow),
        .led_green(led_green),
        .lock_engaged(lock_engaged),
        .alarm(alarm)
    );

    // Clock de 10 ns
    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic send_digit(input [3:0] d);
        begin
            @(negedge clk);
            digit       <= d;
            digit_valid <= 1'b1;
            @(negedge clk);
            digit_valid <= 1'b0;
        end
    endtask

    task automatic expect_locked;
        begin
            if (!(led_red && !led_yellow && !led_green && lock_engaged && !alarm)) begin
                $fatal("Esperado estado LOCKED, mas os sinais diferem");
            end
        end
    endtask

    task automatic expect_dig1;
        begin
            if (!(!led_red && led_yellow && !led_green && lock_engaged && !alarm)) begin
                $fatal("Esperado estado DIG1_OK, mas os sinais diferem");
            end
        end
    endtask

    task automatic expect_dig2;
        begin
            if (!(led_yellow && lock_engaged && !led_green && !alarm)) begin
                $fatal("Esperado estado DIG2_OK, mas os sinais diferem");
            end
        end
    endtask

    task automatic expect_open;
        begin
            if (!(!lock_engaged && led_green && !alarm)) begin
                $fatal("Esperado estado ABERTO, mas os sinais diferem");
            end
        end
    endtask

    task automatic expect_error;
        begin
            if (!(alarm && lock_engaged && !led_green)) begin
                $fatal("Esperado estado ERRO, mas os sinais diferem");
            end
        end
    endtask

    initial begin
        $display("Iniciando simulacao do Cofre Eletronico");
        digit       = 4'd0;
        digit_valid = 1'b0;

        reset = 1'b1;
        repeat (2) @(negedge clk);
        reset = 1'b0;
        repeat (2) @(negedge clk);
        expect_locked();

        // Sequencia correta 1-2-3
        send_digit(4'd1);
        repeat (2) @(negedge clk);
        expect_dig1();

        send_digit(4'd2);
        repeat (BLINK_PERIOD) @(negedge clk); // permite ver piscando
        expect_dig2();

        send_digit(4'd3);
        repeat (2) @(negedge clk);
        expect_open();
        $display("Senha correta abriu o cofre");

        // Reset para testar sequencia incorreta apos digito 1
        reset = 1'b1;
        @(negedge clk);
        reset = 1'b0;
        repeat (2) @(negedge clk);
        expect_locked();

        send_digit(4'd1);
        repeat (2) @(negedge clk);
        expect_dig1();

        send_digit(4'd5);
        repeat (BLINK_PERIOD) @(negedge clk);
        expect_error();
        $display("Sequencia incorreta apos primeiro digito levou ao estado de erro");

        // Reset e erro direto
        reset = 1'b1;
        @(negedge clk);
        reset = 1'b0;
        repeat (2) @(negedge clk);

        send_digit(4'd9);
        repeat (BLINK_PERIOD) @(negedge clk);
        expect_error();
        $display("Primeiro digito incorreto levou ao estado de erro");

        $display("Teste finalizado sem erros");
        $finish;
    end
endmodule

