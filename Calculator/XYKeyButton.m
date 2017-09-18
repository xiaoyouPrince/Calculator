//
//  XYKeyButton.m
//  Calculator
//
//  Created by 渠晓友 on 2017/9/15.
//  Copyright © 2017年 XiaoYou. All rights reserved.
//

#import "XYKeyButton.h"
#import "UIImage+XYAdd.h"

#define XYColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]


@interface XYKeyButton ()

@property(nonatomic,strong) UIView *cover;

@end

@implementation XYKeyButton

- (UIView *)cover
{
    if (_cover == nil) {
        _cover = [UIView new];
        _cover.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
        _cover.frame = self.bounds;
    }
    return _cover;
}


// 重新init设置对应的状态颜色
- (instancetype)initWithFrame:(CGRect)frame
{
//    208 208 210
    if (self = [super initWithFrame:frame]) {
        self.titleLabel.font = [UIFont fontWithName:@".SFUIDisplay-Thin" size:40];
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self setBackgroundImage:[UIImage imageWithColor:XYColor(208, 208, 210)] forState:UIControlStateNormal];
        self.layer.borderWidth = 0.25;
        self.layer.borderColor = [UIColor blackColor].CGColor;
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (highlighted) {
        [self addSubview:self.cover];
    }else
    {
        [self.cover removeFromSuperview];
    }
}

- (void)setIsSymbol:(BOOL)isSymbol
{
//    200 201 203
    [self setBackgroundImage:[UIImage imageWithColor:XYColor(200, 201, 203)] forState:UIControlStateNormal];
}

- (void)setIsRight:(BOOL)isRight
{
//    223 136 39        XYColor(245, 114, 16)
    [self setBackgroundImage:[UIImage imageWithColor:XYColor(246, 137, 42)] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

}

- (void)setBtnType:(ButtonType)btnType
{
    _btnType = btnType;
    
    switch (btnType) {
        case ButtonTypeNum:
            // 正常状态直接返回
            break;
        case ButtonTypeSymbol:
            // 上边的，颜色深一点
            self.isSymbol = YES;
            break;
        case ButtonTypeRight:
            // 右边的黄色
            self.isRight = YES;
            break;
        case ButtonTypeZero:
            // 0 数字按钮，特殊处理，变大-此处代码实际没有用，调用顺序表明这里还没有创建titleLabel，所以对应的frame无效
        {
            CGFloat newX =  self.titleLabel.center.x - self.frame.size.width / 4;
            self.titleLabel.center = CGPointMake(newX, self.center.y);
        }
            break;
            
        default:
            break;
    }
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    if (self.btnType == ButtonTypeZero) {
        
        CGRect rect = [super titleRectForContentRect:contentRect];
        rect.origin.x = rect.origin.x - contentRect.size.width / 4;
        return rect;
    }
    return [super titleRectForContentRect:contentRect];
}



@end
