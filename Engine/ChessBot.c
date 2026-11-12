// ChessBot.c
// YF Schaak - eigen schaakbot: negamax met alfa-bèta, rustig-zoeken (slagen),
// zetvolgorde (slagen eerst, killer-zetten) en iteratief verdiepen met tijdslimiet.

#include "ChessBot.h"
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <math.h>

#define CB_INF 1000000
#define CB_MATE 100000
#define CB_MAX_PLY 64
#define CB_HIST_MAX 1024
#define CB_HIST_KEEP 900

static const int VAL[7] = { 0, 100, 320, 330, 500, 900, 0 };

// Tabellen vanuit wit gezien, eerste rij = rij 8.
static const int PST_PAWN[64] = {
     0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-20,-20, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0 };
static const int PST_KNIGHT[64] = {
   -50,-40,-30,-30,-30,-30,-40,-50,
   -40,-20,  0,  0,  0,  0,-20,-40,
   -30,  0, 10, 15, 15, 10,  0,-30,
   -30,  5, 15, 20, 20, 15,  5,-30,
   -30,  0, 15, 20, 20, 15,  0,-30,
   -30,  5, 10, 15, 15, 10,  5,-30,
   -40,-20,  0,  5,  5,  0,-20,-40,
   -50,-40,-30,-30,-30,-30,-40,-50 };
static const int PST_BISHOP[64] = {
   -20,-10,-10,-10,-10,-10,-10,-20,
   -10,  0,  0,  0,  0,  0,  0,-10,
   -10,  0,  5, 10, 10,  5,  0,-10,
   -10,  5,  5, 10, 10,  5,  5,-10,
   -10,  0, 10, 10, 10, 10,  0,-10,
   -10, 10, 10, 10, 10, 10, 10,-10,
   -10,  5,  0,  0,  0,  0,  5,-10,
   -20,-10,-10,-10,-10,-10,-10,-20 };
static const int PST_ROOK[64] = {
     0,  0,  0,  0,  0,  0,  0,  0,
     5, 10, 10, 10, 10, 10, 10,  5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
     0,  0,  0,  5,  5,  0,  0,  0 };
static const int PST_QUEEN[64] = {
   -20,-10,-10, -5, -5,-10,-10,-20,
   -10,  0,  0,  0,  0,  0,  0,-10,
   -10,  0,  5,  5,  5,  5,  0,-10,
    -5,  0,  5,  5,  5,  5,  0, -5,
     0,  0,  5,  5,  5,  5,  0, -5,
   -10,  5,  5,  5,  5,  5,  0,-10,
   -10,  0,  5,  0,  0,  0,  0,-10,
   -20,-10,-10, -5, -5,-10,-10,-20 };
static const int PST_KING_MID[64] = {
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -20,-30,-30,-40,-40,-30,-30,-20,
   -10,-20,-20,-20,-20,-20,-20,-10,
    20, 20,  0,  0,  0,  0, 20, 20,
    20, 30, 10,  0,  0, 10, 30, 20 };
static const int PST_KING_END[64] = {
   -50,-40,-30,-20,-20,-30,-40,-50,
   -30,-20,-10,  0,  0,-10,-20,-30,
   -30,-10, 20, 30, 30, 20,-10,-30,
   -30,-10, 30, 40, 40, 30,-10,-30,
   -30,-10, 30, 40, 40, 30,-10,-30,
   -30,-10, 20, 30, 30, 20,-10,-30,
   -30,-30,  0,  0,  0,  0,-30,-30,
   -50,-30,-30,-30,-30,-30,-30,-50 };

static const int *PST[7] = { NULL, PST_PAWN, PST_KNIGHT, PST_BISHOP, PST_ROOK, PST_QUEEN, NULL };

static int center_dist(int sq) {
    int f = CE_FILE(sq), r = CE_RANK(sq);
    int df = f < 4 ? 3 - f : f - 4;
    int dr = r < 4 ? 3 - r : r - 4;
    return df + dr;
}

