all: termui cmdline

cmdline: cmdline.d chess.d ~/projects/d-tui/libtui.o
	dmd cmdline.d chess.d -de -unittest -debug -g -D -Dddocs/

termui: termui.d chess.d ~/projects/d-tui/libtui.o
	dmd termui.d chess.d -de -unittest -debug -g -I~/projects/d-tui/ \
	    ~/projects/d-tui/libtui.o -L-lutil -D -Dddocs/


clean:
	rm cmdline termui *.o *~
