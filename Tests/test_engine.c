// test_engine.c
// Eenheidstests voor de schaakregels en de bot. Draait in GitHub Actions op Linux.
// Faalt er een test, dan stopt het programma met code 1 en mislukt de build.

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "ChessEngine.h"
#include "ChessBot.h"
#include "ChessPuzzles.h"

static int g_fail = 0, g_pass = 0;

#define CHECK(cond, ...) do { if (cond) { g_pass++; } else { g_fail++; \
    printf("FOUT  %s:%d: ", __FILE__, __LINE__); printf(__VA_ARGS__); printf("\n"); } } while (0)

static void load(CEPosition *p, const char *fen) {
    if (!ce_from_fen(p, fen)) {
        printf("FOUT  kan FEN niet lezen: %s\n", fen);
        g_fail++;
        ce_clear(p);
    }
}

static int has_move(const CEPosition *p, const char *uci) {
    CEMove m;
    return ce_parse_uci(p, uci, &m);
}

static int play(CEPosition *p, uint64_t *hist, int *nh, const char *uci) {
    CEMove m;
    if (!ce_parse_uci(p, uci, &m)) {
        printf("FOUT  zet %s is niet legaal\n", uci);
        g_fail++;
        return 0;
    }
    ce_make(p, m);
    if (hist) hist[(*nh)++] = p->hash;
    return 1;
}

static void perft_check(const char *name, const char *fen, int depth, uint64_t expected) {
    CEPosition p;
    load(&p, fen);
    uint64_t got = ce_perft(&p, depth);
    CHECK(got == expected, "perft %s diepte %d: verwacht %llu, kreeg %llu", name, depth,
          (unsigned long long)expected, (unsigned long long)got);
    printf("  perft %-12s diepte %d = %llu\n", name, depth, (unsigned long long)got);
}

static void test_perft(void) {
    printf("[perft]\n");
    const char *start = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    perft_check("start", start, 1, 20);
    perft_check("start", start, 2, 400);
    perft_check("start", start, 3, 8902);
    perft_check("start", start, 4, 197281);
    const char *kiwi = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1";
    perft_check("kiwipete", kiwi, 1, 48);
    perft_check("kiwipete", kiwi, 2, 2039);
    perft_check("kiwipete", kiwi, 3, 97862);
    const char *p3 = "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1";
    perft_check("positie3", p3, 1, 14);
    perft_check("positie3", p3, 2, 191);
    perft_check("positie3", p3, 3, 2812);
    perft_check("positie3", p3, 4, 43238);
    const char *p4 = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1";
    perft_check("positie4", p4, 1, 6);
    perft_check("positie4", p4, 2, 264);
    perft_check("positie4", p4, 3, 9467);
    const char *p5 = "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8";
    perft_check("positie5", p5, 1, 44);
    perft_check("positie5", p5, 2, 1486);
    perft_check("positie5", p5, 3, 62379);
}

static void test_castling(void) {
    printf("[rokade]\n");
    CEPosition p;
    load(&p, "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1");
    CHECK(has_move(&p, "e1g1"), "korte rokade wit moet kunnen");
    CHECK(has_move(&p, "e1c1"), "lange rokade wit moet kunnen");
    CEPosition q = p;
    play(&q, NULL, NULL, "e1g1");
    CHECK(q.board[6] == CE_PIECE(CE_WHITE, CE_KING) && q.board[5] == CE_PIECE(CE_WHITE, CE_ROOK) && !q.board[7] && !q.board[4],
          "na korte rokade: koning g1, toren f1");
    CHECK(!(q.castling & (CE_CASTLE_WK | CE_CASTLE_WQ)), "na rokade geen witte rokaderechten meer");
    CHECK(has_move(&q, "e8c8"), "zwart mag nog lang rokeren");
    CHECK(!has_move(&q, "e8g8"), "zwart niet kort: witte toren op f1 valt f8 aan");
    q = p;
    play(&q, NULL, NULL, "e1c1");
    CHECK(q.board[2] == CE_PIECE(CE_WHITE, CE_KING) && q.board[3] == CE_PIECE(CE_WHITE, CE_ROOK) && !q.board[0],
          "na lange rokade: koning c1, toren d1");
    char san[16];
    CEMove m;
    ce_parse_uci(&p, "e1g1", &m);
    ce_move_to_san(&p, m, san, sizeof san);
    CHECK(strcmp(san, "O-O") == 0, "SAN korte rokade: %s", san);

    // Door een aangevallen veld (f1) rokeren mag niet; lange rokade wel.
    load(&p, "4kr2/8/8/8/8/8/8/R3K2R w KQ - 0 1");
    CHECK(!has_move(&p, "e1g1"), "geen korte rokade als f1 wordt aangevallen");
    CHECK(has_move(&p, "e1c1"), "lange rokade blijft mogelijk");
    // Uit schaak rokeren mag niet.
    load(&p, "4r1k1/8/8/8/8/8/8/R3K2R w KQ - 0 1");
    CHECK(!has_move(&p, "e1g1") && !has_move(&p, "e1c1"), "geen rokade uit schaak");
    // Stuk ertussen.
    load(&p, "4k3/8/8/8/8/8/8/RN2K1NR w KQ - 0 1");
    CHECK(!has_move(&p, "e1g1") && !has_move(&p, "e1c1"), "geen rokade met stuk ertussen");
    // Torenzet haalt het recht aan die kant weg.
    load(&p, "4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1");
    play(&p, NULL, NULL, "h1h2");
    play(&p, NULL, NULL, "e8d8");
    play(&p, NULL, NULL, "h2h1");
    play(&p, NULL, NULL, "d8e8");
    CHECK(!has_move(&p, "e1g1") && has_move(&p, "e1c1"), "na torenzet geen korte rokade meer");
    // Toren slaan haalt recht weg.
    load(&p, "r3k2r/8/8/8/8/8/6b1/R3K2R b KQkq - 0 1");
    play(&p, NULL, NULL, "g2h1");
    CHECK(!(p.castling & CE_CASTLE_WK), "geslagen toren h1: geen korte rokade");
}

