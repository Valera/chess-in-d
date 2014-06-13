all: chess

chess: chess.d
	dmd chess.d -de -unittest

clean:
	rm *.o

docs:
	dmd -Dddocs chess.d -D
