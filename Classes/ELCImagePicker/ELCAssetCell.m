//
//  AssetCell.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAssetTablePicker.h"

@interface ELCAssetCell ()

@property (nonatomic, retain) NSArray *rowAssets;
@property (nonatomic, retain) NSMutableArray *imageViewArray;
@property (nonatomic, retain) NSMutableArray *overlayViewArray;

@end

@implementation ELCAssetCell

@synthesize rowAssets = _rowAssets;

- (id)initWithAssets:(NSArray *)assets reuseIdentifier:(NSString *)identifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	if(self) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self addGestureRecognizer:tapRecognizer];

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                                   initWithTarget:self
                                                   action:@selector(cellLongPress:)];
        longPress.minimumPressDuration = 0.2;
        longPress.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:longPress];
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.imageViewArray = mutableArray;
        
        NSMutableArray *overlayArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.overlayViewArray = overlayArray;

        [self setAssets:assets];
	}
	return self;
}

- (void)setAssets:(NSArray *)assets
{
    self.rowAssets = assets;
	for (UIView *view in [self subviews]) {
		[view removeFromSuperview];
	}
    //set up a pointer here so we don't keep calling [UIImage imageNamed:] if creating overlays
    UIImage *overlayImage = nil;
    for (int i = 0; i < [_rowAssets count]; ++i) {

        ELCAsset *asset = [_rowAssets objectAtIndex:i];

        if (i < [_imageViewArray count]) {
            UIImageView *imageView = [_imageViewArray objectAtIndex:i];
            imageView.image = [UIImage imageWithCGImage:asset.asset.thumbnail];
        } else {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:asset.asset.thumbnail]];
            [_imageViewArray addObject:imageView];
        }
        
        if (i < [_overlayViewArray count]) {
            UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = asset.selected ? NO : YES;
        } else {
            if (overlayImage == nil) {
                overlayImage = [UIImage imageNamed:@"Overlay.png"];
            }
            UIImageView *overlayView = [[UIImageView alloc] initWithImage:overlayImage];
            [_overlayViewArray addObject:overlayView];
            overlayView.hidden = asset.selected ? NO : YES;
        }
    }
}

- (void)cellTapped:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint point = [tapRecognizer locationInView:self];
    CGFloat totalWidth = self.rowAssets.count * 75 + (self.rowAssets.count - 1) * 4;
    CGFloat startX = (self.bounds.size.width - totalWidth) / 2;
    
	CGRect frame = CGRectMake(startX, 2, 75, 75);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
        if (CGRectContainsPoint(frame, point)) {
            ELCAsset *asset = [_rowAssets objectAtIndex:i];
            asset.selected = !asset.selected;
            UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = !asset.selected;
            break;
        }
        frame.origin.x = frame.origin.x + frame.size.width + 4;
    }
}

- (void)cellLongPress:(UILongPressGestureRecognizer *)tapRecognizer
{
    if (tapRecognizer.state != UIGestureRecognizerStateEnded) {
        CGPoint point = [tapRecognizer locationInView:self];
        CGFloat totalWidth = self.rowAssets.count * 75 + (self.rowAssets.count - 1) * 4;
        CGFloat startX = (self.bounds.size.width - totalWidth) / 2;
        
        CGRect frame = CGRectMake(startX, 2, 75, 75);
        
        for (int i = 0; i < [_rowAssets count]; ++i) {
            if (CGRectContainsPoint(frame, point)) {

                // get the tableview and the controller
                UITableView *tableView = (UITableView *)self.superview;
                ELCAssetTablePicker *controller = (ELCAssetTablePicker *) tableView.dataSource;
                
                // get the point inside the controller view
                CGPoint point = [tapRecognizer locationInView:controller.view];

                // calculate where to shoe the preview image
                float contentHeight = tableView.bounds.size.height;
                float previewImageHeight = contentHeight / 2 - 10;
                CGRect imageViewFrame = CGRectNull;
                float topDiff = point.y - tableView.bounds.origin.y;
                if (topDiff < contentHeight / 2) {
                    imageViewFrame = CGRectMake(0, tableView.bounds.origin.y + tableView.bounds.size.height - previewImageHeight, 320, previewImageHeight);
                } else {
                    imageViewFrame = CGRectMake(0, tableView.bounds.origin.y, 320, previewImageHeight);
                }
                
                // get the image using assets
                ELCAsset *asset = [_rowAssets objectAtIndex:i];
                ALAssetRepresentation *assetRep = [[asset asset] defaultRepresentation];
                CGImageRef imgRef = [assetRep fullScreenImage];
                UIImage *image = [UIImage imageWithCGImage:imgRef
                                                   scale:[UIScreen mainScreen].scale
                                             orientation:UIImageOrientationUp];
                
                // define the preview image view
                controller.previewImageView.frame = imageViewFrame;
                controller.previewImageView.image = image;
                controller.previewImageView.hidden = NO;
                
                break;
            }
            frame.origin.x = frame.origin.x + frame.size.width + 4;
        }
    } else {
        UITableView *tableView = (UITableView *)self.superview;
        ELCAssetTablePicker *controller = (ELCAssetTablePicker *) tableView.dataSource;
        controller.previewImageView.hidden = YES;
    }
}

- (void)layoutSubviews
{    
    CGFloat totalWidth = self.rowAssets.count * 75 + (self.rowAssets.count - 1) * 4;
    CGFloat startX = (self.bounds.size.width - totalWidth) / 2;
    
	CGRect frame = CGRectMake(startX, 2, 75, 75);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
		UIImageView *imageView = [_imageViewArray objectAtIndex:i];
		[imageView setFrame:frame];
		[self addSubview:imageView];
        
        
        UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
        [overlayView setFrame:frame];
        [self addSubview:overlayView];
        
		frame.origin.x = frame.origin.x + frame.size.width + 4;
	}
    
    self.backgroundColor = [UIColor blackColor];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"Long press Ended");
    }
    else {
        NSLog(@"Long press detected.");
    }
}

@end
