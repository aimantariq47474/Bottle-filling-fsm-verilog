//============================================================
// Testbench for Automatic Bottle Filling Machine FSM
//============================================================
`timescale 1ns/1ps
module tb_bottle_filler;

    reg clk;
    reg reset;
    reg bottle_sensor;
    reg exit_sensor;
    reg jam_sensor;
    reg estop;
    wire conveyor_on;
    wire valve_open;
    wire alarm;

    // Instantiate DUT
    bottle_filler #(
        .ALIGN_CYCLES(5),
        .FILL_CYCLES(8),
        .SETTLE_CYCLES(4)
    ) dut (
        .clk(clk),
        .reset(reset),
        .bottle_sensor(bottle_sensor),
        .exit_sensor(exit_sensor),
        .jam_sensor(jam_sensor),
        .estop(estop),
        .conveyor_on(conveyor_on),
        .valve_open(valve_open),
        .alarm(alarm)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_bottle_filler);

        // Init
        clk = 0; reset = 1;
        bottle_sensor = 0; exit_sensor = 0; jam_sensor = 0; estop = 0;

        // Release reset
        #20 reset = 0;

        // First bottle arrives
        #50 bottle_sensor = 1;
        #10 bottle_sensor = 0;

        // Simulate bottle leaving
        #200 exit_sensor = 1;
        #10 exit_sensor = 0;

        // Second bottle arrives
        #50 bottle_sensor = 1;
        #10 bottle_sensor = 0;

        // Jam occurs
        #100 jam_sensor = 1;
        #40 jam_sensor = 0;

        // Emergency stop triggered
        #100 estop = 1;
        #50 estop = 0;

        #200 $finish;
    end

endmodule
