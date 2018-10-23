//
//  ViewController.m
//  Example
//
//  Created by Injoy on 2018/10/2.
//  Copyright © 2018 Injoy. All rights reserved.
//

#import "ViewController.h"
#import "IDPhotoView.h"

@interface ViewController ()

@property (nonatomic, strong) IDPhotoView *photoView;
@property (nonatomic, strong) UIView *foregroundView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Example";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"ContentInsets" style:UIBarButtonItemStylePlain target:self action:@selector(contentInsetsDemo)];
    
    self.photoView = [[IDPhotoView alloc] initWithFrame:self.view.bounds];
    self.photoView.automaticallyAdaptiveScrollViewInset = NO;
    self.photoView.image = [UIImage imageNamed:@"hakka"];
    [self.view addSubview:self.photoView];
    
    self.photoView.autoresizingMask = 63;    // all
    self.photoView.layer.borderWidth = 3;
    self.photoView.layer.borderColor = [UIColor redColor].CGColor;
    
    self.foregroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.view.frame.size.height)];
    self.foregroundView.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.3];
    self.foregroundView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:self.foregroundView];
}

- (void)contentInsetsDemo {
    if (self.foregroundView.bounds.size.width == 0) {
        self.foregroundView.bounds = CGRectMake(0, 0, 200, self.foregroundView.bounds.size.height);
        self.photoView.contentInset = UIEdgeInsetsMake(0, 100, 0, 0);
    } else {
        self.foregroundView.bounds = CGRectMake(0, 0, 0, self.foregroundView.bounds.size.height);
        self.photoView.contentInset = UIEdgeInsetsZero;
    }
}

@end
