;Program pro ètení èasového údaje z obvodu RTC 72421
;Aktuální verze


ORG	0000H
	JMP START

ORG	0003H		;vektor pøerušení INT0
	JMP CTENI

;Registry pro nastavení periody zobrazování datumu a doby
;trvání zobrazení datumu. Pouívá je podprogram PREP.

DOBA_D	EQU	5BH	;registr pro úschovu hodnoty DOBA
PER_D	EQU	5AH	;registr pro úschovu hodnoty PER
DOBA	EQU	59H	;doba trvání zobrazení datumu
PER	EQU	58H	;perioda zobrazování datumu

;Registry pro doèasné uloení údajù o datumu a èasu.
;Registry jsou plnìny programem CTENI, co je obsluná
;rutina externího pøerušení INT0. Aktualizace dat je
;provádìna 1x za sekundu (INT generuje RTC)

H10	EQU	57H	;naètené desítky hodin
H1	EQU	56H	;naètené jednotky hodin
MI10	EQU	55H	;naètené desítky minut
MI1	EQU	54H	;naètené jednotky minut
S10	EQU	53H	;naètené desítky sekund
S1	EQU	52H	;naètené jednotky sekund
DEN_W	EQU	51H	;naètené èíslo dne v tıdnu
ROK10	EQU	50H	;naètené desítky rokù
ROK1	EQU	4FH	;naètené jednotky rokù
MES10	EQU	4EH	;naètené desítky mìsícù
MES1	EQU	4DH	;naètené jednotky mìsícù
DEN10	EQU	4CH	;naètené desítky dnù
DEN1	EQU	4BH	;naètené jednotky dnù

;Definice registrù pro ruèní nastavování aktuálního èasu
;Pouívají se jako poèitadla, která jsou poté pøevedena
;pomocí podprogramù BCD_XXX do kódu BCD a uloena do
;odpovídajících registrù

DEN	EQU	4AH	;registr èísla dne v tıdnu (0 = nedìle)
ROKY	EQU	49H	;registr rokù
MESICE	EQU	48H	;registr mìsícù
DNY	EQU	47H	;registr dnù
HOD	EQU	46H	;registr hodin
MIN	EQU	45H	;regist minut
SEK	EQU	44H	;registr sekund

;Definice registrù pro nastavení èasovıch údajù v RTC
;Údaje v tìchto registrech jsou povaovány za platná data
;a pomocí podprogramu ZAPIS jsou zapsána do registrù RTC,
;kterı je následnì odblokován a èasomíra se rozebìhne.

W_NEW	EQU	43H	;novı den v tıdnu (0 je nedìle)
Y10_NEW	EQU	42H	;nové desítky let (0 a 9)
Y1_NEW	EQU	41H	;nové jednotky let (0 a 9)
M10_NEW	EQU	40H	;nové desítky mìsícù (0 nebo 1)
M1_NEW	EQU	3FH	;nové jednotky mìsícù (0 a 9)
D10_NEW	EQU	3EH	;nové desítky dnù (0 a 3)
D1_NEW	EQU	3DH	;nové jednotky dnù (0 a 9)
H10_NEW	EQU	3CH	;nové desítky hodin (0 a 2)
H1_NEW	EQU	3BH	;nové jednotky hodin (0 a 9)
MI10_NEW EQU	3AH	;nové desítky minut (0 a 5)
MI1_NEW	EQU	39H	;nové jednotky minut (0 a 9)
S10_NEW	EQU	38H	;nové desítky sekund (0 a 5)
S1_NEW	EQU	37H	;nové jednotky sekund (0 a 9)


;videoRAM

;Definice registrù aktuálních èasovıch údajù
;Èas je zobrazován na 7mi místném displeji ve formátu WHHMMSS
;Pracuje se s 24 hodinovım cyklem

SEK_JED	EQU	36H	;jedná se o adresy 7mi segmentovek
SEK_DES	EQU	35H
MIN_JED	EQU	34H
MIN_DES	EQU	33H
HOD_JED	EQU	32H
HOD_DES	EQU	31H
DEN_TYD	EQU	30H

;Definice portu a bitù

