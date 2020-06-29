# Digital_Clock
Digital clock design is a result of a Final-Year Project at <b>SŠIEŘ Rožnov pod Radhoštěm </b> (Czech Republic) as part of <b>Maturita Exam</b>. LK design including hardware, circuit boards and software written in assembly language is available within this repository. 

This Repository contains final schemes of circuit boards, list of components and schemes. Detail documentation available in Czech Language. 

# About the Project
<b>Hardware</b><br>
A custom architecture based on Intel Microcontroler <b>i8051/MCS-51</b> *(8-bit, 128B RAM, 4x 8-bit paraler ports, 24MHz)*. Seven-segment displays are controlled by additional drivers and their intensity is adjustable by 
a Potentiometer on the back panel. Chassis was custom made by SSI Schäfer, s.r.o. <br>
All Cirucit Boards are one sided print: <br>
LK01-16 is the board of seven-segment dispalys. <br>
LK02-16 is the main board embeding microcontroller i8051 and Epson made real-time chip <b>RTC72421</b><br>
LK03-16 contains switches for time setting and Potentiometer for adjusting brigthness of the dispaly.

<b>Software</b>
Software is developed in Assembly language for Intel microcontrolers series i8051/MSC-51. 
Insturction set and manual are available at: <a href='http://web.mit.edu/6.115/www/document/8051.pdf'> http://web.mit.edu/6.115/www/document/8051.pdf </a>
