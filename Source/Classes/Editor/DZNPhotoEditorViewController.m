//
//  DZNPhotoEditorViewController.m
//  DZNPhotoPickerController
//  https://github.com/dzenbot/DZNPhotoPickerController
//
//  Created by Ignacio Romero Zurbuchen on 10/5/13.
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Licence: MIT-Licence
//

#import "DZNPhotoEditorViewController.h"
#import "ImageScrollView.h"

#define DZN_IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define DZN_IS_IOS8 ([[UIDevice currentDevice].systemVersion floatValue] > 8.0)
CGFloat degreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

typedef NS_ENUM(NSInteger, DZNPhotoAspect) {
    DZNPhotoAspectUnknown,
    DZNPhotoAspectSquare,
    DZNPhotoAspectVerticalRectangle,
    DZNPhotoAspectHorizontalRectangle
};

@interface DZNPhotoEditorContainerView : UIView
@end

@implementation DZNPhotoEditorContainerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    
    if ([self.subviews containsObject:view]) {
        return view;
    }
    else if ([view isEqual:self]) {
        return nil;
    }
    return view;
}

@end

@interface DZNPhotoEditorViewController () <UIScrollViewDelegate>
{
    BOOL imageLandscape;
    int rotationCount;
}
/** An optional UIImage use for displaying the already existing full size image. */
@property (nonatomic, copy) UIImage *editingImage;
@property (nonatomic, copy) UIImage *originalSizedImage;

/** The scrollview containing the image for allowing panning and zooming. */
@property (nonatomic, readonly) ImageScrollView *scrollView;
/** The container for the mask guide image. */
@property (nonatomic, readonly) UIImageView *maskView;
/** The view layed out at the bottom for displaying action buttons. */
@property (nonatomic, readonly) DZNPhotoEditorContainerView *bottomView;

@end

@implementation DZNPhotoEditorViewController
@synthesize scrollView = _scrollView;
@synthesize maskView = _maskView;
@synthesize bottomView = _bottomView;
@synthesize activityIndicator = _activityIndicator;
@synthesize cropSize = _cropSize;

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        self.editingImage = image;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor blackColor];
    
    if (DZN_IS_IPAD) {
        self.title = NSLocalizedString(@"Edit Photo", nil);
    }
    else {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

#pragma mark - View lifecycle

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)loadView
{
    [super loadView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (_scrollView.superview) {
        return;
    }
    
    [self.view addSubview:self.scrollView];
    self.scrollView.center = self.view.center;
    
    [self.view addSubview:self.bottomView];
    
    [self.view insertSubview:self.maskView aboveSubview:self.scrollView];
    
    NSDictionary *views = @{@"bottomView": self.bottomView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomView(88)]|" options:0 metrics:nil views:views]];
    
    [self.view layoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!DZN_IS_IPAD) {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!DZN_IS_IPAD) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }
    else if (self.navigationController.isNavigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        self.navigationItem.hidesBackButton = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (!DZN_IS_IPAD) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - Getter methods

- (UIScrollView *)scrollView
{
    if (!_scrollView)
    {
        _scrollView = [[ImageScrollView alloc] initWithFrame:CGRectMake(0, 0, self.cropSize.width, self.cropSize.height)];
        _scrollView.backgroundColor = [UIColor colorWithRed:0xf3/255.0 green:0xf4/255.0 blue:0xf7/255.0 alpha:1.0];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        [_scrollView displayImage:self.originalSizedImage];
        UITapGestureRecognizer *twoTaps = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twoTapsGestureHandle)];
        twoTaps.numberOfTapsRequired = 2;
        [_scrollView addGestureRecognizer:twoTaps];
    }
    return _scrollView;
}

- (UIImageView *)maskView
{
    if (!_maskView)
    {
        _maskView = [[UIImageView alloc] initWithImage:[self overlayMask]];
        _maskView.userInteractionEnabled = NO;
    }
    return _maskView;
}

