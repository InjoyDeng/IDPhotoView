//
//  IDPhotoView.m
//  ImmLearnTeacher
//
//  Created by Injoy on 2018/9/19.
//  Copyright © 2018年 ImmLearnStudent. All rights reserved.
//

#import "IDPhotoView.h"

typedef NS_ENUM(NSInteger, IDScrollViewContentOffsetAlignment) {
    IDScrollViewContentOffsetAlignmentTop,
    IDScrollViewContentOffsetAlignmentLeft,
    IDScrollViewContentOffsetAlignmentBottom,
    IDScrollViewContentOffsetAlignmentRight,
    IDScrollViewContentOffsetAlignmentCenter
};


static CGFloat id_currentSystemVersion;


@interface IDPhotoView() <UIScrollViewDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIView *packView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) BOOL isNeedsRelayout;

@end

@implementation IDPhotoView
@dynamic image;

+ (void)initialize {
    id_currentSystemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame image:nil];
}

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image {
    if (self = [super initWithFrame:frame]) {
        [self _initPhotoView];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)_initPhotoView {
    self.automaticallyAdaptiveScrollViewInset = YES;
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.scrollView];
    
    self.packView = [[UIView alloc] init];
    [self.scrollView addSubview:self.packView];
    
    self.containerView = [[UIView alloc] init];
    [self.packView addSubview:self.containerView];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleToFill;
    [self.containerView addSubview:self.imageView];
    
    // constraint
    [NSLayoutConstraint activateConstraints:@[
                                              [self.scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [self.scrollView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
                                              [self.scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                              [self.scrollView.rightAnchor constraintEqualToAnchor:self.rightAnchor]
                                              ]];
    
    [self registerRotationNotification];
    [self setupGestureRecognizer];
}

- (void)setupGestureRecognizer {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapHandler:)];
    tapGestureRecognizer.numberOfTapsRequired = 2;
    [self.containerView addGestureRecognizer:tapGestureRecognizer];
    self.doubleTapGestureRecognizer = tapGestureRecognizer;
}

- (void)registerRotationNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangedOrientation:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

#pragma mark - Setter Getter

- (UIImage *)image {
    return self.imageView.image;
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
    
    if (self.deleate && [self.deleate respondsToSelector:@selector(photoView:imageDidChanged:)]) {
        [self.deleate photoView:self imageDidChanged:image];
    }
    
    [self needsAdjustLayout];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        while (self.isNeedsRelayout) {
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (self.deleate && [self.deleate respondsToSelector:@selector(photoViewLoadedImageComplete:)]) {
                [self.deleate photoViewLoadedImageComplete:self];
            }
        });
    });
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;
    self.scrollView.scrollIndicatorInsets = contentInset;
    
    [self updateScrollViewContentInset];
    [self resetScaleWithContainerSize:[self getDefaultContainerSize]];
    [self updatePackLayout];
    
    if (self.scrollView.zoomScale < self.scrollView.minimumZoomScale) {
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    }
}

- (void)setAutomaticallyAdaptiveScrollViewInset:(BOOL)automaticallyAdaptiveScrollViewInset {
    _automaticallyAdaptiveScrollViewInset = automaticallyAdaptiveScrollViewInset;
    
    if (@available(iOS 11.0, *)) {
        if (automaticallyAdaptiveScrollViewInset) {
            self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
        } else {
            self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
}

#pragma mark - Override

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.isNeedsRelayout) {
        self.scrollView.zoomScale   = 1;
        self.containerView.frame    = CGRectMake(0, 0, self.image.size.width, self.image.size.height);
        self.imageView.frame        = self.containerView.bounds;
        self.scrollView.contentSize = self.containerView.frame.size;
        
        // Adjust insets of the scrollView, otherwise the photo will be displayed on the left.
        [self updateScrollViewContentInset];
        [self adjustDisplayStyleWithContentMode];
        
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    }
    
    [self updatePackLayout];
    
    if (self.isNeedsRelayout) {
        self.isNeedsRelayout = NO;
    }
}

#pragma mark - Public Function

- (void)needsAdjustLayout {
    self.isNeedsRelayout = YES;
    [self setNeedsLayout];
}

#pragma mark - Action

