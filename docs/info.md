## How it works

A playlist picks parts of a note table, so parts that repeat are kept only one time. A tempo counter times each sixteenth note, and a tone counter divides the 100 kHz clock down to the pitch of the note.

## How to test

Run it with a 100 kHz clock. With all switches off the song plays and loops. Listen to uo[0]. ui[7] high pauses. In the Vulkos board viewer (25.175 MHz clock), turn on ui[6] and listen to uio_out[7].

## External hardware

A small speaker or buzzer on uo[0], or the Tiny Tapeout audio PMOD on uio[7].
