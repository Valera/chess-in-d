import std.stdio;
import std.algorithm;
import std.ascii;
import std.math;
import std.string;
import std.conv;
import std.c.process;
import core.runtime;

// TODO: checkmate in case when player can not do any turn.
// TODO: condition of a draw.
// TODO: find piece by predicate.

class Piece {
    enum Color { Black, White };
    this(int row, int col, Color color, ChessBoard board) {
        this._color = color;
        this.row = row;
        this.col = col;
        board.setPiece(row, col, this);
    }

    invariant() {
        assert(0 <= row && row < 8);
        assert(0 <= col && col < 8);
    }

    const bool canMove(int new_row, int new_col, ChessBoard board) {
        return (board.board[new_row][new_col] is null &&
                canMoveInt(new_row, new_col, board));
    }

    abstract const bool canMoveInt(int new_row, int new_col, ChessBoard board);

    bool canAttack(int new_row, int new_col, ChessBoard board) {
        return (board.board[new_row][new_col] &&
                board.board[new_row][new_col].color() == oppositeColor() &&
                canMoveInt(new_row, new_col, board));
    }

    void performMove(int new_row, int new_col, ChessBoard board) {
        assert(canMove(new_row, new_col, board));
        board.removePiece(row, col);
        board.setPiece(new_row, new_col, this);
        _firstTurn = false;
    }

    void performAttack(int new_row, int new_col, ChessBoard board) {
        assert(canAttack(new_row, new_col, board));
        board.removePiece(row, col);
        board.removePiece(new_row, new_col);
        board.setPiece(new_row, new_col, this);
        _firstTurn = false;
    }

    const Color color() {
        return _color;
    }

    abstract CellType type();

    bool firstTurn() {
        return _firstTurn;
    }

    const Color oppositeColor() {
        final switch (_color) {
            case Color.White: return Color.Black;
            case Color.Black: return Color.White;
        }
    }
    private:
    int row, col;
    Color _color;
    bool _firstTurn = true;
}

enum CellType {
    Empty, Pawn, Tower, Horse, Bishop, King, Queen
};

char typeToChar(CellType type) {
    final switch(type) {
        case CellType.Empty: return '.';
        case CellType.Pawn: return 'P';
        case CellType.Tower: return 'T';
        case CellType.Horse: return 'H';
        case CellType.Bishop: return 'B';
        case CellType.King: return 'K';
        case CellType.Queen: return 'Q';
    }
}

/// Returns true if there is no obstacle along vertical, horizontal,
/// or diagonal line.
bool noObstacleAlong(int r0, int c0, int r1, int c1, ChessBoard board)
{
    assert(r0 == r1 || c0 == c1 || (abs(r1 - r0) == abs(c1 - c0)));
    int dr = sgn(r1 - r0);
    int dc = sgn(c1 - c0);
    for(int r = r0 + dr, c = c0 + dc; r != r1 || c != c1;
            r += dr, c += dc) {
        if (board.cellType(r, c) != CellType.Empty) {
            writeln("bingo ", r, " ", c);
            return false;
        }
    }
    return true;
}

class Pawn: Piece {
private:
    int turnOfLongStep = -1;
public:
    this(int row, int col, Color color, ChessBoard board) {
        super(row, col, color, board);
    }
    override const bool canMoveInt(int new_row, int new_col, ChessBoard board) {
        if (new_col != col) {
            return false;
        }
        int delta = (color == Piece.Color.White) ? 1 : -1;
        if (_firstTurn) {
            if (new_row == row + 2 * delta) {
                return true;
            }
        }
        if (new_row == row + delta) {
            return true;
        }
        return false;
    }
    override bool canAttack(int new_row, int new_col, ChessBoard board) {
        int delta = (color == Piece.Color.White) ? 1 : -1;
        if (new_row == row + delta && abs(new_col - col) == 1) {
            if (board.cellType(new_row, new_col) != CellType.Empty) {
                return true;
            }
            auto en_passant = cast(Pawn) board.board[row][new_col];
            if (en_passant !is null && en_passant.turnOfLongStep == board.nTurn - 1) {
                return true;
            }
        }
        return false;
    }
    override void performMove(int new_row, int new_col, ChessBoard board) {
        assert(canMove(new_row, new_col, board));
        if (abs(new_row - row) == 2 && firstTurn) {
            turnOfLongStep = board.nTurn;
        }
        super.performMove(new_row, new_col, board);
        if ((color == Piece.Color.White && row == 7) ||
                (color == Piece.Color.Black && row == 0))
        {
            board.board[row][col] = new Queen(row, col, color, board);
        }
    }
    override void performAttack(int new_row, int new_col, ChessBoard board) {
        assert(canAttack(new_row, new_col, board));
        int delta = (color == Piece.Color.White) ? 1 : -1;
        if (new_row == row + delta && abs(new_col - col) == 1) {
            if (board.cellType(new_row, new_col) != CellType.Empty) {
                board.removePiece(row, col);
                board.removePiece(new_row, new_col);
                board.setPiece(new_row, new_col, this);
            }
            auto en_passant = cast(Pawn) board.board[row][new_col];
            if (en_passant !is null && en_passant.turnOfLongStep == board.nTurn - 1) {
                board.removePiece(row, col);
                board.removePiece(row, new_col);
                board.setPiece(new_row, new_col, this);
            }
        }
        _firstTurn = false;
    }
        
