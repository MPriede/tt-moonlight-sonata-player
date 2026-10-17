/*
 * Moonlight Sonata player v5: plays the main theme of Beethoven's Moonlight Sonata,
 * 3rd movement (Presto agitato, bars 1 to 20, the top line of the right hand), as a
 * square wave on one pin. Made from the happy birthday chip template.
 *
 * Pattern reuse: the 283 notes of the song are kept as 219 notes in a note table.
 * A short playlist (8 lines) says which part of the table to play next and how
 * many notes. Parts that repeat in the music are kept only one time.
 *
 *   uo_out[0]   audio out (connect a small speaker)
 *   uio_out[7]  the same signal, on the Tiny Tapeout audio PMOD pin
 *   uo_out[7]   high while the song plays
 *
 * All switches off: plays the song at normal speed and loops it.
 *   ui_in[1:0]  speed: 0 normal (score tempo), 1 slow, 2 slower, 3 very slow
 *   ui_in[2]    octave up
 *   ui_in[3]    loop off: stop at the end
 *   ui_in[5:4]  not used
 *   ui_in[6]    viewer mode: on for a 25.175 MHz clock (the Vulkos VGA viewer)
 *   ui_in[7]    pause (high) / play (low). After the end (loop off), on then off starts again.
 *
 * Expects a 100 kHz clock (the Tiny Tapeout clock). With ui_in[6] on, the player
 * divides the clock by 252 first, so it also plays at the right pitch on a
 * 25.175 MHz clock, such as the Vulkos board viewer.
 */

