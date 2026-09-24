*----------------------------------------------
* Parameters and models
*----------------------------------------------

.lib "../cic018.l" TT
.option scale=90n
.temp 70
.option post

*----------------------------------------------
* Simulation netlist
*----------------------------------------------

Vdd vdd gnd 1.8
Vin1 A gnd pulse(0 1 0 50ps 50ps 150ps 400ps)
Vin2 B gnd pulse(0 1 100ps 50ps 50ps 150ps 400ps)
M1 c A gnd gnd N_18 W=8 L=2
+ AS=40 PS=26 AD=40 PD=26
M2 y B c gnd N_18 W=8 L=2
+ AS=40 PS=26 AD=40 PD=26
M3 y A vdd vdd P_18 W=8 L=2
+ AS=40 PS=26 AD=40 PD=26
M4 y B vdd vdd P_18 W=8 L=2
+ AS=40 PS=26 AD=40 PD=26

*----------------------------------------------
* Stimulus
*----------------------------------------------

.tran 1ps 800ps
.end