    override CellType type() {
        return CellType.Pawn;
    }
}

class Horse: Piece {
    this(int row, int col, Color color, ChessBoard board) {
        super(row, col, color, board);
    }
    override const bool canMoveInt(int new_row, int new_col, ChessBoard board) {
        int d_row = abs(new_row - row);
        int d_col = abs(new_col - col);
        return min(d_row, d_col) == 1 && max(d_row, d_col) == 2;
    }
    override CellType type() {
        return CellType.Horse;
    }
}

class Tower: Piece {
    this(int row, int col, Color color, ChessBoard board) {
        super(row, col, color, board);
    }
    override const bool canMoveInt(int new_row, int new_col, ChessBoard board) {
        if (row == new_row || col == new_col) {
            return noObstacleAlong(row, col, new_row, new_col, board);
        }
        return false;
    }
    override CellType type() {
        return CellType.Tower;
    }
}


class Bishop: Piece {
    this(int row, int col, Color color, ChessBoard board) {
        super(row, col, color, board);
    }
    override const bool canMoveInt(int new_row, int new_col, ChessBoard board) {
        if (abs(row - new_row) == abs(col - new_col)) {
            return noObstacleAlong(row, col, new_row, new_col, board);
        }
        return false;
    }
    override CellType type() {
        return CellType.Bishop;
    }
}

class King: Piece {
    this(int row, int col, Color color, ChessBoard board) {
        super(row, col, color, board);
    }
    override const bool canMoveInt(int new_row, int new_col, ChessBoard board) {
        int abs_dy = abs(row - new_row);
        int abs_dx = abs(col - new_col);
        return (min(abs_dx, abs_dy).among(0, 1) && max(abs_dx, abs_dy) == 1 &&
                !board.cellIsUnderAttack(new_row, new_col, oppositeColor()));

    }
    override CellType type() {
        return CellType.King;
    }
}

class Queen: Piece {
    this(int row, int col, Color color, ChessBoard board) {
        super(row, col, color, board);
    }
    override const bool canMoveInt(int new_row, int new_col, ChessBoard board) {
        int abs_dy = abs(row - new_row);
        int abs_dx = abs(col - new_col);
        if (abs_dx == 0 || abs_dy == 0 || abs_dx == abs_dy) {
            return noObstacleAlong(row, col, new_row, new_col, board);
        }
        return false;
    }
    override CellType type() {
        return CellType.Queen;
    }
}

class ChessBoard {
    private:
        Piece board[8][8];
        int nWhite, nBlack;
        uint nTurn;
        bool blackCheck, whiteCheck;
        bool blackWins, whiteWins;
        bool draw;
        invariant() {
            uint b, w;
            foreach (r; 0..8) {
                foreach (c; 0..8) {
                    auto p = board[r][c];
                    if (p is null) {
                        continue;
                    }
                    assert(p.row == r);
                    assert(p.col == c);
                    if (p.color == Piece.Color.White) {
                        ++w;
                    } else {
                        ++b;
                    }
                }
            }
            assert(w == nWhite);
            assert(b == nBlack);
            assert(blackWins + whiteWins + draw <= 1);
        }
    public:
        enum CastleType {
            Left, Right
        }
        this() {
            new Tower(0, 0, Piece.Color.White, this);
            new Horse(0, 1, Piece.Color.White, this);
            new Bishop(0, 2, Piece.Color.White, this);
            new Queen(0, 3, Piece.Color.White, this);
            new King(0, 4, Piece.Color.White, this);
            new Bishop(0, 5, Piece.Color.White, this);
            new Horse(0, 6, Piece.Color.White, this);
            new Tower(0, 7, Piece.Color.White, this);

            new Tower(7, 0, Piece.Color.Black, this);
            new Horse(7, 1, Piece.Color.Black, this);
            new Bishop(7, 2, Piece.Color.Black, this);
            new Queen(7, 3, Piece.Color.Black, this);
            new King(7, 4, Piece.Color.Black, this);
            new Bishop(7, 5, Piece.Color.Black, this);
            new Horse(7, 6, Piece.Color.Black, this);
            new Tower(7, 7, Piece.Color.Black, this);

            foreach (c; 0..8) {
                new Pawn(1, c, Piece.Color.White, this);
            }

            foreach (c; 0..8) {
                new Pawn(6, c, Piece.Color.Black, this);
            }
            writeln("ChessBoard 3");
        }

