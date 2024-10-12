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

module top (
    input                    clk,            // Clock input
    output      wire [7:0]   led,            // 8-bit output for LEDs
    output      wire [3:0]   col,            // 4-bit output to select active LED column
    output      wire         cs,             // Chip select signal for SPI
    output      wire         sck,            // Serial clock for SPI
    input                    miso,           // Master In Slave Out (data from SPI device)
    output      wire         mosi            // Master Out Slave In (data to SPI device)
);

    // System clock counter and control for delay before starting SPI operation
    reg [4:0] clock_counter;                  // 5-bit clock counter

    reg [7:0] led_register;                   // Register to store LED output values
    reg [4:0] col_register;                   // Register to store column activation for LEDs
    assign led = led_register;                // Assign register values to output
    assign col = col_register;                // Assign register values to column output

    // SPI registers and variables to handle SPI communication
    reg flash_done;                           // Flag indicating SPI operation completion
    reg start_flash;                          // Flag to start SPI flash read operation

    reg cs_register, mosi_register, sck_register;  // Registers for SPI control signals
    assign cs = cs_register;                  // Chip select output assignment
    assign mosi = mosi_register;              // MOSI output assignment
    assign sck = sck_register;                // SCK output assignment

    integer OPERATION_LENGTH;                 // Counter for the length of the SPI operation
    integer SI_PULSE;                         // Counter for outgoing data bits (MOSI)
    integer SO_SAMPLE;                        // Counter for incoming data bits (MISO)
    reg [7:0] OPCODE;                         // 8-bit SPI opcode for the flash memory command
    reg [23:0] RESPONSE_DATA;                 // 24-bit register for storing response from SPI device

    // Initial block for setting default/reset states
    initial begin
        // Clock and led initialization
        clock_counter <= 0;                   // Reset clock counter
        
        led_register <= 8'b11111111;          // Set all LEDs off
        col_register <= 4'b1110;              // Activate specific LED column (column 0)

        // SPI initialization
        start_flash <= 0;                     // Do not start flash read yet
        flash_done <= 0;                      // SPI operation not completed

        sck_register <= 1;                    // Set SCK to high
        cs_register <= 1;                     // Set chip select to high (inactive)
        mosi_register <= 1;                   // Set MOSI to default state (high)

        OPERATION_LENGTH <= 0;                // Initialize SPI operation length counter
        SI_PULSE <= 0;                        // Reset outgoing data bit counter
        SO_SAMPLE <= 0;                       // Reset incoming data bit counter
        OPCODE <= 8'h9F;                      // Set SPI command for "Read ID" (9Fh)
        RESPONSE_DATA <= 24'b0;               // Initialize response data to a default value
    end

    // Start SPI operation after clock delay
    always @(negedge clk) begin
        if (clock_counter < 10) begin
            clock_counter <= clock_counter + 1;          // Increment clock counter
        end else if (clock_counter == 10) begin          // Trigger SPI flash read after 10 cycles
            start_flash <= 1;                            // Start flash read operation
            clock_counter <= clock_counter + 1;          // Increment counter to move to the next state
        end else if (start_flash && flash_done) begin    // Update LEDs with SPI response data
            led_register[7:0] <= RESPONSE_DATA[15:8];    // Set LEDs based on response data
            start_flash <= 0;                            // Reset flash start flag
        end
    end

    // SPI operation
    always @(negedge clk) begin
        if (start_flash && !flash_done) begin
            cs_register <= 0;                            // Set chip select low (start SPI)
            OPERATION_LENGTH <= OPERATION_LENGTH + 1;    // Increment operation length counter
            // Send opcode to SPI device (MOSI)
            if(OPERATION_LENGTH >= 0 && OPERATION_LENGTH <= 7) begin
                SI_PULSE <= SI_PULSE + 1;                // Increment outgoing bit counter
                mosi_register <= OPCODE[7-SI_PULSE];     // Send one bit of opcode (MSB first)
            end
            // Receive response from SPI device (MISO)
            if(OPERATION_LENGTH > 7 && OPERATION_LENGTH <= 32) begin
                SO_SAMPLE <= SO_SAMPLE + 1;              // Increment incoming bit counter
                RESPONSE_DATA[23-SO_SAMPLE] <= miso;     // Store incoming bit in response register
            end
            // End SPI operation after receiving full response
            if(OPERATION_LENGTH == 32) begin
                cs_register <= 1;                        // Set chip select high (end SPI)
                flash_done <= 1;                         // Mark SPI operation as complete
            end
        end
    end

    // Clock assignment for SPI clock (SCK) signal
    always @(*) begin
        sck_register = clk;                             // Set SCK to match system clock
    end

endmodule
