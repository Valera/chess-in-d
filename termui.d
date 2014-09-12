import tui;
import std.conv;
import std.stdio;
import chess;

public class ChessWindow : TWindow {
    this(TApplication parent) {
	this(parent, TWindow.Flag.CENTERED | TWindow.Flag.RESIZABLE);
    }

    private TLabel label;
    private ChessBoard board;

    this(TApplication parent, Flag flags) {
	super(parent, "Chess", 0, 0, 60, 23);
        uint row;
        label = addLabel("Message Boxes", 20, 10);
        board = new ChessBoard;
    }

    override void draw() {
        super.draw();

        drawBoard();
    }

    void drawBoard() {
        foreach(r; 0..8) {
            foreach(c; 0..8) {
                /*wchar ch = typeToChar(board.cellType(r, c));
                auto cell = new Cell('\u2654');
                cell.foreColor = Color.WHITE;
                cell.backColor = Color.BLUE;
                if (ch != '.' && board.cellColor(r,c) == Piece.Color.Black) {
                    ch = std.ascii.toLower(ch);
                    cell.foreColor = Color.BLACK;
                }
                if (ch == '.') {
                    cell.foreColor = Color.WHITE;
                }
                */
                auto cell = new Cell(board.cellUtfChar(r, c));
                cell.foreColor = Color.WHITE;
                cell.backColor = Color.BLUE;
                application.backend.screen.putCharXY(2 + 2 * c, 2 + 2 * r, cell);
            }
            //addLabel(s, 1, r);
        }
    }

    override void onMouseDown(TMouseEvent event) {
        label.text = dtext(event.x, " ", event.y);
    }
}

public class MyApplication : TApplication {

    this() {
        super();

        new ChessWindow(this);

        addFileMenu();
        addWindowMenu();
    }
}

void main(string [] args) {
    MyApplication app = new MyApplication();
    app.run();
}
