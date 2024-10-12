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
 
`timescale 1 ns / 1 ps  // Time scale directive, 1 ns time unit, 1 ps time precision

module output_tb();

    // Declare wires for SPI signals and output values
    wire mosi, sck, cs;             // SPI signals: MOSI, SCK, and CS
    wire [7:0] led;                 // 8-bit wire for LED outputs
    wire [3:0] col;                 // 4-bit wire for column selection (LED control)

    // Declare registers for clock and MISO signal (input to DUT)
    reg clk = 0;                    // Clock signal initialised to 0
    reg miso;                       // MISO input (Master In Slave Out)

    localparam CLK_PERIOD = 83.33;  // ns (12MHz)
    localparam HALF_CLK_PERIOD = 41.67;
    localparam DURATION = 5000;     // Simulation duration parameter (in ns)

    // Instantiate the main module (Device Under Test - DUT)
    top uut (
        .clk(clk),                  // Connect clock signal
        .led(led),                  // Connect LED output
        .col(col),                  // Connect column selection output
        .cs(cs),                    // Connect chip select (CS) output
        .sck(sck),                  // Connect serial clock (SCK) output
        .mosi(mosi),                // Connect MOSI output
        .miso(miso)                 // Connect MISO input
    );

    initial begin
        // Wait for MOSI operation to finish, while MISO is in high impedence
        miso <= 0;
        repeat (20) @(posedge clk);

        // Simulate hex value 1F (0001 1111 on MISO)
        miso <= 0;
        repeat (3) @(posedge clk);
        miso <= 1;
        repeat (5) @(posedge clk);

        // Simulate hex value 85 (1000 0101 on MISO)
        miso <= 1;
        repeat (1) @(posedge clk);
        miso <= 0;
        repeat (4) @(posedge clk);
        miso <= 1;
        repeat (1) @(posedge clk);
        miso <= 0;
        repeat (1) @(posedge clk);
        miso <= 1;
        repeat (1) @(posedge clk);

        // Simulate hex value 01 (0000 0001 on MISO)
        miso <= 0;
        repeat (7) @(posedge clk);
        miso <= 1;
        repeat (1) @(posedge clk);
    end

    // VCD dump for waveform analysis
    initial begin
        $dumpfile("output_tb.vcd");    // Create VCD file for simulation waveform output
        $dumpvars(0, output_tb);       // Dump variables from top module (output_tb)
        #(DURATION);                   // Run simulation for specified duration
        $finish;                       // End the simulation
    end

    // Clock generation block
    always begin
        #(HALF_CLK_PERIOD)             // Half-period delay
        clk = ~clk;                    // Toggle clock signal every half period
    end

endmodule
