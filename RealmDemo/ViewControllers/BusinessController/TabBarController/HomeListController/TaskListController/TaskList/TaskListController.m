//
//  TaskListController.m
//  RealmDemo
//
//  Created by lottak_mac2 on 16/8/1.
//  Copyright © 2016年 com.luohaifang. All rights reserved.
//

#import "TaskListController.h"
#import "UserManager.h"
#import "UserHttp.h"
#import "InchargeTaskView.h"
#import "CreateTaskView.h"
#import "MemberTaskView.h"
#import "FinishTaskView.h"
#import "TaskCreateController.h"
#import "TaskDetailController.h"

@interface TaskListController ()<UIScrollViewDelegate,TaskClickedDelegate,RBQFetchedResultsControllerDelegate> {
    UserManager *_userManager;
    UISegmentedControl *_topSegmentedControl;//上面的分段控件
    UIScrollView *_bottomScrollView;//下面的滚动视图
    UIButton *_addTaskBtn;//添加任务按钮
    RBQFetchedResultsController *_taskFetchedResultsController;//当前用户任务数据监听
    RBQFetchedResultsController *_taskDraftFetchedResultsController;//当前用户任务数据监听
    
    InchargeTaskView *_incharge;//负责
    CreateTaskView *_create;//委派
    MemberTaskView *_member;//知悉
    FinishTaskView *_finish;//完结
    
    BOOL isFirstLoad;
}

@end