static void test_en_passant(void) {
    printf("[en passant]\n");
    CEPosition p;
    load(&p, "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1");
    play(&p, NULL, NULL, "d7d5");
    play(&p, NULL, NULL, "e4e5");
    play(&p, NULL, NULL, "f7f5");
    CHECK(p.ep == CE_SQ(5, 5), "en-passantveld f6 gezet (kreeg %d)", p.ep);
    CHECK(has_move(&p, "e5f6"), "e5xf6 en passant moet kunnen");
    CEMove m;
    ce_parse_uci(&p, "e5f6", &m);
    char san[16];
    ce_move_to_san(&p, m, san, sizeof san);
    CHECK(strcmp(san, "exf6") == 0, "SAN en passant: %s", san);
    CEPosition q = p;
    ce_make(&q, m);
    CHECK(q.board[CE_SQ(5, 4)] == 0, "geslagen pion op f5 is weg");
    CHECK(q.board[CE_SQ(5, 5)] == CE_PIECE(CE_WHITE, CE_PAWN), "witte pion staat op f6");
    CHECK(q.hash == ce_compute_hash(&q), "hash klopt na en passant");
    // Niet meer mogelijk een zet later.
    play(&p, NULL, NULL, "g1f3");
    play(&p, NULL, NULL, "a7a6");
    CHECK(!has_move(&p, "e5f6"), "en passant alleen direct");
    // Gepend langs de rij: e5xd6 zou de eigen koning schaak zetten.
    load(&p, "8/8/8/K2pP2r/8/8/8/7k w - d6 0 1");
    CHECK(!has_move(&p, "e5d6"), "en passant mag niet als de koning dan schaak staat");
    load(&p, "8/8/8/K2pP3/8/8/8/7k w - d6 0 1");
    CHECK(has_move(&p, "e5d6"), "zonder penning mag en passant wel");
}

static void test_promotion(void) {
    printf("[promotie]\n");
    CEPosition p;
    load(&p, "1r5k/P7/8/8/8/8/8/K7 w - - 0 1");
    CEMove mv[CE_MAX_MOVES];
    int n = ce_gen_legal(&p, mv);
    int promos = 0;
    for (int i = 0; i < n; i++) if (mv[i].flags & CE_FLAG_PROMO) promos++;
    CHECK(promos == 8, "4 promoties vooruit + 4 met slaan op b8 (kreeg %d)", promos);
    CEPosition q = p;
    play(&q, NULL, NULL, "a7a8q");
    CHECK(q.board[CE_SQ(0, 7)] == CE_PIECE(CE_WHITE, CE_QUEEN), "a8 is een witte dame");
    q = p;
    play(&q, NULL, NULL, "a7b8n");
    CHECK(q.board[CE_SQ(1, 7)] == CE_PIECE(CE_WHITE, CE_KNIGHT), "b8 is een wit paard (onderpromotie met slaan)");
    CHECK(q.hash == ce_compute_hash(&q), "hash klopt na promotie");
    CEMove m;
    ce_parse_uci(&p, "a7a8q", &m);
    char san[16];
    ce_move_to_san(&p, m, san, sizeof san);
    CHECK(strcmp(san, "a8=Q") == 0, "SAN promotie: %s", san);
    // Zwarte promotie.
    load(&p, "7k/8/8/8/8/8/p7/7K b - - 0 1");
    play(&p, NULL, NULL, "a2a1r");
    CHECK(p.board[0] == CE_PIECE(CE_BLACK, CE_ROOK), "zwarte promotie naar toren");
}

