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

static BOOL isCheatMode = NO;   ///< 记录是否为作弊状态
static BOOL isHavePoint = NO;   ///< 记录是否包含小数点
static BOOL isHaveMinus = NO;   ///< 记录是否为负数
static BOOL isHaveRightSymbol = NO;   ///< 记录是否输入右边计算符，有就停止保存oldNum,开始保存newNum
static NSInteger currentTextLength = 1;   ///< 记录当前输入框文字长度
static CGFloat oldNum = 0;  ///< 记录计算的第一个数字
static CGFloat newNum = 0;  ///< 记录计算的第二个数字


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerHCons;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"font = %@",self.textField.font);
  
    self.containerHCons.constant = keyWH * 5;
    [self setupUI];
    
    
    [self addObserverForTestField];
}


- (void)addObserverForTestField
{
    [self.textField addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSLog(@"new text is  %@",change[@"new"]);
    
    NSString *newText = change[@"new"];
    NSMutableString *newTextM = [NSMutableString stringWithString:newText];
    
    // 保存对应的值为数字
    if (isHaveRightSymbol) {
        
        // 如果已经输入 右边运算符号，保存新值
        newNum = [[newTextM stringByReplacingOccurrencesOfString:@"," withString:@""] floatValue];
    }else
    {
        // 如果没有输入 右边运算符号，保存旧值
        oldNum = [[newTextM stringByReplacingOccurrencesOfString:@"," withString:@""] floatValue];
    }

}

- (void)dealloc
{
    [self.textField removeObserver:self forKeyPath:@"text"];
}

- (void)setupUI
{
    // 设置列数为 4
    int clos = 4;
    
    NSArray *keys = @[@"c",@"+/-",@"%",@"÷",
                     @"7",@"8",@"9",@"x",
                     @"4",@"5",@"6",@"-",
                     @"1",@"2",@"3",@"+",
                     @"0",@"",@".",@"="];

    for (int i = 0; i < 20; i++) {
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
            btn.frame = CGRectMake(x, y, keyWH * 2, keyWH);
            btn.btnType = ButtonTypeZero;
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
            if ( !isHaveMinus && (currentTextLength >= 11)) return; // 正数正常最大值 123，345，789
            if (isHaveMinus && (currentTextLength >= 12)) return; // 负数正常最大值 -123，345，789
           
            /// 2. 进入计算
            [self calculateWithNum:sender.currentTitle];
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
            
        }
            
            break;
            
        default:
            break;
    }
    
}


/**
 计算普通数字
 */
- (void)calculateWithNum:(NSString *)numStr
{

    
    
    NSMutableString * text = [NSMutableString stringWithString:self.textField.text];
    
    // 如果原来是 0 ,直接赋值，然后退出，不用考虑加 . - , 这些了
    if (text.integerValue == 0) {
//        oldNum = numStr.integerValue;
        currentTextLength = 1;
        self.textField.text = numStr;
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
        NSInteger index = text.length % 3;
        if (index == 0) {
            index = 3;
        }
        [text insertString:@"," atIndex:index];
        
        self.textField.text = text;
    }
    
    
    if (text.length >= 7) {
        
        
        // 先去掉 , 得到原来数字
        text = [NSMutableString stringWithString:[text stringByReplacingOccurrencesOfString:@"," withString:@""]];
        // 在计算现在新数字
        text = [NSMutableString stringWithString:[text stringByAppendingString:numStr]];
        NSInteger index = text.length % 3;
        if (index == 0) {
            index = 3;
        }

        [text insertString:@"," atIndex:text.length - 3];
        [text insertString:@"," atIndex:index];
        
        self.textField.text = text;
    }
    
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
    }
    
    if ([numStr isEqualToString:@"+/-"]) {
        
        isHaveMinus = !isHaveMinus;
        if (isHaveMinus) {
            
            NSMutableString *text = [NSMutableString stringWithString:self.textField.text];
            [text insertString:@"-" atIndex:0];
            self.textField.text = text;
            currentTextLength = text.length;
            
        }else
        {
            NSMutableString *text = [NSMutableString stringWithString:self.textField.text];
            self.textField.text = [text stringByReplacingOccurrencesOfString:@"-" withString:@""];
            currentTextLength = text.length;
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
    // 每点击一次 右边运算符 就不再赋值 oldNum ，做一个标记，判断，然后计算新值
    isHaveRightSymbol = YES;
    
    
    /*
     加减乘除
     
     oldNum 运算 newNum
     
     */
    
    if ([numStr isEqualToString:@"+"]) {
        
        
    }
    
    if ([numStr isEqualToString:@"-"]) {
        
    }
    
    
    if ([numStr isEqualToString:@"X"] || [numStr isEqualToString:@"x"]) {
        
    }
    
    
    if ([numStr isEqualToString:@"/"]) {
        
    }
    
    if ([numStr isEqualToString:@"="]) {
        
    }
    
}





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
    }else
    {
        [sender setTitle:@"." forState:UIControlStateNormal];
    }
}







@end
