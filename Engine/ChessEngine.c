// ChessEngine.c
// YF Schaak - alle schaakregels: zetten maken, schaak, mat, pat, remise.

#include "ChessEngine.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

static uint64_t Z_PIECE[16][64];
static uint64_t Z_SIDE;
static uint64_t Z_CASTLE[16];
static uint64_t Z_EP[8];
static uint8_t KNIGHT_T[64][8], KNIGHT_N[64];
static uint8_t KING_T[64][8], KING_N[64];
static uint8_t RAY[64][8][7], RAY_N[64][8];
static uint8_t CASTLE_MASK[64];
static int g_ready = 0;

// Richtingen 0-3 recht (toren), 4-7 schuin (loper).
static const int DIRS[8][2] = { {1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1} };
static const int KNIGHT_D[8][2] = { {1,2},{2,1},{2,-1},{1,-2},{-1,-2},{-2,-1},{-2,1},{-1,2} };

static uint64_t splitmix(uint64_t *s) {
    uint64_t z = (*s += 0x9E3779B97F4A7C15ULL);
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}

void ce_init(void) {
    if (g_ready) return;
    uint64_t seed = 0x5946436865737321ULL;
    for (int p = 0; p < 16; p++)
        for (int s = 0; s < 64; s++) Z_PIECE[p][s] = splitmix(&seed);
    Z_SIDE = splitmix(&seed);
    for (int i = 0; i < 16; i++) Z_CASTLE[i] = splitmix(&seed);
    for (int i = 0; i < 8; i++) Z_EP[i] = splitmix(&seed);

    for (int sq = 0; sq < 64; sq++) {
        int f = CE_FILE(sq), r = CE_RANK(sq);
        KNIGHT_N[sq] = 0;
        for (int k = 0; k < 8; k++) {
            int nf = f + KNIGHT_D[k][0], nr = r + KNIGHT_D[k][1];
            if (nf >= 0 && nf < 8 && nr >= 0 && nr < 8) KNIGHT_T[sq][KNIGHT_N[sq]++] = (uint8_t)CE_SQ(nf, nr);
        }
        KING_N[sq] = 0;
        for (int d = 0; d < 8; d++) {
            int nf = f + DIRS[d][0], nr = r + DIRS[d][1];
            if (nf >= 0 && nf < 8 && nr >= 0 && nr < 8) KING_T[sq][KING_N[sq]++] = (uint8_t)CE_SQ(nf, nr);
            int n = 0;
            nf = f + DIRS[d][0]; nr = r + DIRS[d][1];
            while (nf >= 0 && nf < 8 && nr >= 0 && nr < 8) {
                RAY[sq][d][n++] = (uint8_t)CE_SQ(nf, nr);
                nf += DIRS[d][0]; nr += DIRS[d][1];
            }
            RAY_N[sq][d] = (uint8_t)n;
        }
        CASTLE_MASK[sq] = 15;
    }
    CASTLE_MASK[0] = (uint8_t)(15 & ~CE_CASTLE_WQ);
    CASTLE_MASK[7] = (uint8_t)(15 & ~CE_CASTLE_WK);
    CASTLE_MASK[4] = (uint8_t)(15 & ~(CE_CASTLE_WK | CE_CASTLE_WQ));
    CASTLE_MASK[56] = (uint8_t)(15 & ~CE_CASTLE_BQ);
    CASTLE_MASK[63] = (uint8_t)(15 & ~CE_CASTLE_BK);
    CASTLE_MASK[60] = (uint8_t)(15 & ~(CE_CASTLE_BK | CE_CASTLE_BQ));
    g_ready = 1;
}

uint64_t ce_compute_hash(const CEPosition *p) {
    ce_init();
    uint64_t h = 0;
    for (int sq = 0; sq < 64; sq++)
        if (p->board[sq]) h ^= Z_PIECE[p->board[sq]][sq];
    if (p->side == CE_BLACK) h ^= Z_SIDE;
    h ^= Z_CASTLE[p->castling & 15];
    if (p->ep >= 0) h ^= Z_EP[p->ep & 7];
    return h;
}

void ce_clear(CEPosition *p) {
    ce_init();
    memset(p, 0, sizeof(*p));
    p->side = CE_WHITE;
    p->ep = -1;
    p->fullmove = 1;
    p->hash = ce_compute_hash(p);
}

