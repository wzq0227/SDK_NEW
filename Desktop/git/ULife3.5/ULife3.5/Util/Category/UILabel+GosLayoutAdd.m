//
//  UILabel+GosLayoutAdd.m
//  ULife3.5
//
//  Created by Goscam on 2017/11/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "UILabel+GosLayoutAdd.h"

@implementation UILabel (GosLayoutAdd)

- (void)setLinespacing:(float)spacing{
    
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc]initWithString:self.text];
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    
    [paragraphStyle setLineSpacing:spacing];//行间距
    
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [self.text length])];
    
    [self setAttributedText:attributedString];
    
    [self sizeToFit];
    
}

- (void)insertImage:(UIImage*)image atIndex:(NSUInteger)index bounds:(CGRect)bounds {
    //创建富文本
    NSMutableAttributedString *attri = [[NSMutableAttributedString alloc] initWithString: self.text];
    //NSTextAttachment可以将要插入的图片作为特殊字符处理
    NSTextAttachment *attch = [[NSTextAttachment alloc] init];
    //定义图片内容及位置和大小
    attch.image = image;
    attch.bounds = bounds;
    //创建带有图片的富文本
    NSAttributedString *string = [NSAttributedString attributedStringWithAttachment:attch];
    
    //将图片放在最后一位
    //[attri appendAttributedString:string];
    //将图片放在第一位
    [attri insertAttributedString:string atIndex:index];
    //用label的attributedText属性来使用富文本
    self.attributedText = attri;
}
@end
