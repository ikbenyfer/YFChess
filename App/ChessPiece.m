// ChessPiece.m

#import "ChessPiece.h"

@implementation ChessPiece

+ (NSString *)filledGlyphForType:(int)type {
    switch (type) {
        case CE_KING: return @"♚";
        case CE_QUEEN: return @"♛";
        case CE_ROOK: return @"♜";
        case CE_BISHOP: return @"♝";
        case CE_KNIGHT: return @"♞";
        case CE_PAWN: return @"♟︎";
        default: return @"";
    }
}

+ (NSString *)outlineGlyphForType:(int)type {
    switch (type) {
        case CE_KING: return @"♔";
        case CE_QUEEN: return @"♕";
        case CE_ROOK: return @"♖";
        case CE_BISHOP: return @"♗";
        case CE_KNIGHT: return @"♘";
        case CE_PAWN: return @"♙";
        default: return @"";
    }
}

+ (NSString *)textGlyphForPiece:(uint8_t)piece {
    if (!piece) return @"";
    return CE_COLOR(piece) == CE_WHITE ? [self outlineGlyphForType:CE_TYPE(piece)]
                                       : [self filledGlyphForType:CE_TYPE(piece)];
}

+ (NSString *)dutchNameForType:(int)type {
    switch (type) {
        case CE_KING: return @"koning";
        case CE_QUEEN: return @"dame";
        case CE_ROOK: return @"toren";
        case CE_BISHOP: return @"loper";
        case CE_KNIGHT: return @"paard";
        case CE_PAWN: return @"pion";
        default: return @"";
    }
}

+ (int)valueForType:(int)type {
    switch (type) {
        case CE_PAWN: return 1;
        case CE_KNIGHT: return 3;
        case CE_BISHOP: return 3;
        case CE_ROOK: return 5;
        case CE_QUEEN: return 9;
        default: return 0;
    }
}

+ (NSString *)figurineSAN:(NSString *)san {
    NSMutableString *m = [san mutableCopy];
    NSDictionary *map = @{ @"K": @"♔", @"Q": @"♕", @"R": @"♖", @"B": @"♗", @"N": @"♘" };
    for (NSString *k in map) {
        [m replaceOccurrencesOfString:k withString:map[k] options:0 range:NSMakeRange(0, m.length)];
    }
    return m;
}

@end

@implementation PieceView

- (instancetype)initWithPiece:(uint8_t)piece {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _piece = piece;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setPiece:(uint8_t)piece {
    _piece = piece;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!_piece) return;
    CGSize size = self.bounds.size;
    CGFloat s = MIN(size.width, size.height);
    UIFont *font = [UIFont systemFontOfSize:s * 0.78];
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.alignment = NSTextAlignmentCenter;
    int type = CE_TYPE(_piece);
    BOOL white = CE_COLOR(_piece) == CE_WHITE;
    NSString *filled = [ChessPiece filledGlyphForType:type];
    NSString *outline = [ChessPiece outlineGlyphForType:type];

    NSDictionary *measure = @{ NSFontAttributeName: font, NSParagraphStyleAttributeName: ps };
    CGSize ts = [filled sizeWithAttributes:measure];
    CGRect r = CGRectMake(0, (size.height - ts.height) / 2.0 + s * 0.01, size.width, ts.height);

    UIColor *dark = [UIColor colorWithWhite:0.08 alpha:1.0];
    if (white) {
        // Witte binnenkant, daarover de zwarte omtrek.
        [filled drawInRect:r withAttributes:@{ NSFontAttributeName: font, NSParagraphStyleAttributeName: ps,
                                               NSForegroundColorAttributeName: [UIColor whiteColor] }];
        [outline drawInRect:r withAttributes:@{ NSFontAttributeName: font, NSParagraphStyleAttributeName: ps,
                                                NSForegroundColorAttributeName: dark }];
    } else {
        [filled drawInRect:r withAttributes:@{ NSFontAttributeName: font, NSParagraphStyleAttributeName: ps,
                                               NSForegroundColorAttributeName: dark,
                                               NSStrokeColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.35],
                                               NSStrokeWidthAttributeName: @(-1.5) }];
    }
}

@end
