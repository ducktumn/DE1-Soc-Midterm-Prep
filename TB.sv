
```systemverilog
// ============================================================================
// 1. DESIGN UNDER TEST (DUT) - counter.sv
// ============================================================================
module counter (
    input  logic       clk,
    input  logic       rst_n,   // Active-low asynchronous reset
    input  logic       enable,
    output logic [3:0] count
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'b0000;
        end else if (enable) begin
            count <= count + 1'b1;
        end
    end

endmodule


// ============================================================================
// 2. INPUT TEXT FILE LAYOUT - stimulus.dat
// Save the block below into a file named 'stimulus.dat' in your working dir:
/*
0 0
0 0
1 0
1 1
1 1
1 1
1 0
1 0
1 1
1 1
*/
// ============================================================================


// ============================================================================
// 3. SYSTEMVERILOG TESTBENCH - tb_counter.sv
// ============================================================================
`timescale 1ns/1ps

module tb_counter;

    // -------------------------------------------------------------
    // Signal Declarations
    // -------------------------------------------------------------
    logic       clk;
    logic       rst_n;
    logic       enable;
    logic [3:0] count;

    // File I/O Variables
    int         file_handle;
    int         status;
    logic       file_rst_n;
    logic       file_enable;

    // -------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------
    counter dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (enable),
        .count  (count)
    );

    // -------------------------------------------------------------
    // Clock Generation (100MHz / 10ns period)
    // -------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------------
    // File-Driven Stimulus & Test Sequence Control
    // -------------------------------------------------------------
    initial begin
        // Initialize signals
        rst_n  = 0;
        enable = 0;

        $display("[%0t ns] --- Starting File-Driven Testbench ---", $time);

        // A. Open file in read mode
        file_handle = $fopen("stimulus.dat", "r");

        // B. Check for valid file handle
        if (file_handle == 0) begin
            $error("[%0t ns] ERROR: Could not open 'stimulus.dat'!", $time);
            $finish;
        end else begin
            $display("[%0t ns] Successfully opened 'stimulus.dat'", $time);
        end

        #10;

        // C. Read line-by-line until EOF ($feof)
        while (!$feof(file_handle)) begin
            // Drive inputs on negedge to avoid setup/hold timing races on posedge
            @(negedge clk);

            status = $fscanf(file_handle, "%b %b\n", file_rst_n, file_enable);

            if (status == 2) begin
                rst_n  <= file_rst_n;
                enable <= file_enable;
                $display("[%0t ns] READ FILE -> Applied rst_n=%b, enable=%b", $time, file_rst_n, file_enable);
            end
        end

        // D. Close file handle
        $fclose(file_handle);

        #30;
        $display("[%0t ns] --- Testbench Finished Successfully ---", $time);
        $finish;
    end

    // -------------------------------------------------------------
    // Automatic Monitor Control
    // -------------------------------------------------------------
    always @(posedge clk) begin
        $display("[%0t ns] MONITOR: rst_n=%b | enable=%b | Count=%d", $time, rst_n, enable, count);
    end

    // -------------------------------------------------------------
    // Waveform Dump Control (GTKWave / EDA Playground)
    // -------------------------------------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_counter);
    end

endmodule

```