I_O	EQU	P2	;port ovládající RTC
BUSY	BIT	P2.5	;naètenı bit BUSY
RDG	BIT	P3.0	;ètení RTC (aktivní v L)
WRT	BIT	P3.1	;zápis do RTC (aktivní v L)
RESET	BIT	P0.0	;tlaèítko RESET
NAS_HOD	BIT	P0.1	;tlaèítko pro nastavení hodin, resp. dnù
NAS_MIN	BIT	P0.2	;tlaèítko pro nastavení minut, resp. mìsícù
NAS_SEK	BIT	P0.3	;tlaèítko pro nastavení sekund, resp. rokù
DAT_TIM	BIT	P0.5	;spínaè pro funkci automatického zobrazování datumu
TIM_DAT	BIT	P0.6	;tlaèítko pro pøepínání reimu zobrazení èas/datum
SETING	BIT	P0.4	;tlaèítko SET pro aktualizaci èasovıch údajù
ADJUST	BIT	7EH	;pomocnı bit (vlajka) pro umìlé vyvolání RESET
DATUM	BIT	7DH	;pomocnı bit (vlajka) pro nastavení aktuálního datumu a dne v tıdnu
TIME	BIT	7CH	;pomocnı bit urèující (vlajka), zda se zobrazuje èas nebo datum
ERROR	BIT	7BH	;pomocnı bit (vlajka) indikující chybu pøi kontrole dat v registrech RTC
LE1	BIT	P1.5	;bity LE (Latch Enable) poskytují zápísové pulzy pro
LE2	BIT	P1.6	;dekodéry sedmisegmentovek (aktivní je sestupná hrana)
LE3	BIT	P1.7
LE4	BIT	P3.3
LE5	BIT	P3.4
LE6	BIT	P3.5
LE7	BIT	P3.6
BLANK	BIT	P1.4	;bit BLANK umoòuje zhasnutí celého displeje (aktivní v L)
TEST	BIT	P3.7	;bit TEST umoòuje zobrazit na všech pozicích displeje 8 (aktivní v L)
DT	BIT	P0.7	;bit DT umoòuje zobrazit desetinné teèky na SEG2 a SEG4 (aktivní v L)


START:	CLR EA
	CLR BLANK
	CALL DELAY
	CALL DELAY
	CALL DELAY
	JNB RESET,TES3	;servisní nastavení
	JNB SETING,TEST2;podrením tlaèítka se po RST spustí tréninková sekvence pro displej
	jmp st109
TEST3:	CLR BLANK	;zatemnìní displeje
	MOV R0,#10
TEST4:	CLR TEST	;test displeje po zapnutí hodin
	CLR DT
	CALL DELAY
	CALL DELAY
	CALL DELAY
	SETB TEST
	SETB DT
	CALL DELAY
	CALL DELAY
	CALL DELAY
	DJNZ R0,TEST4
	CLR BLANK	;aktivace displeje
	JMP ST109
TEST2:	CALL TESTUJ	;tréninková sekvence pro displej
	JMP TEST3


;-------------------------------------------------------------------------
;zde program pokraèuje po pøipojení napájení
ST109:	SETB ADJUST	;hodiny bìí
	SETB TIME	;bit urèuje, zda se zobrazuje èas nebo datum
	CLR DATUM	;datum bylo nastaveno
	CALL PER_DOB	;implicitní hodnoty periody a doby zobrazení datumu
	SETB EX0	;povolení externího pøerušení EX0 (viz registr IE), pin P3.2
	SETB IT0	;pøerušení bude spouštìno saestupnou hranou (viz TCON)
	SETB EA		;povolení všech pøerušení
	JMP N4		;skok pøímo na na test tlaèítek

;-------------------------------------------------------------------------------------
;Zde program pokraèuje po resetu hodin (podrení RESET pøed pøipojením napájení)
;Nastavení pøerušovacího systému 8051 a pomocnıch registrù

TES3:	JNB RESET,$	;pozdrení bìhu pøi drení tlaèítka RESET
	CALL DELAY	;eliminace zákmitù tlaèítka
	CLR EA		;všechna pøerušení zakázána
	SETB EX0	;povolení externího pøerušení EX0 (viz registr IE), pin P3.2
	SETB IT0	;pøerušení bude spouštìno saestupnou hranou (viz TCON)
	CLR ADJUST	;hodiny nebìí, bude tøeba je znovu nastavit
	SETB DATUM	;datum nebylo nastaveno
	CLR TIME
	CALL PER_DOB	;naète implicitní hodnoty konstant pro pøepínání èas/datum
	JMP REG_RTC

;Podprogram PER_DOB nastavuje implicitní hodnoty periody a doby zobrazení datumu

PER_DOB:MOV PER,#30	;hodnota je v sekundách (perioda zobrazování)
	MOV DOBA,#5	;hodnota je v sekundách (doba zobrazování datumu)
	MOV PER_D,PER	;definice obsahu pøechodnıch registrù
	MOV DOBA_D,DOBA
	RET
;---------------------------------------------------------------------
;Poèáteèní inicializace obvodu
;Po této proceduøe jsou generovány pulzy INT na vıstupu STD.P (pin 1)
;s periodou 1 s a ve všech tøech speciálních registrech RTC jsou nastavena potøebná data
;Nastavení registrù F, E a D v RTC (viz manuál k RTC - str. 14)
;pøi zápisu do konfiguraèních registrù není nutné testovat signál BUSY

	;zápis do registru F
