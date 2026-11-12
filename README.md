# YF Schaak

Een offline schaakapp voor de iPad 2 (iOS 9.3.5, armv7) die ook op een iPhone werkt.
Gemaakt in Objective-C + UIKit en gebouwd met Theos op GitHub Actions.

## Wat zit erin

- **Spelen tegen bot**: kies je kleur (wit, zwart of willekeurig) en een niveau van 1 tot 5.
  De bot is een eigen alfa-bèta-zoeker en werkt zonder internet.
- **Custom chess**: zet zelf stukken op het bord, zoveel als je wilt
  (bijvoorbeeld drie dames). Elke kant moet precies één koning hebben.
  Je kunt stukken weghalen, verplaatsen, de kanten wisselen, kiezen wie begint,
  stellingen opslaan en daarna spelen tegen de bot of 1 tegen 1.
- **Lokaal 1 tegen 1**: twee spelers op één iPad. Optioneel draait het bord mee
  en kun je de markering van de vorige zet verbergen.
- **Schaakklok**: 1+0, 3+2, 5+0, 10+5, 15+10 of een eigen tijd. Tikken om te wisselen,
  pauzeren en resetten. De tijd wordt gemeten met tijdstempels, dus de klok klopt
  ook als de app even op de achtergrond staat.
- **Instellingen**: licht/donker thema, animaties, legale zetten tonen, coördinaten,
  botniveau. Alles wordt bewaard in NSUserDefaults.

## Meegroeiende bot

Bij "Spelen tegen bot" staat de meegroeiende bot. Zijn sterkte loopt van 0 (ultra slecht: bijna
willekeurige zetten, soms zelfs bewust de slechtste) tot 100. Win je, dan gaat hij omhoog (+12 onder
sterkte 30, daarna +8); wint hij, dan gaat hij omlaag (-8 / -10); remise is +3. De sterkte en de telling
worden bewaard en kunnen worden teruggezet.

## Elo

- **Speel tegen een Elo**: de bot krijgt een sterkte van 0-100 via `sterkte = (Elo - 200) / 16`
  (een schatting: sterkte 0 is ongeveer 200 Elo, sterkte 100 ongeveer 1800 Elo).
- **Elo-test**: 3 potjes (wit, zwart, wit). Eerste potje tegen ~800 Elo, daarna +/-400 en +/-200
  afhankelijk van de uitslag. Uitslag = prestatierating: gemiddelde Elo van de tegenstanders
  + 400 x (winst - verlies) / 3, afgerond op 50.

## Puzzels

Mat in 1, mat in 2 en eindspel-oefeningen (zet mat tegen de bot binnen een aantal zetten). Elke puzzel
wordt in de tests gecontroleerd met een eigen matzoeker. Elke zet die (geforceerd) mat geeft telt als goed,
niet alleen één vaste oplossing. Bij mat in 2 verdedigt de tegenstander zo lang mogelijk.