- (void)doubleTapHandler :(UITapGestureRecognizer *)recognizer {
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    } else if (self.scrollView.zoomScale < self.scrollView.maximumZoomScale) {
        CGPoint location  = [recognizer locationInView:recognizer.view];
        CGRect zoomToRect = CGRectMake(0, 0, 50, 50);
        zoomToRect.origin = CGPointMake(location.x - CGRectGetWidth(zoomToRect)/2, location.y - CGRectGetHeight(zoomToRect)/2);
        [self.scrollView zoomToRect:zoomToRect animated:YES];
    }
}

#pragma mark - Adjust Pick

- (void)updatePackLayout {
    CGSize effectAreaSize   = [self effectAreaSize];
    
    if (self.automaticallyAdaptiveScrollViewInset) {
        self.packView.frame = CGRectMake(self.packView.frame.origin.x,
                                         self.packView.frame.origin.y,
                                         MAX(effectAreaSize.width, self.containerView.frame.size.width),
                                         MAX(effectAreaSize.height, self.containerView.frame.size.height));
    } else {
        self.packView.frame = CGRectMake(self.packView.frame.origin.x,
                                         self.packView.frame.origin.y,
                                         self.containerView.frame.size.width,
                                         self.containerView.frame.size.height);
    }
    self.containerView.center = self.packView.center;
}

- (void)updateScrollViewContentInset {
    CGRect frame = self.containerView.frame;
    
    CGFloat top = 0, left = 0;
    if (!self.automaticallyAdaptiveScrollViewInset) {
        if (self.scrollView.contentSize.width < self.bounds.size.width) {
            left = (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) / 2;
        }
        if (self.scrollView.contentSize.height < self.bounds.size.height) {
            top = (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) / 2;
        }
        
        top  -= frame.origin.y;
        left -= frame.origin.x;
    }
    
    self.scrollView.contentInset = UIEdgeInsetsMake(top + self.contentInset.top,
                                                    left + self.contentInset.left,
                                                    top + self.contentInset.bottom,
                                                    left + self.contentInset.right);
}

#pragma mark Adjust ContentMode
- (void)adjustDisplayStyleWithContentMode {
    CGSize containerSize = [self getDefaultContainerSize];
    [self resetScaleWithContainerSize:containerSize];
    
    switch (self.contentMode) {
        case IDPhotoViewContentModeScaleAspectFill:
            [self adjustScrollViewContentOffsetAlignment:IDScrollViewContentOffsetAlignmentCenter];
            break;
            
        case IDPhotoViewContentModeScaleAspectFillToTop:
            [self adjustScrollViewContentOffsetAlignment:IDScrollViewContentOffsetAlignmentTop];
            break;
        
        case IDPhotoViewContentModeScaleAspectFillToLeft:
            [self adjustScrollViewContentOffsetAlignment:IDScrollViewContentOffsetAlignmentLeft];
            break;
        
        case IDPhotoViewContentModeScaleAspectFillToBottom:
            [self adjustScrollViewContentOffsetAlignment:IDScrollViewContentOffsetAlignmentBottom];
            break;
            
        case IDPhotoViewContentModeScaleAspectFillToRight:
            [self adjustScrollViewContentOffsetAlignment:IDScrollViewContentOffsetAlignmentRight];
            break;
            
        case IDPhotoViewContentModeScaleAspectFit:
        default:
            [self adjustScrollViewContentOffsetAlignment:IDScrollViewContentOffsetAlignmentCenter];
            break;
    }
}

- (void)resetScaleWithContainerSize:(CGSize)containerSize {
    CGSize effectAreaSize   = [self effectAreaSize];
    CGFloat widthRatio      = effectAreaSize.width / containerSize.width;
    CGFloat heightRatio     = effectAreaSize.height / containerSize.height;
    CGFloat minRatio        = MIN(widthRatio, heightRatio);
    CGFloat maxRatio        = MAX(widthRatio, heightRatio);
    
    self.scrollView.maximumZoomScale = 1.0;
    switch (self.contentMode) {
        case IDPhotoViewContentModeScaleAspectFill:
        case IDPhotoViewContentModeScaleAspectFillToTop:
        case IDPhotoViewContentModeScaleAspectFillToLeft:
        case IDPhotoViewContentModeScaleAspectFillToBottom:
        case IDPhotoViewContentModeScaleAspectFillToRight:
            self.scrollView.minimumZoomScale = MIN(1.0, maxRatio);
            break;
            
        case IDPhotoViewContentModeScaleAspectFit:
        default:
            self.scrollView.minimumZoomScale = MIN(1.0, minRatio);
            break;
    }
}

