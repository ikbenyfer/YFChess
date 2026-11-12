// ChessEndgame.c
// YF Schaak - exacte tabel voor koning + pion tegen koning (terugrekenen) en een eindspel-maker.

#include "ChessEndgame.h"
#include "ChessBot.h"
#include <string.h>
#include <pthread.h>

enum { KPK_UNKNOWN = 0, KPK_INVALID = 1, KPK_DRAW = 2, KPK_WIN = 3 };

// Index: zet (0 = wit/pion aan zet, 1 = zwart), witte koning, zwarte koning, pionveld.
static uint8_t KPK[2 * 64 * 64 * 64];
static pthread_once_t kpk_once = PTHREAD_ONCE_INIT;

static int kidx(int stm, int wk, int bk, int ps) {
    return ((stm * 64 + wk) * 64 + bk) * 64 + ps;
}

static int dist(int a, int b) {
    int df = CE_FILE(a) - CE_FILE(b), dr = CE_RANK(a) - CE_RANK(b);
    if (df < 0) df = -df;
    if (dr < 0) dr = -dr;
    return df > dr ? df : dr;
}

// Valt een witte pion op ps het veld sq aan?
static int pawn_attacks(int ps, int sq) {
    if (CE_RANK(sq) != CE_RANK(ps) + 1) return 0;
    int df = CE_FILE(sq) - CE_FILE(ps);
    return df == 1 || df == -1;
}

static void kpk_build(void) {
    memset(KPK, KPK_UNKNOWN, sizeof(KPK));
    // Beginwaarden.
    for (int stm = 0; stm < 2; stm++)
    for (int wk = 0; wk < 64; wk++)
    for (int bk = 0; bk < 64; bk++)
    for (int ps = 0; ps < 64; ps++) {
        int i = kidx(stm, wk, bk, ps);
        int pr = CE_RANK(ps);
        if (pr < 1 || pr > 6 || wk == bk || wk == ps || bk == ps || dist(wk, bk) <= 1 ||
            (stm == 0 && pawn_attacks(ps, bk))) {
            KPK[i] = KPK_INVALID;
            continue;
        }
        if (stm == 0) {
            int promo = ps + 8;
            if (pr == 6 && wk != promo && bk != promo && (dist(bk, promo) > 1 || dist(wk, promo) == 1))
                KPK[i] = KPK_WIN;   // veilig promoveren
        } else {
            // Zwart kan de onbeschermde pion slaan.
            if (dist(bk, ps) == 1 && dist(wk, ps) > 1) { KPK[i] = KPK_DRAW; continue; }
            int moves = 0;
            for (int t = 0; t < 64; t++) {
                if (dist(t, bk) != 1 || dist(t, wk) <= 1 || pawn_attacks(ps, t) || t == ps) continue;
                moves++;
            }
            if (moves == 0) KPK[i] = pawn_attacks(ps, bk) ? KPK_WIN : KPK_DRAW;   // mat of pat
        }
    }
    // Terugrekenen tot er niets meer verandert.
    int changed = 1;
    while (changed) {
        changed = 0;
        for (int stm = 0; stm < 2; stm++)
        for (int wk = 0; wk < 64; wk++)
        for (int bk = 0; bk < 64; bk++)
        for (int ps = 8; ps < 56; ps++) {
            int i = kidx(stm, wk, bk, ps);
            if (KPK[i] != KPK_UNKNOWN) continue;
            int result;
            if (stm == 0) {
                int anyWin = 0, allDraw = 1;
                for (int t = 0; t < 64; t++) {
                    if (dist(t, wk) != 1 || dist(t, bk) <= 1 || t == ps) continue;
                    uint8_t r = KPK[kidx(1, t, bk, ps)];
                    if (r == KPK_WIN) anyWin = 1;
                    if (r != KPK_DRAW && r != KPK_INVALID) allDraw = 0;
                }
                int push = ps + 8;
                if (CE_RANK(ps) < 6 && push != wk && push != bk) {
                    uint8_t r = KPK[kidx(1, wk, bk, push)];
                    if (r == KPK_WIN) anyWin = 1;
                    if (r != KPK_DRAW && r != KPK_INVALID) allDraw = 0;
                    int dbl = ps + 16;
                    if (CE_RANK(ps) == 1 && dbl != wk && dbl != bk) {
                        r = KPK[kidx(1, wk, bk, dbl)];
                        if (r == KPK_WIN) anyWin = 1;
                        if (r != KPK_DRAW && r != KPK_INVALID) allDraw = 0;
                    }
                }
                result = anyWin ? KPK_WIN : (allDraw ? KPK_DRAW : KPK_UNKNOWN);
            } else {
                int anyDraw = 0, allWin = 1;
                for (int t = 0; t < 64; t++) {
                    if (dist(t, bk) != 1 || dist(t, wk) <= 1 || pawn_attacks(ps, t) || t == ps) continue;
                    uint8_t r = KPK[kidx(0, wk, t, ps)];
                    if (r == KPK_DRAW) anyDraw = 1;
                    if (r != KPK_WIN) allWin = 0;
                }
                result = anyDraw ? KPK_DRAW : (allWin ? KPK_WIN : KPK_UNKNOWN);
            }
            if (result != KPK_UNKNOWN) { KPK[i] = (uint8_t)result; changed = 1; }
        }
    }
}