int cb_evaluate(const CEPosition *p) {
    int score[2] = {0, 0}, npm[2] = {0, 0}, mat[2] = {0, 0}, bishops[2] = {0, 0};
    int ksq[2] = {-1, -1};
    for (int sq = 0; sq < 64; sq++) {
        uint8_t pc = p->board[sq];
        if (!pc) continue;
        int col = CE_COLOR(pc), type = CE_TYPE(pc);
        int f = CE_FILE(sq), r = CE_RANK(sq);
        int idx = col == CE_WHITE ? (7 - r) * 8 + f : r * 8 + f;
        if (type == CE_KING) { ksq[col] = sq; continue; }
        score[col] += VAL[type] + PST[type][idx];
        mat[col] += VAL[type];
        if (type != CE_PAWN) npm[col] += VAL[type];
        if (type == CE_BISHOP) bishops[col]++;
    }
    int endgame = npm[0] + npm[1] <= 2600;
    for (int c = 0; c < 2; c++) {
        if (ksq[c] >= 0) {
            int f = CE_FILE(ksq[c]), r = CE_RANK(ksq[c]);
            int idx = c == CE_WHITE ? (7 - r) * 8 + f : r * 8 + f;
            score[c] += endgame ? PST_KING_END[idx] : PST_KING_MID[idx];
        }
        if (bishops[c] >= 2) score[c] += 30;
    }
    // Hulp om te leren matzetten: de verliezende koning naar de rand duwen.
    int diff = mat[0] - mat[1];
    if (ksq[0] >= 0 && ksq[1] >= 0) {
        int win = -1;
        if (diff >= 400 && npm[1] <= 330) win = 0;
        else if (diff <= -400 && npm[0] <= 330) win = 1;
        if (win >= 0) {
            int lose = win ^ 1;
            int fd = CE_FILE(ksq[0]) - CE_FILE(ksq[1]); if (fd < 0) fd = -fd;
            int rd = CE_RANK(ksq[0]) - CE_RANK(ksq[1]); if (rd < 0) rd = -rd;
            score[win] += 10 * center_dist(ksq[lose]) + 4 * (14 - fd - rd);
        }
    }
    int total = score[0] - score[1];
    return p->side == CE_WHITE ? total : -total;
}

typedef struct {
    CEMove moves[CB_MAX_PLY][CE_MAX_MOVES];
    int scores[CB_MAX_PLY][CE_MAX_MOVES];
    CEMove killers[CB_MAX_PLY][2];
    uint64_t hashes[CB_HIST_MAX];
    int nh;
    long nodes;
    double deadline;
    int useDeadline;
    int stop;
    volatile int *cancel;
} SearchCtx;

static double now_ms(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec * 1000.0 + (double)tv.tv_usec / 1000.0;
}

static void check_time(SearchCtx *c) {
    if (c->cancel && *c->cancel) c->stop = 1;
    if (c->useDeadline && now_ms() > c->deadline) c->stop = 1;
}

static int same_move(CEMove a, CEMove b) {
    return a.from == b.from && a.to == b.to && a.promo == b.promo;
}

static void score_moves(SearchCtx *c, const CEPosition *p, int ply, int n) {
    CEMove *mv = c->moves[ply];
    int *sc = c->scores[ply];
    for (int i = 0; i < n; i++) {
        int s = 0;
        if (mv[i].flags & CE_FLAG_CAPTURE) {
            int victim = (mv[i].flags & CE_FLAG_EP) ? CE_PAWN : CE_TYPE(p->board[mv[i].to]);
            int attacker = CE_TYPE(p->board[mv[i].from]);
            s = 100000 + VAL[victim] * 10 - VAL[attacker] / 10;
        }
        if (mv[i].flags & CE_FLAG_PROMO) s += 90000 + VAL[mv[i].promo];
        if (!s) {
            if (same_move(mv[i], c->killers[ply][0])) s = 50000;
            else if (same_move(mv[i], c->killers[ply][1])) s = 49000;
        }
        sc[i] = s;
    }
}

static void pick(SearchCtx *c, int ply, int i, int n) {
    int *sc = c->scores[ply];
    CEMove *mv = c->moves[ply];
    int best = i;
    for (int j = i + 1; j < n; j++)
        if (sc[j] > sc[best]) best = j;
    if (best != i) {
        int ts = sc[i]; sc[i] = sc[best]; sc[best] = ts;
        CEMove tm = mv[i]; mv[i] = mv[best]; mv[best] = tm;
    }
}

static int is_repetition(SearchCtx *c, const CEPosition *p) {
    int last = c->nh - 1;   // de huidige stelling
    int lowest = last - p->halfmove;
    if (lowest < 0) lowest = 0;
    for (int i = last - 2; i >= lowest; i -= 2)
        if (c->hashes[i] == p->hash) return 1;
    return 0;
}