- (void)adjustScrollViewContentOffsetAlignment:(IDScrollViewContentOffsetAlignment)alignment {
    CGSize effectAreaSize   = [self effectAreaSize];
    switch (alignment) {
        case IDScrollViewContentOffsetAlignmentTop:
            self.scrollView.contentOffset = CGPointMake(self.scrollView.contentSize.width - effectAreaSize.width, 0);
            break;
            
        case IDScrollViewContentOffsetAlignmentLeft:
            self.scrollView.contentOffset = CGPointMake(0, (self.scrollView.contentSize.height - effectAreaSize.height) / 2);
            break;
            
        case IDScrollViewContentOffsetAlignmentBottom:
            self.scrollView.contentOffset = CGPointMake(0, self.scrollView.contentSize.height - effectAreaSize.height);
            break;
            
        case IDScrollViewContentOffsetAlignmentRight:
            self.scrollView.contentOffset = CGPointMake(self.scrollView.contentSize.width - effectAreaSize.width,
                                                        (effectAreaSize.height - self.scrollView.contentSize.height) / 2);
            break;
            
        case IDScrollViewContentOffsetAlignmentCenter:
        default:
            self.scrollView.contentOffset = CGPointMake((self.scrollView.contentSize.width - effectAreaSize.width) / 2,
                                                        (self.scrollView.contentSize.height - effectAreaSize.height) / 2);
            break;
    }
}

#pragma mark - Notification

- (void)didChangedOrientation:(NSNotification *)notification {
    [self needsAdjustLayout];
}

#pragma mark - Helper

- (CGSize)getDefaultContainerSize {
    CGFloat minImageSide = MIN(self.image.size.width, self.image.size.height);
    
    switch (self.contentMode) {
        case IDPhotoViewContentModeScaleAspectFill:
        case IDPhotoViewContentModeScaleAspectFillToTop:
        case IDPhotoViewContentModeScaleAspectFillToLeft:
        case IDPhotoViewContentModeScaleAspectFillToBottom:
        case IDPhotoViewContentModeScaleAspectFillToRight:
            return CGSizeMake(minImageSide, minImageSide);
            
        case IDPhotoViewContentModeScaleAspectFit:
        default:
            return self.image.size;
    }
}

- (CGSize)effectAreaSize {
    CGFloat effectWidth, effectHeight = 0;
    
    if (self.automaticallyAdaptiveScrollViewInset && id_currentSystemVersion >= 11.0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        UIEdgeInsets adjustedContentInset = self.scrollView.adjustedContentInset;
        effectWidth  = self.bounds.size.width - (adjustedContentInset.left + adjustedContentInset.right);
        effectHeight = self.bounds.size.height - (adjustedContentInset.top + adjustedContentInset.bottom);
#pragma clang diagnostic pop
    } else {
        effectWidth  = self.bounds.size.width - (self.scrollView.contentInset.left + self.scrollView.contentInset.right);
        effectHeight = self.bounds.size.height - (self.scrollView.contentInset.top + self.scrollView.contentInset.bottom);
    }
    
    return CGSizeMake(MAX(0, effectWidth), MAX(0, effectHeight));
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.containerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self updatePackLayout];
    
    if (!self.automaticallyAdaptiveScrollViewInset) {
        [self updateScrollViewContentInset];
    }
    
    if (self.deleate && [self.deleate respondsToSelector:@selector(photoViewDidZoom:)]) {
        [self.deleate photoViewDidZoom:self];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    if (self.deleate && [self.deleate respondsToSelector:@selector(photoViewDidEndZooming:scale:)]) {
        [self.deleate photoViewDidEndZooming:self scale:scale];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.deleate && [self.deleate respondsToSelector:@selector(photoViewDidScroll:)]) {
        [self.deleate photoViewDidScroll:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.deleate && [self.deleate respondsToSelector:@selector(photoViewEndedScrolling:)]) {
        [self.deleate photoViewEndedScrolling:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.deleate && [self.deleate respondsToSelector:@selector(photoViewEndedScrolling:)] && !decelerate) {
        [self.deleate photoViewEndedScrolling:self];
    }
}

@end