Aantallen: 43 mat in 1, 24 mat in 2 en 50 eindspelen met weinig stukken waarin je tegen de bot
moet winnen (gecontroleerd met de lichess-tablebase; extra eindspelen maakt de app zelf, met een
exacte tabel voor koning + pion tegen koning in `Engine/ChessEndgame.c`). 95 puzzels komen uit de [lichess-puzzeldatabase](https://database.lichess.org/#puzzles)
(CC0, vrij te gebruiken): populaire puzzels met een rating tot ongeveer 1700, van makkelijk naar moeilijk.

### Puzzels downloaden

Bovenaan de puzzellijst staat "Meer puzzels downloaden (gratis)". De app haalt dan via
`/api/puzzle/batch/{soort}` van lichess.org 10, 25 of 50 puzzels op (zonder account), in de soort
gemengd, mat in 1, mat in 2 of eindspel en een gekozen moeilijkheid. De partij-notatie wordt met
`ce_parse_san` nagespeeld tot de puzzelstelling. De puzzels worden bewaard in
`Documents/gedownloade_puzzels.json` (maximaal 2000) en werken daarna offline.

## 1 tegen 1 opslaan

Tik tijdens een 1-tegen-1-partij op Opslaan. Daarna wordt de partij na elke zet vanzelf bijgewerkt.
Verder spelen via Lokaal 1 tegen 1 → Opgeslagen partij verder spelen.

## Zetbeoordeling

Bij spelen tegen de bot, 1 tegen 1 en Custom kun je vóór het potje de zetbeoordeling aan- of uitzetten
(ook bij Instellingen). Na elke zet zoekt de bot (3 zetten diep) de beste zet en vergelijkt die met jouw zet.
Het verschil in winstkans bepaalt het oordeel: ★ Beste zet, ! Uitstekend, ✓ Goed, ?! Onnauwkeurig, ? Fout,
?? Blunder of □ Enige zet. Daarnaast zie je de betere zet en je nauwkeurigheid in procenten.

## Online spelen (lichess.org)

Via de officiële Board API van lichess.org. Inloggen gaat met een persoonlijk API-token
(rechten `board:play` en `challenge:write`), te maken op lichess.org/account/oauth/token.
Het token staat in de sleutelhanger van de iPad (of, als die niet werkt bij een niet-ondertekende app,
in de app-instellingen). Mogelijk: een tegenstander zoeken (rapid/klassiek), tegen de lichess-computer
(niveau 1-8), een vriend uitdagen, uitdagingen accepteren, opgeven, remise en afbreken.
Chess.com kan niet: hun openbare API kan alleen gegevens lezen, geen zetten doen.

## Stukken

In Instellingen kies je de stukken (Klassiek, Modern of 3D) en de bordkleur (bruin, groen, blauw, grijs).
De plaatjes komen van [lichess.org](https://github.com/lichess-org/lila/blob/master/COPYING.md) en staan als SVG in `Art/pieces/`;
GitHub Actions maakt er tijdens het bouwen PNG's van.

| Set | Maker | Licentie |
| --- | --- | --- |
| Modern (`cburnett`) | Colin M.L. Burnett | GPLv2+ |
| 3D (`staunty`) | sadsnake1 | CC BY-NC-SA 4.0 (niet commercieel) |

## Regels die de engine kent

Legale zetten, schaak, mat, pat, rokade, en passant, promotie (ook onderpromotie),
remise door de 50-zettenregel, drie keer dezelfde stelling en te weinig materiaal.
Zetten terugnemen en opnieuw beginnen.

## Mappen

| Map | Inhoud |
| --- | --- |
| `Engine/` | `ChessEngine` (regels) en `ChessBot` (de bot). Gewone C, geen UIKit. |
| `App/` | De schermen: `MainMenu`, `GameManager`, `GameViewController`, `ChessBoard`, `ChessPiece`, `CustomBoardEditor`, `LocalMultiplayer`, `ChessClock`, `SettingsManager`, `SettingsViewController`. |
| `Tests/` | Eenheidstests van de engine (perft, rokade, en passant, promotie, mat, pat, remise, eigen stellingen, bot). |
| `Resources/` | `Info.plist` en de app-iconen. |

## Bouwen

Elke push start de workflow `.github/workflows/build.yml`:

1. **Engine-tests**: de engine wordt op Linux gecompileerd met gcc en clang en de tests draaien
   (ook met AddressSanitizer). Mislukt een test, dan stopt de build.
2. **App bouwen**: Theos met SDK iPhoneOS14.5, minimale versie iOS 9.0, alleen armv7.
   Het resultaat (`.ipa` en `.deb`) staat bij de run onder *Artifacts*.

## Installeren op de iPad (met AppSync Unified)

Zet `YFChess.ipa` op de iPad en installeer met iOSApp Proxy Install of Filza.
De `.deb` kan ook via Filza worden geïnstalleerd.
