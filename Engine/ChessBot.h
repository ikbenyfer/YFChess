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

// Zetbeoordeling (zoals "Beste zet" of "Blunder").
typedef enum {
    CB_RATE_BEST = 0,
    CB_RATE_EXCELLENT,
    CB_RATE_GOOD,
    CB_RATE_INACCURACY,
    CB_RATE_MISTAKE,
    CB_RATE_BLUNDER,
    CB_RATE_FORCED      // er was maar één legale zet
} CBRating;

typedef struct {
    CBRating rating;
    CEMove best;         // beste zet volgens de bot
    int bestScore;       // waardering na de beste zet (centipionnen, kant die zet)
    int playedScore;     // waardering na de gespeelde zet
    double winLoss;      // verlies aan winstkans in procentpunten (0-100)
} CBMoveAnalysis;

// Kansen op winst (0-100) bij een waardering in centipionnen.
double cb_win_percent(int cp);
// Nauwkeurigheid (0-100) van een zet bij een bepaald verlies aan winstkans.
double cb_move_accuracy(double winLoss);
// Beoordeelt de gespeelde zet in stelling `before`. Geeft 1 bij succes.
int cb_analyse_move(const CEPosition *before, const uint64_t *history, int count,
                    CEMove played, int depth, CBMoveAnalysis *out, volatile int *cancel);

#ifdef __cplusplus
}
#endif

#endif
