// ChessPuzzles.c
// YF Schaak - de puzzellijst en een kleine matzoeker.

#include "ChessPuzzles.h"

static const CPPuzzle PUZZLES[] = {
    // ---- Mat in 1 ----
    { CP_MATE, 1, "6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1", "Achterste rij",
      "De zwarte koning zit vast achter zijn eigen pionnen.", NULL, NULL, 0 },
    { CP_MATE, 1, "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 1", "Herdersmat",
      "Het veld f7 wordt alleen door de koning verdedigd.", NULL, NULL, 0 },
    { CP_MATE, 1, "7k/8/6K1/8/8/8/Q7/8 w - - 0 1", "Dame en koning",
      "Je koning dekt al de velden voor de zwarte koning. Geef schaak langs de rand.", NULL, NULL, 0 },
    { CP_MATE, 1, "6rk/6pp/8/6N1/8/8/8/6K1 w - - 0 1", "Stikmat",
      "De koning staat helemaal ingesloten door zijn eigen stukken. Welk stuk springt eroverheen?", NULL, NULL, 0 },
    { CP_MATE, 1, "rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2", "Gekkenmat (zwart)",
      "Wit heeft de diagonaal naar zijn koning geopend.", NULL, NULL, 0 },
    { CP_MATE, 1, "r1bqk2r/pppp1ppp/2n2n2/2b1p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1", "Aanval op f7",
      "Dame en loper kijken allebei naar hetzelfde veld.", NULL, NULL, 0 },
    { CP_MATE, 1, "7k/7p/5N2/8/8/8/8/6RK w - - 0 1", "Toren en paard",
      "Het paard beschermt een belangrijk veld naast de koning.", NULL, NULL, 0 },
    { CP_MATE, 1, "3k4/8/3K4/8/8/8/8/7R w - - 0 1", "Torenmat",
      "De koningen staan tegenover elkaar. Nu nog schaak langs de rand.", NULL, NULL, 0 },
    { CP_MATE, 1, "1k6/ppp5/8/8/8/8/8/K3R3 w - - 0 1", "Achterste rij 2",
      "Zwart heeft zijn pionnen niet opgeschoven.", NULL, NULL, 0 },
    { CP_MATE, 1, "6k1/5ppp/8/8/8/8/2q2PPP/6K1 b - - 0 1", "Zwart: dame op de rand",
      "De witte koning kan nergens heen als je schaak geeft op de eerste rij.", NULL, NULL, 0 },
    { CP_MATE, 1, "6k1/5ppp/8/8/8/8/1B4Q1/6K1 w - - 0 1", "Dame en loper",
      "De loper op b2 kijkt naar g7.", NULL, NULL, 0 },
    { CP_MATE, 1, "1r4k1/5ppp/8/8/8/8/5PPP/6K1 b - - 0 1", "Zwart: toren",
      "Ook wit heeft geen luchtgaatje gemaakt.", NULL, NULL, 0 },
    { CP_MATE, 1, "k7/2Q5/1K6/8/8/8/8/8 w - - 0 1", "Dame in de hoek",
      "Er zijn meerdere manieren. Pas op voor pat!", NULL, NULL, 0 },
    // ---- Mat in 2 ----
    { CP_MATE, 2, "r5k1/5ppp/8/8/8/8/3R1PPP/3R2K1 w - - 0 1", "Dubbele torens",
      "Offer de eerste toren; de tweede maakt het af.", NULL, NULL, 0 },
    { CP_MATE, 2, "5r1k/6pp/7N/3Q4/8/8/8/6K1 w - - 0 1", "Stikmat van Philidor",
      "Offer je dame op g8. De toren moet slaan en dan springt het paard.", NULL, NULL, 0 },
    { CP_MATE, 2, "2k5/8/1K6/8/8/8/8/3R4 w - - 0 1", "Toren en koning",
      "Sluit eerst de koning op met een rustige torenzet.", NULL, NULL, 0 },
    { CP_MATE, 2, "6k1/8/5K2/8/8/8/8/7Q w - - 0 1", "Dame en koning 2",
      "Neem eerst velden af zonder schaak te geven. Pas op voor pat.", NULL, NULL, 0 },
    { CP_MATE, 2, "6k1/8/8/8/8/8/R7/1R4K1 w - - 0 1", "Torenladder",
      "De ene toren sluit een rij af, de andere geeft mat op de rij erachter.", NULL, NULL, 0 },
    { CP_MATE, 2, "r1bk3r/pppp1Qpp/2n5/8/8/8/PPP2PPP/R1B1K2R w KQ - 0 1", "Loper helpt de dame",
      "Geef eerst schaak met de loper.", NULL, NULL, 0 },
    { CP_MATE, 2, "6rk/6pp/8/8/8/8/1B4Q1/6K1 w - - 0 1", "Rustige damezet",
      "Dreig mat op g7. De zwarte toren kan niet alles tegelijk verdedigen.", NULL, NULL, 0 },
    { CP_MATE, 2, "1r4k1/1r3ppp/8/8/8/8/4RPPP/6K1 b - - 0 1", "Zwart: dubbele torens",
      "Geef schaak op de eerste rij. Wit kan alleen ertussen gaan staan.", NULL, NULL, 0 },
    { CP_MATE, 2, "3r2k1/3r1ppp/8/8/8/8/5PPP/R5K1 b - - 0 1", "Zwart: offer en mat",
      "Offer een toren op d1.", NULL, NULL, 0 },
    // ---- Uit de lichess-puzzeldatabase (CC0), gecontroleerd met de matzoeker ----
    { CP_MATE, 1, "6k1/R7/6K1/7P/8/8/6p1/7r w - - 0 59", "Mat met de toren", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "g3g2", 847 },
    { CP_MATE, 1, "4k3/p7/1p1Q4/1P1p2p1/P2b2q1/2p4p/2B2P1P/5K2 w - - 4 50", "Balestra-mat", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "f8e8", 931 },
    { CP_MATE, 1, "5r1k/p1p1Q2p/1p6/3pP3/3Pp3/1NP1n1qP/PP2R1P1/6K1 b - - 2 28", "Mat met de toren", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "e6e7", 962 },
    { CP_MATE, 1, "5rk1/1q3r2/3p2pQ/3p4/3B4/2P2P2/P5PP/6K1 w - - 0 31", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "h7g6", 994 },
    { CP_MATE, 1, "2kr3r/ppp5/7q/3pPp2/1b1n4/2NB2P1/PP3Q1P/2R1K2R b K - 1 18", "Mat met de dame", "Er staat iets onbeschermd.", NULL, "e2f2", 1025 },
    { CP_MATE, 1, "1rb2b1r/4kp1p/2np1N2/qN2p3/4Pp2/2P5/PP3PPP/R2QK2R w KQ - 3 16", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "e8e7", 1047 },
    { CP_MATE, 1, "r1bq1rk1/ppp3p1/7p/4Pp1Q/2P1p3/P3P1P1/1PnNKPP1/3R1B1R b - - 0 15", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "d4e5", 1071 },
    { CP_MATE, 1, "rn1q3r/4k1p1/2pbp2p/4Np1Q/3Pn3/4B3/PP3PPP/R4RK1 w - - 3 16", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "e8e7", 1081 },
    { CP_MATE, 1, "1r5k/5prp/p3pQ2/3p4/8/P1N3qP/1PP5/1R4RK b - - 1 31", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "e1g1", 1104 },
    { CP_MATE, 1, "r2q1bnr/ppp2pkp/6pN/1B1Pp3/4P3/8/PPP3PP/RNBb1RK1 w - - 2 12", "Epaulettenmat", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "f6g7", 1119 },
    { CP_MATE, 1, "1r6/p1p2n2/1pk2Pp1/6r1/8/2N5/PPP4K/3R2R1 b - - 3 24", "Mat met de toren", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "f1g1", 1127 },
    { CP_MATE, 1, "1qr1k3/1p2r2p/p1n1Q3/8/8/P5P1/1P3PP1/2RR2K1 w - - 1 24", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "g7e7", 1131 },
    { CP_MATE, 1, "6k1/p4pp1/4p2p/8/P3Pq2/7B/3QKP1n/4R3 b - - 2 31", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "f1e2", 1144 },
    { CP_MATE, 1, "6k1/1p3p1p/p1p3q1/3pQ2N/3P4/4PK2/8/8 w - - 6 56", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "c2g6", 1152 },
    { CP_MATE, 1, "r3r1k1/ppp2R2/1b5Q/3PP2n/2B3bq/2N5/PP4PP/R6K b - - 0 18", "Mat met het paard", "Gebruik een penning.", NULL, "f1f7", 1158 },
    { CP_MATE, 1, "r1bq3r/pp2k1bp/2np1np1/2p1p1N1/4PB2/1QPP4/PP1N1PPP/R3K2R w KQ - 0 11", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "e6e5", 1167 },
    { CP_MATE, 1, "rnbBk2r/pp1p1ppp/8/2bNp3/4n3/5N2/PPP1PPPP/R2QKB1R b KQkq - 0 7", "Mat met de loper", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "g5d8", 1170 },
    { CP_MATE, 1, "2k5/p1p2ppp/2R5/8/8/6Pb/PPQ1qb1P/R6K b - - 1 22", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "g1h1", 1179 },
    { CP_MATE, 1, "r4rk1/4p1bp/3p2p1/q1pP1P2/4QP2/4B3/1pK4P/1B1R3R b - - 1 22", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "c1c2", 1189 },
    { CP_MATE, 1, "4rk2/ppp2p1p/2qp4/8/8/2PK4/PP1P1Q1P/R1B3N1 b - - 0 17", "Zwaluwstaartmat", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "c2c3", 1194 },
    { CP_MATE, 1, "3r2k1/2Q2p1p/6p1/3b4/q2Np3/2P3PP/1R1P1P2/1K6 b - - 13 40", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "c2b1", 1219 },
    { CP_MATE, 1, "r2q2kr/pp1n2bp/n2B2p1/2pp4/2P5/3B1Q1P/PP4P1/R3R1K1 w - - 4 19", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "f8g8", 1229 },
    { CP_MATE, 1, "4R3/4R1pk/7p/p2P4/8/8/PPPr3r/5K2 b - - 1 29", "Mat met de toren", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "d7e7", 1237 },
    { CP_MATE, 1, "8/1b6/pk2p3/1p1pb3/1P2PP2/P1PBK1P1/3R2rr/1N1R4 b - - 0 35", "Mat van Pillsbury", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "f2f4", 1246 },
    { CP_MATE, 1, "r1bq1b1r/ppp2Q1p/2n2n2/4Nk2/3Pp3/8/PPP2PPP/R1B1K2R w KQ - 4 13", "Mat met een pion", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "e6f5", 1264 },
    { CP_MATE, 1, "8/6p1/1qn1p2p/3kP3/2R4Q/7P/r4PP1/6K1 w - - 1 40", "Driehoeksmat", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "b4c6", 1267 },
    { CP_MATE, 1, "r3k2r/ppp1Npp1/1bnp4/4p2b/2B1P1n1/1QPP3P/PP1N2P1/R1B1RK2 b kq - 0 14", "Mat met het paard", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "f5e7", 1271 },
    { CP_MATE, 1, "8/R3b1k1/4P3/5P1K/4P1r1/8/P7/8 b - - 0 46", "Operamat", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "h4h5", 1275 },
    { CP_MATE, 1, "r3k2r/1pQ2p2/p1b1pPp1/B2q1nNp/3p1P2/1P1P4/P5PP/R4RK1 w kq - 7 24", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "b5d5", 1286 },
    { CP_MATE, 1, "rn2qr2/pp2bkpn/2p1b2p/3p1P2/6PB/2NP4/PPP1Q2P/R3KB1R w KQ - 0 15", "Mat met de dame", "Zoek een schaak die geen vluchtveld overlaat.", NULL, "d7e6", 1298 },
    { CP_MATE, 2, "r2q1rk1/3bbpp1/p1p3n1/3Pp3/2p1Q1p1/2N2P2/PP2B2R/2K4R w - - 0 24", "Offer en mat", "Durf iets te offeren.", NULL, "g5g4", 1108 },
    { CP_MATE, 2, "rnb2rk1/pp4pp/2p5/3p1p2/3Pn2q/2NBPP2/PP4PN/R1BQR1K1 b - - 0 13", "Koningsaanval", "Begin met een sterke schaak of een stille dreiging.", NULL, "f1h2", 1154 },
    { CP_MATE, 2, "3rk2r/pp2bppp/2pQ4/2Bn4/6P1/3P4/PPP4P/1K2R1Nq w k - 4 20", "Mat met de dame", "Begin met een sterke schaak of een stille dreiging.", NULL, "a8d8", 1172 },
    { CP_MATE, 2, "8/2p5/3b2kp/3p2p1/P3p1KP/1P2R3/1B4P1/8 b - - 0 36", "Mat met een pion", "Begin met een sterke schaak of een stille dreiging.", NULL, "h3h4", 1258 },
    { CP_MATE, 2, "4r1k1/ppp2ppp/1bp5/1q6/PN2r3/2P2Q2/1P1P1PPP/R1B2RK1 b - - 0 16", "Offer en mat", "Lok een stuk naar een slecht veld.", NULL, "a2a4", 1311 },
    { CP_MATE, 2, "r4rk1/ppp3pR/2np1qQ1/8/8/2P2NB1/PP3KP1/1Bb5 w - - 1 19", "Offer en mat", "Lok een stuk naar een slecht veld.", NULL, "d8f6", 1342 },
    { CP_MATE, 2, "r5k1/1p3p2/2p1ppp1/3p4/2nP4/1QB4P/rPP1BPP1/qNKR3R b - - 4 22", "Offer en mat", "Lok een stuk naar een slecht veld.", NULL, "f3e2", 1362 },
    { CP_MATE, 2, "2kr3r/1bpp1ppp/1b4q1/p3Pn2/PpN5/1BPP1P2/3BQ1PP/R4R1K b - - 0 18", "Offer en mat", "Durf iets te offeren.", NULL, "b2c3", 1381 },
    { CP_MATE, 2, "7k/1Q4p1/p6p/8/8/5rqP/P4rP1/R5RK b - - 4 29", "Offer en mat", "Durf iets te offeren.", NULL, "d5b7", 1425 },
    { CP_MATE, 2, "2kr4/2p2pp1/8/1R2PP1p/6n1/8/1Q4PP/3q2BK b - - 2 28", "Offer en mat", "Lok een stuk naar een slecht veld.", NULL, "e2b2", 1464 },
    { CP_MATE, 2, "r7/7R/2p2k2/3p4/pp6/qP1Br3/P1P1N1R1/1K6 w - - 0 29", "Mat van Pillsbury", "Begin met een sterke schaak of een stille dreiging.", NULL, "f7f6", 1502 },
    { CP_MATE, 2, "k7/P7/1K6/1N6/2n5/4p1p1/8/8 w - - 2 60", "Mat met het paard", "Verdedig eerst goed.", NULL, "d2c4", 1535 },
    { CP_MATE, 2, "r2q2rk/pp1n2np/2p5/3pPp2/3P1Q1N/8/PPP2PPP/R4RK1 w - f6 0 19", "Offer en mat", "Durf iets te offeren.", NULL, "f7f5", 1596 },
    { CP_MATE, 2, "2kr3r/pppn1ppp/8/8/3P2n1/5N1q/PPP1BN2/R1BQR1K1 b - - 0 20", "Koningsaanval", "Begin met een sterke schaak of een stille dreiging.", NULL, "e4f2", 1618 },
    { CP_MATE, 2, "8/3R4/6R1/2k2p2/7P/1P1P2K1/1PPb2P1/5r2 b - - 0 36", "Mat van Pillsbury", "Begin met een sterke schaak of een stille dreiging.", NULL, "b6g6", 1694 },
    // ---- Eindspel-oefeningen (zet mat tegen de bot) ----
    { CP_ENDGAME, 15, "8/8/8/4k3/8/8/8/3QK3 w - - 0 1", "Koning + dame tegen koning",
      "Duw de koning met je dame naar de rand en haal je eigen koning erbij. Pas op voor pat!", NULL, NULL, 0 },
    { CP_ENDGAME, 30, "8/8/8/4k3/8/8/8/4K2R w - - 0 1", "Koning + toren tegen koning",
      "Maak het hok van de zwarte koning steeds kleiner. Je koning moet helpen.", NULL, NULL, 0 },
    { CP_ENDGAME, 15, "8/8/3k4/8/8/8/8/R3K2R w - - 0 1", "Twee torens (ladder)",
      "Schuif de torens om de beurt een rij op, zoals een ladder.", NULL, NULL, 0 },
    { CP_ENDGAME, 40, "4k3/8/4K3/4P3/8/8/8/8 w - - 0 1", "Pion naar de overkant",
      "Je koning moet de pion begeleiden. Maak een dame en zet daarna mat.", NULL, NULL, 0 },
    // ---- Eindspel-oefeningen: vind de juiste zetten (lichess-puzzeldatabase, CC0) ----
    { CP_LINE, 2, "8/8/3pp1p1/8/1k1Q2KP/1p3P2/2r5/8 b - - 9 55", "Dame en toren", "Gebruik een penning.", "c2c4 d4c4 b4c4", "b2d4", 659 },
    { CP_LINE, 2, "8/4k3/8/p5rp/R3K3/4P3/P7/8 b - - 1 38", "Toreneindspel", "Zoek een spies: val een stuk aan met een ander stuk erachter.", "g5g4 e4f3 g4a4", "d3e4", 662 },
    { CP_LINE, 2, "8/2N1k1p1/3p3p/8/1r4P1/5K1P/8/8 w - - 1 41", "Eindspel", "Zoek een vork: val twee stukken tegelijk aan.", "c7d5 e7e6 d5b4", "f7e7", 669 },
    { CP_LINE, 2, "8/6p1/3k1p1p/4qQ1P/4PKP1/8/8/8 w - - 1 64", "Dame-eindspel", "Zoek de zet die veel materiaal wint.", "f5e5 f6e5 f4f5", "e7e5", 718 },
    { CP_LINE, 2, "8/8/8/KP6/5p1P/5k2/4bP2/8 w - - 1 50", "Lopereindspel", "Er staat een pion ver naar voren. Gebruik hem.", "b5b6 e2d3 b6b7", "e4f3", 772 },
    { CP_LINE, 2, "8/8/8/6p1/5KPk/8/8/8 w - - 0 81", "Pioneneindspel", "Soms is wachten het sterkst: laat de tegenstander een slechte zet doen.", "f4f5 h4h3 f5g5", "g6g5", 787 },
    { CP_LINE, 3, "8/4k3/4p3/3nP3/2N2PK1/1p6/8/8 b - - 1 55", "Paardeneindspel", "Kan er een pion promoveren?", "d5e3 c4e3 b3b2 e3c4 b2b1q", "h4g4", 887 },
    { CP_LINE, 2, "8/8/4kn1N/2Kp4/3P2p1/5pP1/5P2/8 b - - 2 55", "Paardeneindspel", "Zoek de zet die veel materiaal wint.", "f6e4 c5c6 e4f2", "b5c5", 933 },
    { CP_LINE, 3, "3r2k1/1r1P1pp1/7p/8/8/8/6PP/2RR3K w - - 1 35", "Toreneindspel", "Kijk door een stuk heen.", "c1c8 b7d7 c8d8 d7d8 d1d8", "b6b7", 979 },
    { CP_LINE, 3, "8/8/8/P1k3p1/3p4/3K1p1P/2N5/8 b - - 3 53", "Paardeneindspel", "Kan er een pion promoveren?", "f3f2 d3e2 d4d3 e2d3 f2f1q", "b4c2", 1021 },
    { CP_LINE, 3, "8/6p1/p3p2p/4P2P/k1K3P1/8/8/8 w - - 0 37", "Pioneneindspel", "Zoek de zet die voordeel geeft.", "c4c5 a6a5 c5d6 a4b3 d6e6", "a5a4", 1080 },
    { CP_LINE, 3, "7k/7p/5r1P/8/8/1P2p3/2P5/1K4R1 b - - 2 51", "Toreneindspel", "Er staat een pion ver naar voren. Gebruik hem.", "e3e2 g1e1 f6f1 b1c1 f1e1", "g5g1", 1094 },
    { CP_LINE, 2, "8/Q3KPp1/1p4kp/2p5/8/5r1P/8/8 b - - 4 52", "Dame en toren", "Zoek een spies: val een stuk aan met een ander stuk erachter.", "f3f7 e7d6 f7a7", "e6e7", 1138 },
    { CP_LINE, 3, "1bK5/pP3p2/B7/1P4p1/6k1/8/7p/8 w - - 0 44", "Lopereindspel", "Kan er een pion promoveren?", "c8b8 h2h1q b8a7 h1d1 b7b8q", "h3h2", 1139 },
    { CP_LINE, 3, "8/p6p/6p1/1P2p3/Pk2K3/5P2/6PP/8 b - - 5 34", "Pioneneindspel", "Zoek de zet die veel materiaal wint.", "b4a4 e4e5 a4b5 f3f4 a7a5", "e3e4", 1143 },
    { CP_LINE, 2, "8/5k2/1p4p1/1R1K2P1/r6P/8/8/8 b - - 12 58", "Toreneindspel", "Gebruik een penning.", "a4a5 b5a5 b6a5", "c4d5", 1145 },
    { CP_LINE, 2, "6k1/6p1/5P2/4B2B/2b1P3/3p4/r4RK1/1r6 w - - 1 42", "Eindspel", "Er staat een pion ver naar voren. Gebruik hem.", "f6f7 c4f7 h5f7", "a3a2", 1184 },
    { CP_LINE, 3, "8/5ppp/4P3/1p1p1K1P/k2P2P1/P7/8/8 b - - 0 33", "Pioneneindspel", "Zoek de zet die veel materiaal wint.", "f7e6 f5e6 a4a3 e6d5 b5b4", "e5e6", 1201 },
    { CP_LINE, 3, "8/pp6/4k1p1/4P3/6p1/PP1KR1P1/5r2/8 b - - 2 37", "Toreneindspel", "De koning staat onbeschermd.", "f2f3 d3e4 f3e3 e4e3 e6e5", "c4d3", 1223 },
    { CP_LINE, 2, "8/1b4p1/1k3pPp/4K2P/4PP2/8/8/8 w - - 0 47", "Lopereindspel", "Zoek de zet die voordeel geeft.", "e5e6 b7e4 e6f7", "f7f6", 1224 },
    { CP_LINE, 2, "5k2/5p2/5Q2/1p2P3/8/6KP/6P1/5q2 b - - 7 50", "Dame-eindspel", "Zoek de zet die veel materiaal wint.", "f1f6 e5f6 b5b4", "f4g3", 1239 },
    { CP_LINE, 3, "8/6r1/4p3/1kPp3p/1P1P1P2/3K2P1/1R6/8 b - - 0 48", "Toreneindspel", "Zoek de zet die veel materiaal wint.", "g7g3 d3c2 g3g2 c2b1 g2b2", "h2g3", 1258 },
    { CP_LINE, 2, "8/8/5K2/5Q2/3k1p2/5Pp1/6P1/1q6 b - - 3 58", "Dame-eindspel", "Zoek de zet die veel materiaal wint.", "b1f5 f6f5 d4e3", "e6f5", 1276 },
    { CP_LINE, 3, "8/8/6p1/1p1k1p1p/1Pn2P1P/2K1N3/5P2/8 b - - 7 46", "Paardeneindspel", "Zoek de zet die veel materiaal wint.", "c4e3 f2e3 d5e4 c3d2 e4f3", "c2e3", 1281 },
    { CP_LINE, 2, "8/8/4k3/K7/4p2p/6pP/P5P1/8 w - - 0 44", "Pioneneindspel", "Zoek de zet die veel materiaal wint.", "a5b4 e6d5 b4c3", "f5e4", 1293 },
    { CP_LINE, 2, "8/pp3p2/8/3k4/5P2/1Pq1P1RP/6PK/8 w - - 1 36", "Dame en toren", "Zet een stuk opzij zodat een ander stuk aanvalt.", "e3e4 d5d4 g3c3", "e5c3", 1317 },
    { CP_LINE, 3, "8/6R1/8/4P3/7p/5kr1/7K/8 w - - 1 56", "Toreneindspel", "Zoek de zet die veel materiaal wint.", "g7g3 h4g3 h2g1 g3g2 e5e6", "g4f3", 1346 },
    { CP_LINE, 3, "8/8/1pk5/4p1p1/2K1Pp1p/2P2P1P/6P1/8 w - - 0 39", "Pioneneindspel", "Soms is wachten het sterkst: laat de tegenstander een slechte zet doen.", "c4b4 b6b5 c3c4 b5c4 b4c4", "h5h4", 1350 },
    { CP_LINE, 2, "8/4Kbk1/p7/6Pp/4P2P/P1P5/8/8 w - - 7 58", "Lopereindspel", "Een rustige zet zonder schaak of slag kan het sterkst zijn.", "e4e5 f7c4 e5e6", "g6g7", 1352 },
    { CP_LINE, 3, "8/1R4pp/3k4/8/8/3q1N1P/6PK/8 w - - 0 32", "Eindspel", "Zoek een vork: val twee stukken tegelijk aan.", "b7d7 d6d7 f3e5 d7c8 e5d3", "d7d6", 1358 },
    { CP_LINE, 3, "8/8/p5P1/P2kN3/2np1K2/8/8/8 b - - 1 61", "Paardeneindspel", "Zoek de zet die veel materiaal wint.", "c4e5 g6g7 e5g6 f4f3 g6e7", "d3e5", 1371 },
    { CP_LINE, 2, "8/8/2p1k1p1/p1KpP3/P4PP1/8/8/8 b - - 1 39", "Pioneneindspel", "Lok een verdediger weg.", "g6g5 f4g5 e6e5", "d4c5", 1375 },
    { CP_LINE, 2, "8/6pk/4Qp2/1q6/p3P1P1/5PK1/7P/8 b - - 0 62", "Dame-eindspel", "Zoek de zet die veel materiaal wint.", "b5e5 e6e5 f6e5", "f7e6", 1381 },
    { CP_LINE, 2, "8/3PR1p1/5pkp/8/4P3/6P1/1p1r3P/4K3 w - - 0 38", "Toreneindspel", "Kan er een pion promoveren?", "e1d2 b2b1q d7d8q", "b3b2", 1392 },
    { CP_LINE, 3, "8/8/p7/1pp1k3/2P2p2/PPK2P2/8/8 w - - 0 49", "Pioneneindspel", "Zoek de zet die veel materiaal wint.", "c4b5 a6b5 a3a4 b5a4 b3a4", "b7b5", 1416 },
    { CP_LINE, 2, "8/6k1/6p1/1r6/1pK3P1/p1P5/6P1/1R6 b - - 1 39", "Toreneindspel", "Er staat een pion ver naar voren. Gebruik hem.", "a3a2 b1a1 b4b3", "d3c4", 1434 },
    { CP_LINE, 3, "8/2k3p1/5p1p/4p3/4K1PP/5P2/8/8 w - - 4 46", "Pioneneindspel", "Zoek de zet die veel materiaal wint.", "e4f5 c7b6 f5g6 e5e4 f3e4", "b6c7", 1443 },
    { CP_LINE, 2, "2R5/5kp1/8/3R4/K7/1P6/8/4q3 b - - 2 57", "Dame en toren", "Zoek een vork: val twee stukken tegelijk aan.", "e1e4 b3b4 e4d5", "b4a4", 1446 },
    { CP_LINE, 2, "8/6pk/7p/2pq4/3p4/5PP1/P3QK1P/8 w - - 2 41", "Dame-eindspel", "Zoek de zet die voordeel geeft.", "e2e4 d5e4 f3e4", "c4d5", 1492 },
    { CP_LINE, 3, "8/8/4p1pp/1k2P3/2pP1P2/1PK1P3/8/8 b - - 0 46", "Pioneneindspel", "Een rustige zet zonder schaak of slag kan het sterkst zijn.", "c4b3 c3b3 h6h5 b3c3 h5h4", "b2b3", 1496 },
    { CP_LINE, 2, "8/8/K4k1p/6pP/6P1/P1r2P2/5R2/8 b - - 0 43", "Toreneindspel", "Zoek de zet die voordeel geeft.", "c3a3 a6b5 f6e5", "b6a6", 1513 },
    { CP_LINE, 3, "8/7p/2P5/1P5K/1Pk2b2/8/8/8 w - - 1 54", "Lopereindspel", "Kan er een pion promoveren?", "b5b6 c4b5 c6c7 b5b6 c7c8q", "d5c4", 1520 },
    { CP_LINE, 2, "8/8/p4k2/P5p1/1N2K1P1/8/5n2/8 w - - 1 47", "Paardeneindspel", "Zoek de zet die veel materiaal wint.", "e4f3 f2d1 b4a6", "h3f2", 1531 },
    { CP_LINE, 2, "8/8/6kp/pp1p4/2pP2KP/P1P5/1P6/8 b - - 0 48", "Pioneneindspel", "Soms is wachten het sterkst: laat de tegenstander een slechte zet doen.", "h6h5 g4f4 g6f6", "h3h4", 1568 },
    { CP_LINE, 2, "6k1/5p2/6p1/3p1rRp/8/3K4/P1P5/8 w - - 2 32", "Toreneindspel", "Zoek de zet die veel materiaal wint.", "g5f5 g6f5 a2a4", "f2f5", 1570 },
    { CP_LINE, 2, "8/4kpp1/4b2p/2PB4/1K6/p5P1/5PP1/8 w - - 7 45", "Lopereindspel", "Zoek de zet die veel materiaal wint.", "d5e6 e7e6 b4a3", "d7e6", 1577 },
    { CP_LINE, 3, "1k6/1p6/p6p/2Q3q1/8/5KP1/P5P1/8 w - - 5 41", "Dame-eindspel", "Zoek de zet die veel materiaal wint.", "c5g5 h6g5 f3g4 a6a5 g4g5", "d2g5", 1582 },
    { CP_LINE, 2, "8/8/1p1k4/1K2p2p/P2p3P/4PP2/8/8 w - - 0 43", "Pioneneindspel", "Zoek de zet die veel materiaal wint.", "e3d4 d6d5 d4e5", "d5d4", 1592 },
    { CP_LINE, 2, "8/5p2/4pP2/4P3/R4KPk/8/pr6/8 b - - 6 57", "Toreneindspel", "Kan er een pion promoveren?", "b2b4 a4b4 a2a1q", "f3f4", 1593 },
    { CP_LINE, 2, "8/4k3/8/7R/6K1/5p2/P3n1P1/8 b - - 0 51", "Eindspel", "Kan er een pion promoveren?", "f3g2 g4f3 g2g1q", "h4g4", 1594 },
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