REG_RTC:MOV I_O,#01011111B	;RESET obvodu
	CLR WRT			;TEST = 0, 24/12 = 1, STOP = 0, RESET = 1
	SETB WRT		;zápis dat do registru F

	MOV I_O,#01011111B	;nastavení cyklu 24/12 hod
	CLR WRT			;TEST = 0, 24/12 = 1, STOP = 0, RESET = 1
	SETB WRT		;zápis dat do registru F

	MOV I_O,#01001111B	;odblokování obvodu
	CLR WRT			;TEST = 0, 24/12 = 1, STOP = 0, RESET = 0
	SETB WRT		;zápis dat do registru F

	;zápis do registru E (nutné pøi vyuívání signálu STD.P - pin 1 RTC)
	MOV I_O,#01001110B	;adresa a data registru E
	CLR WRT			;t1 = 0, t2 = 1, ITRPT/STND = 0, MASK = 0
	SETB WRT		;nastaven reim Fixed period pulse output mode

;V tomto místì ji jsou na pinu 1 RTC generovány pøerušovací pulzy s trváním
;asi 8 ms a periodou 1 s

	;zápis do registru D
	MOV I_O,#01001101B	;adresa a data registru D
	CLR WRT			;30sADJ = 0, IRQ FLAG = 1, BUSY = 0, HOLD = 0
	SETB WRT

	;zápis do registru F - zastavení a reset èítaèe
	MOV I_O,#01111111B	;zastavení a RESET èítaèe v obvodu RTC
	CLR WRT			;TEST = 0, 24/12 = 1, STOP = 1, RESET = 1
	SETB WRT		;zápis dat do registru F

;----------------------------------------------------------------------------

;Sekvence pro vıchozí stav nastavování datumu (bliká údaj 01.01.16)

N20:	CLR EA		;zákaz pøerušení
	CLR ADJUST	;nejsou nastavena ádná data
	SETB DATUM	;jako 1. se bude nastavovat datum a den v tıdnu
	MOV DEN,#0	;registr èísla dne v tıdnu (0 = nedìle)
	MOV ROKY,#16	;registr rokù
	MOV MESICE,#1	;registr mìsícù
	MOV DNY,#1	;registr dnù
	CALL BCD_DNY	;tyto podprogramy zároveò plní videoRAM
	CALL BCD_MES
	CALL BCD_ROK
	MOV DEN_TYD,DEN
	CALL DISPLEJ
	CLR DT		;desetinné teèky pøi zobrazení datumu aktivní
	JNB RESET,$	;nutné, jinak po RST tlaèítkem RESET nebude displej blikat
	CALL DELAY	;potlaèení zákmitù pøi povolení tlaèítka
;------------------------------------------------------------------------
;Testování stisku tlaèítka RESET. Není-li stisknuto, sekvence testování
;se opakuje a na displeji bliká údaj 01.01.16 (implicitní vıchozí datum)

RYCH:	JNB RESET,DAT1	;stisknuto tlaèítko RESET?
	CALL DELAY	;zpodìní asi 65 ms
	CALL DELAY
	JNB RESET,DAT1	;tlaèítko se testuje opakovanì
	CALL DELAY	;aby byla jeho reakce dostateènì rychlá
	CALL DELAY
	JNB RESET,DAT1
	CALL DELAY
	CALL DELAY
	JNB RESET,DAT1
	CPL BLANK	;zatemòovací pulzy pro displej (aktivní v L)
	JMP RYCH
;---------------------------------------------------------------------------

DAT1:	CALL DELAY	;potlaèení zákmitù tlaèítka
	JNB RESET,$	;ochrana pøed trvalım drením tlaèítka
	SETB BLANK	;aktivace displeje (konec blikání)
	CLR ADJUST	;informace pro systém, e není nastaven platnı datum a èas
	SETB DATUM	;jako první se bude nastavovat datum


;---------------------------------------------------------------------
;H L A V N Í   P R O G R A M O V Á   S M Y È K A
;Cyklus pro opakované ètení 6 nastavovacích tlaèítek.
;Jedná se o hlavní programovou smyèku pøi bìících hodinách,
;která je 1x za 1s pøerušována signálem z RTC

N4:	JNB SETING,N10		;tlaèítko SET - po jeho 1.stisku dojde k zapsání datumu, 2. stisk = zápis èasu
	JNB NAS_HOD,MEZI_N1	;tlaèítko pro nastavování hodin, resp. dnù
	JNB NAS_MIN,MEZI_N2	;tlaèítko pro nastavování minut, resp. mìsícù
	JNB NAS_SEK,MEZI_N3	;tlaèítko pro nastavování sekund, resp. rokù
	JNB RESET,$		;tlaèítko RESET - ádná reakce
	JNB TIM_DAT,N5		;tlaèítko pro pøepínání zobrazení èas/datum
	JMP N4

