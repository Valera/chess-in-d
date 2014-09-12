all: termui chess 

chess: cmdline.d chess.d
	dmd cmdline.d chess.d -de -unittest -debug -g

termui: termui.d chess.d ~/projects/d-tui/libtui.o
	dmd termui.d chess.d -de -unittest -debug -g -I~/projects/d-tui/ \
	    ~/projects/d-tui/libtui.o -L-lutil


clean:
	rm *.o *~

docs:
	dmd -Dddocs chess.d -D
