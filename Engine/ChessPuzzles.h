// ChessPuzzles.h
// YF Schaak - puzzels (mat in 1, mat in 2) en eindspel-oefeningen.
// Alle puzzels worden in de tests gecontroleerd met de matzoeker.

#ifndef YF_CHESS_PUZZLES_H
#define YF_CHESS_PUZZLES_H

#include "ChessEngine.h"

#ifdef __cplusplus
extern "C" {
#endif

enum { CP_MATE = 0, CP_ENDGAME = 1 };

typedef struct {
    int type;            // CP_MATE of CP_ENDGAME
    int n;               // mat in n zetten, of (eindspel) maximaal aantal eigen zetten
    const char *fen;
    const char *title;   // korte Nederlandse titel
    const char *hint;    // tip in woorden
} CPPuzzle;

int cp_count(void);
const CPPuzzle *cp_get(int index);

// Kan de kant aan zet geforceerd mat zetten in hoogstens n zetten?
int cb_mate_in(const CEPosition *pos, int n);
// Zet deze zet (geforceerd) mat binnen n zetten?
int cb_move_mates_within(const CEPosition *pos, CEMove move, int n);
// Vindt een zet die mat zet binnen n zetten (voor de tip).
int cb_find_mate_move(const CEPosition *pos, int n, CEMove *out);
// Beste verdediging voor de kant aan zet als de tegenstander mat in n dreigt:
// kiest de zet die het mat zo lang mogelijk uitstelt.
int cb_best_defense(const CEPosition *pos, int n, CEMove *out);

#ifdef __cplusplus
}
#endif

#endif