void ce_start(CEPosition *p) {
    ce_from_fen(p, "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
}

void ce_fix_castling(CEPosition *p) {
    const uint8_t *b = p->board;
    if (b[4] != CE_PIECE(CE_WHITE, CE_KING)) p->castling &= ~(CE_CASTLE_WK | CE_CASTLE_WQ);
    if (b[7] != CE_PIECE(CE_WHITE, CE_ROOK)) p->castling &= ~CE_CASTLE_WK;
    if (b[0] != CE_PIECE(CE_WHITE, CE_ROOK)) p->castling &= ~CE_CASTLE_WQ;
    if (b[60] != CE_PIECE(CE_BLACK, CE_KING)) p->castling &= ~(CE_CASTLE_BK | CE_CASTLE_BQ);
    if (b[63] != CE_PIECE(CE_BLACK, CE_ROOK)) p->castling &= ~CE_CASTLE_BK;
    if (b[56] != CE_PIECE(CE_BLACK, CE_ROOK)) p->castling &= ~CE_CASTLE_BQ;
}

void ce_auto_castling(CEPosition *p) {
    p->castling = CE_CASTLE_WK | CE_CASTLE_WQ | CE_CASTLE_BK | CE_CASTLE_BQ;
    ce_fix_castling(p);
}

static int piece_from_char(char c) {
    switch (c) {
        case 'p': return CE_PAWN;
        case 'n': return CE_KNIGHT;
        case 'b': return CE_BISHOP;
        case 'r': return CE_ROOK;
        case 'q': return CE_QUEEN;
        case 'k': return CE_KING;
        default: return 0;
    }
}

static const char PIECE_CHARS[] = " pnbrqk";

int ce_from_fen(CEPosition *p, const char *fen) {
    ce_init();
    if (!fen) return 0;
    CEPosition q;
    memset(&q, 0, sizeof(q));
    q.ep = -1;
    q.fullmove = 1;
    const char *s = fen;
    while (*s == ' ') s++;
    int r = 7, f = 0;
    while (*s && *s != ' ') {
        char c = *s++;
        if (c == '/') {
            if (f != 8) return 0;
            r--; f = 0;
            if (r < 0) return 0;
            continue;
        }
        if (c >= '1' && c <= '8') {
            f += c - '0';
            if (f > 8) return 0;
            continue;
        }
        int isUpper = (c >= 'A' && c <= 'Z');
        char lc = isUpper ? (char)(c - 'A' + 'a') : c;
        int type = piece_from_char(lc);
        if (!type || f > 7) return 0;
        q.board[CE_SQ(f, r)] = CE_PIECE(isUpper ? CE_WHITE : CE_BLACK, type);
        f++;
    }
    if (r != 0 || f != 8) return 0;
    while (*s == ' ') s++;
    if (*s == 'w') q.side = CE_WHITE;
    else if (*s == 'b') q.side = CE_BLACK;
    else return 0;
    s++;
    while (*s == ' ') s++;
    if (*s == '-') s++;
    else {
        while (*s && *s != ' ') {
            switch (*s) {
                case 'K': q.castling |= CE_CASTLE_WK; break;
                case 'Q': q.castling |= CE_CASTLE_WQ; break;
                case 'k': q.castling |= CE_CASTLE_BK; break;
                case 'q': q.castling |= CE_CASTLE_BQ; break;
                default: return 0;
            }
            s++;
        }
    }
    while (*s == ' ') s++;
    if (*s == '-') s++;
    else if (*s >= 'a' && *s <= 'h' && s[1] >= '1' && s[1] <= '8') {
        q.ep = CE_SQ(s[0] - 'a', s[1] - '1');
        s += 2;
    } else if (*s) return 0;
    while (*s == ' ') s++;
    if (*s >= '0' && *s <= '9') {
        q.halfmove = (int)strtol(s, (char **)&s, 10);
        while (*s == ' ') s++;
        if (*s >= '0' && *s <= '9') q.fullmove = (int)strtol(s, (char **)&s, 10);
    }
    if (q.fullmove < 1) q.fullmove = 1;
    if (q.halfmove < 0) q.halfmove = 0;
    ce_fix_castling(&q);
    q.hash = ce_compute_hash(&q);
    *p = q;
    return 1;
}

void ce_to_fen(const CEPosition *p, char *buf, size_t n) {
    char out[128];
    int k = 0;
    for (int r = 7; r >= 0; r--) {
        int empty = 0;
        for (int f = 0; f < 8; f++) {
            uint8_t pc = p->board[CE_SQ(f, r)];
            if (!pc) { empty++; continue; }
            if (empty) { out[k++] = (char)('0' + empty); empty = 0; }
            char c = PIECE_CHARS[CE_TYPE(pc)];
            if (CE_COLOR(pc) == CE_WHITE) c = (char)(c - 'a' + 'A');
            out[k++] = c;
        }
        if (empty) out[k++] = (char)('0' + empty);
        if (r > 0) out[k++] = '/';
    }
    out[k++] = ' ';
    out[k++] = p->side == CE_WHITE ? 'w' : 'b';
    out[k++] = ' ';
    if (!p->castling) out[k++] = '-';
    else {
        if (p->castling & CE_CASTLE_WK) out[k++] = 'K';
        if (p->castling & CE_CASTLE_WQ) out[k++] = 'Q';
        if (p->castling & CE_CASTLE_BK) out[k++] = 'k';
        if (p->castling & CE_CASTLE_BQ) out[k++] = 'q';
    }
    out[k++] = ' ';
    if (p->ep >= 0) {
        out[k++] = (char)('a' + CE_FILE(p->ep));
        out[k++] = (char)('1' + CE_RANK(p->ep));
    } else out[k++] = '-';
    out[k] = 0;
    snprintf(buf, n, "%s %d %d", out, p->halfmove, p->fullmove);
}

int ce_king_square(const CEPosition *p, int color) {
    uint8_t k = CE_PIECE(color, CE_KING);
    for (int sq = 0; sq < 64; sq++)
        if (p->board[sq] == k) return sq;
    return -1;
}

int ce_attacked(const CEPosition *p, int sq, int by) {
    const uint8_t *b = p->board;
    int f = CE_FILE(sq), r = CE_RANK(sq);
    uint8_t pawn = CE_PIECE(by, CE_PAWN);
    if (by == CE_WHITE) {
        if (r > 0) {
            if (f > 0 && b[sq - 9] == pawn) return 1;
            if (f < 7 && b[sq - 7] == pawn) return 1;
        }
    } else {
        if (r < 7) {
            if (f > 0 && b[sq + 7] == pawn) return 1;
            if (f < 7 && b[sq + 9] == pawn) return 1;
        }
    }
    uint8_t kn = CE_PIECE(by, CE_KNIGHT);
    for (int i = 0; i < KNIGHT_N[sq]; i++)
        if (b[KNIGHT_T[sq][i]] == kn) return 1;
    uint8_t kg = CE_PIECE(by, CE_KING);
    for (int i = 0; i < KING_N[sq]; i++)
        if (b[KING_T[sq][i]] == kg) return 1;
    uint8_t rook = CE_PIECE(by, CE_ROOK), bishop = CE_PIECE(by, CE_BISHOP), queen = CE_PIECE(by, CE_QUEEN);
    for (int d = 0; d < 8; d++) {
        uint8_t a = d < 4 ? rook : bishop;
        for (int i = 0; i < RAY_N[sq][d]; i++) {
            uint8_t t = b[RAY[sq][d][i]];
            if (t) {
                if (t == a || t == queen) return 1;
                break;
            }
        }
    }
    return 0;
}

int ce_in_check(const CEPosition *p, int color) {
    int k = ce_king_square(p, color);
    return k >= 0 && ce_attacked(p, k, color ^ 1);
}

#define ADD_MOVE(fr, t, pr, fl) do { if (n < CE_MAX_MOVES) { \
    mv[n].from = (uint8_t)(fr); mv[n].to = (uint8_t)(t); mv[n].promo = (uint8_t)(pr); mv[n].flags = (uint8_t)(fl); n++; } } while (0)