int ce_kpk_result(const CEPosition *p) {
    int wk = -1, bk = -1, ps = -1, pawnColor = -1, others = 0;
    for (int sq = 0; sq < 64; sq++) {
        uint8_t pc = p->board[sq];
        if (!pc) continue;
        int t = CE_TYPE(pc), c = CE_COLOR(pc);
        if (t == CE_KING) { if (c == CE_WHITE) wk = sq; else bk = sq; }
        else if (t == CE_PAWN && ps < 0) { ps = sq; pawnColor = c; }
        else others++;
    }
    if (wk < 0 || bk < 0 || ps < 0 || others) return -1;
    int strong = pawnColor == CE_WHITE ? wk : bk;
    int weak = pawnColor == CE_WHITE ? bk : wk;
    int pawn = ps;
    if (pawnColor == CE_BLACK) {   // spiegelen zodat de pion "wit" is
        strong ^= 56;
        weak ^= 56;
        pawn ^= 56;
    }
    int stm = p->side == pawnColor ? 0 : 1;
    pthread_once(&kpk_once, kpk_build);
    uint8_t r = KPK[kidx(stm, strong, weak, pawn)];
    if (r == KPK_INVALID) return -1;
    return r == KPK_WIN ? 1 : 0;
}

// ---- Maker ----

static uint32_t eg_rand(uint32_t *s) {
    uint32_t x = *s ? *s : 0x9E3779B9u;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *s = x;
    return x;
}

static int eg_place(CEPosition *p, uint8_t piece, uint32_t *s, int pawn) {
    for (int tries = 0; tries < 200; tries++) {
        int sq = (int)(eg_rand(s) % 64);
        if (p->board[sq]) continue;
        if (pawn && (CE_RANK(sq) == 0 || CE_RANK(sq) == 7)) continue;
        p->board[sq] = piece;
        return sq;
    }
    return -1;
}

static int sq_color(int sq) {
    return (CE_FILE(sq) + CE_RANK(sq)) & 1;
}

