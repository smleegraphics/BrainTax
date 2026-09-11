import { Chess, type Square } from 'chess.js';
import { useMemo, useState, type CSSProperties } from 'react';
import { Chessboard, defaultPieces, type PieceDropHandlerArgs, type SquareHandlerArgs } from 'react-chessboard';
import type { LastMove, Uci } from './session';

const PROMOTION_PIECES = ['q', 'r', 'b', 'n'] as const;
const PIECE_NAMES = { q: 'Queen', r: 'Rook', b: 'Bishop', n: 'Knight' } as const;

const LAST_MOVE: CSSProperties = { backgroundColor: 'rgba(155, 199, 0, 0.41)' };
const SELECTED: CSSProperties = { backgroundColor: 'rgba(20, 85, 30, 0.5)' };
const WRONG: CSSProperties = { backgroundColor: 'rgba(220, 60, 50, 0.6)' };
const HINT: CSSProperties = { boxShadow: 'inset 0 0 0 4px rgba(47, 111, 94, 0.95)' };
const MOVE_DOT = 'radial-gradient(rgba(20, 85, 30, 0.4) 0 19%, transparent 21%)';
const CAPTURE_RING = 'radial-gradient(transparent 0 62%, rgba(20, 85, 30, 0.4) 64%)';

interface BoardProps {
  fen: string;
  orientation: 'white' | 'black';
  lastMove: LastMove | null;
  interactive: boolean;
  hintSquare?: string | null;
  wrongSquare?: string | null;
  /** Called with a legal move; return false to snap the piece back. */
  onMove: (uci: Uci) => boolean;
}

/** Chessboard with tap-to-move (primary on phones) and drag-and-drop. */
export function Board({ fen, orientation, lastMove, interactive, hintSquare, wrongSquare, onMove }: BoardProps) {
  const chess = useMemo(() => new Chess(fen), [fen]);
  // Selection and promotion state are tagged with the position they belong to,
  // so they reset automatically whenever the position changes.
  const [selection, setSelection] = useState<{ fen: string; square: Square } | null>(null);
  const [promotion, setPromotion] = useState<{ fen: string; from: Square; to: Square } | null>(null);
  const selected = interactive && selection?.fen === fen ? selection.square : null;
  const pendingPromotion = interactive && promotion?.fen === fen ? promotion : null;

  const targets = useMemo(
    () => (selected ? chess.moves({ square: selected, verbose: true }).map((m) => m.to) : []),
    [chess, selected],
  );

  const attempt = (from: Square, to: Square): boolean => {
    setSelection(null);
    const candidates = chess.moves({ square: from, verbose: true }).filter((m) => m.to === to);
    if (candidates.length === 0) return false;
    if (candidates[0].promotion) {
      setPromotion({ fen, from, to });
      return false;
    }
    return onMove(from + to);
  };

  const handleSquareClick = ({ square }: SquareHandlerArgs) => {
    if (!interactive) return;
    const sq = square as Square;
    if (selected && targets.includes(sq)) {
      attempt(selected, sq);
      return;
    }
    const piece = chess.get(sq);
    setSelection(piece && piece.color === chess.turn() && sq !== selected ? { fen, square: sq } : null);
  };

  const handlePieceDrop = ({ sourceSquare, targetSquare }: PieceDropHandlerArgs) => {
    if (!interactive || !targetSquare) return false;
    return attempt(sourceSquare as Square, targetSquare as Square);
  };

  const squareStyles: Record<string, CSSProperties> = {};
  const style = (square: string, extra: CSSProperties) => {
    squareStyles[square] = { ...squareStyles[square], ...extra };
  };
  if (lastMove) {
    style(lastMove.from, LAST_MOVE);
    style(lastMove.to, LAST_MOVE);
  }
  if (hintSquare) style(hintSquare, HINT);
  if (selected) style(selected, SELECTED);
  for (const t of targets) style(t, { backgroundImage: chess.get(t) ? CAPTURE_RING : MOVE_DOT });
  if (wrongSquare) style(wrongSquare, WRONG);

  const color = chess.turn();

  return (
    <div className="board-wrap">
      <Chessboard
        options={{
          id: 'puzzle-board',
          position: fen,
          boardOrientation: orientation,
          squareStyles,
          lightSquareStyle: { backgroundColor: '#f0d9b5' },
          darkSquareStyle: { backgroundColor: '#b58863' },
          animationDurationInMs: 250,
          allowDrawingArrows: false,
          allowDragging: interactive,
          canDragPiece: ({ piece }) => interactive && piece.pieceType[0] === color,
          onSquareClick: handleSquareClick,
          onPieceDrop: handlePieceDrop,
        }}
      />
      {pendingPromotion && (
        <div className="promotion" role="dialog" aria-label="Choose a promotion piece">
          <div className="promotion-pieces">
            {PROMOTION_PIECES.map((p) => (
              <button
                key={p}
                type="button"
                className="promotion-piece"
                aria-label={PIECE_NAMES[p]}
                onClick={() => {
                  setPromotion(null);
                  onMove(pendingPromotion.from + pendingPromotion.to + p);
                }}
              >
                {defaultPieces[`${color}${p.toUpperCase()}`]()}
              </button>
            ))}
          </div>
          <button type="button" className="link-btn" onClick={() => setPromotion(null)}>
            Cancel
          </button>
        </div>
      )}
    </div>
  );
}
