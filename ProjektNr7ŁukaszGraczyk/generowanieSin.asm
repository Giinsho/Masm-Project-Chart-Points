; ##########################################
  ;.586P
  .686
  .model flat, stdcall
  option casemap :none   ; case sensitive
;constants from kernel
	STD_INPUT_HANDLE equ	-10
	STD_OUTPUT_HANDLE equ	-11
	GENERIC_READ equ	80000000h
	GENERIC_WRITE equ	40000000h

	CREATE_ALWAYS                        equ 2
	OPEN_EXISTING                        equ 3
	OPEN_ALWAYS                          equ 4

	GetLastError			PROTO
	GetStdHandle			PROTO:DWORD
	WriteConsoleA			PROTO:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
	CreateDirectoryA		PROTO:DWORD,:DWORD    
	GetCurrentDirectoryA	PROTO:DWORD,:DWORD
	CreateFileA				PROTO:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
	lstrcatA				PROTO:DWORD,:DWORD
	WriteFile PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD    
	GetTickCount	PROTO
	CloseHandle		PROTO :DWORD 
;constants from fpu.inc


	SRC1_FPU    EQU   1
	SRC1_REAL   EQU   2
	SRC1_DMEM   EQU   4
	SRC1_DIMM   EQU   8
	SRC1_CONST  EQU   16

	ANG_DEG     EQU   0
	ANG_RAD     EQU   32

	DEST_MEM    EQU   0
	DEST_IMEM   EQU   64
	DEST_FPU    EQU   128

	SRC2_FPU    EQU   256
	SRC2_REAL   EQU   512
	SRC2_DMEM   EQU   1024
	SRC2_DIMM   EQU   2048
	SRC2_CONST  EQU   4096
; ##########################################
;prototypes from fpu.lib
	FpuAtoFL    PROTO :DWORD,:DWORD,:DWORD
	FpuFLtoA    PROTO :DWORD,:DWORD,:DWORD,:DWORD
;prototypes from masm32.lib
	StripLF      PROTO :DWORD
	StdIn        PROTO :DWORD,:DWORD
	StdOut       PROTO :DWORD
	CharToOemA   PROTO :DWORD, :DWORD
;others

	ExitProcess  PROTO :DWORD
	wsprintfA		PROTO C :VARARG
	includelib lib/kernel32.lib
	includelib lib/masm32.lib
	includelib lib/fpu.lib
; ##########################################
_DATA SEGMENT 
	x				   REAL10	?
	xmin			   REAL10	?
	xmax			   REAL10	?	
	zmA				   REAL10	1.0
	zmB				   REAL10	1.0
	
	mnozenie	       REAL10	0.0

	wynik		   REAL10	0.0
	bufor          DWORD		128 dup(0)
	rozmiarbufora  DWORD		128
	
	nastopnie		REAL10 57.32484076
	zamiana			REAL10 ?
	mod360			REAL10 0.0
	pomStos			REAL10 0.0
	zmDok		   REAL10  ?
	pomocDok	   REAL10 ?
	komunikat1	   byte "Podaj liczbê x-min: ",0
	komunikat2	   byte "Podaj liczbê x-max: ",0
		
	zmiennaX	  byte "Podaj zmienna x: ",0 
	zmiennaA	  byte "Podaj zmienna A: ",0
	zmiennaB	  byte "Podaj zmienna B: ",0

	dokladnosc	  byte "Podaj dok³adnoœæ <2,100> : ",0
	stopnie		  byte "K¹t w ° = ",0 
	newLine		byte ' ',10,0
	komunikatWynik db "Wynik dla:  A*(Sin(B*x))= ",0
	

	cin			dword ?
	cout		dword ?

	coutn		dword ?
	ncin		dword ?

	printed		dword 0
	inserted	dword 0
	
	zmiennaDok  dword ?


	bufor2		byte 128 dup(?)
	rbuf2		dword 128

	bufor3		byte "\Wykres.csv",0
	rbuf3	dword $ - bufor3

	fileHandle dword ?
	rozmiar db  ?

	komunikatLiczba2	db ",  ",0
	enterKom	db 0Dh,' ',0
	
_DATA ENDS

_TEXT SEGMENT
	
	Wypisanie MACRO komunikat
		invoke	CharToOemA,OFFSET komunikat,OFFSET komunikat
		invoke	StdOut,OFFSET komunikat
	ENDM
	
	Input MACRO zmienna
		invoke  StdIn, OFFSET bufor, rozmiarbufora
		invoke  StripLF, OFFSET bufor
			;konwresja bufora na typ REAL10 i zapis w zmiennnej x
		invoke FpuAtoFL, ADDR bufor, ADDR zmienna, DEST_MEM
	ENDM

	Mnozenie MACRO x,y
			fld x
			fld y
			fmul st(0), st(1)
			fstp x
	ENDM
	
	Przeliczanie MACRO min,max,pomocDok,zmDok
		fld min
		fld max
		fsub st(0),st(1)
		fstp pomocDok
			invoke FpuFLtoA, ADDR pomocDok, 8, ADDR bufor, SRC1_REAL or SRC2_DIMM
			invoke StdOut,OFFSET bufor;				
		fld zmDok
		fdiv st(1),st(0)
		fstp zmDok
	ENDM

