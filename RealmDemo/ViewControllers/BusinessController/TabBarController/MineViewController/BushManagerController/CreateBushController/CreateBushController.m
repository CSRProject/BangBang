//
//  CreateBushController.m
//  RealmDemo
//
//  Created by lottak_mac2 on 16/7/15.
//  Copyright © 2016年 com.luohaifang. All rights reserved.
//

#import "CreateBushController.h"
#import "CreateBushModel.h"
#import "UserHttp.h"
#import "UserManager.h"
//圈子名称最长多少字符
#define MAX_STARWORDS_LENGTH 20

@interface CreateBushController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate,UITextViewDelegate,UITextFieldDelegate> {
    UserManager *_userManager;//用户管理器
    CreateBushModel *_createBushModel;//创建圈子传给服务器的模;
}

@property (weak, nonatomic) IBOutlet UITableViewCell *nameCell;//圈子名字
@property (weak, nonatomic) IBOutlet UITableViewCell *imageCell;//圈子图标
@property (weak, nonatomic) IBOutlet UITableViewCell *typeCell;//圈子类型
@property (weak, nonatomic) IBOutlet UITableViewCell *detailCell;//圈子详情
@end

@implementation CreateBushController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"创建圈子";
    _userManager = [UserManager manager];
    //初始化 设置模型的默认值
    _createBushModel = [CreateBushModel new];
    _createBushModel.type = 6;
    _createBushModel.typeString = @"其他";
    _createBushModel.hasImage = [UIImage imageNamed:@"default_image_icon"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(rightButtonClicked:)];
    //限制圈子名称的长度
    UITextField *text = [self.nameCell viewWithTag:1000];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textFiledEditChanged:) name:@"UITextFieldTextDidChangeNotification" object:text];
    UITextView *textView = [self.detailCell viewWithTag:1000];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textViewEditChanged:) name:@"UITextViewTextDidChangeNotification" object:textView];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = [UIColor homeListColor];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (void)rightButtonClicked:(UIBarButtonItem*)item {
    [self.navigationController.view showLoadingTips:@""];
    [self.view endEditing:YES];
    UITextField *text = [self.nameCell viewWithTag:1000];
    if([NSString isBlank:text.text]) {
        [self.navigationController.view showMessageTips:@"圈子名称不能为空"];
        return;
    }
    //空格不能输入   ^[a-zA-Z\u4E00-\u9FA5\\d]*$
    //可以输入空格   ^[a-zA-Z\u4E00-\u9FA5\\d\\s]*$
    NSString *pattern = @"^[a-zA-Z\u4E00-\u9FA5\\d]*$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    if(![pred evaluateWithObject:text.text]) {
        [self.navigationController.view showMessageTips:@"圈子名称不能包含特殊字符"];
        return;
    }
    //判断名字是不是包含特殊字符
    _createBushModel.name = text.text;
    [UserHttp createCompany:_createBushModel.name userGuid:_userManager.user.user_guid image:_createBushModel.hasImage companyType:(int)_createBushModel.type handler:^(id data, MError *error) {
        [self.navigationController.view dismissTips];
        if(error) {
            [self.navigationController.view showFailureTips:error.statsMsg];
            return ;
        }
        Company *company = [Company new];
        [company mj_setKeyValues:data[@"data"]];
        //获取创建圈子的所有员工
        //从网络上获取最新的员工数据
        [UserHttp getEmployeeCompnyNo:company.company_no status:5 userGuid:_userManager.user.user_guid handler:^(id data, MError *error) {
            if(error) {
                [self.navigationController.view showFailureTips:error.statsMsg];
                return ;
            }
            NSMutableArray *array = [@[] mutableCopy];
            for (NSDictionary *dic in data[@"list"]) {
                Employee *employee = [Employee new];
                [employee mj_setKeyValues:dic];
                [array addObject:employee];
            }
            //存入本地数据库
            [_userManager updateEmployee:array companyNo:company.company_no];
            [_userManager addCompany:company];
            //#BANG-477 创建圈子成功，判断当前圈子为空则赋值为创建的圈子
            //这里看一下用户当前圈子有没有值，没有就赋这个圈子
            if(_userManager.user.currCompany.company_no == 0) {
                _userManager.user.currCompany = company;
                [_userManager updateUser:_userManager.user];
            }
            [self.navigationController popViewControllerAnimated:YES];
        }];
    }];
}
-(void)textViewEditChanged:(NSNotification *)obj
{
    UITextView *textField = (UITextView *)obj.object;
    NSString *toBeString = textField.text;
    NSString *lang = [textField.textInputMode primaryLanguage];
    if ([lang isEqualToString:@"zh-Hans"]){// 简体中文输入
        //获取高亮部分
        UITextRange *selectedRange = [textField markedTextRange];
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
        if (!position) {
            if (toBeString.length > 200) {
                [self.navigationController.view showMessageTips:@"圈子详情不能大于200个字"];
                textField.text = [toBeString substringToIndex:200];
            }
        }
    } else {// 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
        if (toBeString.length > 200) {
            [self.navigationController.view showMessageTips:@"圈子详情不能大于200个字"];
            NSRange rangeIndex = [toBeString rangeOfComposedCharacterSequenceAtIndex:200];
            if (rangeIndex.length == 1) {
                textField.text = [toBeString substringToIndex:200];
            } else {
                NSRange rangeRange = [toBeString rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, 200)];
                textField.text = [toBeString substringWithRange:rangeRange];
            }
        }
    }
}