static void test_mate_and_stalemate(void) {
    printf("[mat en pat]\n");
    CEPosition p;
    uint64_t hist[64];
    int nh = 0;
    ce_start(&p);
    hist[nh++] = p.hash;
    play(&p, hist, &nh, "f2f3");
    play(&p, hist, &nh, "e7e5");
    play(&p, hist, &nh, "g2g4");
    CEMove m;
    ce_parse_uci(&p, "d8h4", &m);
    char san[16];
    ce_move_to_san(&p, m, san, sizeof san);
    CHECK(strcmp(san, "Qh4#") == 0, "SAN mat: %s", san);
    play(&p, hist, &nh, "d8h4");
    CHECK(ce_status(&p, hist, nh) == CE_CHECKMATE, "gekkenmat is mat");
    CHECK(ce_in_check(&p, CE_WHITE), "wit staat schaak");

    load(&p, "6k1/5ppp/8/8/8/8/8/R5K1 b - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_ONGOING, "nog geen mat");
    load(&p, "R5k1/5ppp/8/8/8/8/8/6K1 b - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_CHECKMATE, "achterste-rijmat");

    load(&p, "7k/5Q2/6K1/8/8/8/8/8 b - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_STALEMATE, "pat");
    CHECK(!ce_in_check(&p, CE_BLACK), "bij pat staat zwart niet schaak");
    load(&p, "k7/P7/K7/8/8/8/8/8 b - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_STALEMATE, "pat met pion");
}

static void test_draws(void) {
    printf("[remise]\n");
    CEPosition p;
    load(&p, "4k3/8/8/8/8/8/8/4K3 w - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_DRAW_MATERIAL, "koning tegen koning");
    load(&p, "4k3/8/8/8/8/8/8/2B1K3 w - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_DRAW_MATERIAL, "koning + loper tegen koning");
    load(&p, "4k3/8/8/8/8/8/8/1N2K3 w - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_DRAW_MATERIAL, "koning + paard tegen koning");
    load(&p, "4kb2/8/8/8/8/8/8/2B1K3 w - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_DRAW_MATERIAL, "lopers op dezelfde kleur");
    load(&p, "2b1k3/8/8/8/8/8/8/2B1K3 w - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_ONGOING, "lopers op verschillende kleur: geen remise");
    load(&p, "4k3/8/8/8/8/8/8/R3K3 w - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_ONGOING, "koning + toren is genoeg");
    load(&p, "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1");
    CHECK(ce_status(&p, NULL, 0) == CE_ONGOING, "pion is genoeg");

    load(&p, "4k3/8/8/8/8/8/8/R3K3 w - - 100 80");
    CHECK(ce_status(&p, NULL, 0) == CE_DRAW_FIFTY, "50-zettenregel");
    load(&p, "4k3/8/8/8/8/8/8/R3K3 w - - 99 80");
    CHECK(ce_status(&p, NULL, 0) == CE_ONGOING, "nog net geen 50 zetten");
    // Mat gaat voor de 50-zettenregel.
    load(&p, "R5k1/5ppp/8/8/8/8/8/6K1 b - - 100 80");
    CHECK(ce_status(&p, NULL, 0) == CE_CHECKMATE, "mat telt ook bij 100 halve zetten");

    // Drievoudige herhaling.
    uint64_t hist[64];
    int nh = 0;
    ce_start(&p);
    hist[nh++] = p.hash;
    const char *seq[] = { "g1f3", "g8f6", "f3g1", "f6g8", "g1f3", "g8f6", "f3g1", "f6g8" };
    for (int i = 0; i < 8; i++) {
        play(&p, hist, &nh, seq[i]);
        CEStatus st = ce_status(&p, hist, nh);
        if (i < 7) CHECK(st == CE_ONGOING, "nog geen herhaling na zet %d", i + 1);
        else CHECK(st == CE_DRAW_REPETITION, "drievoudige herhaling na zet 8");
    }
}

static void test_custom_positions(void) {
    printf("[eigen stellingen]\n");
    CEPosition p;
    char err[256];
    // Wit: koning + 3 dames + 2 torens + 4 paarden; zwart: koning + 8 pionnen.
    load(&p, "4k3/pppppppp/8/8/8/N1N1N1N1/8/QQQRR1K1 w - - 0 1");
    CHECK(ce_validate(&p, err, sizeof err), "stelling met 3 dames is geldig: %s", err);
    CEMove mv[CE_MAX_MOVES];
    int n = ce_gen_legal(&p, mv);
    CHECK(n > 40, "veel zetten met 3 dames (kreeg %d)", n);
    uint64_t pf = ce_perft(&p, 2);
    CHECK(pf > 0, "perft 2 werkt met meerdere dames (%llu)", (unsigned long long)pf);
    CEMove botMove;
    CHECK(cb_choose_move(&p, NULL, 0, 3, &botMove, NULL), "bot vindt een zet met 3 dames");
    CHECK(ce_find_move(&p, botMove.from, botMove.to, botMove.promo, &botMove), "botzet is legaal");

    // Negen dames voor wit: veel zetten, de zetlijst mag niet overlopen.
    load(&p, "kn6/pp6/8/3QQQ2/3QQQ2/3QQQ2/8/7K w - - 0 1");
    n = ce_gen_legal(&p, mv);
    CHECK(n >= 60, "9 dames: veel zetten (kreeg %d)", n);
    CHECK(ce_validate(&p, err, sizeof err), "9 dames is geldig");

    // Kant met alleen koning + pionnen.
    load(&p, "4k3/8/8/8/8/8/PPPPPPPP/4K3 w - - 0 1");
    n = ce_gen_legal(&p, mv);
    CHECK(n == 18, "koning + 8 pionnen: 16 pionzetten + 2 koningszetten (kreeg %d)", n);
    CHECK(ce_status(&p, NULL, 0) == CE_ONGOING, "koning + pionnen: partij loopt");
    load(&p, "4k3/pppppppp/8/8/8/8/8/4K3 b - - 0 1");
    n = ce_gen_legal(&p, mv);
    CHECK(n == 18, "zwart koning + 8 pionnen: 18 zetten (kreeg %d)", n);
    CHECK(cb_choose_move(&p, NULL, 0, 2, &botMove, NULL), "bot speelt met alleen pionnen");

    // Controles van de bewerker.
    load(&p, "4k3/8/8/8/8/8/8/3KK3 w - - 0 1");
    CHECK(!ce_validate(&p, err, sizeof err), "twee witte koningen is ongeldig");
    load(&p, "8/8/8/8/8/8/8/4K3 w - - 0 1");
    CHECK(!ce_validate(&p, err, sizeof err), "zwarte koning ontbreekt");
    load(&p, "P3k3/8/8/8/8/8/8/4K3 w - - 0 1");
    CHECK(!ce_validate(&p, err, sizeof err), "pion op rij 8 is ongeldig");
    load(&p, "4k3/8/8/8/8/8/8/4K2p w - - 0 1");
    CHECK(!ce_validate(&p, err, sizeof err), "pion op rij 1 is ongeldig");
    load(&p, "4k3/8/8/8/8/8/8/4R1K1 w - - 0 1");
    CHECK(!ce_validate(&p, err, sizeof err), "zwart staat schaak terwijl wit aan zet is: ongeldig");
    load(&p, "4k3/8/8/8/8/8/8/4R1K1 b - - 0 1");
    CHECK(ce_validate(&p, err, sizeof err), "zwart staat schaak en is aan zet: geldig");

    // Rokaderechten automatisch.
    ce_clear(&p);
    p.board[4] = CE_PIECE(CE_WHITE, CE_KING);
    p.board[7] = CE_PIECE(CE_WHITE, CE_ROOK);
    p.board[60] = CE_PIECE(CE_BLACK, CE_KING);
    ce_auto_castling(&p);
    CHECK(p.castling == CE_CASTLE_WK, "alleen korte rokade wit (kreeg %d)", p.castling);
}

static void test_fen_and_hash(void) {
    printf("[FEN en hash]\n");
    const char *fens[] = {
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
        "8/8/8/K2pP2r/8/8/8/7k w - d6 0 1",
        "4k3/pppppppp/8/8/8/N1N1N1N1/8/QQQRR1K1 b - - 12 40",
    };
    for (int i = 0; i < 4; i++) {
        CEPosition p;
        load(&p, fens[i]);
        char out[128];
        ce_to_fen(&p, out, sizeof out);
        CHECK(strcmp(out, fens[i]) == 0, "FEN heen en terug: %s -> %s", fens[i], out);
    }
    // Hash bijwerken tijdens zetten moet gelijk zijn aan opnieuw berekenen.
    CEPosition p;
    load(&p, "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1");
    CEMove mv[CE_MAX_MOVES];
    int n = ce_gen_legal(&p, mv);
    int ok = 1;
    for (int i = 0; i < n; i++) {
        CEPosition q = p;
        ce_make(&q, mv[i]);
        if (q.hash != ce_compute_hash(&q)) ok = 0;
        CEMove mv2[CE_MAX_MOVES];
        int n2 = ce_gen_legal(&q, mv2);
        for (int j = 0; j < n2; j++) {
            CEPosition r = q;
            ce_make(&r, mv2[j]);
            if (r.hash != ce_compute_hash(&r)) ok = 0;
        }
    }
    CHECK(ok, "hash klopt na alle zetten (2 diep)");
    CHECK(!ce_from_fen(&p, "dit is geen fen"), "foute FEN wordt geweigerd");
    CHECK(!ce_from_fen(&p, "8/8/8 w - - 0 1"), "te korte FEN wordt geweigerd");
}

static void test_san(void) {
    printf("[notatie]\n");
    CEPosition p;
    CEMove m;
    char san[16];
    ce_start(&p);
    ce_parse_uci(&p, "e2e4", &m);
    ce_move_to_san(&p, m, san, sizeof san);
    CHECK(strcmp(san, "e4") == 0, "SAN e4: %s", san);
    ce_parse_uci(&p, "g1f3", &m);
    ce_move_to_san(&p, m, san, sizeof san);
    CHECK(strcmp(san, "Nf3") == 0, "SAN Nf3: %s", san);
    load(&p, "4k3/8/8/8/8/R7/8/R3K3 w - - 0 1");
    ce_parse_uci(&p, "a1a2", &m);
    ce_move_to_san(&p, m, san, sizeof san);
    CHECK(strcmp(san, "R1a2") == 0, "SAN met rij erbij: %s", san);
    load(&p, "4k3/8/8/8/8/8/4K3/R6R w - - 0 1");
    ce_parse_uci(&p, "a1d1", &m);
    ce_move_to_san(&p, m, san, sizeof san);
    CHECK(strcmp(san, "Rad1") == 0, "SAN met lijn erbij: %s", san);
    load(&p, "4k3/8/8/8/8/8/8/4K2R w - - 0 1");
    ce_parse_uci(&p, "h1h8", &m);
    ce_move_to_san(&p, m, san, sizeof san);
    CHECK(strcmp(san, "Rh8+") == 0, "SAN schaak: %s", san);
}

static void test_parse_san(void) {
    printf("[notatie lezen]\n");
    CEPosition p;
    ce_start(&p);
    const char *game = "e4 c5 Nc3 Nc6 f4 g6 Nf3 Bg7 Bc4 e6 O-O Nge7 Re1 O-O d3 d5 exd5 exd5 Bb5 Nd4 "
                       "a3 Bg4 Ba4 Nef5 Rf1 Nxf3+ gxf3 Bh3 Re1 Bd4+ Kh1 Qh4 Nxd5 Qf2 Qe2";
    char buf[512];
    snprintf(buf, sizeof buf, "%s", game);
    int count = 0, ok = 1;
    for (char *tok = strtok(buf, " "); tok; tok = strtok(NULL, " ")) {
        CEMove m;
        if (!ce_parse_san(&p, tok, &m)) { ok = 0; printf("  kon %s niet lezen\n", tok); break; }
        ce_make(&p, m);
        count++;
    }
    CHECK(ok && count == 35, "partij van 35 halve zetten nagespeeld (%d)", count);
    CEMove m;
    CHECK(ce_parse_san(&p, "Bg2#", &m), "mat-zet Bg2# gelezen");
    // Promotie en 0-0 met nullen.
    load(&p, "8/4P3/8/8/8/8/k7/4K2R w K - 0 1");
    CHECK(ce_parse_san(&p, "e8=Q", &m) && (m.flags & CE_FLAG_PROMO) && m.promo == CE_QUEEN, "promotie e8=Q gelezen");
    CHECK(ce_parse_san(&p, "e8=N", &m) && m.promo == CE_KNIGHT, "onderpromotie e8=N gelezen");
    CHECK(ce_parse_san(&p, "0-0", &m) && (m.flags & CE_FLAG_CASTLE), "0-0 met nullen gelezen");
    CHECK(!ce_parse_san(&p, "Qd4", &m), "onmogelijke zet wordt geweigerd");
    CHECK(!ce_parse_san(&p, "", &m), "lege zet wordt geweigerd");
}

static void test_bot(void) {
    printf("[bot]\n");
    CEPosition p;
    CEMove m;
    int score = 0;
    // Mat in 1.
    load(&p, "6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1");
    CHECK(cb_search_depth(&p, 3, &m, &score), "bot zoekt");
    char uci[8];
    ce_move_to_uci(m, uci, sizeof uci);
    CHECK(strcmp(uci, "a1a8") == 0, "bot vindt mat in 1 (Ra8#), speelde %s", uci);
    // Gratis dame slaan.
    load(&p, "4k3/8/8/3q4/8/8/8/3RK3 w - - 0 1");
    cb_search_depth(&p, 3, &m, &score);
    ce_move_to_uci(m, uci, sizeof uci);
    CHECK(strcmp(uci, "d1d5") == 0, "bot slaat de onbeschermde dame, speelde %s", uci);
    // Mat in 2 met meerdere dames (eigen stelling).
    load(&p, "7k/8/8/8/1Q6/Q7/8/K7 w - - 0 1");
    cb_search_depth(&p, 4, &m, &score);
    CHECK(score > 90000, "bot ziet mat met twee dames (score %d)", score);
    // Elk niveau geeft een legale zet vanaf de beginstelling.
    ce_start(&p);
    for (int lvl = 1; lvl <= 4; lvl++) {
        CHECK(cb_choose_move(&p, &p.hash, 1, lvl, &m, NULL), "niveau %d geeft een zet", lvl);
        CEMove chk;
        CHECK(ce_find_move(&p, m.from, m.to, m.promo, &chk), "niveau %d: zet is legaal", lvl);
    }
    // Geen zetten (mat): bot geeft 0.
    load(&p, "R5k1/5ppp/8/8/8/8/8/6K1 b - - 0 1");
    CHECK(!cb_choose_move(&p, NULL, 0, 3, &m, NULL), "geen zet als je mat staat");
    // Stoppen werkt.
    volatile int cancel = 1;
    ce_start(&p);
    CHECK(!cb_choose_move(&p, NULL, 0, 5, &m, &cancel), "geannuleerde bot geeft geen zet");
    // Bot speelt een hele partij tegen zichzelf zonder fouten.
    ce_start(&p);
    uint64_t hist[512];
    int nh = 0;
    hist[nh++] = p.hash;
    int plies = 0;
    while (plies < 120 && ce_status(&p, hist, nh) == CE_ONGOING) {
        if (!cb_choose_move(&p, hist, nh, 2, &m, NULL)) break;
        CEMove chk;
        if (!ce_find_move(&p, m.from, m.to, m.promo, &chk)) { CHECK(0, "illegale botzet in partij"); break; }
        ce_make(&p, m);
        hist[nh++] = p.hash;
        plies++;
    }
    CHECK(plies > 0, "bot speelde %d halve zetten", plies);
    printf("  partij bot tegen bot: %d halve zetten, status %d\n", plies, (int)ce_status(&p, hist, nh));
}

static int rate(const char *fen, const char *uci, CBMoveAnalysis *a) {
    CEPosition p;
    load(&p, fen);
    CEMove m;
    if (!ce_parse_uci(&p, uci, &m)) { printf("FOUT  zet %s niet legaal\n", uci); g_fail++; return -1; }
    if (!cb_analyse_move(&p, NULL, 0, m, 3, a, NULL)) { printf("FOUT  analyse mislukt\n"); g_fail++; return -1; }
    return (int)a->rating;
}

static void test_move_rating(void) {
    printf("[zetbeoordeling]\n");
    CBMoveAnalysis a;
    int r = rate("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1", "a1a8", &a);
    CHECK(r == CB_RATE_BEST, "mat in 1 is de beste zet (kreeg %d)", r);
    r = rate("4k3/8/8/8/8/8/3Q4/4K3 w - - 0 1", "d2d7", &a);
    CHECK(r == CB_RATE_BLUNDER, "dame weggeven is een blunder (kreeg %d, verlies %.1f)", r, a.winLoss);
    char uci[8];
    ce_move_to_uci(a.best, uci, sizeof uci);
    CHECK(strcmp(uci, "d2d7") != 0, "beste zet is niet de blunder (%s)", uci);
    r = rate("4k3/8/8/3q4/8/8/8/3RK3 w - - 0 1", "d1d5", &a);
    CHECK(r == CB_RATE_BEST, "gratis dame slaan is de beste zet (kreeg %d)", r);
    r = rate("4k3/8/8/3q4/8/8/8/3RK3 w - - 0 1", "e1f2", &a);
    CHECK(r >= CB_RATE_MISTAKE, "dame laten staan is een fout of blunder (kreeg %d, verlies %.1f)", r, a.winLoss);
    r = rate("k7/8/K7/8/7p/8/8/1R6 b - - 0 1", "h4h3", &a);
    CHECK(r == CB_RATE_FORCED, "enige zet wordt herkend (kreeg %d)", r);
    r = rate("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", "e2e4", &a);
    CHECK(r <= CB_RATE_GOOD, "1.e4 is minstens goed (kreeg %d, verlies %.1f)", r, a.winLoss);
    CHECK(cb_win_percent(0) > 49.9 && cb_win_percent(0) < 50.1, "50%% bij gelijke stand");
    CHECK(cb_win_percent(100000) > 99.0 && cb_win_percent(-100000) < 1.0, "mat = bijna 100%% of 0%%");
    CHECK(cb_move_accuracy(0) > 99.0 && cb_move_accuracy(40) < 30.0, "nauwkeurigheid daalt bij verlies");
    volatile int cancel = 1;
    CEPosition p;
    ce_start(&p);
    CEMove m;
    ce_parse_uci(&p, "g1f3", &m);
    CHECK(!cb_analyse_move(&p, NULL, 0, m, 5, &a, &cancel) || 1, "annuleren crasht niet");
}

static void test_puzzles(void) {
    printf("[puzzels]\n");
    int mates = 0, endgames = 0, lineCount = 0, mate1 = 0, mate2 = 0;
    for (int i = 0; i < cp_count(); i++) {
        const CPPuzzle *pz = cp_get(i);
        CEPosition p;
        char err[256];
        CHECK(ce_from_fen(&p, pz->fen), "puzzel %d: FEN leesbaar", i);
        CHECK(ce_validate(&p, err, sizeof err), "puzzel %d (%s): geldige stelling: %s", i, pz->title, err);
        CHECK(ce_status(&p, NULL, 0) == CE_ONGOING, "puzzel %d: partij loopt nog", i);
        if (pz->type == CP_MATE) {
            mates++;
            if (pz->n == 1) mate1++; else mate2++;
            CHECK(cb_mate_in(&p, pz->n), "puzzel %d (%s): mat in %d bestaat", i, pz->title, pz->n);
            if (pz->n > 1) CHECK(!cb_mate_in(&p, pz->n - 1), "puzzel %d (%s): niet korter dan %d", i, pz->title, pz->n);
            CEMove m;
            CHECK(cb_find_mate_move(&p, pz->n, &m), "puzzel %d: tip gevonden", i);
            CHECK(cb_move_mates_within(&p, m, pz->n), "puzzel %d: tip klopt", i);
            if (pz->n == 2) {
                CEPosition q = p;
                ce_make(&q, m);
                CEMove d;
                CHECK(cb_best_defense(&q, 1, &d), "puzzel %d: verdediging gevonden", i);
                ce_make(&q, d);
                CHECK(cb_mate_in(&q, 1), "puzzel %d: na verdediging nog mat in 1", i);
            }
        } else if (pz->type == CP_LINE) {
            lineCount++;
            // Speel de oplossing na: elke zet moet legaal zijn.
            CEPosition q = p;
            char buf[512];
            snprintf(buf, sizeof buf, "%s", pz->line ? pz->line : "");
            int plies = 0, legalAll = 1;
            for (char *tok = strtok(buf, " "); tok; tok = strtok(NULL, " ")) {
                CEMove m;
                if (!ce_parse_uci(&q, tok, &m)) { legalAll = 0; break; }
                ce_make(&q, m);
                plies++;
            }
            CHECK(legalAll, "eindspel %d (%s): oplossing is legaal", i, pz->title);
            CHECK(plies % 2 == 1, "eindspel %d: oplossing eindigt met een eigen zet", i);
            CHECK((plies + 1) / 2 == pz->n, "eindspel %d: aantal eigen zetten klopt", i);
            if (pz->last) {
                CEPosition before;
                CHECK(strlen(pz->last) >= 4, "eindspel %d: laatste zet leesbaar", i);
                (void)before;
            }
        } else {
            endgames++;
            CHECK(pz->n >= 10, "eindspel %d: genoeg zetten", i);
        }
    }
    CHECK(mates == mate1 + mate2 && mate1 >= 40 && mate2 >= 24 && endgames >= 4 && lineCount >= 50,
          "genoeg puzzels (%d mat in 1, %d mat in 2, %d eindspel tegen bot, %d eindspel-reeksen)", mate1, mate2, endgames, lineCount);
    printf("  %d mat in 1, %d mat in 2, %d eindspel tegen bot, %d eindspel-reeksen\n", mate1, mate2, endgames, lineCount);
    // Een foute zet wordt herkend.
    CEPosition p;
    ce_from_fen(&p, "6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1");
    CEMove m;
    ce_parse_uci(&p, "d1d7", &m);
    CHECK(!cb_move_mates_within(&p, m, 1), "Rd7 is geen mat");
    ce_parse_uci(&p, "d1d8", &m);
    CHECK(cb_move_mates_within(&p, m, 1), "Rd8 is mat");
    // Pat telt niet als mat.
    ce_from_fen(&p, "k7/2Q5/1K6/8/8/8/8/8 w - - 0 1");
    ce_parse_uci(&p, "c7c6", &m);
    CHECK(!cb_move_mates_within(&p, m, 1), "Qc6 is pat, geen mat");
}

static void test_adaptive_bot(void) {
    printf("[meegroeiende bot]\n");
    CEPosition p;
    CEMove m;
    for (int s = 0; s <= 100; s += 10) {
        ce_start(&p);
        int ok = 1;
        for (int ply = 0; ply < 6 && ok; ply++) {
            if (!cb_choose_move_strength(&p, NULL, 0, s, &m, NULL)) { ok = 0; break; }
            CEMove chk;
            if (!ce_find_move(&p, m.from, m.to, m.promo, &chk)) ok = 0;
            else ce_make(&p, m);
        }
        CHECK(ok, "sterkte %d speelt legale zetten", s);
    }
    // Sterk: vindt mat in 1.
    ce_from_fen(&p, "6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1");
    cb_choose_move_strength(&p, NULL, 0, 100, &m, NULL);
    char uci[8];
    ce_move_to_uci(m, uci, sizeof uci);
    CHECK(strcmp(uci, "a1a8") == 0, "sterkte 100 vindt mat in 1 (speelde %s)", uci);
    // Ultra slecht: laat in 20 pogingen minstens een keer het mat liggen.
    int missed = 0;
    for (int i = 0; i < 20; i++) {
        cb_choose_move_strength(&p, NULL, 0, 0, &m, NULL);
        ce_move_to_uci(m, uci, sizeof uci);
        if (strcmp(uci, "a1a8") != 0) missed++;
    }
    CHECK(missed >= 5, "sterkte 0 is echt zwak (liet mat %d van 20 keer liggen)", missed);
    // Partij: sterkte 100 tegen sterkte 0 moet goed aflopen voor de sterke kant.
    ce_start(&p);
    uint64_t hist[400];
    int nh = 0;
    hist[nh++] = p.hash;
    int plies = 0;
    while (plies < 80 && ce_status(&p, hist, nh) == CE_ONGOING) {
        int s = p.side == CE_WHITE ? 65 : 0;
        if (!cb_choose_move_strength(&p, hist, nh, s, &m, NULL)) break;
        ce_make(&p, m);
        hist[nh++] = p.hash;
        plies++;
    }
    CEStatus st = ce_status(&p, hist, nh);
    int score = cb_evaluate(&p);
    if (p.side == CE_BLACK) score = -score;
    printf("  sterkte 65 (wit) tegen 0 (zwart): %d halve zetten, status %d, stand %+d\n", plies, (int)st, score);
    CHECK((st == CE_CHECKMATE && p.side == CE_BLACK) || score > 300, "sterkte 65 wint van sterkte 0");
}

int main(void) {
    ce_init();
    test_perft();
    test_castling();
    test_en_passant();
    test_promotion();
    test_mate_and_stalemate();
    test_draws();
    test_custom_positions();
    test_fen_and_hash();
    test_san();
    test_bot();
    test_parse_san();
    test_move_rating();
    test_puzzles();
    test_adaptive_bot();
    printf("\nGeslaagd: %d, mislukt: %d\n", g_pass, g_fail);
    if (g_fail) {
        printf("TESTS MISLUKT\n");
        return 1;
    }
    printf("ALLE TESTS GESLAAGD\n");
    return 0;
}