        bool endOfGame() {
            return blackWins || whiteWins || draw;
        }


        // TODO: save all states of piceses: firstTurn, turnOfLongStep
        void saveToFile(string fileName) {
            auto f = File(fileName, "w");
            f.writefln("%s %s %s", nTurn, nWhite, nBlack);
            foreach(r; 0..8) {
                foreach(c; 0..8) {
                    char chr = typeToChar(cellType(r, c));
                    if (chr != '.' && cellColor(r,c) == Piece.Color.Black) {
                        chr = std.ascii.toLower(chr);
                    }
                    f.write(chr);
                }
                f.writeln();
            }
            f.writeln();
            foreach(r; 0..8) {
                foreach(c; 0..8) {
                    if (board[r][c] !is null) {
                        f.writef("%s ", cast(int) board[r][c].firstTurn());
                    } else {
                        f.write("0 ");
                    }
                }
                f.writeln();
            }
            foreach(r; 0..8) {
                foreach(c; 0..8) {
                    auto pawn = cast(Pawn) board[r][c];
                    if (pawn !is null) {
                        f.writef("%s ", pawn.turnOfLongStep);
                    } else {
                        f.write("-1 ");
                    }
                }
                f.writeln();
            }
        }

        void loadFromFile(string fileName) {
            auto f = File(fileName, "r");
            f.readf(" %d %d %d ", &nTurn, &nWhite, &nBlack);
            nWhite = nBlack = 0;
            foreach(r; 0..8) {
                foreach(c; 0..8) {
                    board[r][c] = null;
                }
            }
            foreach(r; 0..8) {
                    writeln("#2");
                foreach(c; 0..8) {
                    char chr; //= typeToChar(board.cellType(r, c));
                    f.readf(" %c ", &chr);
                    auto color = chr.isLower() ? Piece.Color.Black : Piece.Color.White;
                    chr = std.ascii.toLower(chr);

                    final switch(chr) {
                        case '.': break;
                        case 'p': new Pawn(r, c, color, this); break;
                        case 't': new Tower(r, c, color, this); break;
                        case 'h': new Horse(r, c, color, this); break;
                        case 'b': new Bishop(r, c, color, this); break;
                        case 'k': new King(r, c, color, this); break;
                        case 'q': new Queen(r, c, color, this); break;
                    }
                    writeln("#1");
                }
            }
            foreach(r; 0..8) {
                foreach(c; 0..8) {
                    int firstTurn;
                    f.readf(" %d ", &firstTurn);
                    if (board[r][c] !is null) {
                        board[r][c]._firstTurn = cast(bool) firstTurn;
                    }
                }
            }
            foreach(r; 0..8) {
                foreach(c; 0..8) {
                    int turnOfLongStep;
                    f.readf(" %d ", &turnOfLongStep);
                    if (turnOfLongStep != -1) {
                        (cast(Pawn) board[r][c]).turnOfLongStep = turnOfLongStep;
                    }
                }
            }
        }

        Piece.Color winnerColor() {
            assert(endOfGame());
            if (nWhite == 0) {
                return Piece.Color.Black;
            } else {
                return Piece.Color.White;
            }
        }

        CellType cellType(int r, int c) {
            if (board[r][c] is null) {
                return CellType.Empty;
            }
            // TODO: used typeID
            return board[r][c].type();
        }

        Piece.Color cellColor(int r, int c) {
            assert(board[r][c] !is null);
            return board[r][c].color();
        }