static int qsearch(SearchCtx *c, const CEPosition *p, int alpha, int beta, int ply) {
    c->nodes++;
    if ((c->nodes & 1023) == 0) check_time(c);
    if (c->stop) return 0;
    int stand = cb_evaluate(p);
    if (stand >= beta) return stand;
    if (stand > alpha) alpha = stand;
    if (ply >= CB_MAX_PLY - 1) return stand;
    CEMove *mv = c->moves[ply];
    int n = ce_gen_pseudo(p, mv, 1);
    score_moves(c, p, ply, n);
    int us = p->side;
    int ks = ce_king_square(p, us);
    for (int i = 0; i < n; i++) {
        pick(c, ply, i, n);
        CEMove m = mv[i];
        CEPosition q = *p;
        ce_make(&q, m);
        int k = CE_TYPE(p->board[m.from]) == CE_KING ? m.to : ks;
        if (k >= 0 && ce_attacked(&q, k, us ^ 1)) continue;
        int s = -qsearch(c, &q, -beta, -alpha, ply + 1);
        if (c->stop) return 0;
        if (s >= beta) return s;
        if (s > alpha) alpha = s;
    }
    return alpha;
}

static int search(SearchCtx *c, const CEPosition *p, int depth, int alpha, int beta, int ply) {
    if (ply > 0) {
        if (p->halfmove >= 100) return 0;
        if (is_repetition(c, p)) return 0;
        if (ce_insufficient_material(p)) return 0;
    }
    int us = p->side;
    int ks = ce_king_square(p, us);
    int inCheck = ks >= 0 && ce_attacked(p, ks, us ^ 1);
    if (inCheck && ply < CB_MAX_PLY - 10) depth++;
    if (depth <= 0 || ply >= CB_MAX_PLY - 2) return qsearch(c, p, alpha, beta, ply);
    c->nodes++;
    if ((c->nodes & 1023) == 0) check_time(c);
    if (c->stop) return 0;

    CEMove *mv = c->moves[ply];
    int n = ce_gen_pseudo(p, mv, 0);
    score_moves(c, p, ply, n);
    int legal = 0;
    int best = -CB_INF;
    for (int i = 0; i < n; i++) {
        pick(c, ply, i, n);
        CEMove m = mv[i];
        CEPosition q = *p;
        ce_make(&q, m);
        int k = CE_TYPE(p->board[m.from]) == CE_KING ? m.to : ks;
        if (k >= 0 && ce_attacked(&q, k, us ^ 1)) continue;
        legal++;
        c->hashes[c->nh++] = q.hash;
        int s = -search(c, &q, depth - 1, -beta, -alpha, ply + 1);
        c->nh--;
        if (c->stop) return 0;
        if (s > best) best = s;
        if (s > alpha) alpha = s;
        if (alpha >= beta) {
            if (!(m.flags & (CE_FLAG_CAPTURE | CE_FLAG_PROMO)) && !same_move(m, c->killers[ply][0])) {
                c->killers[ply][1] = c->killers[ply][0];
                c->killers[ply][0] = m;
            }
            break;
        }
    }
    if (!legal) return inCheck ? -CB_MATE + ply : 0;
    return best;
}

static uint32_t rng_state = 0;
static uint32_t next_rand(void) {
    if (!rng_state) rng_state = (uint32_t)now_ms() | 1u;
    rng_state ^= rng_state << 13;
    rng_state ^= rng_state >> 17;
    rng_state ^= rng_state << 5;
    return rng_state;
}

