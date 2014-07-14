all: chess

chess: chess.d
	dmd chess.d -de -unittest -debug -g

clean:
	rm *.o

docs:
	dmd -Dddocs chess.d -D
