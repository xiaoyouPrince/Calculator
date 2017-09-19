//
//  ViewController.m
//  Calculator
//
//  Created by 渠晓友 on 2017/9/15.
//  Copyright © 2017年 XiaoYou. All rights reserved.
//

#import "ViewController.h"
#import "XYKeyButton.h"


#define ScreenW [UIScreen mainScreen].bounds.size.width
#define ScreenH [UIScreen mainScreen].bounds.size.height
#define keyWH ScreenW/4

typedef NS_ENUM( NSInteger , RightSymbolType ) {
    RightSymbolTypePlus,        // default is +
    RightSymbolTypeMinus,       // -
    RightSymbolTypeMaulty,      // X
    RightSymbolTypeDivide,      // /
    RightSymbolTypeCalcultor    // = 这里是计算
};

static BOOL isCheatMode = NO;   ///< 记录是否为作弊状态
static BOOL isHavePoint = NO;   ///< 记录是否包含小数点
static BOOL isHaveMinus = NO;   ///< 记录是否为负数
static BOOL isHaveRightSymbol = NO;   ///< 记录是否输入右边计算符，有就停止保存oldNum,开始保存newNum
static BOOL isHaveRightSymbolFirst = NO;   ///< 开始保存newNum时候是不是第一次
static BOOL isHaveCalculateSymbolClicked = NO;   ///< 保存 = 按钮点击，得出结果后用户再次点击数字直接从新开始，由此判断，
static BOOL isHaveCalculateSymbolClickedFirst = NO;   ///< 保存 = 按钮点击后，用户输入数字是不是第一次
static BOOL isHaveCalculateSymbolClickedDevide = NO;   ///< 保存 = 按钮点击后，用户再次重新输入数字保存 oldNum时候的中间状态，点 = 是 yes，点 + - X / 为NO


static NSInteger currentTextLength = 1;   ///< 记录当前输入框文字长度
static CGFloat oldNum = 0;  ///< 记录计算的第一个数字
static CGFloat newNum = 0;  ///< 记录计算的第二个数字

static BOOL isShowStatusBar = NO;   ///< 记录是否隐藏状态栏
static NSInteger currentDirect = 1;   ///< 记录当前方向 1:竖屏 2:横屏



@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerHCons;
@property(nonatomic,assign) RightSymbolType rightSymbolType;
@property(nonatomic,assign) CGFloat resultNum;

@end

@implementation ViewController


- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden
{
//    if (isShowStatusBar) {
//        return NO;
//    }else
//    {
//        return YES;
//    }
    
    return !isShowStatusBar;
    
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"font = %@",self.textField.font);
  
    self.containerHCons.constant = keyWH * 5;
    [self setupUI];
    
    
    [self addObserverForTestField];
    [self addObserverForDeviceOrientation];
}


- (void)addObserverForTestField
{
    [self.textField addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSLog(@"new text is  %@",change[@"new"]);
    
    NSString *newText = change[@"new"];
    if ([newText isEqualToString:@"."]) {
        newText = @"0.";
    }
    NSMutableString *newTextM = [NSMutableString stringWithString:newText];
    
    isHavePoint = [newText containsString:@"."];
    
    // 保存对应的值为数字
    if (isHaveRightSymbol && !isHaveCalculateSymbolClickedDevide) {
        
        // 如果已经输入 右边运算符号，保存新值
        newNum = [[newTextM stringByReplacingOccurrencesOfString:@"," withString:@""] floatValue];
    }else
    {
        // 如果没有输入 右边运算符号，保存旧值
        oldNum = [[newTextM stringByReplacingOccurrencesOfString:@"," withString:@""] floatValue];
    }
    
//    if (isHaveCalculateSymbolClicked) {
//        oldNum = newNum;
//    }el
    
    NSLog(@"oldNum is  %f",oldNum);
    NSLog(@"newNum is  %f",newNum);

}

- (void)addObserverForDeviceOrientation
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)deviceOrientationDidChange
{
    NSLog(@"NAV deviceOrientationDidChange:%ld",(long)[UIDevice currentDevice].orientation);
    if([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) {
        [self orientationChange:NO];
        isShowStatusBar = YES;
        [self setNeedsStatusBarAppearanceUpdate];
        //注意： UIDeviceOrientationLandscapeLeft 与 UIInterfaceOrientationLandscapeRight
    } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
        [self orientationChange:YES];
        isShowStatusBar = NO;
        [self setNeedsStatusBarAppearanceUpdate];
        
    }
}