static int root_search(const CEPosition *root, const uint64_t *hist, int count,
                       int maxDepth, int timeMs, int noise, volatile int *cancel,
                       CEMove *out, int *outScore) {
    ce_init();
    CEMove rootMoves[CE_MAX_MOVES];
    int rs[CE_MAX_MOVES];
    int n = ce_gen_legal(root, rootMoves);
    if (n == 0) return 0;
    if (n == 1 && noise == 0 && timeMs > 0) {
        *out = rootMoves[0];
        if (outScore) *outScore = 0;
        return 1;
    }
    SearchCtx *c = (SearchCtx *)calloc(1, sizeof(SearchCtx));
    if (!c) { *out = rootMoves[0]; return 1; }
    c->cancel = cancel;
    // Partijgeschiedenis overnemen (voor herhaling van zetten).
    int start = count > CB_HIST_KEEP ? count - CB_HIST_KEEP : 0;
    for (int i = start; hist && i < count; i++) c->hashes[c->nh++] = hist[i];
    if (c->nh == 0 || c->hashes[c->nh - 1] != root->hash) c->hashes[c->nh++] = root->hash;

    // Beginvolgorde: slagen en promoties eerst.
    for (int i = 0; i < n; i++) {
        int s = 0;
        if (rootMoves[i].flags & CE_FLAG_CAPTURE) {
            int victim = (rootMoves[i].flags & CE_FLAG_EP) ? CE_PAWN : CE_TYPE(root->board[rootMoves[i].to]);
            s = VAL[victim] * 10 - VAL[CE_TYPE(root->board[rootMoves[i].from])] / 10 + 10000;
        }
        if (rootMoves[i].flags & CE_FLAG_PROMO) s += 9000 + VAL[rootMoves[i].promo];
        rs[i] = s;
    }
    for (int i = 1; i < n; i++) {
        int j = i;
        while (j > 0 && rs[j] > rs[j - 1]) {
            int ts = rs[j]; rs[j] = rs[j - 1]; rs[j - 1] = ts;
            CEMove tm = rootMoves[j]; rootMoves[j] = rootMoves[j - 1]; rootMoves[j - 1] = tm;
            j--;
        }
    }

    double startTime = now_ms();
    c->deadline = startTime + (timeMs > 0 ? timeMs : 1e12);
    CEMove best = rootMoves[0];
    int bestScore = 0;
    int found = 0;
    for (int d = 1; d <= maxDepth; d++) {
        c->useDeadline = (d > 1 && timeMs > 0);
        int alpha = -CB_INF;
        int iterBestScore = -CB_INF;
        CEMove iterBest = rootMoves[0];
        int completed = 1;
        for (int i = 0; i < n; i++) {
            CEPosition q = *root;
            ce_make(&q, rootMoves[i]);
            c->hashes[c->nh++] = q.hash;
            int s;
            if (noise > 0) s = -search(c, &q, d - 1, -CB_INF, CB_INF, 1);
            else s = -search(c, &q, d - 1, -CB_INF, -alpha, 1);
            c->nh--;
            if (c->stop) { completed = 0; break; }
            if (noise > 0 && s > -CB_MATE + 1000 && s < CB_MATE - 1000)
                s += (int)(next_rand() % (uint32_t)(noise + 1)) - noise / 2;
            rs[i] = s;
            if (s > iterBestScore) { iterBestScore = s; iterBest = rootMoves[i]; }
            if (s > alpha) alpha = s;
        }
        if (!completed) break;
        best = iterBest;
        bestScore = iterBestScore;
        found = 1;
        // Beste zetten vooraan voor de volgende diepte.
        for (int i = 1; i < n; i++) {
            int j = i;
            while (j > 0 && rs[j] > rs[j - 1]) {
                int ts = rs[j]; rs[j] = rs[j - 1]; rs[j - 1] = ts;
                CEMove tm = rootMoves[j]; rootMoves[j] = rootMoves[j - 1]; rootMoves[j - 1] = tm;
                j--;
            }
        }
        if (bestScore > CB_MATE - 200) break;  // mat gevonden
        if (timeMs > 0 && now_ms() - startTime > timeMs * 0.45) break;  // volgende diepte past niet meer
    }
    int cancelled = cancel && *cancel;
    free(c);
    if (cancelled) return 0;
    if (!found) best = rootMoves[0];
    *out = best;
    if (outScore) *outScore = bestScore;
    return 1;
}

int cb_choose_move(const CEPosition *pos, const uint64_t *history, int count,
                   int level, CEMove *out, volatile int *cancel) {
    int depth, timeMs, noise;
    if (level < CB_MIN_LEVEL) level = CB_MIN_LEVEL;
    if (level > CB_MAX_LEVEL) level = CB_MAX_LEVEL;
    switch (level) {
        case 1: depth = 1; timeMs = 1500; noise = 300; break;
        case 2: depth = 2; timeMs = 2500; noise = 80; break;
        case 3: depth = 3; timeMs = 3500; noise = 0; break;
        case 4: depth = 4; timeMs = 5000; noise = 0; break;
        default: depth = 6; timeMs = 7000; noise = 0; break;
    }
    return root_search(pos, history, count, depth, timeMs, noise, cancel, out, NULL);
}

