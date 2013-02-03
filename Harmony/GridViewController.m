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
        self.topGidView = TRUE;
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
    self.gridView.dataSource = self;
    
    if (self.mediaObjects == nil) {
        ;
        self.mediaObjects = [NASMediaLibrary getCategories:[[NASMediaLibrary getMediaCategories] objectAtIndex:0]];
    }
    
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
    return self.mediaObjects.count;
}

- (UIView *) viewAtIndex: (int) index
{
    GridCellView *cell = [GridCellView cellViewFromNib];

    UIImage *img = [[UIImage alloc] init];
    MediaItem *item = [[self.mediaObjects objectAtIndex:index] getMediaItem];
    
    NSString *url = [item getThumbnailURL] ;
    [self.fetcher getDataFromURL:url completion:^(NSData *data){
        [cell setImage:[UIImage imageWithData:data]];
    }];
    [cell setContentIndex: index];
    [cell setImage: img];
    [cell setDelegate: self];
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
    GridCellView *cell = (GridCellView *)view;
    if (self.multiSelectionMode) {
        cell.selected = !cell.selected;
    } else if(self.topGidView) {
        GridViewController *subGridViewController = [[GridViewController alloc] initWithNibName:@"GridViewController" bundle:nil];
        subGridViewController.topGidView = FALSE;
        MediaCategory *catogery = [self.mediaObjects objectAtIndex:cell.contentIndex];
        subGridViewController.mediaObjects = [NASMediaLibrary getMediaItems:catogery];
        [self.navigationController pushViewController:subGridViewController animated:YES];
    } else {
        PictureViewerController *browserController = [[PictureViewerController alloc] initWithDelegate:self];
        browserController.rootController = self.rootController;
        [browserController setInitialPageIndex: cell.contentIndex];

        [self.navigationController pushViewController:browserController animated:YES];
    }
    
}

// ContentProvider
-(id) getContentAtIndex: (int) index
{
    if (index < 0 && index >= self.mediaObjects.count) {
        return nil;
    }
    
    return [self.mediaObjects objectAtIndex: index];
}

// MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return self.mediaObjects.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    NSString *urlString = [[self.mediaObjects objectAtIndex:index] getResizedURL];
    MWPhoto *pic = [MWPhoto photoWithURL: [NSURL URLWithString:urlString]];
    return pic;
}

-(void)loadItems:(NSArray *)mediaItems{
    self.mediaObjects = mediaItems;
    [self.gridView reloadData];
}

@end


