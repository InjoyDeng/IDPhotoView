//
//  IDPhotoView.h
//  ImmLearnTeacher
//
//  Created by Injoy on 2018/9/19.
//  Copyright © 2018年 ImmLearnStudent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IDPhotoView;

typedef NS_ENUM(NSInteger, IDPhotoViewContentMode) {
    IDPhotoViewContentModeScaleAspectFit,
    IDPhotoViewContentModeScaleAspectFill,
    IDPhotoViewContentModeScaleAspectFillToLeft,
    IDPhotoViewContentModeScaleAspectFillToTop,
    IDPhotoViewContentModeScaleAspectFillToRight,
    IDPhotoViewContentModeScaleAspectFillToBottom,
};


@protocol IDPhotoViewDelegate <NSObject>

@optional
- (void)photoView:(IDPhotoView *)photoView imageDidChanged:(UIImage *)image;
- (void)photoViewLoadedImageComplete:(IDPhotoView *)photoView;

- (void)photoViewDidScroll:(IDPhotoView *)photoView;
- (void)photoViewEndedScrolling:(IDPhotoView *)photoView;

- (void)photoViewDidZoom:(IDPhotoView *)photoView;
- (void)photoViewDidEndZooming:(IDPhotoView *)photoView scale:(CGFloat)scale;

@end


@interface IDPhotoView : UIView

@property (nonatomic, strong, readonly) UIScrollView *scrollView;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign) BOOL automaticallyAdaptiveScrollViewInset;    // default YES

// When the contentMode is changed after the image has been displayed, the display mode of the
// photoView will not be changed automatically, and need call needsAdjustLayout.
@property (nonatomic, assign) IDPhotoViewContentMode contentMode;

@property (nonatomic, weak) id<IDPhotoViewDelegate> deleate;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *doubleTapGestureRecognizer;

- (instancetype)init;
- (instancetype)initWithFrame:(CGRect)frame;
- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image;

- (void)needsAdjustLayout;

@end