        bool movePiece(int row, int col, int new_row, int new_col) {
            bool inBoard(int row, int col) {
                return 0 <= row && row < 8 && 0 <= col && col < 8;
            }

            if (!inBoard(row, col)) {
                writeln("Starting coords are outside of the board.");
                return false;
            }

            if (!inBoard(new_row, new_col)) {
                writeln("Target coordinates are outside of the board.");
                return false;
            }

            if (board[row][col] is null) {
                writeln("The board's cell is empty.");
                return false;
            }

            Piece src = cast(Piece) board[row][col];
            Piece.Color playerColor =
                (nTurn % 2 == 0) ? Piece.Color.White : Piece.Color.Black;
            if (src.color() != playerColor) {
                writeln("The piece is of wrong color.");
                return false;
            }

            if (src.canMove(new_row, new_col, this)) {
                src.performMove(new_row, new_col, this);
                ++nTurn;
                afterTurn();
                return true;
            }
            if (src.canAttack(new_row, new_col, this)) {
                src.performAttack(new_row, new_col, this);
                ++nTurn;
                afterTurn();
                return true;
            }
            writeln("Sorry, but this move is imposimple");
            return false;

            assert(0);
        }

        const Piece.Color currentPlayerColor() {
            return (nTurn % 2 == 0) ? Piece.Color.White : Piece.Color.Black;
        }

        bool cellIsUnderAttack(uint row, uint col, Piece.Color color) {
            foreach(r; 0..8) {
                foreach(c; 0..8) {
                    auto piece =  board[r][c];
                    if (piece && piece.color() == color &&
                            piece.canAttack(row, col, this)) {
                        return true;
                    }
                }
            }
            return false;
        }
        
        void afterTurn() {
            uint rk, ck; // King's coords.
            bool check, checkMate;
            King k;
            outer: foreach(r; 0..8) {
                foreach(c; 0..8) {
                    k = cast(King) board[r][c];
                    if (k && k.color() == currentPlayerColor())
                        rk = r;
                        ck = c;
                        break outer;
                }
            }
            check = cellIsUnderAttack(rk, ck, k.oppositeColor());
            auto oldCheck = (nTurn % 2 == 0) ? whiteCheck : blackCheck;
            if (oldCheck && check) {
                (nTurn % 2 == 0) ? whiteWins : blackWins = true;
            }
            (nTurn % 2 == 0) ? whiteCheck : blackCheck = check;
            
            if (!check) {
                return;
            }

            // This block of returns if current player can move any piece.
            foreach(r; 0..8) {
                foreach(c; 0..8) {
                    auto p = board[r][c];
                    if(p is null || p.color() != currentPlayerColor()) {
                        continue;
                    }
                    foreach(r1; 0..8) {
                        foreach(c1; 0..8) {
                            if (r == r1 && c == c1) {
                                continue;
                            }
                            if (p.canMove(r1, c1, this)) {
                                return;
                            }
                        }
                    }
                }
            }
            if (check) {
                (nTurn % 2 == 0) ? blackWins: whiteWins = true;
            } else {
                draw = true;
            }
        }

        void setPiece(int row, int col, Piece p) {
            assert(board[row][col] is null);
            final switch (p.color()) {
                case Piece.Color.White:
                    ++nWhite;
                    break;
                case Piece.Color.Black:
                    ++nBlack;
                    break;
            }
            writeln("setPiece 3");
            board[row][col] = p;
            p.row = row;
            p.col = col;
        }

        void removePiece(int row, int col) {
            assert(board[row][col] !is null);
            auto p = cast(Piece)board[row][col];
            final switch (p.color()) {
                case Piece.Color.White:
                    --nWhite;
                    break;
                case Piece.Color.Black:
                    --nBlack;
                    break;
            }
            board[row][col] = null;
        }

        const bool canDoCasle(CastleType castleType) {
            uint row = (nTurn % 2 == 0) ? 0 : 7;
            King k = cast(King) board[row][4];
            uint towerCol;
            final switch(castleType) {
                case CastleType.Left: towerCol = 0; break;
                case CastleType.Right: towerCol = 7; break;
            }
            Tower t = cast(Tower) board[row][towerCol];
            if (k is null || t is null) {
                return false;
            }
            if (!k.firstTurn() || !t.firstTurn()) {
                return false;
            }
            foreach(col; (min(4, towerCol) + 1)..max(4,towerCol)) {
                if (board[row][col] !is null) {
                    return false;
                }
            }
            return true;
        }

        void doCastle(CastleType castleType) {
            assert(canDoCasle(castleType));
            uint row = (nTurn % 2 == 0) ? 0 : 7;
            King k = cast(King) board[row][4];
            uint towerCol;
            final switch(castleType) {
                case CastleType.Left:
                    towerCol = 0;
                    Tower t = cast(Tower) board[row][towerCol];
                    board[row][2] = k;
                    board[row][3] = t;
                    break;
                case CastleType.Right:
                    towerCol = 7;
                    Tower t = cast(Tower) board[row][towerCol];
                    board[row][6] = k;
                    board[row][5] = t;
                    break;
            }
            ++nTurn;
            afterTurn();
        }
}

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