;Sekvence pro okamité zobrazení datumu stiskem pøíslušného tlaèítka

N5:	CLR TIME		;pøepínací bit pro reim zobrazení DATUM/ÈAS
	CLR DT			;aktivace desetinnıch teèek
	JNB TIM_DAT,$		;tato smyèka je pøerušována INT0
	SETB TIME		;bude se znovu zobrazovat èas
	SETB DT			;vypnutí desetinnıch teèek
	JMP N4
;-------------------------------------------------------------------------------
;Reakce na stisky jednotlivıch tlaèítek s ohledem na pøíznakové bity

;Reakce na tlaèítko SETING
N10:	JB ADJUST,N4		;je-li provedeno nastavení hodin, nedìlej nic a testuj tlaèítka
	JB DATUM,ZAP_DAT	;je-li nastaven pøíznak DATUM, proveï zápis data do 8051 (nikoliv RTC)
	JMP ZAP_TIM		;zapiš nastavenı èas, spus hodiny a jdi na test tlaèítek
;----------------------------------------------------------------------------------
CEK1:	CALL DELAY		;prodleva pro eliminaci zákmitù tlaèítka
	CALL NULY		;naplní videoRAM 0 (implicitní šas je 00.00.00)
	CALL DISPLEJ		;zobrazení implicitního èasu na displeji
	SETB DT			;vypnutí desetinnıch teèek a zobrazení dvojteèek
	JNB SETING,$
	CALL DELAY		;potlaèení zákmitù tlaèítka pøi jeho uvolnìní
	MOV HOD,#0		;vıchozí nastavení pomocnıch registrù
	MOV MIN,#0		;pro následující nastavování èasu
	MOV SEK,#0
	JMP N4			;jdi zpátky na test tlaèítek
;-----------------------------------------------------------------------------------
MEZI_N1:JMP N1
MEZI_N2:JMP N2
MEZI_N3:JMP N3			;pomocné meziskoky, protoe návìští jsou daleko
;-----------------------------------------------------------------------------------

;Uloení novì nastaveného datumu a dne v tıdnu do pøíslušnıch registrù,
;které pouívá podprogram ZAPIS.

ZAP_DAT:CLR DATUM		;stáhnutí vlajky, dále se budou nastavovat èasové údaje
	MOV W_NEW,DEN_TYD	;novı den v tıdnu (0 je nedìle)
	MOV Y10_NEW,SEK_DES	;nové desítky let (0 a 9)
	MOV Y1_NEW,SEK_JED	;nové jednotky let (0 a 9)
	MOV M10_NEW,MIN_DES	;nové desítky mìsícù (0 nebo 1)
	MOV M1_NEW,MIN_JED	;nové jednotky mìsícù (0 a 9)
	MOV D10_NEW,HOD_DES	;nové desítky dnù (0 a 3)
	MOV D1_NEW,HOD_JED	;nové jednotky dnù (0 a 9)
	CLR ADJUST		;není nastaven èas
	JMP CEK1		;pokraèuj v aktualizaci èasu

;Uloení novì nastavenıch èasovıch údajù do registrù,
;které vyuívá podprogram ZAPIS.

ZAP_TIM:MOV S1_NEW,SEK_JED
	MOV S10_NEW,SEK_DES
	MOV MI1_NEW,MIN_JED
	MOV MI10_NEW,MIN_DES
	MOV H1_NEW,HOD_JED
	MOV H10_NEW,HOD_DES
	CALL ZAPIS		;zapíše data do registrù RTC
	MOV I_O,#01001111B	;odblokuje èasomíru v registru F, STOP = 0 a RESET = 0
	CLR WRT			;TEST = 0, 24/12 = 1, STOP = 0, RESET = 0
	SETB WRT		;zápis dat do registru F - SPUŠTÌNÍ RTC
	SETB ADJUST	;bit indikuje nastavení hodin a jejich normální provoz
	SETB TIME	;implicitnì se zobrazuje èas, datum na vyádání tlaèítkem
	SETB EA		;povolení pøerušení - normální bìh hodin
	JMP N4		;zpátky na test tlaèítek


;------------------------------------------------------------------
;Nastavení hodin nebo dnù

N1:	JB ADJUST,H14	;jestlie RTC bìí, není mono upravovat èas ani datum
	JB DATUM,H11	;zaèíná se nastavením data
	INC HOD		;je-li nastaveno datum, nastavuje se èas
	MOV R6,HOD
	CJNE R6,#24,H13	;kontrola maximální hodnoty (23 hodin)
	MOV HOD,#0
