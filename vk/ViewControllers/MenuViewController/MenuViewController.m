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
    LentaRow,
    NewsRow,
    DialogsRow,
    FriendsRow,
    PhotosRow,
    AnswersRow,
    GroupsRow,
    BookmarksRow,
    VideosRow,
    DocumentsRow,
    SettingsRow,
    RowsCount
};

static CGFloat const kRowHeight = 40.f;
static CGFloat const kHeaderViewHeight = 20.f;
static CGFloat const kSeparatorAlpha = 0.25f;

@interface MenuViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation MenuViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.separatorColor = [[UIColor whiteColor] colorWithAlphaComponent:kSeparatorAlpha];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidHide:) name:LGSideMenuDidHideLeftViewNotification object:nil];
    [self.tableView registerNib:[UINib nibWithNibName:@"SimpleCell" bundle:nil] forCellReuseIdentifier:@"SimpleCell"];
}

- (void)viewWillAppear:(BOOL)animated {
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
        case LentaRow: cell.textLabel.text = L(@"lenta"); break;
        case NewsRow: cell.textLabel.text = L(@"news"); break;
        case DialogsRow: cell.textLabel.text = L(@"dialogs"); break;
        case FriendsRow: cell.textLabel.text = L(@"friends"); break;
        case PhotosRow: cell.textLabel.text = L(@"photos"); break;
        case AnswersRow: cell.textLabel.text = L(@"answers"); break;
        case GroupsRow: cell.textLabel.text = L(@"groups"); break;
        case BookmarksRow: cell.textLabel.text = L(@"bookmarks"); break;
        case VideosRow: cell.textLabel.text = L(@"videos"); break;
        case DocumentsRow: cell.textLabel.text = L(@"documents"); break;
        case SettingsRow: cell.textLabel.text = L(@"settings"); break;
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
        case LentaRow: {
            [_viewModel lentaTapped];
            break;
        }
        case NewsRow: {
            [_viewModel newsTapped];
            break;
        }
        case DialogsRow: {
            [_viewModel dialogsTapped];
            break;
        }
        case FriendsRow: {
            [_viewModel friendsTapped];
            break;
        }
        case PhotosRow: {
            [_viewModel photosTapped];
            break;
        }
        case AnswersRow: {
            [_viewModel answersTapped];
            break;
        }
        case GroupsRow: {
            [_viewModel groupsTapped];
            break;
        }
        case BookmarksRow: {
            [_viewModel bookmarksTapped];
            break;
        }
        case VideosRow: {
            [_viewModel videosTapped];
            break;
        }
        case DocumentsRow: {
            [_viewModel documentsTapped];
            break;
        }
        case SettingsRow: {
            [_viewModel settingsTapped];
            break;
        }
    }
}

#pragma mark - Observers
- (void)menuDidHide:(id)sender {
    [self.tableView reloadData];
    self.tableView.contentOffset = CGPointZero;
}

@end
