//============================================================
// Automatic Bottle Filling Machine FSM
//============================================================
module bottle_filler #(
    parameter ALIGN_CYCLES  = 5,
    parameter FILL_CYCLES   = 8,
    parameter SETTLE_CYCLES = 4
)(
    input  wire clk,
    input  wire reset,
    input  wire bottle_sensor,  // Detects bottle under fill nozzle
    input  wire exit_sensor,    // Detects bottle has exited
    input  wire jam_sensor,     // Detects jam
    input  wire estop,          // Emergency stop
    output reg  conveyor_on,    // Motor control for conveyor
    output reg  valve_open,     // Filling valve control
    output reg  alarm           // Alarm for jam or estop
);

    // FSM states
    typedef enum reg [2:0] {
        S_IDLE     = 3'b000,
        S_RUN      = 3'b001,
        S_ALIGN    = 3'b010,
        S_FILL     = 3'b011,
        S_SETTLE   = 3'b100,
        S_MOVE_OUT = 3'b101,
        S_JAM      = 3'b110,
        S_ESTOP    = 3'b111
    } state_t;

    state_t state, next_state;

    reg [7:0] counter; // generic counter for timing

    // Sequential: state + counter update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state   <= S_IDLE;
            counter <= 0;
        end else begin
            state <= next_state;
            if (state == S_ALIGN || state == S_FILL || state == S_SETTLE)
                counter <= counter + 1;
            else
                counter <= 0;
        end
    end

    // Combinational: next state logic
    always @(*) begin
        next_state  = state;
        conveyor_on = 0;
        valve_open  = 0;
        alarm       = 0;

        case (state)
            S_IDLE: begin
                conveyor_on = 0;
                if (!estop) next_state = S_RUN;
            end

            S_RUN: begin
                conveyor_on = 1;
                if (jam_sensor) next_state = S_JAM;
                else if (estop) next_state = S_ESTOP;
                else if (bottle_sensor) next_state = S_ALIGN;
            end

            S_ALIGN: begin
                conveyor_on = 0;
                if (counter >= ALIGN_CYCLES) next_state = S_FILL;
                if (jam_sensor) next_state = S_JAM;
                if (estop) next_state = S_ESTOP;
            end

            S_FILL: begin
                valve_open = 1;
                if (counter >= FILL_CYCLES) next_state = S_SETTLE;
                if (jam_sensor) next_state = S_JAM;
                if (estop) next_state = S_ESTOP;
            end

            S_SETTLE: begin
                if (counter >= SETTLE_CYCLES) next_state = S_MOVE_OUT;
                if (jam_sensor) next_state = S_JAM;
                if (estop) next_state = S_ESTOP;
            end

            S_MOVE_OUT: begin
                conveyor_on = 1;
                if (exit_sensor) next_state = S_RUN;
                if (jam_sensor) next_state = S_JAM;
                if (estop) next_state = S_ESTOP;
            end

            S_JAM: begin
                alarm = 1;
                conveyor_on = 0;
                valve_open = 0;
                if (!jam_sensor && !estop) next_state = S_RUN;
            end

            S_ESTOP: begin
                alarm = 1;
                conveyor_on = 0;
                valve_open = 0;
                if (!estop) next_state = S_RUN;
            end
        endcase
    end

endmodule