H13:	CALL BCD_HOD
	CALL DISPLEJ
	CALL DELAY	;urèuje rychlost pøièítání pøi drení tlaèítka
	CALL DELAY
	CALL DELAY
	CALL DELAY
H14:	JMP N4

;Nastavení dnù

H11:	INC DNY
	MOV R6,DNY
	CJNE R6,#32,H12	;kontrola maximální hodnoty (31 dnù)
	MOV DNY,#1	;došlo k pøeteèení registru dnù
	INC DEN		;zvyš èíslo dne v tıdnu
	MOV R5,DEN
	CJNE R5,#7,H12	;test na pøeteèení registru dne v tıdnu (max. je 6)
	MOV DEN,#0
H12:	CALL BCD_DNY
	MOV DEN_TYD,DEN
	CALL DISPLEJ
	CALL DELAY	;urèuje rychlost pøièítání pøi drení tlaèítka
	CALL DELAY
	CALL DELAY
	JMP N4
;-------------------------------------------------------------------------
;Nastavení minut nebo mìsícù

N2:	JB ADJUST,MEZ_N4;jestlie RTC bìí, není mono upravovat èas ani datum
	JB DATUM,K22
	INC MIN
	MOV R6,MIN
	CJNE R6,#60,K1	;kontrola maximální hodnoty (59 minut)
	MOV MIN,#0
K1:	CALL BCD_MIN
	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	CALL DELAY
	CALL DELAY
	JMP N4

;Nastavení mìsicù

K22:	INC MESICE
	MOV R6,MESICE
	CJNE R6,#13,H19	;kontrola maximální hodnoty (12 mìsícù)
	MOV MESICE,#1	;došlo k pøeteèení registru dnù
H19:	CALL BCD_MES
	CALL DISPLEJ
	CALL DELAY	;urèuje rychlost pøièítání pøi drení tlaèítka
	CALL DELAY
	CALL DELAY
MEZ_N4:	JMP N4
;------------------------------------------------------------------------------
;Nastavení sekund nebo rokù

N3:	JB ADJUST,MEZI_N4	;jestlie RTC bìí, není mono upravovat èas ani datum
	JB DATUM,K33
	INC SEK
	MOV R6,SEK
	CJNE R6,#60,K2	;kontrola maximální hodnoty (59 sekund)
	MOV SEK,#0
K2:	CALL BCD_SEK
	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	CALL DELAY
	CALL DELAY
MEZI_N4:JMP N4

;Nastavení rokù

K33:	INC ROKY
	MOV R6,ROKY
	CJNE R6,#51,H15	;kontrola maximální hodnoty (rok 2050)
	MOV ROKY,#16	;došlo k pøeteèení registru dnù
H15:	CALL BCD_ROK
	CALL DISPLEJ
	CALL DELAY	;urèuje rychlost pøièítání pøi drení tlaèítka
	CALL DELAY
	CALL DELAY
	JMP N4

;-------------------------------------------------------------------------------

;Podprogram BCD_HOD vytvori z binarn. cisla ulozeneho v registru HOD
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese HOD_JED
;a vyssi rad (desitky) na adrese HOD_DES.
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru HOD
;Vystup: dekadicka cisla v pameti videoRAM

BCD_HOD: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,HOD
	 MOV B,#10
         DIV AB
         MOV HOD_DES,A		;vyšší øád
         MOV HOD_JED,B		;niší øád
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram BCD_MIN vytvori z binarn. cisla ulozeneho v registru MIN
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese MIN_JED
;a vyssi rad (desitky) na adrese MIN_DES.
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru MIN
;Vystup: dekadicka cisla v pameti videoRAM

BCD_MIN: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,MIN
	 MOV B,#10
         DIV AB
         MOV MIN_DES,A		;vyšší øád
         MOV MIN_JED,B		;niší øád
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram BCD_SEK vytvori z binarn. cisla ulozeneho v registru SEK
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese SEK_JED
;a vyssi rad (desitky) na adrese SEK_DES.
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru SEK
;Vystup: dekadicka cisla v pameti videoRAM

BCD_SEK: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,SEK
	 MOV B,#10
         DIV AB
         MOV SEK_DES,A		;vyšší øád
         MOV SEK_JED,B		;niší øád
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram BCD_DNY vytvori z binarn. cisla ulozeneho v registru DNY
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese HOD_JED
;a vyssi rad (desitky) na adrese HOD_DES (pozice sispleje jsou sdílené
;pro èasovı a datovı údaj).
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru DNY
;Vystup: dekadicka cisla v pameti videoRAM

