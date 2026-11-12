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
    // ---- Eindspelen met weinig stukken: win tegen de bot (gecontroleerd met de lichess-tablebase) ----
    { CP_ENDGAME, 22, "8/7K/3k4/8/8/8/6Q1/8 w - - 0 1", "Koning + dame tegen koning", "Maak het hok van de koning kleiner met je dame (een paardsprong ervandaan) en haal je koning erbij. Pas op voor pat!", NULL, NULL, 700 },
    { CP_ENDGAME, 22, "8/6Q1/7K/2k5/8/8/8/8 w - - 0 1", "Koning + dame tegen koning", "Maak het hok van de koning kleiner met je dame (een paardsprong ervandaan) en haal je koning erbij. Pas op voor pat!", NULL, NULL, 700 },
    { CP_ENDGAME, 20, "7k/3q4/8/8/8/8/8/7K b - - 0 1", "Koning + dame tegen koning", "Maak het hok van de koning kleiner met je dame (een paardsprong ervandaan) en haal je koning erbij. Pas op voor pat!", NULL, NULL, 700 },
    { CP_ENDGAME, 22, "K7/4Q3/8/8/8/8/8/3k4 w - - 0 1", "Koning + dame tegen koning", "Maak het hok van de koning kleiner met je dame (een paardsprong ervandaan) en haal je koning erbij. Pas op voor pat!", NULL, NULL, 700 },
    { CP_ENDGAME, 20, "1K2Q3/8/8/8/8/1k6/8/8 w - - 0 1", "Koning + dame tegen koning", "Maak het hok van de koning kleiner met je dame (een paardsprong ervandaan) en haal je koning erbij. Pas op voor pat!", NULL, NULL, 700 },
    { CP_ENDGAME, 36, "8/5R2/3k4/8/8/8/8/1K6 w - - 0 1", "Koning + toren tegen koning", "Duw de koning met je toren naar de rand. Je eigen koning moet meehelpen: zet hem tegenover de andere koning.", NULL, NULL, 900 },
    { CP_ENDGAME, 28, "2k5/8/7R/8/8/8/8/K7 w - - 0 1", "Koning + toren tegen koning", "Duw de koning met je toren naar de rand. Je eigen koning moet meehelpen: zet hem tegenover de andere koning.", NULL, NULL, 900 },
    { CP_ENDGAME, 30, "8/3K4/7r/8/8/8/k7/8 b - - 0 1", "Koning + toren tegen koning", "Duw de koning met je toren naar de rand. Je eigen koning moet meehelpen: zet hem tegenover de andere koning.", NULL, NULL, 900 },
    { CP_ENDGAME, 32, "4K3/8/2R5/8/5k2/8/8/8 w - - 0 1", "Koning + toren tegen koning", "Duw de koning met je toren naar de rand. Je eigen koning moet meehelpen: zet hem tegenover de andere koning.", NULL, NULL, 900 },
    { CP_ENDGAME, 36, "8/K7/8/4k3/8/6R1/8/8 w - - 0 1", "Koning + toren tegen koning", "Duw de koning met je toren naar de rand. Je eigen koning moet meehelpen: zet hem tegenover de andere koning.", NULL, NULL, 900 },
    { CP_ENDGAME, 30, "8/6r1/8/8/8/8/k7/5K2 b - - 0 1", "Koning + toren tegen koning", "Duw de koning met je toren naar de rand. Je eigen koning moet meehelpen: zet hem tegenover de andere koning.", NULL, NULL, 900 },
    { CP_ENDGAME, 14, "8/R7/8/3R4/8/6k1/2K5/8 w - - 0 1", "Twee torens tegen koning", "Torenladder: de ene toren sluit een rij af, de andere geeft schaak op de volgende rij.", NULL, NULL, 600 },
    { CP_ENDGAME, 14, "8/4R3/1K6/3R4/6k1/8/8/8 w - - 0 1", "Twee torens tegen koning", "Torenladder: de ene toren sluit een rij af, de andere geeft schaak op de volgende rij.", NULL, NULL, 600 },
    { CP_ENDGAME, 16, "8/1K6/8/r7/r7/8/8/7k b - - 0 1", "Twee torens tegen koning", "Torenladder: de ene toren sluit een rij af, de andere geeft schaak op de volgende rij.", NULL, NULL, 600 },
    { CP_ENDGAME, 14, "3K4/8/5R2/7Q/4k3/8/8/8 w - - 0 1", "Dame en toren tegen koning", "Werk samen: dame en toren maken samen een ladder naar de rand.", NULL, NULL, 600 },
    { CP_ENDGAME, 14, "2K4R/8/6k1/3Q4/8/8/8/8 w - - 0 1", "Dame en toren tegen koning", "Werk samen: dame en toren maken samen een ladder naar de rand.", NULL, NULL, 600 },
    { CP_ENDGAME, 36, "8/8/8/K5k1/8/1P6/8/8 w - - 0 1", "Koning + pion tegen koning", "Je koning moet vóór de pion lopen. Zet je koning op de velden voor de pion en let op de oppositie.", NULL, NULL, 1100 },
    { CP_ENDGAME, 30, "7K/8/8/5P1k/8/8/8/8 w - - 0 1", "Koning + pion tegen koning", "Je koning moet vóór de pion lopen. Zet je koning op de velden voor de pion en let op de oppositie.", NULL, NULL, 1100 },
    { CP_ENDGAME, 30, "8/2p3K1/8/8/8/6k1/8/8 b - - 0 1", "Koning + pion tegen koning", "Je koning moet vóór de pion lopen. Zet je koning op de velden voor de pion en let op de oppositie.", NULL, NULL, 1100 },
    { CP_ENDGAME, 30, "8/8/8/8/8/6P1/3K4/6k1 w - - 0 1", "Koning + pion tegen koning", "Je koning moet vóór de pion lopen. Zet je koning op de velden voor de pion en let op de oppositie.", NULL, NULL, 1100 },
    { CP_ENDGAME, 34, "6k1/8/6K1/8/8/4P3/8/8 w - - 0 1", "Koning + pion tegen koning", "Je koning moet vóór de pion lopen. Zet je koning op de velden voor de pion en let op de oppositie.", NULL, NULL, 1100 },
    { CP_ENDGAME, 28, "8/8/8/2K5/3p4/8/1k6/8 b - - 0 1", "Koning + pion tegen koning", "Je koning moet vóór de pion lopen. Zet je koning op de velden voor de pion en let op de oppositie.", NULL, NULL, 1100 },
    { CP_ENDGAME, 32, "8/8/7K/8/8/8/1k1P4/8 w - - 0 1", "Koning + pion tegen koning", "Je koning moet vóór de pion lopen. Zet je koning op de velden voor de pion en let op de oppositie.", NULL, NULL, 1100 },
    { CP_ENDGAME, 28, "8/8/8/P7/6k1/8/8/4K3 w - - 0 1", "Koning + pion tegen koning", "Je koning moet vóór de pion lopen. Zet je koning op de velden voor de pion en let op de oppositie.", NULL, NULL, 1100 },
    { CP_ENDGAME, 24, "8/8/8/1P3k2/8/3K4/P7/8 w - - 0 1", "Twee pionnen tegen koning", "Twee pionnen naast elkaar beschermen elkaar. Laat ze samen oprukken en maak een dame.", NULL, NULL, 900 },
    { CP_ENDGAME, 26, "8/2K5/8/4P3/3P4/8/7k/8 w - - 0 1", "Twee pionnen tegen koning", "Twee pionnen naast elkaar beschermen elkaar. Laat ze samen oprukken en maak een dame.", NULL, NULL, 900 },
    { CP_ENDGAME, 30, "6k1/8/8/8/1p6/8/p7/K7 b - - 0 1", "Twee pionnen tegen koning", "Twee pionnen naast elkaar beschermen elkaar. Laat ze samen oprukken en maak een dame.", NULL, NULL, 900 },
    { CP_ENDGAME, 22, "8/8/6K1/P3R3/k7/8/8/8 w - - 0 1", "Toren + pion tegen koning", "Met een toren extra is het makkelijk: snij de koning af of maak een dame.", NULL, NULL, 800 },
    { CP_ENDGAME, 26, "6K1/8/8/8/6k1/2R5/1P6/8 w - - 0 1", "Toren + pion tegen koning", "Met een toren extra is het makkelijk: snij de koning af of maak een dame.", NULL, NULL, 800 },
    { CP_ENDGAME, 36, "8/8/1p6/8/8/7P/3K1k2/8 w - - 0 1", "Pion tegen pion", "Tel de zetten: wie is het eerst bij de overkant? Soms moet je eerst de andere pion slaan.", NULL, NULL, 1300 },
    { CP_ENDGAME, 32, "8/8/4K1p1/8/4P3/8/8/5k2 w - - 0 1", "Pion tegen pion", "Tel de zetten: wie is het eerst bij de overkant? Soms moet je eerst de andere pion slaan.", NULL, NULL, 1300 },
    { CP_ENDGAME, 30, "8/8/P5K1/8/8/1p6/8/3k4 b - - 0 1", "Pion tegen pion", "Tel de zetten: wie is het eerst bij de overkant? Soms moet je eerst de andere pion slaan.", NULL, NULL, 1300 },
    { CP_ENDGAME, 30, "8/6p1/P7/5k2/8/8/8/6K1 w - - 0 1", "Pion tegen pion", "Tel de zetten: wie is het eerst bij de overkant? Soms moet je eerst de andere pion slaan.", NULL, NULL, 1300 },
    { CP_ENDGAME, 28, "5k2/1P6/8/8/8/3p4/K7/8 w - - 0 1", "Pion tegen pion", "Tel de zetten: wie is het eerst bij de overkant? Soms moet je eerst de andere pion slaan.", NULL, NULL, 1300 },
    { CP_ENDGAME, 26, "K7/Q7/8/7k/8/8/p7/8 w - - 0 1", "Dame tegen pion", "Geef schaak of val de pion aan, zodat de koning voor zijn pion moet gaan staan. Haal dan je koning erbij.", NULL, NULL, 1300 },
    { CP_ENDGAME, 28, "8/2Q4K/8/8/8/k7/5p2/8 w - - 0 1", "Dame tegen pion", "Geef schaak of val de pion aan, zodat de koning voor zijn pion moet gaan staan. Haal dan je koning erbij.", NULL, NULL, 1300 },
    { CP_ENDGAME, 26, "7k/3q4/3P4/4K3/8/8/8/8 b - - 0 1", "Dame tegen pion", "Geef schaak of val de pion aan, zodat de koning voor zijn pion moet gaan staan. Haal dan je koning erbij.", NULL, NULL, 1300 },
    { CP_ENDGAME, 26, "2Q5/8/8/7K/8/k5p1/8/8 w - - 0 1", "Dame tegen pion", "Geef schaak of val de pion aan, zodat de koning voor zijn pion moet gaan staan. Haal dan je koning erbij.", NULL, NULL, 1300 },
    { CP_ENDGAME, 32, "8/3R4/1p1K4/8/8/8/8/6k1 w - - 0 1", "Toren tegen pion", "Houd de pion tegen met je toren van achteren en breng je koning snel terug.", NULL, NULL, 1400 },
    { CP_ENDGAME, 24, "8/8/1k6/8/1Kp5/8/8/5R2 w - - 0 1", "Toren tegen pion", "Houd de pion tegen met je toren van achteren en breng je koning snel terug.", NULL, NULL, 1400 },
    { CP_ENDGAME, 38, "4r3/8/k2P4/8/8/8/8/2K5 b - - 0 1", "Toren tegen pion", "Houd de pion tegen met je toren van achteren en breng je koning snel terug.", NULL, NULL, 1400 },
    { CP_ENDGAME, 50, "1Q6/6K1/8/8/7r/8/8/5k2 w - - 0 1", "Dame tegen toren", "Moeilijk! Probeer koning en toren te scheiden met schaakjes, zodat je de toren kunt winnen met een vork.", NULL, NULL, 1900 },
    { CP_ENDGAME, 42, "6k1/4r3/2K5/8/8/8/8/5Q2 w - - 0 1", "Dame tegen toren", "Moeilijk! Probeer koning en toren te scheiden met schaakjes, zodat je de toren kunt winnen met een vork.", NULL, NULL, 1900 },
    { CP_ENDGAME, 34, "6B1/6B1/7K/8/8/8/8/6k1 w - - 0 1", "Twee lopers tegen koning", "De lopers maken samen een muur. Duw de koning naar een hoek en houd je eigen koning dichtbij.", NULL, NULL, 1500 },
    { CP_ENDGAME, 36, "8/k7/8/8/8/8/8/2B2B1K w - - 0 1", "Twee lopers tegen koning", "De lopers maken samen een muur. Duw de koning naar een hoek en houd je eigen koning dichtbij.", NULL, NULL, 1500 },
    { CP_ENDGAME, 38, "4b3/8/8/6b1/3K4/8/4k3/8 b - - 0 1", "Twee lopers tegen koning", "De lopers maken samen een muur. Duw de koning naar een hoek en houd je eigen koning dichtbij.", NULL, NULL, 1500 },
    { CP_ENDGAME, 24, "8/4K3/4Q3/8/8/2k5/n7/8 w - - 0 1", "Dame tegen paard", "Pas op voor vorken van het paard. Val eerst het paard aan of sluit de koning in.", NULL, NULL, 1100 },
    { CP_ENDGAME, 26, "8/6k1/8/K7/2Q5/8/8/1n6 w - - 0 1", "Dame tegen paard", "Pas op voor vorken van het paard. Val eerst het paard aan of sluit de koning in.", NULL, NULL, 1100 },
    { CP_ENDGAME, 30, "6b1/8/8/8/3k4/K7/2Q5/8 w - - 0 1", "Dame tegen loper", "De loper kan weinig tegen een dame. Sluit de koning in en pas op voor pat.", NULL, NULL, 1100 },
    { CP_ENDGAME, 22, "8/5k2/8/8/7K/Q4b2/8/8 w - - 0 1", "Dame tegen loper", "De loper kan weinig tegen een dame. Sluit de koning in en pas op voor pat.", NULL, NULL, 1100 },
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
