# r0 - Ultra-precise human reaction meter
FPGA Digital Design challenge

## Features
* Sub-µ precision
* 720p @ 60Hz output
* Unboring font
* Pleasant color scheme
* Zero full-frame buffers

Target device: [Sipeed Tang Mega 138K Pro Dock](https://wiki.sipeed.com/hardware/en/tang/tang-mega-138k/mega-138k-pro.html)

## Key concepts
* No deep buffers or FIFOs
* State update and clock domain crossing during the VSync period
* ASCII font and color mapping
* Double-Dabble number format conversion
* UI update FSM

## TODOs
* [ ] Self-compensation \
 Automatically measures and subtracts latency from the result
* [ ] Dark/Light theme switch
* [ ] TRNG instead of PRNG
* [x] Full HD
* [ ] RISC-V core

![img1](https://i.imgur.com/hQxPF07.jpeg)
![img2](https://i.imgur.com/OwlEGOg.jpeg)

### Video demonstration
[![video](https://img.youtube.com/vi/Y8pYJHHqsCo/0.jpg)](https://www.youtube.com/watch?v=Y8pYJHHqsCo)