BCD_DNY: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,DNY
	 MOV B,#10
         DIV AB
         MOV HOD_DES,A		;vyšší øád
         MOV HOD_JED,B		;niší øád
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram BCD_MES vytvori z binarn. cisla ulozeneho v registru MESICE
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese MIN_JED
;a vyssi rad (desitky) na adrese MIN_DES (pozice sispleje jsou sdílené
;pro èasovı a datovı údaj).
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru MESICE
;Vystup: dekadicka cisla v pameti videoRAM

BCD_MES: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,MESICE
	 MOV B,#10
         DIV AB
         MOV MIN_DES,A		;vyšší øád
         MOV MIN_JED,B		;niší øád
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram BCD_ROK vytvori z binarn. cisla ulozeneho v registru ROKY
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese SEK_JED
;a vyssi rad (desitky) na adrese SEK_DES (pozice sispleje jsou sdílené
;pro èasovı a datovı údaj).
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru ROKY
;Vystup: dekadicka cisla v pameti videoRAM

BCD_ROK: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,ROKY
	 MOV B,#10
         DIV AB
         MOV SEK_DES,A		;vyšší øád
         MOV SEK_JED,B		;niší øád
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram NULY napní videoRAM samımi nulami.

NULY:	MOV SEK_JED,#0
	MOV SEK_DES,#0
	MOV MIN_JED,#0
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0AH		;7. pozice je potmì
	RET

;Podprogram DELAY urèuje rychlost pøièítání údajù na displeji
;pøi ruèním zadávání údajù. Má zpodìní asi 65 ms

DELAY:	MOV TMOD,#01H
	MOV TL0,#0
	MOV TH0,#0
	SETB TR0
	JNB TF0,$
	CLR TR0
	CLR TF0
	RET

;Podprogram DEL vyuívá rutina kontroly displeje

DEL:	MOV R0,#3
DEL1:	CALL DELAY
	DJNZ R0,DEL1
	RET
;------------------------------------------------------------------------
;Podprogram ZAPIS naplní jednotlivé èasové registry aktuálními daty.
;Plní rovnì registry datumu a dne v tıdnu.
;Pøístup k datovım registrùm je podmínìn stavem BUSY=0!

ZAPIS:	PUSH 00H
	PUSH 01H
	PUSH ACC
	MOV R0,#0		;registr adresy registru v RTC
	MOV R1,#S1_NEW		;v R1 je adresa registru jenotek sekund v RAM
Z1:	MOV A,@R1		;hodnota na pøíslušné adrese do ACC
	SWAP A			;data jsou v horní polovinì registru
	ANL A,#11110000B	;vymaskování dolní poloviny registru pro adresu
	ORL A,R0		;sdruení adresy a dat
	MOV I_O,A
	CLR WRT			;zápis údaje do registru
	SETB WRT
	INC R0			;zvıšení adresy registru v RTC o 1
	INC R1			;zvıšení adresy v RAM o 1
	CJNE R0,#0DH,Z1		;kontrola, zda byly zapsány všechny registry
	POP ACC
	POP 01H
	POP 00H
	RET

;-----------------------------------------------------------------
;EXTERNÍ PØERUŠENÍ
;Podprogram CTENI je obsluná rutina externího pøerušení INT0.
;Toto pøerušení je vyvoláno kadou sekundu signálem RTC STD.P
;Program CTENI naplní registry videoRAM v 8051 daty naètenımi z registrù RTC
;První èást vyèítá pouze aktuální èas.

CTENI:	JB DAT_TIM,CT6	;spínaè není sepnutı, zobrazuje se trvale èas
	CALL PREP	;podprogram nastavuje, resp. nuluje bit TIME
CT6:	SETB RDG
	PUSH 00H
	PUSH 01H
	PUSH ACC
	MOV R0,#0	;adresa registru v RTC pro jednotky sekund
	MOV R1,#S1	;adresa registru pro jednotky sekund v 8051
CT1:	MOV A,R0
	ORL A,#0F0H	;horní 4 bity (data) musí bıt v 1 (jako vstup)
	MOV I_O,A	;adresa èteného registru na RTC
	CLR RDG		;ètení registru
	MOV A,I_O	;stav portu do ACC
	SETB RDG	;konec ètecího pulzu
	SWAP A		;prohození spodní a horní ètveøice bitù
	ANL A,#0FH	;vymaskování dat
	MOV @R1,A	;data do pøíslušného registru v 8051
	INC R0		;zvıšení adresy RTC
	INC R1		;posun na další registr
	CJNE R0,#6,CT1	;test, zda byly naèteny všechny èasové údaje

