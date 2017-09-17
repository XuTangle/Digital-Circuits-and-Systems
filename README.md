# Digital-Circuits-and-Systems

- Environment: Altera DE2 Board housing a Cyclone II FPGA chip and a multitude of peripheral components
- IDE: Altera Quartus-II FPGA Design Software

## Arithmetic Logic Unit
- Built a VHDL circuit to choose between various calculations and logical operations.
- This is basically a calculator which can perform multiple operations with no memory, i.e. the circuit is
completely combinational.

## 7-segment Display 
- A 7-segment decoder takes an input, typically a 4 bit binary number, and correctly drives a 7-segment
LED display so that a person can see a number or letter as opposed to trying to interpret the original 4 bit
binary number.

## Traffic Light Controller
- Designed a traffic light control system as a sequential circuit with clock. 
- The system controls two traffic lights on an intersection using a state machine.

## Advanced Traffic Light Controller
- Built on top of Traffic Light Controller project (Day Mode).
- Add a ‘Night mode’ to the system that somehow gives priority to one direction (North-South or EastWest).
- In the night mode the traffic light controller has a default (priority) side (SW [16]) that traffic light is
always green for it if there is no car on the other side. When the time to switch lights (amber to red)
reaches (at the end of amber light period), if no car is detected on the non-default side, the system starts
another green-amber (only solid green) period for the default side, otherwise it acts like day mode with
green-amber-red periods for both sides.


