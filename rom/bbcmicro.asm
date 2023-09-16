\ BBC Micro Wifi Sideway ROM
\ Settings, definitions and constants

\ (C)Roland Leurs 2021
\ Version 1.00 August 2021

            __BBCMICRO__ = 1
            __ATOM__ = 0

			uart = &FC30            \ Base address for the 16C2552 UART B-port

            pagereg = &FCFF
            pageram = &FD00
			timer = &140            \ Count down timer, 3 bytes
			time_out = timer + 4    \ Time-out setting, 1 byte

            errorspace = &100       \ Some volatile memory area for generating error messages
            heap      = &900        \ Some volatile memory area for tempory storage
			strbuf    = &A00        \ Some volatile memory area for string buffer
            flashcode = &900        \ may overlap with heap and string buffer

            osrdch = &FFE0
            oswrch = &FFEE
            osasci = &FFE3
            osword = &FFF1			\ Added Timo Hartong for NTP
            osbyte = &FFF4
            osnewl = &FFE7
            oscli  = &FFF7
            switch = &FE30
            shadow = &F4

			\  Added Timo hartong for NTP
			\ OS Byte constants
			ReadFred 	= &92
			WriteFred 	= &93
			ReadJim 	= &94
			WriteJim 	= &95
			\ OSWord constants
			ReadSysClock = 1
			WriteSysClock = 2

            uptvec = &222           \ User Print Vector
            netprt = &D90           \ Network printer name or ip (32 char)
            uptype = &DB0           \ User Printer Type
            uptsav = &DB1           \ Save old uptvec

            RAW     = 0             \ Telnet raw mode
            PRESTEL = 1             \ Telnet prestel mode
            ANSI    = 2             \ Telnet ansi mode

            line = &F2              \ address for command line pointer
            zp = &90                \ workspace

			save_a = zp+2           \ only used in driver, outside driver is may be used for "local" work
			save_y = zp+3           \ only used in driver, outside driver is may be used for "local" work
			save_x = zp+4           \ only used in driver, outside driver is may be used for "local" work
            pr24pad = zp+5
			paramblok = save_y

			data_counter = zp+6
            blocksize = zp+6
            load_addr = zp+9

            baudrate = zp+6         \ must be the same as blocksize because of MUL10 routine
            parity   = zp+9
            databits = zp+10
            stopbits = zp+11

			buffer_ptr = zp+9       \ buffer_ptr and data_pointer must be adjescent!
			data_pointer = zp+11    \ a.k.a. data length
            size = zp+11            \ indeed, same as data_pointer
            needle = zp+12          \ may overlap with data_pointer, 2 bytes
            datalen = zp+13         \ data length counter, 2 bytes
            crc = zp+15             \ calculated crc, 2 bytes
            servercrc = zp+17       \ received crc, 2 bytes

			read_ptr = zp+15        \ just a few other names, used by the telnet command
			write_ptr = zp+17
			telnet_mode = zp+8      \ telnet mode for displaying text (prestel, ansi, raw etc)
            quelen = zp + 7         \ queue length for prestel and ansi escape sequences

			mux_status  = &AA
			mux_channel = &AB     \ need 5 bytes!
			

ORG &8000-22         ; it's a sideway ROM service and it contains an ATM header
    
