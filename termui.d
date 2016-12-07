module termui;
@safe

import tui;
import std.conv;
import std.stdio;
import chess;

public class ChessWindow : TWindow {
    this(TApplication parent) {
	this(parent, TWindow.Flag.CENTERED | TWindow.Flag.RESIZABLE);
    }

    private TLabel label, label1;
    private ChessBoard board;
    private int row = -1, col = -1;

    this(TApplication parent, Flag flags) {
	super(parent, "Chess", 0, 0, 60, 23);
        uint row;
        label = addLabel("Message Boxes", 20, 10);
        label1 = addLabel("Message Boxes", 20, 12);
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
                if (r == row && c == col) {
                    cell.foreColor = Color.RED;
                } else {
                    cell.foreColor = Color.WHITE;
                }
                cell.backColor = Color.BLUE;
                application.backend.screen.putCharXY(2 + 2 * c, 2 + 2 * r, cell);
            }
            //addLabel(s, 1, r);
        }
    }

    int temp = 0;
    override void onMouseDown(TMouseEvent event) {
        label.text = dtext(event.x, " ", event.y);
        uint newRow = (event.y - 2) / 2;
        uint newCol = (event.x - 2) / 2;
        if (coordsAreInBoard(newRow, newCol) &&
                board.cellType(newRow, newCol) != CellType.Empty &&
                board.cellColor(newRow, newCol) == board.currentPlayerColor()) {
            row = newRow;
            col = newCol;
            return;
        }
        label.width = 100;
        /*    label.text = dtext("from ", row, " ", col, "to ", newRow, " ", newCol, "###",
              cast(uint)coordsAreInBoard(row, col), cast(uint)coordsAreInBoard(newRow, newCol), " ",
              board.cellType(row, col) != CellType.Empty, " ",
              board.cellColor(row, col) == board.currentPlayerColor(), " ",
              board.cellType(newRow, newCol) == CellType.Empty,
              board.cellType(newRow, newCol) != CellType.Empty
              );
         */
        temp = 1;

        if (coordsAreInBoard(row, col) && coordsAreInBoard(newRow, newCol) &&
                board.cellType(row, col) != CellType.Empty &&
                board.cellColor(row, col) == board.currentPlayerColor() &&
                (board.cellType(newRow, newCol) == CellType.Empty ||  
                 (board.cellType(newRow, newCol) != CellType.Empty && 
                  board.cellColor(newRow, newCol) != board.currentPlayerColor()))) {
            string err;
            board.movePiece(row, col, newRow, newCol, err);
            label1.text = dtext(err, " ", temp++);
            row = col = -1;
        }
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
