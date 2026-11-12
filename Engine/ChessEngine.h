// ChessEngine.h
// YF Schaak - de schaakregels (los van de schermen).
// Gewone C, zodat dezelfde code op de iPad en in de tests op Linux draait.

#ifndef YF_CHESS_ENGINE_H
#define YF_CHESS_ENGINE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

enum { CE_WHITE = 0, CE_BLACK = 1 };
enum { CE_EMPTY = 0, CE_PAWN = 1, CE_KNIGHT = 2, CE_BISHOP = 3, CE_ROOK = 4, CE_QUEEN = 5, CE_KING = 6 };

// Een stuk = soort | (kleur << 3). Leeg veld = 0.
#define CE_PIECE(color, type) ((uint8_t)((type) | ((color) << 3)))
#define CE_TYPE(p) ((p) & 7)
#define CE_COLOR(p) (((p) >> 3) & 1)
// Velden: a1 = 0, b1 = 1, ..., h8 = 63.
#define CE_SQ(file, rank) ((rank) * 8 + (file))
#define CE_FILE(sq) ((sq) & 7)
#define CE_RANK(sq) ((sq) >> 3)

enum { CE_CASTLE_WK = 1, CE_CASTLE_WQ = 2, CE_CASTLE_BK = 4, CE_CASTLE_BQ = 8 };
enum { CE_FLAG_CAPTURE = 1, CE_FLAG_EP = 2, CE_FLAG_CASTLE = 4, CE_FLAG_DOUBLE = 8, CE_FLAG_PROMO = 16 };

// Ruim genoeg, ook voor eigen stellingen met heel veel dames.
#define CE_MAX_MOVES 1024

typedef struct {
    uint8_t from, to, promo, flags;
} CEMove;

typedef struct {
    uint8_t board[64];
    int side;        // CE_WHITE of CE_BLACK: wie is aan zet
    int ep;          // en-passantveld of -1
    int castling;    // bits CE_CASTLE_*
    int halfmove;    // zetten sinds laatste slag of pionzet (50-zettenregel)
    int fullmove;
    uint64_t hash;   // Zobrist-sleutel (voor herhaling)
} CEPosition;

typedef enum {
    CE_ONGOING = 0,
    CE_CHECKMATE,
    CE_STALEMATE,
    CE_DRAW_FIFTY,
    CE_DRAW_REPETITION,
    CE_DRAW_MATERIAL
} CEStatus;

void ce_init(void);
void ce_clear(CEPosition *p);
void ce_start(CEPosition *p);
int ce_from_fen(CEPosition *p, const char *fen);           // 1 = gelukt
void ce_to_fen(const CEPosition *p, char *buf, size_t n);
uint64_t ce_compute_hash(const CEPosition *p);
void ce_fix_castling(CEPosition *p);   // haalt rokaderechten weg die niet kunnen
void ce_auto_castling(CEPosition *p);  // geeft rokaderechten als koning en toren op hun beginveld staan

int ce_king_square(const CEPosition *p, int color);      // -1 als er geen koning is
int ce_attacked(const CEPosition *p, int sq, int byColor);
int ce_in_check(const CEPosition *p, int color);

int ce_gen_pseudo(const CEPosition *p, CEMove *moves, int capturesOnly);
int ce_gen_legal(const CEPosition *p, CEMove *moves);
void ce_make(CEPosition *p, CEMove m);  // voert een (pseudo)legale zet uit
int ce_find_move(const CEPosition *p, int from, int to, int promo, CEMove *out);
int ce_parse_uci(const CEPosition *p, const char *uci, CEMove *out);
void ce_move_to_uci(CEMove m, char *buf, size_t n);
void ce_move_to_san(const CEPosition *before, CEMove m, char *buf, size_t n);

uint64_t ce_perft(const CEPosition *p, int depth);
int ce_insufficient_material(const CEPosition *p);
// history: Zobrist-sleutels van alle stellingen in de partij, de huidige als laatste.
CEStatus ce_status(const CEPosition *p, const uint64_t *history, int count);
// Controle voor eigen stellingen. 1 = geldig; anders staat de reden (Nederlands) in err.
int ce_validate(const CEPosition *p, char *err, size_t n);

#ifdef __cplusplus
}
#endif

#endif