- (DZNPhotoEditorContainerView *)bottomView
{
    if (!_bottomView)
    {
        _bottomView = [DZNPhotoEditorContainerView new];
        _bottomView.translatesAutoresizingMaskIntoConstraints = NO;
        _bottomView.tintColor = [UIColor whiteColor];
        _bottomView.userInteractionEnabled = YES;
        
        //        _leftButton = [self buttonWithTitle:NSLocalizedString(@"Cancel", nil)];
        _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftButton setImage:[UIImage imageNamed:@"DZNImageCancel"] forState:UIControlStateNormal];
        [_leftButton addTarget:self action:@selector(cancelEdition:) forControlEvents:UIControlEventTouchUpInside];
        
        //        _middleButton = [self buttonWithTitle:NSLocalizedString(@"Rotation", nil)];
        _middleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_middleButton setImage:[UIImage imageNamed:@"DZNImageRotate"] forState:UIControlStateNormal];
        [_middleButton addTarget:self action:@selector(rotateImage:) forControlEvents:UIControlEventTouchUpInside];
        
        //        _rightButton = [self buttonWithTitle:NSLocalizedString(@"Choose", nil)];
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightButton setImage:[UIImage imageNamed:@"DZNImageSelect"] forState:UIControlStateNormal];
        [_rightButton addTarget:self action:@selector(acceptEdition:) forControlEvents:UIControlEventTouchUpInside];
        
        NSMutableDictionary *views = [NSMutableDictionary new];
        NSDictionary *metrics = @{@"hmargin" : @(13), @"barsHeight": @(self.barsHeight)};
        
        if (DZN_IS_IPAD) {
            if (self.navigationController.viewControllers.count == 1) {
                self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.leftButton];
            }
            
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightButton];
        }
        else {
            self.leftButton.translatesAutoresizingMaskIntoConstraints = NO;
            self.rightButton.translatesAutoresizingMaskIntoConstraints = NO;
            self.middleButton.translatesAutoresizingMaskIntoConstraints = NO;
            
            [_bottomView addSubview:self.leftButton];
            [_bottomView addSubview:self.rightButton];
            [_bottomView addSubview:self.middleButton];
            
            [views setObject:self.leftButton forKey:@"leftButton"];
            [views setObject:self.rightButton forKey:@"rightButton"];
            [views setObject:self.middleButton forKey:@"middleButton"];
            
            [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hmargin-[leftButton]" options:0 metrics:metrics views:views]];
            [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[rightButton]-hmargin-|" options:0 metrics:metrics views:views]];
            [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:self.middleButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
            
            [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftButton]|" options:0 metrics:metrics views:views]];
            [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rightButton]|" options:0 metrics:metrics views:views]];
            [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[middleButton]|" options:0 metrics:metrics views:views]];
        }
        
        if (_cropMode == DZNPhotoEditorViewControllerCropModeCircular)
        {
            UILabel *topLabel = [UILabel new];
            topLabel.translatesAutoresizingMaskIntoConstraints = NO;
            topLabel.textColor = [UIColor whiteColor];
            topLabel.textAlignment = NSTextAlignmentCenter;
            topLabel.font = [UIFont systemFontOfSize:18.0];
            topLabel.text = NSLocalizedString(@"Move and Scale", nil);
            [self.view addSubview:topLabel];
            
            NSDictionary *labels = @{@"label" : topLabel};
            
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|" options:0 metrics:nil views:labels]];
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-barsHeight-[label]" options:0 metrics:metrics views:labels]];
        }
    }
    return _bottomView;
}

- (UIActivityIndicatorView *)activityIndicator
{
    if (!_activityIndicator)
    {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        _activityIndicator.hidesWhenStopped = YES;
        _activityIndicator.color = [UIColor whiteColor];
    }
    return _activityIndicator;
}

- (UIButton *)buttonWithTitle:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button.titleLabel setFont:[UIFont systemFontOfSize:18.0]];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(-1.0, 0.0, 0.0, 0.0)];
    [button setUserInteractionEnabled:YES];
    [button sizeToFit];
    return button;
}

- (CGSize)cropSize
{
    CGSize viewSize = (!DZN_IS_IPAD) ? self.view.bounds.size : self.navigationController.preferredContentSize;
    
    if (self.cropMode == DZNPhotoEditorViewControllerCropModeCustom) {
        CGFloat cropHeight = roundf((_cropSize.height * viewSize.width) / _cropSize.width);
        if (cropHeight > viewSize.height) {
            cropHeight = viewSize.height;
        }
        return CGSizeMake(_cropSize.width, cropHeight);
    }
    else {
        return CGSizeMake(viewSize.width, viewSize.width);
    }
}

- (CGRect)guideRect
{
    return CGRectMake(0.0, 0.0, self.cropSize.width, self.cropSize.height);
}