int ce_generate_endgame(int kind, uint32_t *seed, CEPosition *out, int *moveLimit,
                        const char **title, const char **hint) {
    ce_init();
    if (kind <= EG_MIX || kind >= EG_KIND_COUNT) kind = 1 + (int)(eg_rand(seed) % (EG_KIND_COUNT - 1));
    for (int attempt = 0; attempt < 3000; attempt++) {
        CEPosition p;
        ce_clear(&p);
        int wk = eg_place(&p, CE_PIECE(CE_WHITE, CE_KING), seed, 0);
        int bk = eg_place(&p, CE_PIECE(CE_BLACK, CE_KING), seed, 0);
        if (wk < 0 || bk < 0 || dist(wk, bk) <= 1) continue;
        int ok = 1;
        switch (kind) {
            case EG_QUEEN: ok = eg_place(&p, CE_PIECE(CE_WHITE, CE_QUEEN), seed, 0) >= 0; break;
            case EG_ROOK: ok = eg_place(&p, CE_PIECE(CE_WHITE, CE_ROOK), seed, 0) >= 0; break;
            case EG_PAWN: {
                int ps = eg_place(&p, CE_PIECE(CE_WHITE, CE_PAWN), seed, 1);
                ok = ps >= 0 && CE_RANK(ps) <= 4;   // niet al bijna klaar
                break;
            }
            case EG_TWO_ROOKS:
                ok = eg_place(&p, CE_PIECE(CE_WHITE, CE_ROOK), seed, 0) >= 0 &&
                     eg_place(&p, CE_PIECE(CE_WHITE, CE_ROOK), seed, 0) >= 0;
                break;
            case EG_BISHOPS: {
                int a = eg_place(&p, CE_PIECE(CE_WHITE, CE_BISHOP), seed, 0);
                int b = eg_place(&p, CE_PIECE(CE_WHITE, CE_BISHOP), seed, 0);
                ok = a >= 0 && b >= 0 && sq_color(a) != sq_color(b);
                break;
            }
            default: {
                ok = eg_place(&p, CE_PIECE(CE_WHITE, CE_QUEEN), seed, 0) >= 0 &&
                     eg_place(&p, CE_PIECE(CE_BLACK, (eg_rand(seed) & 1) ? CE_KNIGHT : CE_BISHOP), seed, 0) >= 0;
                break;
            }
        }
        if (!ok) continue;
        p.side = CE_WHITE;
        p.castling = 0;
        p.ep = -1;
        p.hash = ce_compute_hash(&p);
        char err[200];
        if (!ce_validate(&p, err, sizeof err)) continue;
        if (ce_in_check(&p, CE_WHITE)) continue;
        if (ce_status(&p, NULL, 0) != CE_ONGOING) continue;
        // Niet twee witte stukken tegelijk onbeschermd aangevallen (anders gaat er een verloren).
        int hanging = 0;
        for (int sq = 0; sq < 64; sq++) {
            uint8_t pc = p.board[sq];
            if (!pc || CE_COLOR(pc) != CE_WHITE || CE_TYPE(pc) == CE_KING) continue;
            if (ce_attacked(&p, sq, CE_BLACK) && !ce_attacked(&p, sq, CE_WHITE)) hanging++;
        }
        if (hanging >= 2) continue;
        if (kind == EG_PAWN) {
            if (ce_kpk_result(&p) != 1) continue;
        } else {
            // Controle met de bot: wit moet duidelijk beter staan.
            CEMove m;
            int score = 0;
            if (!cb_search_depth(&p, 2, &m, &score) || score < 400) continue;
            // De koning mag niet al bijna mat staan (dan is het te makkelijk).
            if (score > 90000) continue;
        }
        int limit;
        const char *t, *h;
        switch (kind) {
            case EG_QUEEN: limit = 20; t = "Koning + dame tegen koning";
                h = "Maak het hok van de koning kleiner met je dame en haal je koning erbij. Pas op voor pat!"; break;
            case EG_ROOK: limit = 35; t = "Koning + toren tegen koning";
                h = "Duw de koning met je toren naar de rand. Je eigen koning moet meehelpen."; break;
            case EG_PAWN: limit = 45; t = "Koning + pion tegen koning";
                h = "Je koning moet voor de pion lopen. Maak een dame en zet daarna mat."; break;
            case EG_TWO_ROOKS: limit = 15; t = "Twee torens tegen koning";
                h = "Torenladder: de ene toren sluit een rij af, de andere geeft schaak op de volgende rij."; break;
            case EG_BISHOPS: limit = 50; t = "Twee lopers tegen koning";
                h = "De lopers maken samen een muur. Duw de koning naar een hoek."; break;
            default: limit = 35; t = "Dame tegen licht stuk";
                h = "Pas op voor vorken. Sluit de koning in of win het stuk."; break;
        }
        // Soms speel je met zwart: bord spiegelen en kleuren wisselen.
        if (eg_rand(seed) % 3 == 0) {
            CEPosition q;
            ce_clear(&q);
            for (int sq = 0; sq < 64; sq++) {
                uint8_t pc = p.board[sq];
                if (pc) q.board[sq ^ 56] = CE_PIECE(CE_COLOR(pc) ^ 1, CE_TYPE(pc));
            }
            q.side = CE_BLACK;
            q.hash = ce_compute_hash(&q);
            p = q;
        }
        *out = p;
        if (moveLimit) *moveLimit = limit;
        if (title) *title = t;
        if (hint) *hint = h;
        return 1;
    }
    return 0;
}
