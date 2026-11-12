// ChessBot.h
// YF Schaak - de computertegenstander (werkt helemaal offline).
// Alfa-bèta-zoeken met instelbare diepte (niveau 1 t/m 5).

#ifndef YF_CHESS_BOT_H
#define YF_CHESS_BOT_H

#include "ChessEngine.h"

#ifdef __cplusplus
extern "C" {
#endif

#define CB_MIN_LEVEL 1
#define CB_MAX_LEVEL 5

// Kiest een zet voor de kant die aan zet is.
// history: sleutels van de partij (huidige stelling als laatste), mag NULL zijn.
// cancel: als *cancel niet 0 wordt, stopt de bot zo snel mogelijk (mag NULL zijn).
// Geeft 1 terug als er een zet is gevonden.
int cb_choose_move(const CEPosition *pos, const uint64_t *history, int count,
                   int level, CEMove *out, volatile int *cancel);

// Zoekt op een vaste diepte zonder toeval en zonder tijdslimiet (voor tests).
int cb_search_depth(const CEPosition *pos, int depth, CEMove *out, int *score);

// Stellingswaardering vanuit de kant die aan zet is (centipionnen).
int cb_evaluate(const CEPosition *pos);

#ifdef __cplusplus
}
#endif

#endif
