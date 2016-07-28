//
//  CreateMeetingController.m
//  RealmDemo
//
//  Created by lottak_mac2 on 16/7/28.
//  Copyright © 2016年 com.luohaifang. All rights reserved.
//

#import "CreateMeetingController.h"
#import "MeetingEquipmentsModel.h"
#import "MeetingRoomModel.h"
#import "Meeting.h"
#import "Employee.h"
#import "UserHttp.h"
#import "MeetingAgenda.h"

#import "MeetingName.h"
#import "MeetingDevice.h"
#import "MeetingMembersCell.h"
#import "MeetingAttendanceCell.h"
#import "MeetingAgendaTitle.h"
#import "MeetingAgendaCell.h"

#import "SingleSelectController.h"
#import "MuliteSelectController.h"

@interface CreateMeetingController ()<UITableViewDelegate,UITableViewDataSource,MeetingDeviceDelegate,MeetingAgendaDelegate> {
    UITableView *_tableView;//表格视图
    Meeting *_meeting;//会议模型
    MeetingRoomModel *_meetingRoomModel;//会议室模型
    NSMutableArray<MeetingEquipmentsModel*> *_meetingEquipmentsArr;//会议设备数组
    Employee *_incharge;//主持人
    NSMutableArray<MeetingAgenda*> *_meetingAgendaArr;//议程数组
    NSMutableArray<Employee*> *_membersArr;//参与人数组
    NSMutableArray<Employee*> *_attendanceArr;//列席人数组
}

@end

@implementation CreateMeetingController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"新建会议";
    _meeting = [Meeting new];
    _meetingRoomModel = [MeetingRoomModel new];
    _meetingEquipmentsArr = [@[] mutableCopy];
    _incharge = [Employee new];
    _meetingAgendaArr = [@[] mutableCopy];
    _membersArr = [@[] mutableCopy];
    _attendanceArr = [@[] mutableCopy];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCREEN_WIDTH, MAIN_SCREEN_HEIGHT - 64) style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _tableView.tableFooterView = [UIView new];
    [_tableView registerNib:[UINib nibWithNibName:@"MeetingName" bundle:nil] forCellReuseIdentifier:@"MeetingName"];
    [_tableView registerNib:[UINib nibWithNibName:@"MeetingDevice" bundle:nil] forCellReuseIdentifier:@"MeetingDevice"];
    [_tableView registerNib:[UINib nibWithNibName:@"MeetingMembersCell" bundle:nil] forCellReuseIdentifier:@"MeetingMembersCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"MeetingAttendanceCell" bundle:nil] forCellReuseIdentifier:@"MeetingAttendanceCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"MeetingAgendaTitle" bundle:nil] forCellReuseIdentifier:@"MeetingAgendaTitle"];
     [_tableView registerNib:[UINib nibWithNibName:@"MeetingAgendaCell" bundle:nil] forCellReuseIdentifier:@"MeetingAgendaCell"];
    [self.view addSubview:_tableView];
    // Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

