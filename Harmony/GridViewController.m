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


@interface GridViewController ()
- (BOOL)canBeInEditingMode;
- (void) applyBlockForSelectedItems:(void(^)(MediaItem *))block;
@end

@implementation GridViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.fetcher = [[MediaResourceFetcher alloc] init ];
        [self.fetcher initWithNetworkMode:[NASMediaLibrary isRemoteAccess] ? REMOTE_NETWORK : LOCAL_NETWORK];
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
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.rootController hideButtonBack: self.currentCategory.parentCategory == nil];
    [self.rootController hideBottomBar: NO];
    [self.rootController hideCategoryDroplist:NO];
    [MainController setTopBarTitle:@""];

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
    NSLog(@"objects coutn:%d", self.mediaObjects.count);
    return self.mediaObjects.count;
}

- (UIView *) viewAtIndex: (int) index
{
    GridCellView *cell = [GridCellView cellViewFromNib];

    MediaObject *object = [self.mediaObjects objectAtIndex:index];
    NSString *url = [object getThumbnailURL] ;
    [self.fetcher getDataFromURL:url completion:^(NSData *data){
        [cell setImage:[UIImage imageWithData:data]];
    }];
    [cell setContentIndex: index];
    if([object isKindOfClass:[MediaCategory class]]){
        cell.titleLable.hidden = NO;
        cell.titleLable.text = object.title;
    }
    
    if ([object.id rangeOfString:@"*"].location != NSNotFound) {
        [cell tagFavor];
    }else {
        [cell untagFavor];
    }
    [cell setDelegate: self];
    return cell;
}

- (BOOL) canMediaObjectsBeSelected{
    if ([_mediaObjects count] > 0) {
        return [[_mediaObjects objectAtIndex:0] isKindOfClass:[MediaItem class]];
    }
    return FALSE;
}

-(void) onTap: (UIView *) view
{
    GridCellView *cell = (GridCellView *)view;
    if (self.rootController.editingMode) {
        cell.selected = !cell.selected;
    } else {
        MediaObject *object = [self.mediaObjects objectAtIndex:cell.contentIndex];
        if([object isKindOfClass:[MediaCategory class]]) {
            self.currentCategory = (MediaCategory *)object;
            self.mediaObjects = [NASMediaLibrary getMediaObjects:self.currentCategory];
            [self.gridView reloadData];
            [[self rootController] hideButtonBack: FALSE];
            [self.rootController enableButtonEditing:[self canBeInEditingMode]];
        } else {
            PictureViewerController *browserController = [[PictureViewerController alloc] initWithDelegate:self];
            browserController.rootController = self.rootController;
            [browserController setInitialPageIndex: cell.contentIndex];
            [self.rootController enableImageBrowserEditing:YES];

            [self.navigationController pushViewController:browserController animated:YES];
        }
        
    }
    
}

// ContentProvider
-(id) getContentAtIndex: (int) index
{
    if (index < 0 && index >= self.mediaObjects.count) {
        return nil;
    }
    NSLog(@"getContentAtIndex%d", index);
    
    return [self.mediaObjects objectAtIndex: index];
}

- (BOOL)canBeInEditingMode{
    return [_mediaObjects count] > 0 && [[_mediaObjects objectAtIndex:0] isKindOfClass:[MediaItem class]];
}
- (void)backToParentCatogery{
    self.currentCategory = self.currentCategory.parentCategory;
    if (self.currentCategory == nil) {
        NSLog(@"GridViewController:Eorr on back to parent catogery.");
        if(_rootController.mediaCategories.count > 0){
            _rootController.categoryIndex = -1;
            [_rootController hideButtonBack:YES];
            [_rootController setCategoryIndex:0];
        }
        return;
    }
    [self.rootController hideButtonBack:self.currentCategory.parentCategory == nil];
    self.mediaObjects = [NASMediaLibrary getMediaObjects:self.currentCategory];
    [self.rootController enableButtonEditing:[self canBeInEditingMode]];
    [self.gridView reloadData];
}

- (void) gotoTopCatogery:(MediaCategory *)category{
    [self.rootController hideButtonBack:TRUE];
    self.currentCategory = category;
    self.mediaObjects = [NASMediaLibrary getMediaObjects:category];
    [self.rootController enableButtonEditing:[self canBeInEditingMode]];
    [self.gridView reloadData];
}

- (void) applyBlockForSelectedItems:(void(^)(MediaItem *))block {
    if(self.rootController.imageBrowserEditingMode){
        PictureViewerController *pictureViewerController = (PictureViewerController *)self.navigationController.topViewController;
        block([self.mediaObjects objectAtIndex:[pictureViewerController getCurrentPageIndex]]);
        return;
    }
    for(GridCellView *cell in self.gridView.cells){
        if(cell.selected) {
            MediaObject *object = [self.mediaObjects objectAtIndex:cell.contentIndex];
            if([object isKindOfClass:[MediaItem class]]) {
                block((MediaItem*)object);
            }
        }
    }
}

- (void) clearSelections{
    [self.gridView clearAllSelected];
}

- (void) downloadSelectedItems{
    [self applyBlockForSelectedItems:^(MediaItem *item){
        [self.fetcher downloadURL:[item getMediaURL]];
    }];
    [self clearSelections];
}

- (void)tagFavorSelectedItems{

    NSMutableArray *favors = [[NSMutableArray alloc] init];
    NSMutableArray *unFavors = [[NSMutableArray alloc] init];
    
    [self applyBlockForSelectedItems:^(MediaItem *item){
        NSString *title = [[self.fetcher getFileNameFromURL:[item getThumbnailURL]] stringByDeletingPathExtension];
        BOOL favored = [item.id rangeOfString:@"*"].location != NSNotFound;
        if(favored) {
            [unFavors addObject:title];
        } else {
            [favors addObject:title];
        }
        if(self.rootController.imageBrowserEditingMode){
            self.rootController.favorImage.hidden = favored;
        }
    }];
    [NASMediaLibrary tagFavoriteObjects:favors];
    [NASMediaLibrary untagFavoriteObjects:unFavors];
    self.mediaObjects = [NASMediaLibrary getMediaObjects:self.currentCategory];
    [self.gridView reloadData];
    [self clearSelections];
}

- (void)commitPrintSelectedItems{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [self applyBlockForSelectedItems:^(MediaItem *item){
        [array addObject:[self.fetcher getFileNameFromURL:[item getThumbnailURL]]];
    }];
    [NASMediaLibrary commitPrinttaskForFiles:array];
    [self clearSelections];

}

- (void)shareAlbumSelectedItems{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [self applyBlockForSelectedItems:^(MediaItem *item) {
        NSString *file =[ self.fetcher getFileNameFromURL:[item getMediaURL]];
        [array addObject:file];
    }];
    [NASMediaLibrary shareAlbumWithFiles:array];
    [self clearSelections];
}

// MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return self.mediaObjects.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    MediaObject *object = [self.mediaObjects objectAtIndex:index];
    NSString *urlString = [object getResizedURL];
    if(urlString == nil) {
        urlString = [object getMediaURL];
    }
    MWPhoto *pic = [MWPhoto photoWithURL: [NSURL URLWithString:urlString]];
    return pic;
}

- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index{
    MediaItem *item = [self.mediaObjects objectAtIndex:index];
    BOOL favored = [item.id rangeOfString:@"*"].location != NSNotFound;
    self.rootController.favorImage.hidden = !favored;
    return nil;
}

@end


