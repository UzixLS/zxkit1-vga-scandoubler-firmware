##  Alternate firmware for ZXKIT1 VGA scandoubler for ZX Spectrum

PCB: https://github.com/romychs/RGB2VGA

* Low delay (one line)
* Automatically adjust to input timings
* Automatically detect input VSYNC(KSI), HSYNC(SSI) polarity. Supported schemes: V+ H+ and V- H-
* Support for CSYNC (composite sync) input (should be connected to SSI input, KSI should be pulled hight)

Jumpers:
* INVERSE_RGBI - changes polarity of *input* RGBI signals
* INVERSE_KSI - changes polarity of *output* VSYNC signal
* INVERSE_SSI - changes polarity of *output* HSYNC signal
* INVERSE_F14MHZ - changes edge of clock to latch input RGBI signal
* VGA_SCART - no effect
* SET_FK_IN - no effect
* SET_FK_OUT - no effect
