`timescale 1ns / 1ps

module fpga_tester_top2 (
    input  logic        clk,     
    input  logic        btnC,      
    output logic [15:0] led,     
    output logic        ack_led, 
    output logic [6:0]  seg,     
    output logic        dp,      
    output logic[7:0]  an,      
    output logic        pmod_sck,
    output logic        pmod_mosi,
    input  logic        pmod_miso,
    output logic        pmod_cs0,
    output logic        pmod_sd2, 
    output logic        pmod_sd3, 
    output logic        pmod_cs1, 
    output logic        pmod_cs2  
);

    localparam NUM_TESTS = 100000;

    assign pmod_sd2 = 1'b1;
    assign pmod_sd3 = 1'b1;

    logic [31:0] pipe_addr, pipe_wrData, pipe_rdData;
    logic        pipe_rd, pipe_wr, pipe_ack;

    spi_memory_controller spi_inst (
        .clk(clk), .rst(btnC),
        .pipecon_address(pipe_addr), .pipecon_rd(pipe_rd), .pipecon_wr(pipe_wr),
        .pipecon_wrData(pipe_wrData), .pipecon_wrMask(4'b1111), .pipecon_rdData(pipe_rdData),
        .pipecon_ack(pipe_ack),
        .spi_sck(pmod_sck), .spi_mosi(pmod_mosi), .spi_miso(pmod_miso),
        .spi_cs0_n(pmod_cs0), .spi_cs1_n(pmod_cs1), .spi_cs2_n(pmod_cs2)
    );

    typedef enum logic[4:0] { 
        INIT_WAIT,
        CHECK_PHASE,
        FLASH_ERASE_REQ,
        FLASH_ERASE_WAIT,
        FLASH_COOL_DOWN,
        FLASH_POLL_REQ,
        FLASH_POLL_WAIT,
        FLASH_POLL_CHECK,
        WRITE_REQ, 
        WRITE_WAIT, 
        READ_REQ, 
        READ_WAIT, 
        VERIFY, 
        SUCCESS_HALT,
        ERROR_HALT 
    } test_state_t;
    
    test_state_t state, poll_return_state;

    logic [19:0] boot_delay; 
    logic [31:0] current_addr, current_data, test_count, latched_rdData;
    logic [1:0]  test_phase;

    always_ff @(posedge clk) begin
        if (btnC) begin
            state          <= INIT_WAIT;
            boot_delay     <= 20'b0;
            test_count     <= 32'd0;
            test_phase     <= 2'd1;           
            current_addr   <= 32'h5000_0000;  // Start Phase 1
            current_data   <= 32'hAAAA_0000;
            ack_led        <= 1'b0;
            led            <= 16'b0;
            pipe_rd        <= 1'b0;
            pipe_wr        <= 1'b0;
        end else begin
            pipe_rd <= 1'b0;
            pipe_wr <= 1'b0;

            case (state)
                INIT_WAIT: begin
                    if (boot_delay < 20'd500000)
                        boot_delay <= boot_delay + 1'b1;
                    else
                        state <= CHECK_PHASE;
                end

                CHECK_PHASE: begin
                    if (test_phase == 2'd3 && current_addr[11:0] == 12'h000) begin
                        state <= FLASH_ERASE_REQ;
                    end else begin
                        state <= WRITE_REQ;
                    end
                end

                FLASH_ERASE_REQ: begin
                    pipe_addr   <= {8'h41, current_addr[23:0]};
                    pipe_wr     <= 1'b1;
                    state       <= FLASH_ERASE_WAIT;
                end

                FLASH_ERASE_WAIT: begin
                    if (pipe_ack) begin
                        poll_return_state <= WRITE_REQ; 
                        boot_delay        <= 20'd0; 
                        state             <= FLASH_COOL_DOWN;
                    end
                end

                FLASH_COOL_DOWN: begin
                    if (boot_delay < 20'd1000) boot_delay <= boot_delay + 1'b1;
                    else state <= FLASH_POLL_REQ;
                end

                FLASH_POLL_REQ: begin
                    pipe_addr <= 32'h4200_0000;
                    pipe_rd   <= 1'b1;
                    state     <= FLASH_POLL_WAIT;
                end

                FLASH_POLL_WAIT: begin
                    if (pipe_ack) begin
                        latched_rdData <= pipe_rdData;
                        state          <= FLASH_POLL_CHECK;
                    end
                end

                FLASH_POLL_CHECK: begin
                    if (latched_rdData[0] == 1'b1) state <= FLASH_POLL_REQ; 
                    else state <= poll_return_state; 
                end
          
                // WRITE/READ/VERIFY
                WRITE_REQ: begin
                    pipe_addr   <= current_addr; 
                    pipe_wrData <= current_data;
                    pipe_wr     <= 1'b1;
                    state       <= WRITE_WAIT;
                end

                WRITE_WAIT: begin
                    if (pipe_ack) begin
                        if (test_phase == 2'd3) begin
                            poll_return_state <= READ_REQ; 
                            boot_delay        <= 20'd0; 
                            state             <= FLASH_COOL_DOWN;
                        end else begin
                            state <= READ_REQ;
                        end
                    end
                end

                READ_REQ: begin
                    pipe_addr <= current_addr;
                    pipe_rd   <= 1'b1;
                    state     <= READ_WAIT;
                end

                READ_WAIT: begin
                    if (pipe_ack) begin
                        latched_rdData <= pipe_rdData;
                        state          <= VERIFY;
                    end
                end

                VERIFY: begin
                    led   <= current_addr[15:0];
                    if (latched_rdData == current_data) begin
                        if (test_count == (NUM_TESTS - 1)) begin
                            if (test_phase == 2'd1) begin
                                test_phase   <= 2'd2;
                                test_count   <= 32'd0;
                                current_addr <= 32'h6000_0000; 
                                current_data <= 32'hBBBB_0000; 
                                state        <= CHECK_PHASE;
                            end else if (test_phase == 2'd2) begin
                                test_phase   <= 2'd3;
                                test_count   <= 32'd0;
                                current_addr <= 32'h4000_0000; 
                                current_data <= 32'hCCCC_0000; 
                                state        <= CHECK_PHASE;
                            end else begin
                                state        <= SUCCESS_HALT;
                            end
                        end else begin
                            test_count   <= test_count + 1'b1;
                            current_addr <= current_addr + 32'd4;
                            current_data <= current_data + 32'd1;
                            state        <= CHECK_PHASE;
                        end
                    end else begin
                        state <= ERROR_HALT;
                    end
                end

                SUCCESS_HALT: begin
                    ack_led <= 1'b1;
                end

                ERROR_HALT: begin
                    ack_led <= 1'b0;
                end
            endcase
        end
    end

    assign dp = 1'b1; 
    assign an = 8'b11111110; 

    always_comb begin
        case (test_phase)
            2'd1:    seg = 7'b1111001;
            2'd2:    seg = 7'b0100100;
            2'd3:    seg = 7'b0110000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule