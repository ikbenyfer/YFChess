// ChessPuzzles.c
// YF Schaak - de puzzellijst en een kleine matzoeker.

#include "ChessPuzzles.h"

static const CPPuzzle PUZZLES[] = {
    // ---- Mat in 1 ----
    { CP_MATE, 1, "6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1", "Achterste rij",
      "De zwarte koning zit vast achter zijn eigen pionnen." },
    { CP_MATE, 1, "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 1", "Herdersmat",
      "Het veld f7 wordt alleen door de koning verdedigd." },
    { CP_MATE, 1, "7k/8/6K1/8/8/8/Q7/8 w - - 0 1", "Dame en koning",
      "Je koning dekt al de velden voor de zwarte koning. Geef schaak langs de rand." },
    { CP_MATE, 1, "6rk/6pp/8/6N1/8/8/8/6K1 w - - 0 1", "Stikmat",
      "De koning staat helemaal ingesloten door zijn eigen stukken. Welk stuk springt eroverheen?" },
    { CP_MATE, 1, "rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2", "Gekkenmat (zwart)",
      "Wit heeft de diagonaal naar zijn koning geopend." },
    { CP_MATE, 1, "r1bqk2r/pppp1ppp/2n2n2/2b1p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1", "Aanval op f7",
      "Dame en loper kijken allebei naar hetzelfde veld." },
    { CP_MATE, 1, "7k/7p/5N2/8/8/8/8/6RK w - - 0 1", "Toren en paard",
      "Het paard beschermt een belangrijk veld naast de koning." },
    { CP_MATE, 1, "3k4/8/3K4/8/8/8/8/7R w - - 0 1", "Torenmat",
      "De koningen staan tegenover elkaar. Nu nog schaak langs de rand." },
    { CP_MATE, 1, "1k6/ppp5/8/8/8/8/8/K3R3 w - - 0 1", "Achterste rij 2",
      "Zwart heeft zijn pionnen niet opgeschoven." },
    { CP_MATE, 1, "6k1/5ppp/8/8/8/8/2q2PPP/6K1 b - - 0 1", "Zwart: dame op de rand",
      "De witte koning kan nergens heen als je schaak geeft op de eerste rij." },
    { CP_MATE, 1, "6k1/5ppp/8/8/8/8/1B4Q1/6K1 w - - 0 1", "Dame en loper",
      "De loper op b2 kijkt naar g7." },
    { CP_MATE, 1, "1r4k1/5ppp/8/8/8/8/5PPP/6K1 b - - 0 1", "Zwart: toren",
      "Ook wit heeft geen luchtgaatje gemaakt." },
    { CP_MATE, 1, "k7/2Q5/1K6/8/8/8/8/8 w - - 0 1", "Dame in de hoek",
      "Er zijn meerdere manieren. Pas op voor pat!" },
    // ---- Mat in 2 ----
    { CP_MATE, 2, "r5k1/5ppp/8/8/8/8/3R1PPP/3R2K1 w - - 0 1", "Dubbele torens",
      "Offer de eerste toren; de tweede maakt het af." },
    { CP_MATE, 2, "5r1k/6pp/7N/3Q4/8/8/8/6K1 w - - 0 1", "Stikmat van Philidor",
      "Offer je dame op g8. De toren moet slaan en dan springt het paard." },
    { CP_MATE, 2, "2k5/8/1K6/8/8/8/8/3R4 w - - 0 1", "Toren en koning",
      "Sluit eerst de koning op met een rustige torenzet." },
    { CP_MATE, 2, "6k1/8/5K2/8/8/8/8/7Q w - - 0 1", "Dame en koning 2",
      "Neem eerst velden af zonder schaak te geven. Pas op voor pat." },
    { CP_MATE, 2, "6k1/8/8/8/8/8/R7/1R4K1 w - - 0 1", "Torenladder",
      "De ene toren sluit een rij af, de andere geeft mat op de rij erachter." },
    { CP_MATE, 2, "r1bk3r/pppp1Qpp/2n5/8/8/8/PPP2PPP/R1B1K2R w KQ - 0 1", "Loper helpt de dame",
      "Geef eerst schaak met de loper." },
    { CP_MATE, 2, "6rk/6pp/8/8/8/8/1B4Q1/6K1 w - - 0 1", "Rustige damezet",
      "Dreig mat op g7. De zwarte toren kan niet alles tegelijk verdedigen." },
    { CP_MATE, 2, "1r4k1/1r3ppp/8/8/8/8/4RPPP/6K1 b - - 0 1", "Zwart: dubbele torens",
      "Geef schaak op de eerste rij. Wit kan alleen ertussen gaan staan." },
    { CP_MATE, 2, "3r2k1/3r1ppp/8/8/8/8/5PPP/R5K1 b - - 0 1", "Zwart: offer en mat",
      "Offer een toren op d1." },
    // ---- Eindspel-oefeningen (zet mat tegen de bot) ----
    { CP_ENDGAME, 15, "8/8/8/4k3/8/8/8/3QK3 w - - 0 1", "Koning + dame tegen koning",
      "Duw de koning met je dame naar de rand en haal je eigen koning erbij. Pas op voor pat!" },
    { CP_ENDGAME, 30, "8/8/8/4k3/8/8/8/4K2R w - - 0 1", "Koning + toren tegen koning",
      "Maak het hok van de zwarte koning steeds kleiner. Je koning moet helpen." },
    { CP_ENDGAME, 15, "8/8/3k4/8/8/8/8/R3K2R w - - 0 1", "Twee torens (ladder)",
      "Schuif de torens om de beurt een rij op, zoals een ladder." },
    { CP_ENDGAME, 40, "4k3/8/4K3/4P3/8/8/8/8 w - - 0 1", "Pion naar de overkant",
      "Je koning moet de pion begeleiden. Maak een dame en zet daarna mat." },
};

