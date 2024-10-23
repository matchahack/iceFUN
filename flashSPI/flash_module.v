/*
 *  
 *  Copyright(C) 2024 Kai Harris <matchahack@gmail.com>
 * 
 *  Permission to use, copy, modify, and/or distribute this software for any purpose with or
 *  without fee is hereby granted, provided that the above copyright notice and 
 *  this permission notice appear in all copies.
 * 
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO
 *  THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. 
 *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL 
 *  DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 *  AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN 
 *  CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 * 
 */

module flash_module(
    input top_clk,
    input sub_clk,
    input miso,
    output cs,
    output sck,
    output mosi,
    output [7:0] flash_response
);
    /*operation state*/
    parameter await_delay = 0;
    parameter perform_op = 1;
    reg clock_state;

    /*long gap between operations*/
    parameter OPERATION_DELAY = 14'b11111111111111;
    reg [13:0] delay_counter;

    /*opcode*/
    parameter [31:0] OPCODE = {4'b1010, 4'b1011, 8'b0, 8'b0, 8'b0};

    /*counters and flags*/
    integer operation_counter;
    integer SI_pulse, SO_pulse;
    reg clock_start_flag;

    /*module wiring*/
    reg CS_register, MOSI_register, SCK_register;
    reg [7:0] FLASH_RESPONSE;
    assign cs = CS_register;
    assign sck = SCK_register;
    assign mosi = MOSI_register;
    assign flash_response = FLASH_RESPONSE;
    
    /*initialisation*/
    initial begin
        clock_state <= await_delay;
        delay_counter <= 0;
        operation_counter <= 0;
        SI_pulse <= 0;
        clock_start_flag <= 0;
        CS_register <= 1;
        MOSI_register <= OPCODE[31];
        FLASH_RESPONSE <= 8'b11111111;
    end

    /*CS, SI and SO control*/
    always @ (posedge sub_clk) begin
        case (clock_state)
            await_delay : begin
                delay_counter <= delay_counter + 1;
                if (delay_counter == OPERATION_DELAY - 1) begin
                    CS_register <= 0;
                    clock_state <= perform_op;
                end
            end
            perform_op : begin
                if (delay_counter == OPERATION_DELAY) begin
                    clock_start_flag <= 1;
                end begin
                    operation_counter <= operation_counter + 1;
                    if (operation_counter <= 31) begin
                        SI_pulse <= SI_pulse + 1;
                        MOSI_register <= OPCODE[31-SI_pulse];
                    end
                    if (operation_counter >= 31 && operation_counter < 39) begin
                        SO_pulse <= SO_pulse + 1;
                        FLASH_RESPONSE[7-SO_pulse] <= miso;
                    end
                    if (operation_counter == 39) begin
                        clock_state <= await_delay;
                        delay_counter <= 0;
                        operation_counter <= 0;
                        SI_pulse <= 0;
                        clock_start_flag <= 0;
                        MOSI_register <= OPCODE[31];
                        CS_register <= 1;
                    end
                end
            end
        endcase
    end

    /*SCK wiring control*/
    always @ (*) begin
        if (clock_start_flag) SCK_register <= top_clk;
        else SCK_register <= 0;
    end

endmodule