#pragma mark --
#pragma mark -- TextFieldDelegate
-(void)textFiledEditChanged:(NSNotification *)obj
{
    UITextField *textField = (UITextField *)obj.object;
    NSString *toBeString = textField.text;
    NSString *lang = [textField.textInputMode primaryLanguage];
    if ([lang isEqualToString:@"zh-Hans"]){// 简体中文输入
        //获取高亮部分
        UITextRange *selectedRange = [textField markedTextRange];
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
        if (!position) {
            if (toBeString.length > MAX_STARWORDS_LENGTH) {
                [self.navigationController.view showMessageTips:@"圈子名称不能大于20个字"];
                textField.text = [toBeString substringToIndex:MAX_STARWORDS_LENGTH];
            }
        }
    } else {// 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
        if (toBeString.length > MAX_STARWORDS_LENGTH) {
            [self.navigationController.view showMessageTips:@"圈子名称不能大于20个字"];
            NSRange rangeIndex = [toBeString rangeOfComposedCharacterSequenceAtIndex:MAX_STARWORDS_LENGTH];
            if (rangeIndex.length == 1) {
                textField.text = [toBeString substringToIndex:MAX_STARWORDS_LENGTH];
            } else {
                NSRange rangeRange = [toBeString rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, MAX_STARWORDS_LENGTH)];
                textField.text = [toBeString substringWithRange:rangeRange];
            }
        }
    }
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _createBushModel.name = textField.text;
}
#pragma mark --
#pragma mark -- TextViewDelegate
- (void)textViewDidEndEditing:(UITextView *)textView
{
    //当输入框失去第一响应者就把输入框的内容赋给模型变量
    _createBushModel.detail = textView.text;
}
- (void)textViewDidChange:(UITextView *)textView
{
    //textview没有占位符 这里我们自己做了一个
    //根据textview的内容判断是不是需要隐藏占位符
    //占位符是一个标签 tag为1001
    if(textView.text.length == 0)
        [[self.detailCell viewWithTag:1001] setHidden:NO];
    else
        [[self.detailCell viewWithTag:1001] setHidden:YES];
}
#pragma mark --
#pragma mark -- TableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.f;
}
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0) {
        if(indexPath.row == 0) {//圈子名字
            UITextField *text = [self.nameCell viewWithTag:1000];
            text.delegate = self;
            text.text = _createBushModel.name;
            return self.nameCell;
        } else if (indexPath.row == 1) {//圈子图标
            UIImageView *image = [self.imageCell viewWithTag:1000];
            if(_createBushModel.hasImage)
                image.image = _createBushModel.hasImage;
            return self.imageCell;
        } else {//圈子类型
            UILabel *label = [self.typeCell viewWithTag:1000];
            label.text = _createBushModel.typeString;
            return self.typeCell;
        }
    }
    UITextView *text = [self.detailCell viewWithTag:1000];
    text.delegate = self;
    if(_createBushModel.detail)//圈子详情
        text.text = _createBushModel.detail;
    return self.detailCell;
}
- (void)tableView:(UITableView *)sender didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //先取消cell的选中效果
    [sender deselectRowAtIndexPath:indexPath animated:YES];
    //使当前页面不能编辑 触发失去第一响应者的回调 给模型赋值
    [self.view endEditing:YES];
    if(indexPath.section == 1)
        return;
    if(indexPath.row == 0)
        return;
    if (indexPath.row == 1) {
        //选择圈子图标
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"上传图标" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cacleAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *selectAction = [UIAlertAction actionWithTitle:@"选取相册图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = YES;
            picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
            [self presentViewController:picker animated:YES completion:nil];
        }];
        UIAlertAction *creamAction = [UIAlertAction actionWithTitle:@"现在拍摄" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = YES;
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {//看当前设备是否能够拍照
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self presentViewController:picker animated:YES completion:nil];
            } else {
                [self.navigationController.view showFailureTips:@"无法打开相机"];
            }
        }];
        [alertVC addAction:cacleAction];
        [alertVC addAction:selectAction];
        [alertVC addAction:creamAction];
        [self presentViewController:alertVC animated:YES completion:nil];
    } else {
        //选择圈子类型
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"圈子类型" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cacleAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *selectAction1 = [UIAlertAction actionWithTitle:@"国有企业" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _createBushModel.type = 1;
            _createBushModel.typeString = @"国有企业";
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *selectAction2 = [UIAlertAction actionWithTitle:@"私有企业" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _createBushModel.type = 2;
            _createBushModel.typeString = @"私有企业";
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *selectAction3 = [UIAlertAction actionWithTitle:@"事业单位或社会团体" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _createBushModel.type = 3;
            _createBushModel.typeString = @"事业单位或社会团体";
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *selectAction4 = [UIAlertAction actionWithTitle:@"中外合资" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _createBushModel.type = 4;
            _createBushModel.typeString = @"中外合资";
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *selectAction5 = [UIAlertAction actionWithTitle:@"外商独资" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _createBushModel.type = 5;
            _createBushModel.typeString = @"外商独资";
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIAlertAction *selectAction6 = [UIAlertAction actionWithTitle:@"其他" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _createBushModel.type = 6;
            _createBushModel.typeString = @"其他";
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }];
        [alertVC addAction:cacleAction];
        [alertVC addAction:selectAction1];
        [alertVC addAction:selectAction2];
        [alertVC addAction:selectAction3];
        [alertVC addAction:selectAction4];
        [alertVC addAction:selectAction5];
        [alertVC addAction:selectAction6];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo {
    _createBushModel.hasImage = image;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
/// 特殊符号
- (NSString *)specialSymbolsAction{
    //数学符号
    NSString *matSym = @" ﹢﹣×÷±/=≌∽≦≧≒﹤﹥≈≡≠=≤≥<>≮≯∷∶∫∮∝∞∧∨∑∏∪∩∈∵∴⊥∥∠⌒⊙√∟⊿㏒㏑%‰⅟½⅓⅕⅙⅛⅔⅖⅚⅜¾⅗⅝⅞⅘≂≃≄≅≆≇≈≉≊≋≌≍≎≏≐≑≒≓≔≕≖≗≘≙≚≛≜≝≞≟≠≡≢≣≤≥≦≧≨≩⊰⊱⋛⋚∫∬∭∮∯∰∱∲∳%℅‰‱øØπ";
    
    //标点符号
    NSString *punSym = @"。，、＇：∶；?‘’“”〝〞ˆˇ﹕︰﹔﹖﹑·¨….¸;！´？！～—ˉ｜‖＂〃｀@﹫¡¿﹏﹋﹌︴々﹟#﹩$﹠&﹪%*﹡﹢﹦﹤‐￣¯―﹨ˆ˜﹍﹎+=<＿_-ˇ~﹉﹊（）〈〉‹›﹛﹜『』〖〗［］《》〔〕{}「」【】︵︷︿︹︽_﹁﹃︻︶︸﹀︺︾ˉ﹂﹄︼❝❞!():,'[]｛｝^・.·．•＃＾＊＋＝＼＜＞＆§⋯`－–／—|\"\\";
    
    //单位符号＊·
    NSString *unitSym = @"°′″＄￥〒￠￡％＠℃℉﹩﹪‰﹫㎡㏕㎜㎝㎞㏎m³㎎㎏㏄º○¤%$º¹²³";
    
    //货币符号
    NSString *curSym = @"₽€£Ұ₴$₰¢₤¥₳₲₪₵元₣₱฿¤₡₮₭₩ރ円₢₥₫₦zł﷼₠₧₯₨Kčर₹ƒ₸￠";
    
    //制表符
    NSString *tabSym = @"─ ━│┃╌╍╎╏┄ ┅┆┇┈ ┉┊┋┌┍┎┏┐┑┒┓└ ┕┖┗ ┘┙┚┛├┝┞┟┠┡┢┣ ┤┥┦┧┨┩┪┫┬ ┭ ┮ ┯ ┰ ┱ ┲ ┳ ┴ ┵ ┶ ┷ ┸ ┹ ┺ ┻┼ ┽ ┾ ┿ ╀ ╁ ╂ ╃ ╄ ╅ ╆ ╇ ╈ ╉ ╊ ╋ ╪ ╫ ╬═║╒╓╔ ╕╖╗╘╙╚ ╛╜╝╞╟╠ ╡╢╣╤ ╥ ╦ ╧ ╨ ╩ ╳╔ ╗╝╚ ╬ ═ ╓ ╩ ┠ ┨┯ ┷┏ ┓┗ ┛┳ ⊥ ﹃ ﹄┌ ╮ ╭ ╯╰";
    
    return [NSString stringWithFormat:@"%@%@%@%@%@",matSym,punSym,unitSym,curSym,tabSym];
}

@end