int cb_choose_move_strength(const CEPosition *pos, const uint64_t *history, int count,
                            int strength, CEMove *out, volatile int *cancel) {
    ce_init();
    if (strength < 0) strength = 0;
    if (strength > 100) strength = 100;
    CEMove legal[CE_MAX_MOVES];
    int n = ce_gen_legal(pos, legal);
    if (n == 0) return 0;
    if (cancel && *cancel) return 0;
    // Heel zwak: vaak een willekeurige zet (90% bij sterkte 0, 0% vanaf sterkte 30).
    int randomPct = 90 - strength * 3;
    if (randomPct > 0 && (int)(next_rand() % 100) < randomPct) {
        // Bij de allerlaagste sterktes soms zelfs bewust een slechte zet.
        int worstPct = strength < 15 ? (15 - strength) * 3 : 0;
        if (worstPct > 0 && (int)(next_rand() % 100) < worstPct) {
            int worstScore = 1000000;
            CEMove worst = legal[0];
            for (int i = 0; i < n; i++) {
                CEPosition q = *pos;
                ce_make(&q, legal[i]);
                int s = -cb_evaluate(&q);
                if (s < worstScore) { worstScore = s; worst = legal[i]; }
            }
            *out = worst;
            return 1;
        }
        *out = legal[next_rand() % (uint32_t)n];
        return 1;
    }
    int depth = strength < 35 ? 1 : strength < 55 ? 2 : strength < 70 ? 3 : strength < 85 ? 4 : 5;
    int noise = strength < 70 ? 400 - strength * 11 / 2 : 0;
    if (noise < 0) noise = 0;
    int timeMs = depth >= 4 ? 5000 : 3000;
    return root_search(pos, history, count, depth, timeMs, noise, cancel, out, NULL);
}

int cb_search_depth(const CEPosition *pos, int depth, CEMove *out, int *score) {
    return root_search(pos, NULL, 0, depth, 0, 0, NULL, out, score);
}

double cb_win_percent(int cp) {
    if (cp > 3000) cp = 3000;
    if (cp < -3000) cp = -3000;
    return 50.0 + 50.0 * (2.0 / (1.0 + exp(-0.00368208 * (double)cp)) - 1.0);
}

double cb_move_accuracy(double winLoss) {
    if (winLoss < 0) winLoss = 0;
    double a = 103.1668 * exp(-0.04354 * winLoss) - 3.1669;
    if (a < 0) a = 0;
    if (a > 100) a = 100;
    return a;
}

int cb_analyse_move(const CEPosition *before, const uint64_t *hist, int count,
                    CEMove played, int depth, CBMoveAnalysis *out, volatile int *cancel) {
    ce_init();
    if (depth < 1) depth = 1;
    CEMove legal[CE_MAX_MOVES];
    int n = ce_gen_legal(before, legal);
    int found = 0;
    for (int i = 0; i < n; i++) {
        if (same_move(legal[i], played)) { played = legal[i]; found = 1; break; }
    }
    if (!found) return 0;
    memset(out, 0, sizeof(*out));
    out->best = played;
    if (n == 1) {
        out->rating = CB_RATE_FORCED;
        return 1;
    }
    CEMove best;
    int bestScore = 0;
    if (!root_search(before, hist, count, depth, 0, 0, cancel, &best, &bestScore)) return 0;
    int playedScore = bestScore;
    if (!same_move(best, played)) {
        SearchCtx *c = (SearchCtx *)calloc(1, sizeof(SearchCtx));
        if (!c) return 0;
        c->cancel = cancel;
        int start = count > CB_HIST_KEEP ? count - CB_HIST_KEEP : 0;
        for (int i = start; hist && i < count; i++) c->hashes[c->nh++] = hist[i];
        if (c->nh == 0 || c->hashes[c->nh - 1] != before->hash) c->hashes[c->nh++] = before->hash;
        CEPosition q = *before;
        ce_make(&q, played);
        c->hashes[c->nh++] = q.hash;
        playedScore = -search(c, &q, depth - 1, -CB_INF, CB_INF, 1);
        int stopped = c->stop;
        free(c);
        if (stopped) return 0;
        if (playedScore > bestScore) {
            // De gespeelde zet blijkt even goed of beter: dan is hij de beste.
            bestScore = playedScore;
            best = played;
        }
    }
    double loss = cb_win_percent(bestScore) - cb_win_percent(playedScore);
    if (loss < 0) loss = 0;
    out->best = best;
    out->bestScore = bestScore;
    out->playedScore = playedScore;
    out->winLoss = loss;
    if (same_move(best, played) || loss < 1.0) out->rating = CB_RATE_BEST;
    else if (loss < 3.0) out->rating = CB_RATE_EXCELLENT;
    else if (loss < 8.0) out->rating = CB_RATE_GOOD;
    else if (loss < 15.0) out->rating = CB_RATE_INACCURACY;
    else if (loss < 28.0) out->rating = CB_RATE_MISTAKE;
    else out->rating = CB_RATE_BLUNDER;
    return 1;
}
