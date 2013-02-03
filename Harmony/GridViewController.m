//
//  GridViewController.m
//  Merry992
//
//  Created by hongyu on 13-1-20.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import "GridViewController.h"
#import "GridCellView.h"
#import "PictureViewerController.h"
#import "MWPhotoBrowser.h"
#import "MediaResourceFetcher.h"
#import "NASMediaLibrary.h"

@interface GridViewController ()

@end

@implementation GridViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.fetcher = [[MediaResourceFetcher alloc] init ];
        [self.fetcher initWithNetworkMode:LOCAL_NETWORK];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    self.gridView.cellHeight = 82;
    self.gridView.cellWidth = 104;
    self.gridView.cellHSpace = 0;
    self.gridView.cellVSpace = 2;
    self.gridView.hMargin = 7;
    self.gridView.vMargin = 12;
    self.gridView.numberOfColumns = 3;
    
    self.stubData = [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:@"pictures"];
    self.gridView.dataSource = self;

    [self.gridView reloadData];
    
    self.longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressed:)];
    self.multiSelectionMode = NO;
    [self.gridView addGestureRecognizer:self.longPressGes];

}

- (void) viewWillAppear:(BOOL)animated
{
    [self.rootController hideButtonBack: YES];
    [self.rootController hideBottomBar: NO];
    [self.navigationController.view setFrame: [self.rootController rectWithBottomBar]];

    [self.view setFrame: [self.rootController rectWithoutBottomBar]];
    [self.gridView setFrame: [self.rootController rectWithBottomBar]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setGridView:nil];
    [super viewDidUnload];
}

- (int) numberOfCellsInView: (ScrollGridView *) gridView;
{
    return self.stubData.count;
}

- (UIView *) viewAtIndex: (int) index
{
    GridCellView *cell = [GridCellView cellViewFromNib];
    //NSString *imgPath = [self.stubData objectAtIndex:index];
    //UIImage *img = [UIImage imageWithContentsOfFile: imgPath];
    UIImage *img = [[UIImage alloc] init];
    MediaItem *item = [self.stubData objectAtIndex:index];
    
    NSString *url = [[item.resouces objectAtIndex:0] uri];
    [self.fetcher getDataFromURL:url completion:^(NSData *data){
        [cell setImage:[UIImage imageWithData:data]];
    }];
    [cell setContentIndex: index];
    [cell setImage: img];
    [cell setDelegate: self];
    //    float w = img.size.width;
    //    float h = img.size.height;
    //    NSLog(@"!!!%f", w/h);
    //
    //
    //    cell.picture.image = [UIImage imageWithContentsOfFile:[self.stubData objectAtIndex:index]];
    
    
    
    return cell;
}

- (void) onLongPressed: (UILongPressGestureRecognizer *) recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.multiSelectionMode = !self.multiSelectionMode;
        if (self.multiSelectionMode == NO) {
            [self.gridView clearAllSelected];
        }
    }
}


-(void) onTap: (UIView *) view
{

    if (self.multiSelectionMode) {
        GridCellView *cell = (GridCellView *)view;
        cell.selected = !cell.selected;
    } else {
        GridCellView *cell = (GridCellView *)view;
        PictureViewerController *browserController = [[PictureViewerController alloc] initWithDelegate:self];
//        PictureViewerController *browserController = [[PictureViewerController alloc] initWithDelegate: self rootController:self.rootController];

//        PictureViewerController *browserController = [[PictureViewerController alloc] init initWithDelegate:self];
//        browserController.displayActionButton = NO;
        browserController.rootController = self.rootController;
        [browserController setInitialPageIndex: cell.contentIndex];

        [self.navigationController pushViewController:browserController animated:YES];
    }
    
}

// ContentProvider
-(id) getContentAtIndex: (int) index
{
    if (index < 0 && index >= self.stubData.count) {
        return nil;
    }
    
    return [self.stubData objectAtIndex: index];
}

// MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return self.stubData.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    MWPhoto *pic = [MWPhoto photoWithFilePath: [self.stubData objectAtIndex: index]];
    return pic;
}

-(void)loadItems:(NSArray *)mediaItems{
    self.stubData = mediaItems;
    [self.gridView reloadData];
}

@end


