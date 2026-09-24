*----------------------------------------------
* Parameters and models
*----------------------------------------------

.lib "../cic018.l" TT
.option scale=90n
.temp 70
.option post

*----------------------------------------------
* Subcircuit
*----------------------------------------------

.global gnd vdd
.subckt nand A B y
    M1 c A gnd gnd N_18 W=8 L=2
    + AS=40 PS=26 AD=40 PD=26
    M2 y B c gnd N_18 W=8 L=2
    + AS=40 PS=26 AD=40 PD=26
    M3 y A vdd vdd P_18 W=8 L=2
    + AS=40 PS=26 AD=40 PD=26
    M4 y B vdd vdd P_18 W=8 L=2
    + AS=40 PS=26 AD=40 PD=26
.ends

*----------------------------------------------
* Simulation netlist
*----------------------------------------------

Vdd vdd gnd 1.8
X0 vdd in out1 nand
X1 vdd out1 out2 nand
X2 vdd out2 out3 nand
X3 vdd out3 out4 nand
X4 vdd out4 in nand

*----------------------------------------------
* Stimulus
*----------------------------------------------

.ic V(in)=0
.tran 10ps 5000ps
.end