;Druhá èást plynule navazuje na èást pøedchozí a vyèítá z RTC údaje
;o datu a dnu v tıdnu.
;0 = nedìle, 1 = pondìlí ....6 = sobota

	MOV R1,#DEN1	;adresa v RAM 8051 pro jednotky dnù
CT2:	MOV A,R0
	ORL A,#0F0H	;horní 4 bity musí bıt v 1 (jako vstup)
	MOV I_O,A	;adresa èteného registru na RTC
	CLR RDG		;ètení registru
	MOV A,I_O	;stav portu do ACC
	SETB RDG
	SWAP A
	ANL A,#0FH	;vymaskování dat
	MOV @R1,A	;data do videopamìti
	INC R0
	INC R1		;posun na vyšší øád ve videopamìti
	CJNE R0,#0DH,CT2
	POP ACC
	POP 01H
	POP 00H
	MOV I_O,#01001101B	;adresa a data registru D
	CLR WRT			;30sADJ = 0, IRQ FLAG = 1, BUSY = 0, HOLD = 0
	SETB WRT
	JNB TIME,CT3	;bude se zobrazovat datum
	CALL VID_TIM	;bude se zobrazovat èas
	SETB DT
	JMP CT4
CT3:	CLR DT
	CALL VID_DAT
CT4:	CALL DISPLEJ
	RETI
;---------------------------------------------------------------------------

;Podprogram PREP nastavuje, resp. nuluje bit TIME. Obsah registru PER
;urèuje periodu, s kterou se bude na displeji automaticky zobrazovat
;aktuální datum a den v tıdnu. Obsah registru DOBA urèuje, jak dlouho
;bude trvat zobrazení datumu. Po uplynutí této doby se systém znovu
;automaticky vrátí k zobrazování aktuálního èasu. Tato funkce musí bıt
;povolena uivatelem pøepnutím pøepínaèe DAT_TIM!
;Podprogram je volán pouze obslunou rutinou pøerušení CTENI

PREP:	JNB TIME,PR2
	DJNZ PER_D,PR1
	CLR TIME
	MOV PER_D,PER	;obnovení implicitní hodnoty
	JMP PR1
PR2:	DJNZ DOBA_D,PR1
	SETB TIME
	MOV DOBA_D,DOBA	;obnovení implicitní hodnoty
PR1:	RET

;Podprogram VID_TIM naplní videoRAM 8051 èasovımi údaji

VID_TIM:MOV SEK_JED,S1	;jedná se o adresy 7mi segmentovek
	MOV SEK_DES,S10
	MOV MIN_JED,MI1
	MOV MIN_DES,MI10
	MOV HOD_JED,H1
	MOV HOD_DES,H10
	MOV DEN_TYD,#0AH	;7. pozice pøi zobrazení èasu nesvítí
	RET

;Podprogram VID_DAT naplní videoRAM 8051 údaji o datumu a
;dnu v tıdnu

VID_DAT:MOV SEK_JED,ROK1	;jedná se o adresy 7mi segmentovek
	MOV SEK_DES,ROK10
	MOV MIN_JED,MES1
	MOV MIN_DES,MES10
	MOV HOD_JED,DEN1
	MOV HOD_DES,DEN10
	MOV DEN_TYD,DEN_W
	RET

;-----------------------------------------------------------------------------
;Podprogram DISPLEJ vyšle data z pamìti videoRAM na displej

DISPLEJ:PUSH ACC
	CLR BLANK
	SETB TEST
	SETB LE1
	SETB LE2
	SETB LE3
	SETB LE4
	SETB LE5
	SETB LE6
	SETB LE7
	MOV A,P1
	ANL A,#0F0H
	ORL A,HOD_DES
	MOV P1,A
	CLR LE1
	SETB LE1
	MOV A,P1
	ANL A,#0F0H
	ORL A,HOD_JED
	MOV P1,A
	CLR LE2
	SETB LE2
	MOV A,P1
	ANL A,#0F0H
	ORL A,MIN_DES
	MOV P1,A
	CLR LE3
	SETB LE3
	MOV A,P1
	ANL A,#0F0H
	ORL A,MIN_JED
	MOV P1,A
	CLR LE4
	SETB LE4
	MOV A,P1
	ANL A,#0F0H
	ORL A,SEK_DES
	MOV P1,A
	CLR LE5
	SETB LE5
	MOV A,P1
	ANL A,#0F0H
	ORL A,SEK_JED
	MOV P1,A
	CLR LE6
	SETB LE6
	MOV A,P1
	ANL A,#0F0H
	ORL A,DEN_TYD
	MOV P1,A
	CLR LE7
	SETB LE7
	POP ACC
	SETB BLANK
	RET

;-----------------------------------------------------------------------
;Podprogram TESTUJ provádí test displeje.
;Musí svítit (blikat) všechny segmenty, desetinné teèky a dvojteèky.
;Kontrolu provádí vizuálnì uivatel.