- (void)orientationChange:(BOOL)landscapeRight
{
    
    NSInteger inputDirect = landscapeRight ? 2 : 1 ;
    
    // 换屏幕时判断当前状态，防止屏幕收到信息就要修改UI
    if (currentDirect == inputDirect) return;
    currentDirect = inputDirect;
    
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    if (landscapeRight) {
        [UIView animateWithDuration:0.2f animations:^{
            self.view.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.view.bounds = CGRectMake(0, 0, height, width);
            
            // 内容跟着移动
            self.containerHCons.constant = keyWH * 3;
            [self.view layoutIfNeeded];
            [self setupUIForLandsscapeRight];
            if (isCheatMode) [self calculateForCheatModeOnly]; //再计算一次输入的数字
            
        }];
    } else {
        [UIView animateWithDuration:0.2f animations:^{
            self.view.transform = CGAffineTransformMakeRotation(0);
            self.view.bounds = CGRectMake(0, 0, width, height);
            
            self.containerHCons.constant = keyWH * 5;
            [self.view layoutIfNeeded];
            [self setupUIForNormal];
            if (isCheatMode) [self calculateForCheatModeOnly]; //再计算一次输入的数字

        }];
    }
}


- (void)dealloc
{
    [self.textField removeObserver:self forKeyPath:@"text"];
}


/**
 正常竖屏模式下的UI
 */
- (void)setupUI
{

    [self setupUIForNormal];
}

