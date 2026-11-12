// ChessEndgame.h
// YF Schaak - eindspelen met weinig stukken: een exacte tabel voor koning + pion tegen koning
// en een maker van nieuwe, winnende eindspel-oefeningen (werkt zonder internet).

#ifndef YF_CHESS_ENDGAME_H
#define YF_CHESS_ENDGAME_H

#include "ChessEngine.h"

#ifdef __cplusplus
extern "C" {
#endif

// Koning + pion tegen koning: 1 = de kant met de pion wint, 0 = remise, -1 = geen K+P tegen K.
int ce_kpk_result(const CEPosition *p);

enum {
    EG_MIX = 0,          // willekeurig een van de soorten hieronder
    EG_QUEEN,            // koning + dame tegen koning
    EG_ROOK,             // koning + toren tegen koning
    EG_PAWN,             // koning + pion tegen koning (alleen winnende stellingen)
    EG_TWO_ROOKS,        // twee torens tegen koning
    EG_BISHOPS,          // twee lopers tegen koning
    EG_QUEEN_VS_PIECE,   // dame tegen paard of loper
    EG_KIND_COUNT
};

// Maakt een nieuwe winnende eindspel-oefening. De winnende kant is aan zet.
// seed wordt bijgewerkt. Geeft 1 bij succes.
int ce_generate_endgame(int kind, uint32_t *seed, CEPosition *out, int *moveLimit,
                        const char **title, const char **hint);

#ifdef __cplusplus
}
#endif

#endif