main proc

	Wypisanie zmiennaX
	Input x

	Wypisanie komunikat1
	Input xmin
	
	Wypisanie komunikat2
	Input xmax

	Wypisanie zmiennaB
	Input zmB

	Wypisanie zmiennaA
	Input zmA
	
	Wypisanie dokladnosc
	Input zmDok

	fld nastopnie
	fld x
	fmul st(0),st(1)
	fstp zamiana
	
	;kowersja wyninku na napis result z  10 cyframi po przecinku
	Wypisanie stopnie
    invoke FpuFLtoA, ADDR zamiana, 10, ADDR bufor, SRC1_REAL or SRC2_DIMM
    invoke StdOut,OFFSET bufor;	
	Wypisanie newLine
	
;; plik 
	push STD_OUTPUT_HANDLE
	call GetStdHandle
	mov cout, eax
	invoke GetCurrentDirectoryA, OFFSET rbuf2, offset bufor2
	invoke WriteConsoleA, cout, offset bufor2, eax, coutn, 0
	invoke lstrcatA, OFFSET	bufor2, OFFSET bufor3
	invoke CreateFileA, offset bufor2, GENERIC_WRITE, 0 ,0, CREATE_ALWAYS, 0, 0
	mov fileHandle ,eax
	invoke CreateFileA, offset bufor2, GENERIC_READ, 0 ,0, OPEN_EXISTING, 0, 0
	
	Mnozenie x,zmB

	fld xmin
	fld xmax
	fsub st(0),st(1)
	fstp pomocDok
	invoke FpuFLtoA, ADDR pomocDok, 8, ADDR bufor, SRC1_REAL or SRC2_DIMM
	invoke StdOut,OFFSET bufor;				
	fld zmDok
	fld pomocDok
	fdiv st(0),st(1)
	fstp pomocDok

	loopDolnaGranica:
			invoke FpuFLtoA, ADDR x, 8, ADDR bufor, SRC1_REAL or SRC2_DIMM
			invoke StdOut,OFFSET bufor;	
			invoke FpuFLtoA, ADDR xmin, 8, ADDR bufor, SRC1_REAL or SRC2_DIMM
			invoke StdOut,OFFSET bufor;	
			fld x
			fld xmin
			fcompp 
			fstsw ax
			sahf
			fstp pomStos
			jae dodaj
			jbe przedpetle
	dodaj:
		fld pomocDok
		fstp pomocDok

		fld x
		fld pomocDok
		fadd st(0),st(1)
		fstp x
		invoke FpuFLtoA, ADDR pomocDok, 8, ADDR bufor, SRC1_REAL or SRC2_DIMM
		invoke StdOut,OFFSET bufor;	
		jmp loopDolnaGranica
					
	przedpetle:
	invoke FpuFLtoA, ADDR x, 8, ADDR bufor, SRC1_REAL or SRC2_DIMM
	invoke StdOut,OFFSET bufor;	

	invoke FpuFLtoA, ADDR zmDok, 8, ADDR bufor, SRC1_REAL or SRC2_DIMM
	invoke StdOut,OFFSET bufor;	
	
	fld zmDok
	FRNDINT
	fist zmiennaDok
	mov eax, zmiennaDok
;	push eax
;	sub esp, 4           ; or use space you already reserved
;	fstp tbyte ptr [esp]
;	pop eax      ; or better,  pop eax
;	mov zmiennaDok,eax 

	mov ecx, eax
		petla:
			push ecx
			;; obliczenia
				;; wariant A*(Sin(B*x))
				fld x
				fld xmax
				fcompp 
				fstsw ax
				sahf
				fstp pomStos
				jbe koniec
				fld x
				fld pomocDok
				fadd st(0), st(1)
				fstp x
				;fmul st(1),st(0)
				;fstp mnozenie
				fsin
				fstp wynik
				Mnozenie wynik,zmA
			;kowersja wyninku na napis result z  10 cyframi po przecinku
			;;	Wypisanie komunikatWynik
				jmp zapisanie
				@@:
		pop ecx
	loop petla

invoke CloseHandle, fileHandle
koniec:
    invoke ExitProcess, 0
zapisanie:	
	fstp REAL10 PTR wynik
	invoke FpuFLtoA, ADDR wynik, 10, ADDR bufor, SRC1_REAL or SRC2_DIMM
				;jmp ws
				;invoke wsprintfA, offset bufor, offset komunikatLiczba2, wynik
			;;	invoke StdOut,OFFSET bufor;
				
	 invoke WriteFile, fileHandle, offset bufor, 12, rozmiar, 0
	 invoke wsprintfA, offset bufor, offset komunikatLiczba2
	 invoke WriteFile, fileHandle, offset bufor, 4, rozmiar, 0
	 
	 fld x
	 invoke FpuFLtoA, ADDR x, 10, ADDR bufor, SRC1_REAL or SRC2_DIMM
	 invoke WriteFile, fileHandle, offset bufor, 5, rozmiar, 0

	 invoke wsprintfA, offset bufor, offset enterKom
	 invoke WriteFile, fileHandle, offset bufor, 3, rozmiar, 0
	jmp @B

main endp

END