- (CGFloat)barsHeight
{
    CGFloat height = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    height += CGRectGetHeight(self.navigationController.navigationBar.frame);
    return height;
}

CGSize CGSizeAspectFit(CGSize aspectRatio, CGSize boundingSize)
{
    CGFloat hRatio = boundingSize.width / aspectRatio.width;
    CGFloat vRation = boundingSize.height / aspectRatio.height;
    if (hRatio < vRation) {
        boundingSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height;
    }
    else if (vRation < hRatio) {
        boundingSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width;
    }
    return boundingSize;
}

DZNPhotoAspect photoAspectFromSize(CGSize aspectRatio)
{
    if (aspectRatio.width > aspectRatio.height) {
        return DZNPhotoAspectHorizontalRectangle;
    }
    else if (aspectRatio.width < aspectRatio.height) {
        return DZNPhotoAspectVerticalRectangle;
    }
    else if (aspectRatio.width == aspectRatio.height) {
        return DZNPhotoAspectSquare;
    }
    else {
        return DZNPhotoAspectUnknown;
    }
}

- (UIImage *)overlayMask
{
    switch (self.cropMode) {
        case DZNPhotoEditorViewControllerCropModeNone:
        case DZNPhotoEditorViewControllerCropModeSquare:
        case DZNPhotoEditorViewControllerCropModeCustom:
            return [self squareOverlayMask];
        case DZNPhotoEditorViewControllerCropModeCircular:
            return nil;
    }
}

/*
 The square overlay mask image to be displayed on top of the photo as cropping guideline.
 Created with PaintCode. The source file is available inside of the Resource folder.
 */
- (UIImage *)squareOverlayMask
{
    // Constants
    CGRect bounds = self.navigationController.view.bounds;
    
    CGFloat width = self.cropSize.width;
    CGFloat height = self.cropSize.height;
    CGFloat margin = (bounds.size.height-self.cropSize.height)/2;
    CGFloat lineWidth = 1.0;
    
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0);
    
    // Create the bezier path & drawing
    UIBezierPath *clipPath = [UIBezierPath bezierPath];
    [clipPath moveToPoint:CGPointMake(width, margin)];
    [clipPath addLineToPoint:CGPointMake(0, margin)];
    [clipPath addLineToPoint:CGPointMake(0, 0)];
    [clipPath addLineToPoint:CGPointMake(width, 0)];
    [clipPath addLineToPoint:CGPointMake(width, margin)];
    [clipPath closePath];
    [clipPath moveToPoint:CGPointMake(width, CGRectGetHeight(bounds))];
    [clipPath addLineToPoint:CGPointMake(0, CGRectGetHeight(bounds))];
    [clipPath addLineToPoint:CGPointMake(0, margin+height)];
    [clipPath addLineToPoint:CGPointMake(width, margin+height)];
    [clipPath addLineToPoint:CGPointMake(width, CGRectGetHeight(bounds))];
    [clipPath closePath];
    [[UIColor colorWithWhite:0.0 alpha:0.5] setFill];
    [clipPath fill];
    
    // Add the square crop
    CGRect rect = CGRectMake(lineWidth/2, margin+lineWidth/2, width-lineWidth, self.cropSize.height-lineWidth);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:rect];
    [[UIColor colorWithWhite:1.0 alpha:0.5] setStroke];
    maskPath.lineWidth = lineWidth;
    [maskPath stroke];
    
    //Create the image using the current context.
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

/*
 The final edited photo rendering.
 */