int ce_gen_pseudo(const CEPosition *p, CEMove *mv, int capsOnly) {
    int n = 0;
    int us = p->side, them = us ^ 1;
    const uint8_t *b = p->board;
    for (int sq = 0; sq < 64; sq++) {
        uint8_t pc = b[sq];
        if (!pc || CE_COLOR(pc) != us) continue;
        int type = CE_TYPE(pc);
        int f = CE_FILE(sq), r = CE_RANK(sq);
        if (type == CE_PAWN) {
            int dir = us == CE_WHITE ? 8 : -8;
            int startR = us == CE_WHITE ? 1 : 6;
            int lastR = us == CE_WHITE ? 7 : 0;
            int to = sq + dir;
            if (to < 0 || to > 63) continue;
            int promo = CE_RANK(to) == lastR;
            if (!b[to]) {
                if (promo) {
                    ADD_MOVE(sq, to, CE_QUEEN, CE_FLAG_PROMO);
                    if (!capsOnly) {
                        ADD_MOVE(sq, to, CE_ROOK, CE_FLAG_PROMO);
                        ADD_MOVE(sq, to, CE_BISHOP, CE_FLAG_PROMO);
                        ADD_MOVE(sq, to, CE_KNIGHT, CE_FLAG_PROMO);
                    }
                } else if (!capsOnly) {
                    ADD_MOVE(sq, to, 0, 0);
                    if (r == startR && !b[to + dir]) ADD_MOVE(sq, to + dir, 0, CE_FLAG_DOUBLE);
                }
            }
            for (int df = -1; df <= 1; df += 2) {
                int nf = f + df;
                if (nf < 0 || nf > 7) continue;
                int t = to + df;
                if (b[t] && CE_COLOR(b[t]) == them) {
                    if (promo) {
                        ADD_MOVE(sq, t, CE_QUEEN, CE_FLAG_PROMO | CE_FLAG_CAPTURE);
                        if (!capsOnly) {
                            ADD_MOVE(sq, t, CE_ROOK, CE_FLAG_PROMO | CE_FLAG_CAPTURE);
                            ADD_MOVE(sq, t, CE_BISHOP, CE_FLAG_PROMO | CE_FLAG_CAPTURE);
                            ADD_MOVE(sq, t, CE_KNIGHT, CE_FLAG_PROMO | CE_FLAG_CAPTURE);
                        }
                    } else {
                        ADD_MOVE(sq, t, 0, CE_FLAG_CAPTURE);
                    }
                } else if (t == p->ep && !b[t] && b[t - dir] == CE_PIECE(them, CE_PAWN)) {
                    ADD_MOVE(sq, t, 0, CE_FLAG_CAPTURE | CE_FLAG_EP);
                }
            }
        } else if (type == CE_KNIGHT || type == CE_KING) {
            const uint8_t *tg = type == CE_KNIGHT ? KNIGHT_T[sq] : KING_T[sq];
            int cnt = type == CE_KNIGHT ? KNIGHT_N[sq] : KING_N[sq];
            for (int i = 0; i < cnt; i++) {
                int t = tg[i];
                if (!b[t]) { if (!capsOnly) ADD_MOVE(sq, t, 0, 0); }
                else if (CE_COLOR(b[t]) == them) ADD_MOVE(sq, t, 0, CE_FLAG_CAPTURE);
            }
            if (type == CE_KING && !capsOnly) {
                if (us == CE_WHITE && sq == 4) {
                    if ((p->castling & CE_CASTLE_WK) && b[7] == CE_PIECE(CE_WHITE, CE_ROOK) && !b[5] && !b[6] &&
                        !ce_attacked(p, 4, them) && !ce_attacked(p, 5, them) && !ce_attacked(p, 6, them))
                        ADD_MOVE(4, 6, 0, CE_FLAG_CASTLE);
                    if ((p->castling & CE_CASTLE_WQ) && b[0] == CE_PIECE(CE_WHITE, CE_ROOK) && !b[1] && !b[2] && !b[3] &&
                        !ce_attacked(p, 4, them) && !ce_attacked(p, 3, them) && !ce_attacked(p, 2, them))
                        ADD_MOVE(4, 2, 0, CE_FLAG_CASTLE);
                } else if (us == CE_BLACK && sq == 60) {
                    if ((p->castling & CE_CASTLE_BK) && b[63] == CE_PIECE(CE_BLACK, CE_ROOK) && !b[61] && !b[62] &&
                        !ce_attacked(p, 60, them) && !ce_attacked(p, 61, them) && !ce_attacked(p, 62, them))
                        ADD_MOVE(60, 62, 0, CE_FLAG_CASTLE);
                    if ((p->castling & CE_CASTLE_BQ) && b[56] == CE_PIECE(CE_BLACK, CE_ROOK) && !b[57] && !b[58] && !b[59] &&
                        !ce_attacked(p, 60, them) && !ce_attacked(p, 59, them) && !ce_attacked(p, 58, them))
                        ADD_MOVE(60, 58, 0, CE_FLAG_CASTLE);
                }
            }
        } else {
            int d0 = type == CE_ROOK ? 0 : (type == CE_BISHOP ? 4 : 0);
            int d1 = type == CE_BISHOP ? 8 : (type == CE_ROOK ? 4 : 8);
            for (int d = d0; d < d1; d++) {
                for (int i = 0; i < RAY_N[sq][d]; i++) {
                    int t = RAY[sq][d][i];
                    if (!b[t]) { if (!capsOnly) ADD_MOVE(sq, t, 0, 0); continue; }
                    if (CE_COLOR(b[t]) == them) ADD_MOVE(sq, t, 0, CE_FLAG_CAPTURE);
                    break;
                }
            }
        }
    }
    return n;
}