int cp_count(void) {
    return (int)(sizeof(PUZZLES) / sizeof(PUZZLES[0]));
}

const CPPuzzle *cp_get(int index) {
    if (index < 0 || index >= cp_count()) return NULL;
    return &PUZZLES[index];
}

static int all_replies_mate(const CEPosition *p, int n);

int cb_move_mates_within(const CEPosition *p, CEMove m, int n) {
    CEPosition q = *p;
    ce_make(&q, m);
    int check = ce_in_check(&q, q.side);
    if (n <= 1 && !check) return 0;   // mat kan alleen met schaak
    CEMove mv[CE_MAX_MOVES];
    int k = ce_gen_legal(&q, mv);
    if (k == 0) return check;          // mat (of pat = geen mat)
    if (n <= 1) return 0;
    return all_replies_mate(&q, n - 1);
}

int cb_mate_in(const CEPosition *p, int n) {
    if (n < 1) return 0;
    CEMove mv[CE_MAX_MOVES];
    int k = ce_gen_legal(p, mv);
    for (int i = 0; i < k; i++)
        if (cb_move_mates_within(p, mv[i], n)) return 1;
    return 0;
}

static int all_replies_mate(const CEPosition *p, int n) {
    CEMove mv[CE_MAX_MOVES];
    int k = ce_gen_legal(p, mv);
    if (k == 0) return 0;
    for (int i = 0; i < k; i++) {
        CEPosition q = *p;
        ce_make(&q, mv[i]);
        if (!cb_mate_in(&q, n)) return 0;
    }
    return 1;
}

int cb_find_mate_move(const CEPosition *p, int n, CEMove *out) {
    CEMove mv[CE_MAX_MOVES];
    int k = ce_gen_legal(p, mv);
    // Eerst de kortste weg.
    for (int d = 1; d <= n; d++)
        for (int i = 0; i < k; i++)
            if (cb_move_mates_within(p, mv[i], d)) { *out = mv[i]; return 1; }
    return 0;
}

int cb_best_defense(const CEPosition *p, int n, CEMove *out) {
    CEMove mv[CE_MAX_MOVES];
    int k = ce_gen_legal(p, mv);
    if (k == 0) return 0;
    int bestLen = -1;
    for (int i = 0; i < k; i++) {
        CEPosition q = *p;
        ce_make(&q, mv[i]);
        int len = n + 1;   // geen mat gevonden = beste verdediging
        for (int d = 1; d <= n; d++) {
            if (cb_mate_in(&q, d)) { len = d; break; }
        }
        if (len > bestLen) {
            bestLen = len;
            *out = mv[i];
            if (len > n) break;
        }
    }
    return 1;
}