`default_nettype none

module tt_um_mpriede_moonlight_sonata_player (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    localparam LAST_LINE = 3'd7;

    // The switches come from outside the chip, so pass them through two flip-flops.
    reg [7:0] sw_meta, sw;
    always @(posedge clk) begin
        sw_meta <= ui_in;
        sw      <= sw_meta;
    end
    wire [1:0] speed  = sw[1:0];
    wire       octave = sw[2];
    wire       loop   = ~sw[3];   // button 4 on turns loop off
    wire       play   = ~sw[7];   // button 8 on pauses
    wire       viewer = sw[6];    // button 7 on: 25.175 MHz clock

    // ---- the clock enable -----------------------------------------------------
    // With viewer mode off, the player steps on every clock (100 kHz).
    // With viewer mode on, it steps on one clock in 252: 25.175 MHz / 252 = 99.9 kHz.
    reg [7:0] pre;
    always @(posedge clk) begin
        if (!rst_n || !viewer || pre == 8'd251) pre <= 8'd0;
        else                                    pre <= pre + 8'd1;
    end
    wire ce = !viewer || (pre == 8'd251);

    // ---- the playlist ---------------------------------------------------------
    // One line for each part: where it starts in the note table, and how many notes.
    reg [2:0] line;
    reg [7:0] part_start;
    reg [5:0] part_count;
    always @(*) begin
        case (line)
            3'd0: begin part_start = 8'd0; part_count = 6'd63; end
            3'd1: begin part_start = 8'd63; part_count = 6'd63; end
            3'd2: begin part_start = 8'd126; part_count = 6'd20; end
            3'd3: begin part_start = 8'd114; part_count = 6'd35; end
            3'd4: begin part_start = 8'd141; part_count = 6'd13; end
            3'd5: begin part_start = 8'd0; part_count = 6'd24; end
            3'd6: begin part_start = 8'd154; part_count = 6'd63; end
            3'd7: begin part_start = 8'd217; part_count = 6'd2; end
            default: begin part_start = 8'd0; part_count = 6'd1; end
        endcase
    end

    reg  [5:0] in_part;               // which note of the part is playing
    wire [7:0] addr = part_start + {2'b0, in_part};

    // ---- the note table -------------------------------------------------------
    // One line per note: its pitch, then its length in sixteenths minus one.
    reg [5:0] pitch;
    reg [3:0] len_m1;
    always @(*) begin
        case (addr)
            8'd0: begin pitch = 6'd0; len_m1 = 4'd0; end   // GS2
            8'd1: begin pitch = 6'd2; len_m1 = 4'd0; end   // CS3
            8'd2: begin pitch = 6'd4; len_m1 = 4'd0; end   // E3
            8'd3: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd4: begin pitch = 6'd2; len_m1 = 4'd0; end   // CS3
            8'd5: begin pitch = 6'd4; len_m1 = 4'd0; end   // E3
            8'd6: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd7: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd8: begin pitch = 6'd4; len_m1 = 4'd0; end   // E3
            8'd9: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd10: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd11: begin pitch = 6'd14; len_m1 = 4'd0; end   // E4
            8'd12: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd13: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd14: begin pitch = 6'd14; len_m1 = 4'd0; end   // E4
            8'd15: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd16: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd17: begin pitch = 6'd14; len_m1 = 4'd0; end   // E4
            8'd18: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd19: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd20: begin pitch = 6'd14; len_m1 = 4'd0; end   // E4
            8'd21: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd22: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd23: begin pitch = 6'd24; len_m1 = 4'd0; end   // E5
            8'd24: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd25: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd26: begin pitch = 6'd24; len_m1 = 4'd0; end   // E5
            8'd27: begin pitch = 6'd28; len_m1 = 4'd1; end   // GS5
            8'd28: begin pitch = 6'd28; len_m1 = 4'd2; end   // GS5
            8'd29: begin pitch = 6'd0; len_m1 = 4'd0; end   // GS2
            8'd30: begin pitch = 6'd1; len_m1 = 4'd0; end   // C3
            8'd31: begin pitch = 6'd3; len_m1 = 4'd0; end   // DS3
            8'd32: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd33: begin pitch = 6'd1; len_m1 = 4'd0; end   // C3
            8'd34: begin pitch = 6'd3; len_m1 = 4'd0; end   // DS3
            8'd35: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd36: begin pitch = 6'd11; len_m1 = 4'd0; end   // C4
            8'd37: begin pitch = 6'd3; len_m1 = 4'd0; end   // DS3
            8'd38: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd39: begin pitch = 6'd11; len_m1 = 4'd0; end   // C4
            8'd40: begin pitch = 6'd13; len_m1 = 4'd0; end   // DS4
            8'd41: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd42: begin pitch = 6'd11; len_m1 = 4'd0; end   // C4
            8'd43: begin pitch = 6'd13; len_m1 = 4'd0; end   // DS4
            8'd44: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd45: begin pitch = 6'd11; len_m1 = 4'd0; end   // C4
            8'd46: begin pitch = 6'd13; len_m1 = 4'd0; end   // DS4
            8'd47: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd48: begin pitch = 6'd21; len_m1 = 4'd0; end   // C5
            8'd49: begin pitch = 6'd13; len_m1 = 4'd0; end   // DS4
            8'd50: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd51: begin pitch = 6'd21; len_m1 = 4'd0; end   // C5
            8'd52: begin pitch = 6'd23; len_m1 = 4'd0; end   // DS5
            8'd53: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd54: begin pitch = 6'd21; len_m1 = 4'd0; end   // C5
            8'd55: begin pitch = 6'd23; len_m1 = 4'd0; end   // DS5
            8'd56: begin pitch = 6'd28; len_m1 = 4'd1; end   // GS5
            8'd57: begin pitch = 6'd28; len_m1 = 4'd2; end   // GS5
            8'd58: begin pitch = 6'd2; len_m1 = 4'd0; end   // CS3
            8'd59: begin pitch = 6'd5; len_m1 = 4'd0; end   // F3
            8'd60: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd61: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd62: begin pitch = 6'd5; len_m1 = 4'd0; end   // F3
            8'd63: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd64: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd65: begin pitch = 6'd15; len_m1 = 4'd0; end   // F4
            8'd66: begin pitch = 6'd8; len_m1 = 4'd0; end   // GS3
            8'd67: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd68: begin pitch = 6'd15; len_m1 = 4'd0; end   // F4
            8'd69: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd70: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd71: begin pitch = 6'd15; len_m1 = 4'd0; end   // F4
            8'd72: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd73: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd74: begin pitch = 6'd15; len_m1 = 4'd0; end   // F4
            8'd75: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd76: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd77: begin pitch = 6'd25; len_m1 = 4'd0; end   // F5
            8'd78: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd79: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd80: begin pitch = 6'd25; len_m1 = 4'd0; end   // F5
            8'd81: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd82: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd83: begin pitch = 6'd25; len_m1 = 4'd0; end   // F5
            8'd84: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd85: begin pitch = 6'd32; len_m1 = 4'd1; end   // CS6
            8'd86: begin pitch = 6'd32; len_m1 = 4'd2; end   // CS6
            8'd87: begin pitch = 6'd2; len_m1 = 4'd0; end   // CS3
            8'd88: begin pitch = 6'd6; len_m1 = 4'd0; end   // FS3
            8'd89: begin pitch = 6'd9; len_m1 = 4'd0; end   // A3
            8'd90: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd91: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd92: begin pitch = 6'd16; len_m1 = 4'd0; end   // FS4
            8'd93: begin pitch = 6'd19; len_m1 = 4'd0; end   // A4
            8'd94: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd95: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd96: begin pitch = 6'd26; len_m1 = 4'd0; end   // FS5
            8'd97: begin pitch = 6'd29; len_m1 = 4'd0; end   // A5
            8'd98: begin pitch = 6'd32; len_m1 = 4'd1; end   // CS6
            8'd99: begin pitch = 6'd32; len_m1 = 4'd2; end   // CS6
            8'd100: begin pitch = 6'd2; len_m1 = 4'd0; end   // CS3
            8'd101: begin pitch = 6'd4; len_m1 = 4'd0; end   // E3
            8'd102: begin pitch = 6'd7; len_m1 = 4'd0; end   // G3
            8'd103: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd104: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd105: begin pitch = 6'd14; len_m1 = 4'd0; end   // E4
            8'd106: begin pitch = 6'd17; len_m1 = 4'd0; end   // G4
            8'd107: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd108: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd109: begin pitch = 6'd24; len_m1 = 4'd0; end   // E5
            8'd110: begin pitch = 6'd27; len_m1 = 4'd0; end   // G5
            8'd111: begin pitch = 6'd32; len_m1 = 4'd1; end   // CS6
            8'd112: begin pitch = 6'd32; len_m1 = 4'd1; end   // CS6
            8'd113: begin pitch = 6'd31; len_m1 = 4'd1; end   // C6
            8'd114: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd115: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd116: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd117: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd118: begin pitch = 6'd20; len_m1 = 4'd0; end   // AS4
            8'd119: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd120: begin pitch = 6'd21; len_m1 = 4'd0; end   // C5
            8'd121: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd122: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd123: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd124: begin pitch = 6'd23; len_m1 = 4'd0; end   // DS5
            8'd125: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd126: begin pitch = 6'd21; len_m1 = 4'd0; end   // C5
            8'd127: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd128: begin pitch = 6'd23; len_m1 = 4'd0; end   // DS5
            8'd129: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd130: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd131: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd132: begin pitch = 6'd26; len_m1 = 4'd0; end   // FS5
            8'd133: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd134: begin pitch = 6'd24; len_m1 = 4'd0; end   // E5
            8'd135: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd136: begin pitch = 6'd23; len_m1 = 4'd0; end   // DS5
            8'd137: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd138: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd139: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd140: begin pitch = 6'd21; len_m1 = 4'd0; end   // C5
            8'd141: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd142: begin pitch = 6'd19; len_m1 = 4'd0; end   // A4
            8'd143: begin pitch = 6'd27; len_m1 = 4'd0; end   // G5
            8'd144: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd145: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd146: begin pitch = 6'd19; len_m1 = 4'd0; end   // A4
            8'd147: begin pitch = 6'd27; len_m1 = 4'd0; end   // G5
            8'd148: begin pitch = 6'd18; len_m1 = 4'd0; end   // GS4
            8'd149: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd150: begin pitch = 6'd19; len_m1 = 4'd0; end   // A4
            8'd151: begin pitch = 6'd27; len_m1 = 4'd0; end   // G5
            8'd152: begin pitch = 6'd28; len_m1 = 4'd3; end   // GS5
            8'd153: begin pitch = 6'd8; len_m1 = 4'd12; end   // GS3
            8'd154: begin pitch = 6'd24; len_m1 = 4'd0; end   // E5
            8'd155: begin pitch = 6'd28; len_m1 = 4'd0; end   // GS5
            8'd156: begin pitch = 6'd32; len_m1 = 4'd0; end   // CS6
            8'd157: begin pitch = 6'd33; len_m1 = 4'd1; end   // E6
            8'd158: begin pitch = 6'd33; len_m1 = 4'd2; end   // E6
            8'd159: begin pitch = 6'd4; len_m1 = 4'd0; end   // E3
            8'd160: begin pitch = 6'd7; len_m1 = 4'd0; end   // G3
            8'd161: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd162: begin pitch = 6'd14; len_m1 = 4'd0; end   // E4
            8'd163: begin pitch = 6'd7; len_m1 = 4'd0; end   // G3
            8'd164: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd165: begin pitch = 6'd14; len_m1 = 4'd0; end   // E4
            8'd166: begin pitch = 6'd17; len_m1 = 4'd0; end   // G4
            8'd167: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd168: begin pitch = 6'd14; len_m1 = 4'd0; end   // E4
            8'd169: begin pitch = 6'd17; len_m1 = 4'd0; end   // G4
            8'd170: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd171: begin pitch = 6'd14; len_m1 = 4'd0; end   // E4
            8'd172: begin pitch = 6'd17; len_m1 = 4'd0; end   // G4
            8'd173: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd174: begin pitch = 6'd24; len_m1 = 4'd0; end   // E5
            8'd175: begin pitch = 6'd17; len_m1 = 4'd0; end   // G4
            8'd176: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd177: begin pitch = 6'd24; len_m1 = 4'd0; end   // E5
            8'd178: begin pitch = 6'd27; len_m1 = 4'd0; end   // G5
            8'd179: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd180: begin pitch = 6'd24; len_m1 = 4'd0; end   // E5
            8'd181: begin pitch = 6'd27; len_m1 = 4'd0; end   // G5
            8'd182: begin pitch = 6'd32; len_m1 = 4'd0; end   // CS6
            8'd183: begin pitch = 6'd24; len_m1 = 4'd0; end   // E5
            8'd184: begin pitch = 6'd27; len_m1 = 4'd0; end   // G5
            8'd185: begin pitch = 6'd32; len_m1 = 4'd0; end   // CS6
            8'd186: begin pitch = 6'd33; len_m1 = 4'd1; end   // E6
            8'd187: begin pitch = 6'd33; len_m1 = 4'd2; end   // E6
            8'd188: begin pitch = 6'd3; len_m1 = 4'd0; end   // DS3
            8'd189: begin pitch = 6'd10; len_m1 = 4'd0; end   // AS3
            8'd190: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd191: begin pitch = 6'd13; len_m1 = 4'd0; end   // DS4
            8'd192: begin pitch = 6'd10; len_m1 = 4'd0; end   // AS3
            8'd193: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd194: begin pitch = 6'd13; len_m1 = 4'd0; end   // DS4
            8'd195: begin pitch = 6'd20; len_m1 = 4'd0; end   // AS4
            8'd196: begin pitch = 6'd12; len_m1 = 4'd0; end   // CS4
            8'd197: begin pitch = 6'd13; len_m1 = 4'd0; end   // DS4
            8'd198: begin pitch = 6'd20; len_m1 = 4'd0; end   // AS4
            8'd199: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd200: begin pitch = 6'd13; len_m1 = 4'd0; end   // DS4
            8'd201: begin pitch = 6'd20; len_m1 = 4'd0; end   // AS4
            8'd202: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd203: begin pitch = 6'd23; len_m1 = 4'd0; end   // DS5
            8'd204: begin pitch = 6'd20; len_m1 = 4'd0; end   // AS4
            8'd205: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd206: begin pitch = 6'd23; len_m1 = 4'd0; end   // DS5
            8'd207: begin pitch = 6'd30; len_m1 = 4'd0; end   // AS5
            8'd208: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd209: begin pitch = 6'd23; len_m1 = 4'd0; end   // DS5
            8'd210: begin pitch = 6'd30; len_m1 = 4'd0; end   // AS5
            8'd211: begin pitch = 6'd32; len_m1 = 4'd0; end   // CS6
            8'd212: begin pitch = 6'd30; len_m1 = 4'd0; end   // AS5
            8'd213: begin pitch = 6'd23; len_m1 = 4'd0; end   // DS5
            8'd214: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd215: begin pitch = 6'd30; len_m1 = 4'd0; end   // AS5
            8'd216: begin pitch = 6'd23; len_m1 = 4'd0; end   // DS5
            8'd217: begin pitch = 6'd22; len_m1 = 4'd0; end   // CS5
            8'd218: begin pitch = 6'd20; len_m1 = 4'd0; end   // AS4
            default: begin pitch = 6'd0; len_m1 = 4'd0; end
        endcase
    end

    // ---- the pitch table ------------------------------------------------------
    // Clock ticks in half a cycle of each note: 100,000 / (2 x frequency), rounded.
    reg [8:0] half_period;
    always @(*) begin
        case (pitch)
            6'd0: half_period = 9'd482;   // GS2, 104 Hz
            6'd1: half_period = 9'd382;   // C3, 131 Hz
            6'd2: half_period = 9'd361;   // CS3, 139 Hz
            6'd3: half_period = 9'd321;   // DS3, 156 Hz
            6'd4: half_period = 9'd303;   // E3, 165 Hz
            6'd5: half_period = 9'd286;   // F3, 175 Hz
            6'd6: half_period = 9'd270;   // FS3, 185 Hz
            6'd7: half_period = 9'd255;   // G3, 196 Hz
            6'd8: half_period = 9'd241;   // GS3, 208 Hz
            6'd9: half_period = 9'd227;   // A3, 220 Hz
            6'd10: half_period = 9'd215;   // AS3, 233 Hz
            6'd11: half_period = 9'd191;   // C4, 262 Hz
            6'd12: half_period = 9'd180;   // CS4, 277 Hz
            6'd13: half_period = 9'd161;   // DS4, 311 Hz
            6'd14: half_period = 9'd152;   // E4, 330 Hz
            6'd15: half_period = 9'd143;   // F4, 349 Hz
            6'd16: half_period = 9'd135;   // FS4, 370 Hz
            6'd17: half_period = 9'd128;   // G4, 392 Hz
            6'd18: half_period = 9'd120;   // GS4, 415 Hz
            6'd19: half_period = 9'd114;   // A4, 440 Hz
            6'd20: half_period = 9'd107;   // AS4, 466 Hz
            6'd21: half_period = 9'd96;   // C5, 523 Hz
            6'd22: half_period = 9'd90;   // CS5, 554 Hz
            6'd23: half_period = 9'd80;   // DS5, 622 Hz
            6'd24: half_period = 9'd76;   // E5, 659 Hz
            6'd25: half_period = 9'd72;   // F5, 698 Hz
            6'd26: half_period = 9'd68;   // FS5, 740 Hz
            6'd27: half_period = 9'd64;   // G5, 784 Hz
            6'd28: half_period = 9'd60;   // GS5, 831 Hz
            6'd29: half_period = 9'd57;   // A5, 880 Hz
            6'd30: half_period = 9'd54;   // AS5, 932 Hz
            6'd31: half_period = 9'd48;   // C6, 1047 Hz
            6'd32: half_period = 9'd45;   // CS6, 1109 Hz
            6'd33: half_period = 9'd38;   // E6, 1319 Hz
            default: half_period = 9'd482;
        endcase
    end
    wire [8:0] half = octave ? {1'b0, half_period[8:1]} : half_period;

    // ---- the tempo ------------------------------------------------------------
    // Clock ticks in one sixteenth note. The score asks for 154 beats a minute.
    reg [15:0] six_ticks;
    always @(*) begin
        case (speed)
            2'd0: six_ticks = 16'd9740;     // normal, score tempo
            2'd1: six_ticks = 16'd14610;    // slow
            2'd2: six_ticks = 16'd19480;    // slower, half speed
            default: six_ticks = 16'd29220; // very slow, one third speed
        endcase
    end

    reg [15:0] tick;
    reg [3:0]  step;      // which sixteenth of the note
    reg        active;    // low after the last note when loop is off
    reg        play_last;
    reg [8:0]  pos;       // note number in the song, for tests
    wire six_done  = (tick >= six_ticks - 16'd1);
    wire note_done = six_done && (step == len_m1);
    wire part_done = (in_part == part_count - 6'd1);

    // After the song ends (loop off), switching ui[7] on and off again starts it
    // again from the first note.
    always @(posedge clk) begin
        if (!rst_n) begin
            tick <= 16'd0; step <= 4'd0; in_part <= 6'd0; line <= 3'd0;
            pos <= 9'd0; active <= 1'b1; play_last <= 1'b0;
        end else if (ce) begin
            play_last <= play;
            if (!active && play && !play_last) begin
                tick <= 16'd0; step <= 4'd0; in_part <= 6'd0; line <= 3'd0;
                pos <= 9'd0; active <= 1'b1;
            end else if (play && active) begin
                if (!six_done) begin
                    tick <= tick + 16'd1;
                end else begin
                    tick <= 16'd0;
                    if (!note_done) begin
                        step <= step + 4'd1;
                    end else begin
                        step <= 4'd0;
                        if (!part_done) begin
                            in_part <= in_part + 6'd1;
                            pos     <= pos + 9'd1;
                        end else begin
                            in_part <= 6'd0;
                            if (line == LAST_LINE) begin
                                line   <= 3'd0;
                                pos    <= 9'd0;
                                active <= loop;
                            end else begin
                                line <= line + 3'd1;
                                pos  <= pos + 9'd1;
                            end
                        end
                    end
                end
            end
        end
    end

    // A short silence in the last quarter of the last sixteenth of every note,
    // so each note is heard as its own note.
    wire gap = (step == len_m1) && (tick >= six_ticks - (six_ticks >> 2));

    // ---- the tone -------------------------------------------------------------
    // Counts up to half a cycle, then flips the output. That makes a square wave.
    reg [8:0] tone_count;
    reg       audio;
    always @(posedge clk) begin
        if (!rst_n || (ce && note_done)) begin
            tone_count <= 9'd0;
            audio      <= 1'b0;
        end else if (!ce) begin
            // wait for the next step
        end else if (tone_count >= half - 9'd1) begin
            tone_count <= 9'd0;
            audio      <= ~audio;
        end else begin
            tone_count <= tone_count + 9'd1;
        end
    end

    wire playing = play & active;
    // A flip-flop on the speaker, so the pin has no short pulses.
    reg speaker;
    always @(posedge clk) begin
        if (!rst_n) speaker <= 1'b0;
        else        speaker <= audio & ~gap & playing;
    end

    assign uo_out  = {playing, 6'b0, speaker};
    assign uio_out = {speaker, 7'b0};
    assign uio_oe  = 8'h80;

    wire _unused_ok = &{ena, sw[5:4], uio_in};

endmodule