TESTUJ:	CALL ROT_1
	CALL ROT_2
	CALL ROT_3
	CALL ROT_4
	CALL ROT_5
	CALL ROT_6
	CALL ROT_7
RR_8:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH	;segmentovky nesvítí
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DELAY
	CALL DELAY
	CALL DELAY
	CALL DISPLEJ
	MOV R1,#16
RR_9:	CPL DT
	CALL DELAY
	CALL DELAY
	CALL DELAY
	DJNZ R1,RR_9
	MOV R1,#15
RR_1:	CALL DELAY
	CLR BLANK
	CPL TEST
	CALL DELAY
	SETB BLANK
	DJNZ R1,RR_1
	CALL D1_6
	CALL DELAY
	CALL DELAY
	CALL DELAY
	MOV R1,#3
RR_10:	CALL D1_7
	CALL DEL
	CALL D1_8
	CALL DEL
	CALL D1_9
	CALL DEL
	CALL D1_10
	CALL DEL
	CALL D1_11
	CALL DEL
	CALL D1_12
	CALL DEL
	CALL D1_13
	CALL DEL
	CALL D1_14
	CALL DEL
	CALL D1_15
	CALL DEL
	CALL D1_16
	CALL DEL
	CALL D1_17
	CALL DEL
	DJNZ R1,RR_10
	JNB SETING,$	;ochrana pøes drením tlaèítka
	CALL DELAY
	RET		;konec podprogramu TESTUJ

;Kontrola 1. segmentovky

ROT_1:	MOV R1,#0
	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH	;segmentovka nesvítí
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_11:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC HOD_DES
	INC R1
	CJNE R1,#10,ROT_11
	RET

;Kontrola 1. + 2. segmentovky

ROT_2:	MOV R1,#0
	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH	;segmentovka nesvítí
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH	;segmentovka nesvítí
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_12:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_12
	RET

;Kontrola 1. + 2. + 3. segmentovky

ROT_3:	MOV R1,#0
	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH	;segmentovka nesvítí
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_13:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC MIN_DES
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_13
	RET

;Kontrola 1. + 2. + 3. + 4. segmentovky

ROT_4:	MOV R1,#0
	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH	;segmentovka nesvítí
	MOV MIN_JED,#0
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_14:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC MIN_JED
	INC MIN_DES
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_14
	RET

;Kontrola 1. + 2. + 3. + 4. + 5. segmentovky

ROT_5:	MOV R1,#0
	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0
	MOV MIN_JED,#0
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_15:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC SEK_DES
	INC MIN_JED
	INC MIN_DES
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_15
	RET

;Kontrola 1. + 2. + 3. + 4. + 5. + 6. segmentovky

ROT_6:	MOV R1,#0
	MOV SEK_JED,#0
	MOV SEK_DES,#0
	MOV MIN_JED,#0
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_16:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC SEK_JED
	INC SEK_DES
	INC MIN_JED
	INC MIN_DES
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_16
	RET

;Kontrola 1. + 2. + 3. + 4. + 5. + 6. + 7. segmentovky

ROT_7:	MOV R1,#0
	MOV SEK_JED,#0
	MOV SEK_DES,#0
	MOV MIN_JED,#0
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0
ROT_17:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC DEN_TYD
	INC SEK_JED
	INC SEK_DES
	INC MIN_JED
	INC MIN_DES
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_17
	RET

D1_6:	MOV SEK_JED,#6
	MOV SEK_DES,#5
	MOV MIN_JED,#4
	MOV MIN_DES,#3
	MOV HOD_JED,#2
	MOV HOD_DES,#1
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_7:	MOV SEK_JED,#5
	MOV SEK_DES,#4
	MOV MIN_JED,#3
	MOV MIN_DES,#2
	MOV HOD_JED,#1
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_8:	MOV SEK_JED,#4
	MOV SEK_DES,#3
	MOV MIN_JED,#2
	MOV MIN_DES,#1
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_9:	MOV SEK_JED,#3
	MOV SEK_DES,#2
	MOV MIN_JED,#1
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_10:	MOV SEK_JED,#2
	MOV SEK_DES,#1
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_11:	MOV SEK_JED,#1
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_12:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_13:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#5
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_14:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#5
	MOV HOD_DES,#4
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_15:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#5
	MOV HOD_JED,#4
	MOV HOD_DES,#3
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_16:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#5
	MOV MIN_DES,#4
	MOV HOD_JED,#3
	MOV HOD_DES,#2
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_17:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#5
	MOV MIN_JED,#4
	MOV MIN_DES,#3
	MOV HOD_JED,#2
	MOV HOD_DES,#1
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

        END
