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