#pragma mark -- 
#pragma mark -- UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 2) {
        if(indexPath.row == 1) {
            if(_membersArr.count != 0)
                return [self employeeArrHeight:_membersArr];
        } else if(indexPath.row == 2) {
            if(_attendanceArr.count != 0)
                return [self employeeArrHeight:_attendanceArr];
        }
    }
    return 60.f;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0)
        return 1;
    if(section == 1) {
        if(_meeting.room_id == 0)
            return 1;
        return 3;
    }
    if(section == 2)
        return 3;
    if(section == 3)
        return _meetingAgendaArr.count + 1;
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 15.f;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if(indexPath.section == 0) {//会议主题
        cell = [tableView dequeueReusableCellWithIdentifier:@"MeetingName" forIndexPath:indexPath];
    } else if (indexPath.section == 1) {
        if(indexPath.row == 0) {//普通cell
            cell = [tableView dequeueReusableCellWithIdentifier:@"PailCell"];
            if(!cell)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"PailCell"];
        } else if(indexPath.row == 1) {//普通cell
            cell = [tableView dequeueReusableCellWithIdentifier:@"PailCell"];
            if(!cell)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"PailCell"];
        } else {//会议设备cell
            cell = [tableView dequeueReusableCellWithIdentifier:@"MeetingDevice" forIndexPath:indexPath];
        }
    } else if (indexPath.section == 2) {
        if(indexPath.row == 0) {//普通cell
            cell = [tableView dequeueReusableCellWithIdentifier:@"PailCell"];
            if(!cell)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"PailCell"];
        } else if (indexPath.row == 1) {//参与人cell
            cell = [tableView dequeueReusableCellWithIdentifier:@"MeetingMembersCell" forIndexPath:indexPath];
        } else {//列席人cell
            cell = [tableView dequeueReusableCellWithIdentifier:@"MeetingAttendanceCell" forIndexPath:indexPath];
        }
    } else if (indexPath.section == 3) {
        if(indexPath.row == 0) {//议程加cell
            cell = [tableView dequeueReusableCellWithIdentifier:@"MeetingAgendaTitle" forIndexPath:indexPath];
        } else {//议程cell
            cell = [tableView dequeueReusableCellWithIdentifier:@"MeetingAgendaCell" forIndexPath:indexPath];
        }
    } else {//普通cell
        cell = [tableView dequeueReusableCellWithIdentifier:@"PailCell"];
        if(!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"PailCell"];
    }
    
    
    if(indexPath.section == 0) {//会议主题
        cell.data = _meeting;
    } else if (indexPath.section == 1) {
        if(indexPath.row == 0) {//会议室
            cell.textLabel.text = @"会议室";
            cell.detailTextLabel.text = _meetingRoomModel.room_name ?: @"请选择 （必填）";
        } else if (indexPath.row == 1) {//会议时间
            cell.textLabel.text = @"会议时间";
            NSDate *begin = [NSDate dateWithTimeIntervalSince1970:_meeting.begin / 1000];
            NSDate *end = [NSDate dateWithTimeIntervalSince1970:_meeting.end / 1000];
            NSString *timeStr = [NSString stringWithFormat:@"%ld/%02ld/%02ld %02ld:%02ld-%02ld:%02ld",begin.year,begin.month,begin.day,begin.hour,begin.minute,end.hour,end.minute];
            cell.detailTextLabel.text = timeStr;
        } else {//设备
            MeetingDevice *device = (id)cell;
            device.data = _meeting;
            device.delegate = self;
        }
    } else if (indexPath.section == 2) {
        if(indexPath.row == 0) {//主持人
            cell.textLabel.text = @"主持人";
            cell.detailTextLabel.text = _incharge.real_name ?: @"请选择（必填）";
        } else if (indexPath.row == 1) {//参与人
            MeetingMembersCell *member = (id)cell;
            member.data = _membersArr;
        } else {//列席人
            MeetingAttendanceCell *attendance = (id)cell;
            attendance.data = _attendanceArr;
        }
    } else if (indexPath.section == 3) {
        if(indexPath.row == 0) {//议程
            
        } else {//议程内容
            MeetingAgendaCell *agenda = (id)cell;
            agenda.data = _meetingAgendaArr[indexPath.row - 1];
            agenda.delegate = self;
        }
    } else {//提醒时间
        cell.textLabel.text = @"提醒时间";
        if(_meeting.before) {
            if(_meeting.before < 60)
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d分钟前",_meeting.before];
            else
                 cell.detailTextLabel.text = [NSString stringWithFormat:@"%d小时前",_meeting.before / 60];
        }
        else
            cell.detailTextLabel.text = @"从不";
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 0) {
        
    } else if (indexPath.section == 1) {
        if(indexPath.row == 0) {//选择会议室
            
        }
    } else if (indexPath.section == 2) {
        if(indexPath.row == 0) {//选择主持人
            SingleSelectController *single = [SingleSelectController new];
            NSMutableArray *array = [@[] mutableCopy];
            [array addObjectsFromArray:_membersArr];
            [array addObjectsFromArray:_attendanceArr];
            single.outEmployees = array;
            single.singleSelect = ^(Employee *employee) {
                _incharge = employee;
                [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            };
            [self.navigationController pushViewController:single animated:YES];
        } else if (indexPath.row == 1) {//选择参与人
            MuliteSelectController *mulite = [MuliteSelectController new];
            NSMutableArray *array = [@[] mutableCopy];
            if(_incharge.id)
                [array addObject:_incharge];
            [array addObjectsFromArray:_attendanceArr];
            mulite.outEmployees = array;
            mulite.selectedEmployees = _membersArr;
            mulite.muliteSelect = ^(NSMutableArray *array) {
                _membersArr = array;
                [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            };
            [self.navigationController pushViewController:mulite animated:YES];
        } else {//选择列席人
            MuliteSelectController *mulite = [MuliteSelectController new];
            NSMutableArray *array = [@[] mutableCopy];
            if(_incharge.id)
                [array addObject:_incharge];
            [array addObjectsFromArray:_membersArr];
            mulite.outEmployees = array;
            mulite.selectedEmployees = _attendanceArr;
            mulite.muliteSelect = ^(NSMutableArray *array) {
                _attendanceArr = array;
                [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            };
            [self.navigationController pushViewController:mulite animated:YES];
        }
    } else if (indexPath.section == 3) {
        if(indexPath.row == 0) {//增加议程
            MeetingAgenda *meet = [MeetingAgenda new];
            meet.index = (int)_meetingAgendaArr.count;
            [_meetingAgendaArr addObject:meet];
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationNone];
        }
    } else {//选择提醒时间
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提醒时间" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *ok0 = [UIAlertAction actionWithTitle:@"从不" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _meeting.before = 0;
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *ok5 = [UIAlertAction actionWithTitle:@"5分钟前" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _meeting.before = 5;
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *ok10 = [UIAlertAction actionWithTitle:@"10分钟前" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _meeting.before = 10;
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *ok20 = [UIAlertAction actionWithTitle:@"20分钟前" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _meeting.before = 20;
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *ok30 = [UIAlertAction actionWithTitle:@"30分钟前" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _meeting.before = 30;
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *ok60 = [UIAlertAction actionWithTitle:@"1小时前" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _meeting.before = 60;
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *ok120 = [UIAlertAction actionWithTitle:@"2小时前" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _meeting.before = 120;
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *ok360 = [UIAlertAction actionWithTitle:@"6小时前" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _meeting.before = 360;
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *ok720 = [UIAlertAction actionWithTitle:@"12小时前" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _meeting.before = 720;
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
        }];
        [alertVC addAction:cancle];
        [alertVC addAction:ok0];
        [alertVC addAction:ok5];
        [alertVC addAction:ok10];
        [alertVC addAction:ok20];
        [alertVC addAction:ok30];
        [alertVC addAction:ok60];
        [alertVC addAction:ok120];
        [alertVC addAction:ok360];
        [alertVC addAction:ok720];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}
#pragma mark -- MeetingDeviceDelegate
//更多按钮被点击
- (void)MeetingDeviceMore {
    
}
#pragma mark -- MeetingAgendaDelegate
//议程删除按钮被点击
- (void)MeetingAgendaDelete:(MeetingAgenda*)meetingAgenda {
    [_meetingAgendaArr removeObjectAtIndex:meetingAgenda.index];
    for (int index = 0; index < _meetingAgendaArr.count; index ++) {
        MeetingAgenda *meetingAgenda = _meetingAgendaArr[index];
        meetingAgenda.index = index;
    }
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationNone];
}
//求员工数组的高度
- (CGFloat)employeeArrHeight:(NSMutableArray<Employee*>*)membersArr {
    //上下行/左右项的间距
    CGFloat space = 5;
    //项的高度
    CGFloat itemHeight = 30;
    //项的坐标
    CGFloat currPointX = 0;
    CGFloat currPointY = 0;
    //最大宽度width - 108
    CGFloat memberWidth = MAIN_SCREEN_WIDTH - 108;
    for (Employee *employee in membersArr) {
        CGFloat currWidth = [employee.real_name textSizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(100, itemHeight)].width + 10;
        if(currWidth + currPointX > memberWidth) {//如果超过了展示视图的宽度
            currPointX = 0;
            currPointY += itemHeight + space;
        }
        currPointX += currWidth + space;
    }
    return currPointY + itemHeight + 30;
}

@end