void ce_make(CEPosition *p, CEMove m) {
    uint8_t *b = p->board;
    int from = m.from, to = m.to;
    uint8_t pc = b[from];
    int us = p->side, them = us ^ 1;
    uint64_t h = p->hash;
    if (p->ep >= 0) h ^= Z_EP[p->ep & 7];
    h ^= Z_CASTLE[p->castling & 15];
    p->halfmove++;
    if (m.flags & CE_FLAG_EP) {
        int cap = to + (us == CE_WHITE ? -8 : 8);
        if (b[cap]) h ^= Z_PIECE[b[cap]][cap];
        b[cap] = 0;
        p->halfmove = 0;
    } else if (b[to]) {
        h ^= Z_PIECE[b[to]][to];
        p->halfmove = 0;
    }
    h ^= Z_PIECE[pc][from];
    b[from] = 0;
    uint8_t placed = pc;
    if (m.flags & CE_FLAG_PROMO) placed = CE_PIECE(us, m.promo ? m.promo : CE_QUEEN);
    b[to] = placed;
    h ^= Z_PIECE[placed][to];
    if (CE_TYPE(pc) == CE_PAWN) p->halfmove = 0;
    if (m.flags & CE_FLAG_CASTLE) {
        int rf, rt;
        switch (to) {
            case 6: rf = 7; rt = 5; break;
            case 2: rf = 0; rt = 3; break;
            case 62: rf = 63; rt = 61; break;
            default: rf = 56; rt = 59; break;
        }
        uint8_t rk = b[rf];
        if (rk) {
            h ^= Z_PIECE[rk][rf] ^ Z_PIECE[rk][rt];
            b[rt] = rk;
            b[rf] = 0;
        }
    }
    p->castling &= CASTLE_MASK[from] & CASTLE_MASK[to];
    p->ep = -1;
    if (m.flags & CE_FLAG_DOUBLE) {
        // Alleen een en-passantveld als er echt een pion naast staat die kan slaan.
        int f = CE_FILE(to);
        uint8_t ep = CE_PIECE(them, CE_PAWN);
        if ((f > 0 && b[to - 1] == ep) || (f < 7 && b[to + 1] == ep)) p->ep = (from + to) / 2;
    }
    if (p->ep >= 0) h ^= Z_EP[p->ep & 7];
    h ^= Z_CASTLE[p->castling & 15];
    if (us == CE_BLACK) p->fullmove++;
    p->side = them;
    h ^= Z_SIDE;
    p->hash = h;
}

