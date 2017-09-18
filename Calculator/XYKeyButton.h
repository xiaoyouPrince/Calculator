//
//  XYKeyButton.h
//  Calculator
//
//  Created by 渠晓友 on 2017/9/15.
//  Copyright © 2017年 XiaoYou. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM( NSInteger , ButtonType) {
    ButtonTypeNum,  ///< 是不是数字，default
    ButtonTypeSymbol, ///< 是不是符号，最上方
    ButtonTypeRight, ///< 是不是最右侧，黄色背景
    ButtonTypeZero // 标识数字 0 的按钮
};

@interface XYKeyButton : UIButton

@property(nonatomic , assign) ButtonType btnType;

@property(nonatomic , assign) BOOL isNum;  ///< 是不是数子，default
@property(nonatomic , assign) BOOL isSymbol;  ///< 是不是符号，最上方
@property(nonatomic , assign) BOOL isRight; ///< 是不是最右侧，黄色背景



@end
