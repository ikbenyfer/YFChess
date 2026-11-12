// MoveRating.m

#import "MoveRating.h"

static UIColor *Hex(unsigned int hex) {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0 green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0 alpha:1.0];
}

@implementation MoveRating

+ (NSString *)nameFor:(CBRating)r {
    switch (r) {
        case CB_RATE_BEST: return @"Beste zet";
        case CB_RATE_EXCELLENT: return @"Uitstekend";
        case CB_RATE_GOOD: return @"Goed";
        case CB_RATE_INACCURACY: return @"Onnauwkeurig";
        case CB_RATE_MISTAKE: return @"Fout";
        case CB_RATE_BLUNDER: return @"Blunder";
        case CB_RATE_FORCED: return @"Enige zet";
    }
    return @"";
}

+ (NSString *)symbolFor:(CBRating)r {
    switch (r) {
        case CB_RATE_BEST: return @"★";
        case CB_RATE_EXCELLENT: return @"!";
        case CB_RATE_GOOD: return @"✓";
        case CB_RATE_INACCURACY: return @"?!";
        case CB_RATE_MISTAKE: return @"?";
        case CB_RATE_BLUNDER: return @"??";
        case CB_RATE_FORCED: return @"□";
    }
    return @"";
}

+ (UIColor *)colorFor:(CBRating)r {
    switch (r) {
        case CB_RATE_BEST: return Hex(0x5FA33B);
        case CB_RATE_EXCELLENT: return Hex(0x7FB04A);
        case CB_RATE_GOOD: return Hex(0x6E8F5A);
        case CB_RATE_INACCURACY: return Hex(0xE0AE1B);
        case CB_RATE_MISTAKE: return Hex(0xF08A3C);
        case CB_RATE_BLUNDER: return Hex(0xE5372A);
        case CB_RATE_FORCED: return Hex(0x8A9A80);
    }
    return [UIColor grayColor];
}

@end