int ce_gen_legal(const CEPosition *p, CEMove *out) {
    CEMove tmp[CE_MAX_MOVES];
    int n = ce_gen_pseudo(p, tmp, 0);
    int us = p->side;
    int ks = ce_king_square(p, us);
    int k = 0;
    for (int i = 0; i < n; i++) {
        CEPosition c = *p;
        ce_make(&c, tmp[i]);
        int kk = (CE_TYPE(p->board[tmp[i].from]) == CE_KING) ? tmp[i].to : ks;
        if (kk < 0 || !ce_attacked(&c, kk, us ^ 1)) out[k++] = tmp[i];
    }
    return k;
}

int ce_find_move(const CEPosition *p, int from, int to, int promo, CEMove *out) {
    CEMove mv[CE_MAX_MOVES];
    int n = ce_gen_legal(p, mv);
    for (int i = 0; i < n; i++) {
        if (mv[i].from != from || mv[i].to != to) continue;
        if (mv[i].flags & CE_FLAG_PROMO) {
            int want = promo ? promo : CE_QUEEN;
            if (mv[i].promo != want) continue;
        }
        *out = mv[i];
        return 1;
    }
    return 0;
}

int ce_parse_uci(const CEPosition *p, const char *u, CEMove *out) {
    if (!u || strlen(u) < 4) return 0;
    if (u[0] < 'a' || u[0] > 'h' || u[2] < 'a' || u[2] > 'h') return 0;
    if (u[1] < '1' || u[1] > '8' || u[3] < '1' || u[3] > '8') return 0;
    int from = CE_SQ(u[0] - 'a', u[1] - '1');
    int to = CE_SQ(u[2] - 'a', u[3] - '1');
    int promo = u[4] ? piece_from_char(u[4]) : 0;
    return ce_find_move(p, from, to, promo, out);
}

