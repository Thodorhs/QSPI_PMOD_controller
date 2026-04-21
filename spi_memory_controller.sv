`timescale 1ns / 1ps

module spi_memory_controller (
    input  logic        clk,     
    input  logic        rst,

    input  logic [31:0] pipecon_address,
    input  logic        pipecon_rd,
    input  logic        pipecon_wr,
    input  logic [31:0] pipecon_wrData,
    input  logic [3:0]  pipecon_wrMask,
    output logic [31:0] pipecon_rdData,
    output logic        pipecon_ack,

    output logic        spi_sck,
    output logic        spi_mosi,
    input  logic        spi_miso,
    output logic        spi_cs0_n, // Flash
    output logic        spi_cs1_n, // PSRAM A
    output logic        spi_cs2_n  // PSRAM B
);

    
    parameter DIVIDER_RATIO = 8; 
    logic [7:0] clk_div; 

    typedef enum logic[2:0] {
        IDLE,
        DO_TRANSFER,
        CS_TOGGLE,
        DONE
    } state_t;

    state_t state, next_state;

    // EXPANDED to 72 bits to accommodate the 8 Dummy Cycles for Fast Read
    logic [71:0] shift_reg;
    logic [31:0] read_data;
    logic [6:0]  bits_to_transfer; 
    logic        phase;

    logic [23:0] addr_reg;
    logic [31:0] data_reg;
    
    logic is_flash_erase, is_flash_unlock;
    logic [7:0] cmd;

    always_ff @(posedge clk) begin
        if (rst) begin
            state          <= IDLE;
            spi_sck        <= 1'b0;
            spi_mosi       <= 1'b0;
            spi_cs0_n      <= 1'b1;
            spi_cs1_n      <= 1'b1;
            spi_cs2_n      <= 1'b1;
            pipecon_ack    <= 1'b0;
            pipecon_rdData <= 32'b0;
            clk_div        <= '0;
            phase          <= 1'b0;
        end else begin
            pipecon_ack <= 1'b0;

            case (state)
                IDLE: begin
                    spi_cs0_n <= 1'b1;
                    spi_cs1_n <= 1'b1;
                    spi_cs2_n <= 1'b1;
                    spi_sck   <= 1'b0;
                    clk_div   <= '0;
                    phase     <= 1'b0;

                    if (pipecon_rd || pipecon_wr) begin
                        addr_reg  <= pipecon_address[23:0];
                        data_reg  <= pipecon_wrData;
                        read_data <= 32'b0; 
                        
                        is_flash_erase  <= (pipecon_address[31:24] == 8'h41);
                        is_flash_unlock <= (pipecon_address[31:24] == 8'h43);

                        if (pipecon_address[31:28] == 4'h4) spi_cs0_n <= 1'b0;
                        if (pipecon_address[31:28] == 4'h5) spi_cs1_n <= 1'b0;
                        if (pipecon_address[31:28] == 4'h6) spi_cs2_n <= 1'b0;

                        // ================
                        // COMMAND ROUTING 
                        // ================
                        if (pipecon_wr && (pipecon_address[31:24] == 8'h40 || pipecon_address[31:24] == 8'h41 || pipecon_address[31:24] == 8'h43)) begin
                            // WREN (0x06)
                            spi_mosi         <= 1'b0; 
                            shift_reg        <= {7'b0000110, 65'b0}; // 7 + 65 = 72 bits
                            bits_to_transfer <= 7'd8;
                            next_state       <= CS_TOGGLE;
                            
                        end else if (pipecon_rd && pipecon_address[31:24] == 8'h42) begin
                            // Read Status (0x05)
                            spi_mosi         <= 1'b0; 
                            shift_reg        <= {7'b0000101, 65'b0}; // 7 + 65 = 72 bits
                            bits_to_transfer <= 7'd16; 
                            next_state       <= DONE;
                            
                        end else if (pipecon_rd) begin
                            // FAST READ (0x0B) -> 8 cmd + 24 addr + 8 dummy + 32 data = 72 bits
                            cmd = 8'h0B;
                            spi_mosi         <= cmd[7];
                            // Pad with 8 dummy zeros, then 33 zeros to fill out 72 bits
                            shift_reg        <= {cmd[6:0], pipecon_address[23:0], 8'h00, 33'b0}; 
                            bits_to_transfer <= 7'd72;
                            next_state       <= DONE;
                            
                        end else begin
                            // PAGE PROGRAM (0x02) -> 8 cmd + 24 addr + 32 data = 64 bits
                            cmd = 8'h02;
                            spi_mosi         <= cmd[7]; 
                            shift_reg        <= {cmd[6:0], pipecon_address[23:0], pipecon_wrData, 9'b0}; // 7+24+32+9=72
                            bits_to_transfer <= 7'd64;
                            next_state       <= DONE;
                        end

                        state <= DO_TRANSFER;
                    end
                end

                DO_TRANSFER: begin
                    if (clk_div == (DIVIDER_RATIO / 2 - 1)) begin
                        clk_div <= '0;
                        
                        if (phase == 0) begin
                            // Rising Edge -> Sample MISO
                            spi_sck <= 1'b1;
                            if (bits_to_transfer <= 32) begin
                                read_data <= {read_data[30:0], spi_miso};
                            end
                            phase <= 1'b1;
                        end else begin
                            // Falling Edge -> Shift MOSI
                            spi_sck <= 1'b0;
                            if (bits_to_transfer == 1) begin
                                state <= next_state;
                            end else begin
                                spi_mosi         <= shift_reg[71];
                                shift_reg        <= {shift_reg[70:0], 1'b0};
                                bits_to_transfer <= bits_to_transfer - 1;
                                phase            <= 1'b0;
                            end
                        end
                    end else begin
                        clk_div <= clk_div + 1;
                    end
                end

                CS_TOGGLE: begin
                    spi_cs0_n <= 1'b1; 
                    if (clk_div == 8'd20) begin 
                        spi_cs0_n <= 1'b0; 
                        
                        if (is_flash_erase) begin
                            // SECTOR ERASE (0x20)
                            spi_mosi         <= 1'b0; 
                            shift_reg        <= {7'b0100000, addr_reg, 41'b0}; // 7 + 24 + 41 = 72 bits
                            bits_to_transfer <= 7'd32;
                        end else if (is_flash_unlock) begin
                            // WRITE STATUS REGISTER (0x01)
                            spi_mosi         <= 1'b0; 
                            shift_reg        <= {7'b0000001, data_reg[7:0], 57'b0}; // 7 + 8 + 57 = 72 bits
                            bits_to_transfer <= 7'd16;
                        end else begin
                            // PAGE PROGRAM (0x02)
                            spi_mosi         <= 1'b0; 
                            shift_reg        <= {7'b0000010, addr_reg, data_reg, 9'b0}; // 7 + 24 + 32 + 9 = 72
                            bits_to_transfer <= 7'd64;
                        end
                        
                        next_state <= DONE;
                        clk_div    <= '0;
                        phase      <= 1'b0;
                        state      <= DO_TRANSFER;
                    end else begin
                        clk_div <= clk_div + 1;
                    end
                end

                DONE: begin
                    spi_cs0_n   <= 1'b1;
                    spi_cs1_n   <= 1'b1;
                    spi_cs2_n   <= 1'b1;
                    spi_sck     <= 1'b0;
                    pipecon_rdData <= read_data; 
                    pipecon_ack    <= 1'b1;
                    state          <= IDLE;
                end
            endcase
        end
    end
endmodule