- (void)setupUIForLandsscapeRight
{
    // 0.先移除以前的
    [self.containerView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    
    // 设置列数为 10
    int clos = 10;
    
    NSArray *keys = @[
                      @"(",@")",@"mc",@"m+",@"m-",@"mr",@"c",@"+/-",@"%",@"÷",
                      @"2nd",@"x2",@"x3",@"xy",@"ex",@"10x",@"7",@"8",@"9",@"x",
                      @"1/x",@"2√x",@"2√x",@"y√x",@"ln",@"Log10",@"4",@"5",@"6",@"-",
                      @"x!",@"sin",@"cos",@"tan",@"e",@"EE",@"1",@"2",@"3",@"+",
                      @"Rad",@"sinh",@"cosh",@"tanh",@"∏",@"Rand",@"0",@"",@".",@"="];
    
    if (isCheatMode) {
        keys = @[
                 @"(",@")",@"mc",@"m+",@"m-",@"mr",@"c",@"+/-",@"%",@"÷",
                 @"2nd",@"x2",@"x3",@"xy",@"ex",@"10x",@"7",@"8",@"9",@"x",
                 @"1/x",@"2√x",@"2√x",@"y√x",@"ln",@"Log10",@"4",@"5",@"6",@"-",
                 @"x!",@"sin",@"cos",@"tan",@"e",@"EE",@"1",@"2",@"3",@"+",
                 @"Rad",@"sinh",@"cosh",@"tanh",@"∏",@"Rand",@"0",@"",@"·",@"="];
    }
    
    for (int i = 0; i < keys.count; i++) {
        XYKeyButton *btn = [XYKeyButton new];
        [btn setTitle:keys[i] forState:UIControlStateNormal];
        [btn.titleLabel sizeToFit];
        btn.tag = i;
        [btn addTarget:self action:@selector(keyClick:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchDownRepeat];
        [self.containerView addSubview:btn];
        btn.titleLabel.font = [UIFont fontWithName:@".SFUIDisplay-Thin" size:35];
        
        if (i / clos == 0 && i % clos != clos - 1) {
            //btn.isSymbol = YES;
            btn.btnType = ButtonTypeSymbol;
            btn.titleLabel.font = [UIFont fontWithName:@".SFUIDisplay-Thin" size:30];
        }
        
        if (i % clos <= 5) {
            btn.btnType = ButtonTypeSymbol;
            btn.titleLabel.font = [UIFont fontWithName:@".SFUIDisplay-Thin" size:20];
        }
        
        if (i % clos == clos - 1) {
            //btn.isRight = YES;
            btn.btnType = ButtonTypeRight;
        }
        
        
        CGFloat landscapeW = self.containerView.frame.size.width / clos;
        CGFloat landscapeH = self.containerHCons.constant / 5;

        CGFloat x = (i % clos) * landscapeW;
        CGFloat y = (i / clos) * landscapeH;
        if ([keys[i] isEqualToString:@"0"]) {
            
            btn.btnType = ButtonTypeZero;
            btn.frame = CGRectMake(x, y, landscapeW * 2, landscapeH);
            i ++;
        }else
        {
            btn.frame = CGRectMake(x, y, landscapeW, landscapeH);
        }
        
        // 添加作弊状态
        if ([keys[i] isEqualToString:@"."] || [keys[i] isEqualToString:@"·"]) {
            [btn addTarget:self action:@selector(zeroKeyClick:) forControlEvents:UIControlEventTouchDownRepeat];
        }
        
    }
}

/*
    实际上可以抽取一下方法，这样可能会更好一些，将两种布局用一个方法创建
 
    有些特异的问题，还是需要单独处理，暂时先分开写着
 
 */

- (void)setupUIForNormal
{
    // 0.先移除以前的
    [self.containerView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    
    // 设置列数为 4
    int clos = 4;
    
    NSArray *keys = @[@"c",@"+/-",@"%",@"÷",
                      @"7",@"8",@"9",@"x",
                      @"4",@"5",@"6",@"-",
                      @"1",@"2",@"3",@"+",
                      @"0",@"",@".",@"="];
    
    if (isCheatMode) {
        keys = @[@"c",@"+/-",@"%",@"÷",
                 @"7",@"8",@"9",@"x",
                 @"4",@"5",@"6",@"-",
                 @"1",@"2",@"3",@"+",
                 @"0",@"",@"·",@"="];
    }
    
    for (int i = 0; i < keys.count; i++) {
        XYKeyButton *btn = [XYKeyButton new];
        [btn setTitle:keys[i] forState:UIControlStateNormal];
        [btn.titleLabel sizeToFit];
        btn.tag = i;
        [btn addTarget:self action:@selector(keyClick:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchDownRepeat];
        [self.containerView addSubview:btn];
        
        if (i / clos == 0 ) {
            //btn.isSymbol = YES;
            btn.btnType = ButtonTypeSymbol;
        }
        
        if (i % clos == clos - 1) {
            //btn.isRight = YES;
            btn.btnType = ButtonTypeRight;
        }
        
        
        CGFloat x = (i % clos) * keyWH;
        CGFloat y = (i / clos) * keyWH;
        if ([keys[i] isEqualToString:@"0"]) {
            
            btn.btnType = ButtonTypeZero;
            btn.frame = CGRectMake(x, y, keyWH * 2, keyWH);
            i ++;
        }else
        {
            btn.frame = CGRectMake(x, y, keyWH, keyWH);
        }

        
        // 添加作弊状态
        if ([keys[i] isEqualToString:@"."]) {
            [btn addTarget:self action:@selector(zeroKeyClick:) forControlEvents:UIControlEventTouchDownRepeat];
        }
        
    }
}


- (void)keyClick:(XYKeyButton *)sender
{
    NSLog(@"点击了 --- %@",sender.currentTitle);
    
    /*
     基本规则：
     
     1. 点击数字
     
        0 :
            if (value == 0)
                return; 不再进行添加
        . :
            if (value 是否包含小数点)
                return; 不再进行添加
            else
                添加一个小数点（如果原来是0，则直接修改为 0.）
        1~9 :
            if (text.length 是否大于9位，包含小数点则是10位)
            
     2. 点击普通运算符 + - * / =
     
         + - * /:
            点击前记录 前值
            再次点击  直接计算得到新值，相当于点击 =
     
     
         = :
            直接计算两个值结果
     
     3. 点击特殊运算符 AC/C  +/-  %
        
        AC/C :
            AC 是彻底清除所有值
            C:只是清除，当前计算输入的值，（如 +5 写错成 +4 可按 C 删除修改成5）
        +/- : 给数字添加正负属性
     
        % : 这个是直接取 百分比，缩小100倍，并直接得出结果
     
     
     4. textField的文字长度
        
        有小数点时候添加小数点共10位，中间不用 , 隔开
     
        没有小数点正常数字可输入9位，每三位用 , 隔开（实际11位）
     
        添加正负属性什么时候都可以
     
    
     额外规则：
     
        进入作弊模式之后，点击 = 按钮，功能只有一个 😀😁😀😁
     

     */
    
    
    /// 先判断是否长度过大禁止输入
    
    switch (sender.btnType) {
        case ButtonTypeNum:
        {
            /// 1.先判断是否长度过大禁止输入
//            if ( !isHaveMinus && (currentTextLength >= 11)) return; // 正数正常最大值 123，345，789
//            if (isHaveMinus && (currentTextLength >= 12)) return; // 负数正常最大值 -123，345，789
//            if (isHavePoint && (currentTextLength >= 10)) return; // 负数正常最大值 123.345789
//            if (!isHavePoint && (currentTextLength >= 9)) return; // 负数正常最大值 123345789
            NSMutableString *text = [NSMutableString stringWithString:self.textField.text];
            text = [NSMutableString stringWithString:[text stringByReplacingOccurrencesOfString:@"," withString:@""]];
            text = [NSMutableString stringWithString:[text stringByReplacingOccurrencesOfString:@"." withString:@""]];
            text = [NSMutableString stringWithString:[text stringByReplacingOccurrencesOfString:@"-" withString:@""]];
            NSInteger length = text.length;
            if (length >= 9 && !isHaveRightSymbolFirst) return;


           
            /// 2. 进入计算
            if (isHaveRightSymbol && !isHaveCalculateSymbolClicked) {
                
                // 如果上一次已经输入运算符号，直接第一个数字赋值为当前点击数字
                [self calculateNewNumWithNum:sender.currentTitle];

            }else
            {
                
                [self calculateWithNum:sender.currentTitle];
            }
        }
            
            break;
        case ButtonTypeSymbol:
        {
            [self calculateWithSymbol:sender.currentTitle];
        }
            
            break;
        case ButtonTypeRight:
        {
            [self calculateWithRight:sender.currentTitle];
        }
            
            break;
        case ButtonTypeZero:
        {
            NSMutableString *text = [NSMutableString stringWithString:self.textField.text];
            text = [NSMutableString stringWithString:[text stringByReplacingOccurrencesOfString:@"," withString:@""]];
            text = [NSMutableString stringWithString:[text stringByReplacingOccurrencesOfString:@"." withString:@""]];
            text = [NSMutableString stringWithString:[text stringByReplacingOccurrencesOfString:@"-" withString:@""]];
            NSInteger length = text.length;
            if (length >= 9) return;
            
            if ([text integerValue] == 0) {
                return;
            }else
            {
                [self calculateWithNum:@"0"];
            }
        }
            
            break;
            
        default:
            break;
    }
    
}

/**
 计算普通数字 -- newNum
 */
- (void)calculateNewNumWithNum:(NSString *)numStr
{
    
    // 1. 直接给新值赋值
    if (isHaveRightSymbolFirst) {
        
        self.textField.text = numStr;
        
        // isHaveRightSymbolFirst 赋值为NO，这样再次进入就不再直接赋值，而是从新开始
        isHaveRightSymbolFirst = NO;
    }else
    {
        [self calculateWithNum:numStr];
    }
}

/**
 计算普通数字 -- oldNum
 */
- (void)calculateWithNum:(NSString *)numStr
{
    // -1 首先判断范围如果不是 . 0-9 就直接返回
    if ([numStr isEqualToString:@"·"]) {
        numStr = @".";
    }
    
    
    // 0.获得上次计算结果后，下次直接点击数字开始赋旧值、新值
    if (isHaveCalculateSymbolClickedFirst) {
        
        if ([numStr isEqualToString:@"."]) {
            numStr = @"0.";
        }
        self.textField.text = numStr;
        
        isHaveCalculateSymbolClickedFirst = NO;
        
        oldNum = [numStr floatValue];
        
        return;
    }
    
    // 1. 判断是不是点击了小数点
    if ([numStr isEqualToString:@"."]) {
        if (isHavePoint) {
            return;
        };
        isHavePoint = YES;
    }
    
    
    
    NSMutableString * text = [NSMutableString stringWithString:self.textField.text];
    
    // 如果原来是 0 ,直接赋值，然后退出，不用考虑加 . - , 这些了
    if (text.integerValue == 0 && ![numStr isEqualToString:@"."] && !isHavePoint) {
//        oldNum = numStr.integerValue;
        currentTextLength = 1;
        self.textField.text = numStr;
        return;
    }else if (text.integerValue == 0 && [numStr isEqualToString:@"."])
    {
        self.textField.text =  [text stringByAppendingString:numStr];
        return;
    }

    if (text.length < 3) {
        self.textField.text = [text stringByAppendingString:numStr];
    }
    
    if (text.length >= 3 && text.length < 7) { // 到7 是因为有一个 ,
        
        // 先去掉 , 得到原来数字
        text = [NSMutableString stringWithString:[text stringByReplacingOccurrencesOfString:@"," withString:@""]];
        // 在计算现在新数字
        text = [NSMutableString stringWithString:[text stringByAppendingString:numStr]];

        if (!isHavePoint) { // 没有小数点的话加上 , 分割
            
            NSInteger index = text.length % 3;
            if (index == 0) {
                index = 3;
            }
            [text insertString:@"," atIndex:index];
        }
        
        self.textField.text = text;
        // 防止text 长度变为7 影响下面，直接退出
        if (text.length == 7) {
            return;
        }
    }
    
    
    if (text.length >= 7) { // 上边刚赋值完成后可能就等于 7 了，会一下加两个数字
        
        
            
        // 先去掉 , 得到原来数字
        text = [NSMutableString stringWithString:[text stringByReplacingOccurrencesOfString:@"," withString:@""]];
        // 在计算现在新数字
        text = [NSMutableString stringWithString:[text stringByAppendingString:numStr]];
        
        
        if (!isHavePoint) { // 没有小数点的话加上 , 分割
            
            NSInteger index = text.length % 3;
            if (index == 0) {
                index = 3;
            }
            
            [text insertString:@"," atIndex:text.length - 3];
            [text insertString:@"," atIndex:index];
        }
        
        self.textField.text = text;
    }
    
#warning TODO 处理小数点开始
    
    // 计算当前原来值，长度 ---- 是否有负号和小数点去对应的方法中计算
    if (isHavePoint) {
//        oldNum = text.floatValue;
        currentTextLength = text.length;
        
        if (isHaveMinus) {
//            oldNum = -text.floatValue;
            currentTextLength = text.length + 1;
        }
    }else
    {
//        oldNum = text.integerValue;
        currentTextLength = text.length;
        
        if (isHaveMinus) {
//            oldNum = -text.floatValue;
            currentTextLength = text.length + 1;
        }
    }
    
    
    
    
    
    
    
//    self.textField.text = [text stringByAppendingString:numStr];
}


/**
 计算上边运算符
 */
- (void)calculateWithSymbol:(NSString *)numStr
{

//    oldNum = 0;
//    currentTextLength = 0;
//    
//    
//    self.textField.text = @"0";
    
    if ([numStr isEqualToString:@"C"] || [numStr isEqualToString:@"c"]) {
       
//        oldNum = 0;
        currentTextLength = 0;
        self.textField.text = @"0";
        oldNum = newNum = 0;
        isHaveRightSymbol = isHaveRightSymbolFirst = NO;
        isHaveCalculateSymbolClicked = isHaveCalculateSymbolClickedFirst = NO;
        isHavePoint = NO;
        isHaveCalculateSymbolClickedDevide = NO; //退出中间状态
    }
    
    if ([numStr isEqualToString:@"+/-"]) {
        
//        isHaveMinus = !isHaveMinus;
        
        NSMutableString *text = [NSMutableString stringWithString:self.textField.text];
        isHaveMinus = [text containsString:@"-"];
        
        if (isHaveMinus) {
            
            self.textField.text = [text stringByReplacingOccurrencesOfString:@"-" withString:@""];
            currentTextLength = text.length;
            
        }else
        {
            [text insertString:@"-" atIndex:0];
            self.textField.text = text;
            currentTextLength = text.length;
        }
        
        if (isHaveRightSymbol && !isHaveCalculateSymbolClickedDevide) {
            // 这里直接 用新值给 oldNum 赋值，计算的时候直接用 负数计算
            // 因为已经有右边运算符之后只记录最新值，不会修改原来值。这里需要手动修改
            oldNum = newNum;
        }
        
    }
    
    if ([numStr isEqualToString:@"%"]) {
        
        NSMutableString *text = [NSMutableString stringWithString:self.textField.text];
        
        // 如果有 , 分割先获得正确的数字
        NSString *numStr = [text stringByReplacingOccurrencesOfString:@"," withString:@""];
        
        NSNumber *num = [NSNumber numberWithDouble:numStr.floatValue / 100];
    
        
//        self.textField.text = [num stringValue];

        
        self.textField.text = [NSString stringWithFormat:@"%1.2f",numStr.floatValue / 100];

        // 去掉无用的后部分 0 数位
        
//        self.textField.text = [self formartScientificNotationWithString:self.textField.text];
        
        
        /*
         
         这是一个计算符号
         
         直接使用 oldNum 去做对应的计算即可
         
         textNum = oldNum / 100;
         
         textNum 要使用科学计数法表示
         
         
         
         
         */
        
#warning TODO 科学计数法展示对应的计算结果
        
        
    }
}

/**
 计算右边运算符
 */
- (void)calculateWithRight:(NSString *)numStr
{
    
    /*
     加减乘除
     
     oldNum 运算 newNum
     
     */
    
    if ([numStr isEqualToString:@"+"]) {
        
        _rightSymbolType = RightSymbolTypePlus;
        // 记录 等号 点击，此处与等号点击处相反
        isHaveCalculateSymbolClicked = isHaveCalculateSymbolClickedFirst = NO;
        isHaveCalculateSymbolClickedDevide = NO; //退出中间状态
        

    }
    
    if ([numStr isEqualToString:@"-"]) {
        
        _rightSymbolType = RightSymbolTypeMinus;
        // 记录 等号 点击，此处与等号点击处相反
        isHaveCalculateSymbolClicked = isHaveCalculateSymbolClickedFirst = NO;
        isHaveCalculateSymbolClickedDevide = NO; //退出中间状态
    }
    
    
    if ([numStr isEqualToString:@"X"] || [numStr isEqualToString:@"x"]) {
        
        _rightSymbolType = RightSymbolTypeMaulty;
        // 记录 等号 点击，此处与等号点击处相反
        isHaveCalculateSymbolClicked = isHaveCalculateSymbolClickedFirst = NO;
        isHaveCalculateSymbolClickedDevide = NO; //退出中间状态
    }
    
    
    if ([numStr isEqualToString:@"÷"]) {
        
        _rightSymbolType = RightSymbolTypeDivide;
        // 记录 等号 点击，此处与等号点击处相反
        isHaveCalculateSymbolClicked = isHaveCalculateSymbolClickedFirst = NO;
        isHaveCalculateSymbolClickedDevide = NO; //退出中间状态
        
    }
    
    if ([numStr isEqualToString:@"="]) {
        
        if (isCheatMode) {
            
            [self calculateForCheatModeOnly];
            
            return;
        }
        
        // 运算完成之后，重新赋值 isHaveRightSymbol，下次继续从 oldNum 开始。
        isHaveRightSymbol = NO;
        isHaveRightSymbolFirst = isHaveRightSymbol;
        isHaveCalculateSymbolClickedDevide = YES; //进入中间状态
        // 记录 等号 点击，下次用户直接点击数字的话就是彻底新的计算，如果还是点击 等于号，那就是重复上面的运算
        isHaveCalculateSymbolClicked = isHaveCalculateSymbolClickedFirst =YES;
        
        // 计算
        switch (_rightSymbolType) {
            case RightSymbolTypePlus:
            {
                self.resultNum = oldNum + newNum;
                
                
                
            }
                break;
            case RightSymbolTypeMinus:
            {
                self.resultNum = oldNum - newNum;
            }
                break;
            case RightSymbolTypeMaulty:
            {
                self.resultNum = oldNum * newNum;
            }
                break;
            case RightSymbolTypeDivide:
            {
                // 这里需要判断 除数不能为 0 的问题吗
                self.resultNum = oldNum / newNum;
            }
                break;
                
            default:
                break;
        }
        
        // 计算完结果之后，统一处理一下整体越界问题
        NSString *resultStr = [NSString stringWithFormat:@"%f",_resultNum];
        if ([resultStr floatValue]) {
            // 说明还是数字，不动
        }else
        {
            // 如果已经不是数字了就赋值为空
            oldNum = 0;
            newNum = 0;
            return;
        }
    
    }
    
    
    // 每点击一次 右边运算符 就不再赋值 oldNum ，做一个标记，判断，然后计算新值
    isHaveRightSymbol = YES;
    isHaveRightSymbolFirst = isHaveRightSymbol;
    
}





/**
 字符串的数字转成科学计数法展示
 */
- (NSString *)formartScientificNotationWithString:(NSString *)str
{

    long double num = [[NSString stringWithFormat:@"%@",str] floatValue];

    NSNumberFormatter * formatter = [[NSNumberFormatter alloc]init];

    formatter.numberStyle = kCFNumberFormatterScientificStyle;
//    formatter.formatWidth = 10;
//    formatter.groupingSize = 3;
    
    NSString * string = [formatter stringFromNumber:[NSNumber numberWithDouble:num]];

//    return [NSString calculateFormat:string];
    return string;

}




/**
 双击 . 进入作弊状态
 */
- (void)zeroKeyClick:(XYKeyButton *)sender
{
    NSLog(@"双击了 --- %@",sender.currentTitle);
    // 进入/退出 作弊状态
    isCheatMode = !isCheatMode;
    if (isCheatMode) {
        [sender setTitle:@"·" forState:UIControlStateNormal];
        [self calculateWithSymbol:@"c"]; // 复位
    }else
    {
        [sender setTitle:@"." forState:UIControlStateNormal];
    }
}


- (void)calculateForCheatModeOnly
{
    [self calculateWithSymbol:@"C"];
    
    CGFloat myNum = 18658275117;
    
    if (currentDirect == 1) {
        self.textField.text = [NSString stringWithFormat:@"%g",myNum];
    }else
    {
        self.textField.text = [NSString stringWithFormat:@"%0.0f",myNum];
    }
}

- (void)setResultNum:(CGFloat)resultNum
{
    _resultNum = resultNum;
    
    self.textField.text = [NSString stringWithFormat:@"%g",resultNum];
}







@end