- (UIImage *)editedImage
{
    UIImage *image = nil;
    
    CGRect guideRect = [self guideRect];
    
    UIGraphicsBeginImageContextWithOptions(guideRect.size, NO, 0);{
        [self.scrollView drawViewHierarchyInRect:guideRect afterScreenUpdates:NO];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

#pragma mark - Setter methods

- (void)setCropMode:(DZNPhotoEditorViewControllerCropMode)mode
{
    NSAssert(mode > DZNPhotoEditorViewControllerCropModeNone, @"Expecting other cropMode than 'None' for edition.");
    
    _cropMode = mode;
}

/*
 Sets the crop size
 Instead of asigning the same CGSize value, we first calculate a proportional height
 based on the maximum width of the container (ie: for iPhone, 320px).
 */
- (void)setCropSize:(CGSize)size
{
    if (self.cropMode == DZNPhotoEditorViewControllerCropModeCustom) {
        NSAssert(!CGSizeEqualToSize(size, CGSizeZero) , @"Expecting a non-zero CGSize for cropMode 'Custom'.");
    }
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        CGFloat width = (!DZN_IS_IPAD) ? self.view.bounds.size.width : self.navigationController.preferredContentSize.width;
        size = CGSizeMake(width, width);
    }
    
    self.editingImage = [self resizeImage:self.editingImage];
    self.originalSizedImage = [self imageWithImage:self.editingImage scaledToFitToSize:size];
    _cropSize = size;
}

- (UIImage *)resizeImage:(UIImage *)image
{
    
    CGFloat factor = CGRectGetWidth([UIScreen mainScreen].bounds) * [UIScreen mainScreen].scale/ image.size.width;
    factor = MAX(0.5, factor);
    CGSize newSize = CGSizeMake(image.size.width * factor, image.size.height * factor);
    UIGraphicsBeginImageContextWithOptions(newSize, YES, image.scale);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)imageWithImage:(UIImage *)image
          scaledToFitToSize:(CGSize)newSize
{
    
    //Determine the scale factors
    CGFloat widthScale = newSize.width/image.size.width;
    CGFloat heightScale = newSize.height/image.size.height;
    
    CGFloat scaleFactor;
    
    //The smaller scale factor will scale more (0 < scaleFactor < 1) leaving the other dimension inside the newSize rect
    widthScale < heightScale ? (scaleFactor = widthScale) : (scaleFactor = heightScale);
    
    //Scale the image not reduce quality
    return [UIImage imageWithData:UIImagePNGRepresentation(image) scale:scaleFactor];
}

- (UIImage *)imageRotated:(UIImage *)image byDegrees:(CGFloat)degrees
{
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContextWithOptions(rotatedSize, YES, image.scale);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    // Rotate the image context
    CGContextRotateCTM(bitmap, degreesToRadians(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - DZNPhotoEditorViewController methods

- (void)acceptEdition:(id)sender
{
    if (self.scrollView.zoomScale > self.scrollView.maximumZoomScale) {
        return;
    }
    
    dispatch_queue_t exampleQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(exampleQueue, ^{
        
        UIImage *editedImage = [self editedImage];
        dispatch_queue_t queue = dispatch_get_main_queue();
        dispatch_async(queue, ^{
            
            if (self.acceptBlock) {
                
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                 [NSValue valueWithCGRect:self.guideRect], UIImagePickerControllerCropRect,
                                                 @"public.image", UIImagePickerControllerMediaType,
                                                 @(self.cropMode), DZNPhotoPickerControllerCropMode,
                                                 @(self.scrollView.zoomScale), DZNPhotoPickerControllerCropZoomScale,
                                                 nil];
                
                if (self.editingImage) {
                    [userInfo setObject:self.editingImage forKey:UIImagePickerControllerOriginalImage];
                }
                if (editedImage) {
                    [userInfo setObject:editedImage forKey:UIImagePickerControllerEditedImage];
                }
                
                self.acceptBlock(self, userInfo);
            }
        });
    });
}

- (void)cancelEdition:(id)sender
{
    if (self.cancelBlock) {
        self.cancelBlock(self);
    }
}

- (void)rotateImage:(id)sender
{
    rotationCount++;
    imageLandscape = rotationCount % 2;
    CGFloat degree = rotationCount % 4 * 90;
    
    UIImage *newImage = [self imageRotated:self.editingImage byDegrees:degree];
    CGFloat factor = imageLandscape ? _cropSize.width/newImage.size.width : _cropSize.height/newImage.size.height;
    newImage = [UIImage imageWithData:UIImagePNGRepresentation(newImage) scale:factor];
    
    [_scrollView displayImage:newImage];
}

- (void)twoTapsGestureHandle
{
    //双击顶边
    CGFloat factor = MAX(_cropSize.width/_scrollView.contentSize.width, _cropSize.height/_scrollView.contentSize.height);
    //最小放大1.2倍
    factor = MAX(1.2, factor);
    if (_scrollView.zoomScale > _scrollView.minimumZoomScale) {
        _scrollView.zoomScale = _scrollView.minimumZoomScale;
    }else {
        _scrollView.zoomScale = _scrollView.minimumZoomScale * factor;
    }
}

#pragma mark - View Auto-Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}


#pragma mark - View lifeterm

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    _scrollView = nil;
    _editingImage = nil;
    _bottomView = nil;
    _activityIndicator = nil;
}

@end
