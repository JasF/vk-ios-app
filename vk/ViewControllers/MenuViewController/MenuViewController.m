//
//  MenuViewController.m
//  Horoscopes
//
//  Created by Jasf on 05.11.2017.
//  Copyright © 2017 Mail.Ru. All rights reserved.
//

#import "LGSideMenuController.h"
#import "MenuViewController.h"
#import "vk-Swift.h"

typedef NS_ENUM(NSInteger, MenuRows) {
    NewsRow,
    DialogsRow,
    RowsCount
};

static CGFloat const kRowHeight = 40.f;
static CGFloat const kHeaderViewHeight = 20.f;
static CGFloat const kSeparatorAlpha = 0.25f;

@interface MenuViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) id<MenuHandlerProtocol> handler;
@end

@implementation MenuViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    // AV: Because MenuViewController initializes inside LGMenuViewController third-party component.
    // AV: Typhoon storyboard initialization possible
    [super viewDidLoad];
    self.tableView.separatorColor = [[UIColor whiteColor] colorWithAlphaComponent:kSeparatorAlpha];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidHide:) name:LGSideMenuDidHideLeftViewNotification object:nil];
    [self.tableView registerNib:[UINib nibWithNibName:@"SimpleCell" bundle:nil] forCellReuseIdentifier:@"SimpleCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    if (!self.handler) {
        NSCParameterAssert(_pythonBridge);
        self.handler = [self.pythonBridge handlerWithProtocol:@protocol(MenuHandlerProtocol)];
    }
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGRect frame = self.view.bounds;
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    frame.size.width = [UIScreen mainScreen].bounds.size.width;
    frame.size.height += statusBarHeight;
    frame.origin.y -= statusBarHeight;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return RowsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SimpleCell"];
    cell.textLabel.textColor = [UIColor whiteColor];
    switch (indexPath.row) {
        case NewsRow: cell.textLabel.text = L(@"lenta"); break;
        case DialogsRow: cell.textLabel.text = L(@"dialogs"); break;
    }
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kHeaderViewHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kRowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case NewsRow: {
            dispatch_python(^{
                [_handler newsTapped];
            });
            break;
        }
        case DialogsRow: {
            dispatch_python(^{
                [_handler dialogsTapped];
            });
            break;
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

#pragma mark - Observers
- (void)menuDidHide:(id)sender {
    [self.tableView reloadData];
    self.tableView.contentOffset = CGPointZero;
}

@end
