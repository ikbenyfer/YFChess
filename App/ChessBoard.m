// ChessBoard.m

#import "ChessBoard.h"
#import "ChessPiece.h"
#import "SettingsManager.h"

@implementation ChessBoardView {
    uint8_t _board[64];
    NSMutableDictionary *_pieces;   // @(veld) -> PieceView
    BOOL _animating;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        memset(_board, 0, sizeof(_board));
        _pieces = [NSMutableDictionary dictionary];
        _selectedSquare = -1;
        _lastFrom = -1;
        _lastTo = -1;
        _checkSquare = -1;
        _showCoordinates = YES;
        self.contentMode = UIViewContentModeRedraw;
        self.opaque = YES;
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 4;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (CGFloat)squareSize {
    return self.bounds.size.width / 8.0;
}

- (CGRect)rectForSquare:(int)sq {
    int f = CE_FILE(sq), r = CE_RANK(sq);
    int col = _flipped ? 7 - f : f;
    int row = _flipped ? r : 7 - r;
    CGFloat s = [self squareSize];
    return CGRectMake(col * s, row * s, s, s);
}

- (int)squareAtPoint:(CGPoint)p {
    CGFloat s = [self squareSize];
    if (s <= 0) return -1;
    int col = (int)floor(p.x / s), row = (int)floor(p.y / s);
    if (col < 0 || col > 7 || row < 0 || row > 7) return -1;
    int f = _flipped ? 7 - col : col;
    int r = _flipped ? row : 7 - row;
    return CE_SQ(f, r);
}

- (void)handleTap:(UITapGestureRecognizer *)g {
    int sq = [self squareAtPoint:[g locationInView:self]];
    if (sq >= 0) [self.delegate boardView:self didTapSquare:sq];
}

- (void)setSelectedSquare:(int)s { _selectedSquare = s; [self setNeedsDisplay]; }
- (void)setTargetSquares:(NSArray *)t { _targetSquares = [t copy]; [self setNeedsDisplay]; }
- (void)setLastFrom:(int)v { _lastFrom = v; [self setNeedsDisplay]; }
- (void)setLastTo:(int)v { _lastTo = v; [self setNeedsDisplay]; }
- (void)setCheckSquare:(int)v { _checkSquare = v; [self setNeedsDisplay]; }
- (void)setShowCoordinates:(BOOL)v { _showCoordinates = v; [self setNeedsDisplay]; }

- (void)refreshTheme {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    SettingsManager *st = [SettingsManager shared];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat s = [self squareSize];
    UIColor *light = st.lightSquareColor, *dark = st.darkSquareColor;
    for (int sq = 0; sq < 64; sq++) {
        CGRect r = [self rectForSquare:sq];
        BOOL isLight = ((CE_FILE(sq) + CE_RANK(sq)) & 1) == 1;
        [(isLight ? light : dark) setFill];
        UIRectFill(r);
        if (sq == _lastFrom || sq == _lastTo) {
            [[UIColor colorWithRed:0.80 green:0.82 blue:0.25 alpha:0.50] setFill];
            UIRectFillUsingBlendMode(r, kCGBlendModeNormal);
        }
        if (sq == _selectedSquare) {
            [[UIColor colorWithRed:0.36 green:0.66 blue:0.95 alpha:0.55] setFill];
            UIRectFillUsingBlendMode(r, kCGBlendModeNormal);
        }
        if (sq == _checkSquare) {
            CGContextSaveGState(ctx);
            [[UIColor colorWithRed:0.90 green:0.15 blue:0.12 alpha:0.70] setFill];
            CGContextFillEllipseInRect(ctx, CGRectInset(r, s * 0.04, s * 0.04));
            CGContextRestoreGState(ctx);
        }
    }
    // Waar mag het gekozen stuk heen?
    UIColor *hint = [UIColor colorWithWhite:0.0 alpha:0.28];
    for (NSNumber *n in _targetSquares) {
        int sq = n.intValue;
        CGRect r = [self rectForSquare:sq];
        if (_board[sq]) {
            CGContextSetStrokeColorWithColor(ctx, hint.CGColor);
            CGContextSetLineWidth(ctx, s * 0.08);
            CGContextStrokeEllipseInRect(ctx, CGRectInset(r, s * 0.07, s * 0.07));
        } else {
            CGFloat d = s * 0.30;
            CGContextSetFillColorWithColor(ctx, hint.CGColor);
            CGContextFillEllipseInRect(ctx, CGRectMake(CGRectGetMidX(r) - d / 2, CGRectGetMidY(r) - d / 2, d, d));
        }
    }
    if (_showCoordinates && s > 18) {
        UIFont *font = [UIFont boldSystemFontOfSize:MAX(9, s * 0.16)];
        for (int i = 0; i < 8; i++) {
            // Letters onderaan.
            int f = _flipped ? 7 - i : i;
            int bottomRank = _flipped ? 7 : 0;
            int sq = CE_SQ(f, bottomRank);
            CGRect r = [self rectForSquare:sq];
            BOOL isLight = ((f + bottomRank) & 1) == 1;
            NSString *letter = [NSString stringWithFormat:@"%c", 'a' + f];
            NSDictionary *attrs = @{ NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: isLight ? dark : light };
            CGSize ts = [letter sizeWithAttributes:attrs];
            [letter drawAtPoint:CGPointMake(CGRectGetMaxX(r) - ts.width - s * 0.05, CGRectGetMaxY(r) - ts.height - s * 0.02)
                 withAttributes:attrs];
            // Cijfers links.
            int rank = _flipped ? i : 7 - i;
            int leftFile = _flipped ? 7 : 0;
            sq = CE_SQ(leftFile, rank);
            r = [self rectForSquare:sq];
            isLight = ((leftFile + rank) & 1) == 1;
            NSString *num = [NSString stringWithFormat:@"%d", rank + 1];
            attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: isLight ? dark : light };
            [num drawAtPoint:CGPointMake(r.origin.x + s * 0.05, r.origin.y + s * 0.02) withAttributes:attrs];
        }
    }
}

