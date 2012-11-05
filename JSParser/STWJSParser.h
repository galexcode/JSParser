//
//  STWJSParser.h
//  Side
//
//  Created by Rachel Brindle on 11/4/12.
//  Copyright (c) 2012 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STWJSParser : NSObject
{
    NSInteger scope;
    NSMutableArray *minScopeLevels;
    NSMutableDictionary *variables;
}

-(void)processString:(NSString *)str;
-(void)processString:(NSString *)str toPos:(NSInteger)pos;
-(NSArray *)getCurrentVariables;
-(int)getIndentLevel;

@end
