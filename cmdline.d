module cmdline

class ChessConsoleUI {
    void run() {
        auto board = new ChessBoard();

        void printBoard() {
            writeln();
            foreach(r; 0..8) {
                r = 7 - r;
                writef(" %s  ", r);
                foreach(c; 0..8) {
                    char chr = typeToChar(board.cellType(r, c));
                    if (chr != '.' && board.cellColor(r,c) == Piece.Color.Black) {
                        chr = std.ascii.toLower(chr);
                    }
                    write(chr);
                }
                writeln();
            }
            writeln();
            writeln("    01234567");
            writeln();
        }

        void doTurn() {
            bool turnPerformed = false;
            while(!turnPerformed) {
                printBoard();
                auto command = stdin.readln().strip().split();
                if (!command) {
                    writeln("Enter some command:");
                    continue;
                }
                switch(command[0]) {
                    case "castle": 
                        if (command[1] == "left") {
                            if (board.canDoCasle(ChessBoard.CastleType.Left)) {
                                board.doCastle(ChessBoard.CastleType.Left);
                                turnPerformed = true;
                            }
                        } else if (command[1] == "right") {
                            if (board.canDoCasle(ChessBoard.CastleType.Right)) {
                                board.doCastle(ChessBoard.CastleType.Right);
                                turnPerformed = true;
                            }
                        } else {
                            writeln("Unknown castle type. Please user either \"left\""
                                    " or \"right\".");
                        }
                        break;
                    case "save": 
                        board.saveToFile("save.txt");
                        break;
                    case "load": 
                        board.loadFromFile("save.txt");
                        break;
                    case "exit":
                        Runtime.terminate();
                        exit(0);
                        break;
                    default:
                        int r0, c0, r1, c1;
                        try {
                            r0 = to!int(command[0]);
                            c0 = to!int(command[1]);
                            r1 = to!int(command[2]);
                            c1 = to!int(command[3]);
                        } catch (ConvException) {
                            writeln("Enter four integers or EXIT, LOAD, SAVE, CASTLE LEFT, or CASLTE RIGHT");
                            break;
                        }
                        board.movePiece(r0, c0, r1, c1);
                        turnPerformed = true;
                        break;
                }
            }
            if (board.endOfGame()) {
                writeln("Congratulations! You have won!");
                Runtime.terminate();
                exit(0);
            }
        }


        while(true) {
            doTurn();
        }
    }
    private:

}

void main()
{
    writeln("main OK");
    auto game = new ChessConsoleUI();
    game.run();
}