void ce_move_to_uci(CEMove m, char *buf, size_t n) {
    char s[6];
    s[0] = (char)('a' + CE_FILE(m.from));
    s[1] = (char)('1' + CE_RANK(m.from));
    s[2] = (char)('a' + CE_FILE(m.to));
    s[3] = (char)('1' + CE_RANK(m.to));
    s[4] = (m.flags & CE_FLAG_PROMO) ? PIECE_CHARS[m.promo] : 0;
    s[5] = 0;
    snprintf(buf, n, "%s", s);
}

void ce_move_to_san(const CEPosition *before, CEMove m, char *buf, size_t n) {
    char s[16];
    int k = 0;
    uint8_t pc = before->board[m.from];
    int type = CE_TYPE(pc);
    if (m.flags & CE_FLAG_CASTLE) {
        const char *c = CE_FILE(m.to) == 6 ? "O-O" : "O-O-O";
        strcpy(s, c);
        k = (int)strlen(c);
    } else {
        int capture = (m.flags & CE_FLAG_CAPTURE) || before->board[m.to];
        if (type == CE_PAWN) {
            if (capture) {
                s[k++] = (char)('a' + CE_FILE(m.from));
                s[k++] = 'x';
            }
        } else {
            s[k++] = "  NBRQK"[type];
            CEMove mv[CE_MAX_MOVES];
            int cnt = ce_gen_legal(before, mv);
            int ambiguous = 0, sameFile = 0, sameRank = 0;
            for (int i = 0; i < cnt; i++) {
                if (mv[i].to != m.to || mv[i].from == m.from) continue;
                if (before->board[mv[i].from] != pc) continue;
                ambiguous = 1;
                if (CE_FILE(mv[i].from) == CE_FILE(m.from)) sameFile = 1;
                if (CE_RANK(mv[i].from) == CE_RANK(m.from)) sameRank = 1;
            }
            if (ambiguous) {
                if (!sameFile) s[k++] = (char)('a' + CE_FILE(m.from));
                else if (!sameRank) s[k++] = (char)('1' + CE_RANK(m.from));
                else {
                    s[k++] = (char)('a' + CE_FILE(m.from));
                    s[k++] = (char)('1' + CE_RANK(m.from));
                }
            }
            if (capture) s[k++] = 'x';
        }
        s[k++] = (char)('a' + CE_FILE(m.to));
        s[k++] = (char)('1' + CE_RANK(m.to));
        if (m.flags & CE_FLAG_PROMO) {
            s[k++] = '=';
            s[k++] = "  NBRQK"[m.promo ? m.promo : CE_QUEEN];
        }
    }
    CEPosition after = *before;
    ce_make(&after, m);
    if (ce_in_check(&after, after.side)) {
        CEMove mv[CE_MAX_MOVES];
        s[k++] = ce_gen_legal(&after, mv) == 0 ? '#' : '+';
    }
    s[k] = 0;
    snprintf(buf, n, "%s", s);
}

static void strip_san(const char *in, char *out, size_t n) {
    size_t k = 0;
    for (const char *s = in; *s && k + 1 < n; s++) {
        char c = *s;
        if (c == '+' || c == '#' || c == '!' || c == '?' || c == ' ') continue;
        if (c == '0') c = 'O';   // 0-0 schrijven sommigen met nullen
        out[k++] = c;
    }
    out[k] = 0;
}

int ce_parse_san(const CEPosition *p, const char *san, CEMove *out) {
    if (!san || !*san) return 0;
    char want[16];
    strip_san(san, want, sizeof want);
    CEMove mv[CE_MAX_MOVES];
    int n = ce_gen_legal(p, mv);
    for (int i = 0; i < n; i++) {
        char buf[16], got[16];
        ce_move_to_san(p, mv[i], buf, sizeof buf);
        strip_san(buf, got, sizeof got);
        if (strcmp(got, want) == 0) {
            *out = mv[i];
            return 1;
        }
    }
    return 0;
}

