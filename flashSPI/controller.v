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

`include "sub_clock_module.v"
`include "flash_module.v"
`include "leds.v"

module main (
    input   clk,
    input   miso,
    output  cs,
    output  sck,
    output  mosi,
    output  [7:0] led,
    output  [3:0] col
);

    /*system wiring*/
    wire [7:0] flash_response;
    wire sub_clock, SI_out_clock;

    /*clock module management*/
    sub_clock_module sub_clock_module (
        .top_clk(clk),
        .sub_clock(sub_clock),
        .SI_out_clock(SI_out_clock)
    );

    /*flash module management*/
    flash_module flash_module (
        .top_clk(sub_clock),
        .sub_clk(SI_out_clock),
        .miso(miso),
        .cs(cs),
        .sck(sck),
        .mosi(mosi),
        .flash_response(flash_response)
    );

    /*led module management*/
    led_module led_module (
        .led_set(flash_response),
        .led(led),
        .col(col)
    );

endmodule