- (void)rebuildPieces {
    for (UIView *v in _pieces.allValues) [v removeFromSuperview];
    [_pieces removeAllObjects];
    for (int sq = 0; sq < 64; sq++) {
        if (!_board[sq]) continue;
        PieceView *pv = [[PieceView alloc] initWithPiece:_board[sq]];
        pv.frame = [self rectForSquare:sq];
        [self addSubview:pv];
        _pieces[@(sq)] = pv;
    }
}

- (void)setBoard:(const uint8_t *)board animatedFrom:(int)from to:(int)to {
    memcpy(_board, board, 64);
    [self setNeedsDisplay];
    PieceView *mover = from >= 0 ? _pieces[@(from)] : nil;
    if (mover && to >= 0 && to != from && self.window) {
        PieceView *victim = _pieces[@(to)];
        [self bringSubviewToFront:mover];
        _animating = YES;
        CGRect target = [self rectForSquare:to];
        [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            mover.frame = target;
            victim.alpha = 0.0;
        } completion:^(BOOL finished) {
            self->_animating = NO;
            [self rebuildPieces];
        }];
    } else {
        [self rebuildPieces];
    }
}

- (void)setFlipped:(BOOL)flipped animated:(BOOL)animated {
    if (flipped == _flipped) return;
    _flipped = flipped;
    if (animated && self.window) {
        [UIView transitionWithView:self duration:0.5
                           options:UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionAllowAnimatedContent
                        animations:^{
                            [self setNeedsDisplay];
                            [self.layer displayIfNeeded];
                            [self rebuildPieces];
                        } completion:nil];
    } else {
        [self setNeedsDisplay];
        [self rebuildPieces];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_animating) return;
    for (NSNumber *k in _pieces) {
        UIView *v = _pieces[k];
        v.frame = [self rectForSquare:k.intValue];
    }
    [self setNeedsDisplay];
}

@end