uint64_t ce_perft(const CEPosition *p, int depth) {
    if (depth <= 0) return 1;
    CEMove mv[CE_MAX_MOVES];
    int n = ce_gen_legal(p, mv);
    if (depth == 1) return (uint64_t)n;
    uint64_t total = 0;
    for (int i = 0; i < n; i++) {
        CEPosition c = *p;
        ce_make(&c, mv[i]);
        total += ce_perft(&c, depth - 1);
    }
    return total;
}

int ce_insufficient_material(const CEPosition *p) {
    int minors = 0, knights = 0, lightB = 0, darkB = 0;
    for (int sq = 0; sq < 64; sq++) {
        uint8_t pc = p->board[sq];
        if (!pc) continue;
        int t = CE_TYPE(pc);
        if (t == CE_PAWN || t == CE_ROOK || t == CE_QUEEN) return 0;
        if (t == CE_KNIGHT) { minors++; knights++; }
        if (t == CE_BISHOP) {
            minors++;
            if ((CE_FILE(sq) + CE_RANK(sq)) & 1) lightB++; else darkB++;
        }
    }
    if (minors <= 1) return 1;
    // Alleen lopers, allemaal op dezelfde veldkleur: mat is onmogelijk.
    if (knights == 0 && (lightB == 0 || darkB == 0)) return 1;
    return 0;
}

CEStatus ce_status(const CEPosition *p, const uint64_t *hist, int count) {
    CEMove mv[CE_MAX_MOVES];
    int n = ce_gen_legal(p, mv);
    if (n == 0) return ce_in_check(p, p->side) ? CE_CHECKMATE : CE_STALEMATE;
    if (ce_insufficient_material(p)) return CE_DRAW_MATERIAL;
    if (p->halfmove >= 100) return CE_DRAW_FIFTY;
    if (hist && count > 0) {
        int seen = 0;
        int lowest = count - 1 - p->halfmove;
        if (lowest < 0) lowest = 0;
        for (int i = count - 1; i >= lowest; i--)
            if (hist[i] == p->hash) seen++;
        if (seen >= 3) return CE_DRAW_REPETITION;
    }
    return CE_ONGOING;
}

int ce_validate(const CEPosition *p, char *err, size_t n) {
    int kings[2] = {0, 0};
    int badPawn = 0;
    for (int sq = 0; sq < 64; sq++) {
        uint8_t pc = p->board[sq];
        if (!pc) continue;
        if (CE_TYPE(pc) == CE_KING) kings[CE_COLOR(pc)]++;
        if (CE_TYPE(pc) == CE_PAWN && (CE_RANK(sq) == 0 || CE_RANK(sq) == 7)) badPawn = 1;
    }
    const char *msg = NULL;
    if (kings[CE_WHITE] == 0) msg = "Wit heeft nog geen koning. Zet precies \xC3\xA9\xC3\xA9n witte koning op het bord.";
    else if (kings[CE_WHITE] > 1) msg = "Wit heeft meer dan \xC3\xA9\xC3\xA9n koning. Er mag maar \xC3\xA9\xC3\xA9n witte koning zijn.";
    else if (kings[CE_BLACK] == 0) msg = "Zwart heeft nog geen koning. Zet precies \xC3\xA9\xC3\xA9n zwarte koning op het bord.";
    else if (kings[CE_BLACK] > 1) msg = "Zwart heeft meer dan \xC3\xA9\xC3\xA9n koning. Er mag maar \xC3\xA9\xC3\xA9n zwarte koning zijn.";
    else if (badPawn) msg = "Een pion mag niet op de eerste of de laatste rij staan.";
    else {
        int other = p->side ^ 1;
        if (ce_in_check(p, other))
            msg = other == CE_WHITE
                ? "De witte koning staat schaak, maar zwart is aan zet. Dan kan de koning geslagen worden; dat mag niet."
                : "De zwarte koning staat schaak, maar wit is aan zet. Dan kan de koning geslagen worden; dat mag niet.";
    }
    if (msg) {
        if (err && n) snprintf(err, n, "%s", msg);
        return 0;
    }
    if (err && n) err[0] = 0;
    return 1;
}