@implementation TaskListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"任务列表";
    _userManager = [UserManager manager];
    _taskFetchedResultsController = [_userManager createTaskFetchedResultsController:_userManager.user.currCompany.company_no];
    _taskFetchedResultsController.delegate = self;
    _taskDraftFetchedResultsController = [_userManager createTaskDraftFetchedResultsController];
    _taskDraftFetchedResultsController.delegate = self;
    self.view.backgroundColor = [UIColor whiteColor];
    
    _topSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"委派的",@"负责的",@"知悉的",@"已完结"]];
    _topSegmentedControl.frame = CGRectMake(10, 5, MAIN_SCREEN_WIDTH - 20, 30);
    _topSegmentedControl.tintColor = [UIColor siginColor];
    [_topSegmentedControl addTarget:self action:@selector(segmentedClicked:) forControlEvents:UIControlEventValueChanged];
    _topSegmentedControl.backgroundColor = [UIColor whiteColor];
    UIView *bagView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCREEN_WIDTH, 40)];
    bagView.backgroundColor = [UIColor colorWithRed:247 / 255.f green:247 / 255.f blue:247 / 255.f alpha:1];
    [self.view addSubview:bagView];
    [self.view addSubview:_topSegmentedControl];
    
    _bottomScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, MAIN_SCREEN_WIDTH, MAIN_SCREEN_HEIGHT - 64 - 40)];
    _bottomScrollView.delegate = self;
    _bottomScrollView.showsVerticalScrollIndicator = NO;
    _bottomScrollView.showsHorizontalScrollIndicator = NO;
    _bottomScrollView.bounces = NO;
    _bottomScrollView.pagingEnabled = YES;
    _bottomScrollView.scrollEnabled = NO;
    _bottomScrollView.contentSize = CGSizeMake(4 * _bottomScrollView.frame.size.width, _bottomScrollView.frame.size.height);
    [self.view addSubview:_bottomScrollView];
    //委派的
    _create = [[CreateTaskView alloc] initWithFrame:CGRectMake(0, 0, _bottomScrollView.frame.size.width, _bottomScrollView.frame.size.height)];
    _create.delegate = self;
    [_bottomScrollView addSubview:_create];
    //负责的
    _incharge = [[InchargeTaskView alloc] initWithFrame:CGRectMake(_bottomScrollView.frame.size.width, 0, _bottomScrollView.frame.size.width, _bottomScrollView.frame.size.height)];
    _incharge.delegate = self;
    [_bottomScrollView addSubview:_incharge];
    //知悉的
    _member = [[MemberTaskView alloc] initWithFrame:CGRectMake(2 * _bottomScrollView.frame.size.width, 0, _bottomScrollView.frame.size.width, _bottomScrollView.frame.size.height)];
    _member.delegate = self;
    [_bottomScrollView addSubview:_member];
    //完结的
    _finish = [[FinishTaskView alloc] initWithFrame:CGRectMake(3 * _bottomScrollView.frame.size.width, 0, _bottomScrollView.frame.size.width, _bottomScrollView.frame.size.height)];
    _finish.delegate = self;
    [_bottomScrollView addSubview:_finish];
    //显示第几个
    if(self.type == 0)//我委派的
    _topSegmentedControl.selectedSegmentIndex = 0;
    else//我负责的
    _topSegmentedControl.selectedSegmentIndex = 1;
    [self segmentedClicked:_topSegmentedControl];
    _addTaskBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_addTaskBtn addTarget:self action:@selector(addTaskClicked:)
          forControlEvents:UIControlEventTouchUpInside];
    _addTaskBtn.frame = CGRectMake(0, 0, 40, 40);
    [_addTaskBtn setImage:[UIImage imageNamed:@"right_barbtn_icon"] forState:UIControlStateNormal];
    if([_userManager getTaskDraftArr:_userManager.user.currCompany.company_no].count != 0)
        [_addTaskBtn addHotView:HOTVIEW_ALIGNMENT_TOP_RIGHT];
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadTaskClicked:)],[[UIBarButtonItem alloc] initWithCustomView:_addTaskBtn]];
    // Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = [UIColor siginColor];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //是不是第一次加载这个页面
    if(isFirstLoad) return;
    isFirstLoad = YES;
    
    [self getCurrData];
    if(![[_userManager getTaskArr:_userManager.user.currCompany.company_no] count])
        [self tongBuTask];
}
- (void)addTaskClicked:(UIButton*)item {
    //添加任务
    TaskCreateController *create = [TaskCreateController new];
    [self.navigationController pushViewController:create animated:YES];
}
- (void)loadTaskClicked:(UIBarButtonItem*)item {
    [self tongBuTask];
}
#pragma mark -- RBQFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(nonnull RBQFetchedResultsController *)controller {
    if(controller == _taskDraftFetchedResultsController) {
        if([_userManager getTaskDraftArr:_userManager.user.currCompany.company_no].count != 0) {
            [_addTaskBtn addHotView:HOTVIEW_ALIGNMENT_TOP_RIGHT];
        } else {
            [_addTaskBtn removeHotView];
        }
    } else {
        [self getCurrData];
    }
}
//获得各个页面对应的数据
- (void)getCurrData {
    @synchronized (self) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSMutableArray *inchargeArr = [@[] mutableCopy];
            NSMutableArray *createArr = [@[] mutableCopy];
            NSMutableArray *memberArr = [@[] mutableCopy];
            NSMutableArray *finishArr = [@[] mutableCopy];
        NSArray *allTaskArr = [_userManager getTaskArr:_userManager.user.currCompany.company_no];
        Employee *employee = [_userManager getEmployeeWithGuid:_userManager.user.user_guid companyNo:_userManager.user.currCompany.company_no];
        for (TaskModel *model in allTaskArr) {
            if(model.company_no != _userManager.user.currCompany.company_no) continue;
            if(model.status == 0) continue;
            //得到已终止的任务
            if(model.status == 7 || model.status == 8) {
                [finishArr addObject:model];
                continue;
            }
            //得到委派的任务
            if([model.createdby isEqualToString:employee.employee_guid]) {
                [createArr addObject:model];
            }
            //得到负责的任务
            if([model.incharge isEqualToString:employee.employee_guid]) {
                [inchargeArr addObject:model];
            }
            //得到我知悉的任务
            if([model.members rangeOfString:employee.employee_guid].location != NSNotFound) {
                [memberArr addObject:model];
            }
        }
        _finish.data = finishArr;
        _create.data = createArr;
        _incharge.data = inchargeArr;
        _member.data = memberArr; 
    });
    }
}
//同步任务
- (void)tongBuTask {
    if(_userManager.user.currCompany.company_no == 0)
        return;
    [self.navigationController.view showLoadingTips:@""];
    Employee *employee = [_userManager getEmployeeWithGuid:_userManager.user.user_guid companyNo:_userManager.user.currCompany.company_no];
    [UserHttp getTaskList:employee.employee_guid handler:^(id data, MError *error) {
        [self.navigationController.view dismissTips];
        if(error) {
            [self.navigationController.view showFailureTips:error.statsMsg];
            return ;
        }
        NSMutableArray<TaskModel*> *array = [@[] mutableCopy];
        for (NSDictionary *dic in data[@"list"]) {
            TaskModel *model = [TaskModel new];
            [model mj_setKeyValues:dic];
            model.descriptionStr = dic[@"description"];
            [array addObject:model];
        }
        [_userManager updateTask:array companyNo:_userManager.user.currCompany.company_no];
    }];
}
#pragma mark -- TaskClickedDelegate
- (void)taskClicked:(TaskModel *)taskModel {
    //查看任务详情
    TaskDetailController *detail = [TaskDetailController new];
    detail.data = taskModel;
    [self.navigationController pushViewController:detail animated:YES];
}
- (void)segmentedClicked:(UISegmentedControl*)control {
    [_bottomScrollView setContentOffset:CGPointMake(control.selectedSegmentIndex * _bottomScrollView.frame.size.width, 0) animated:NO];
    [self.view endEditing:YES];
}
#pragma mark -- UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int index = (scrollView.contentOffset.x + scrollView.frame.size.width / 2.f) / scrollView.frame.size.width;
    [_topSegmentedControl setSelectedSegmentIndex:index];
    [self.view endEditing:YES];
}
@end
