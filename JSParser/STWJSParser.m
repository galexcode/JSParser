//
//  STWJSParser.m
//  Side
//
//  Created by Rachel Brindle on 11/4/12.
//  Copyright (c) 2012 Rachel Brindle. All rights reserved.
//

#import "STWJSParser.h"

@implementation STWJSParser

-(void)processString:(NSString *)str toPos:(NSInteger)pos
{
    if ([str length] == 0)
        return;
    NSString *s = [str substringToIndex:pos];
    [self processString:s];
}

-(void)processString:(NSString *)str
{
    
    scope = 0;
    variables = [[NSMutableDictionary alloc] init];
    
    NSUInteger length = [str length];
    
    BOOL isWord = NO;
    BOOL isEscaped = NO;
    BOOL isString = NO;
    BOOL isComment = NO;
    BOOL isSingleLineComment = NO;
    
    NSRange wordRange, stringRange, commentRange;
    
    NSRange instructionRange = NSMakeRange(0, NSNotFound);
    
    for (NSUInteger i = 0; i < length; i++) {
        if (isEscaped) {
            isEscaped = NO;
            continue;
        }
        
        unichar c = [str characterAtIndex:i];
        
        if (!isWord && !isComment && !isString && isalpha(c) && c != '_') {
            isWord = YES;
            wordRange.location = i;
        }
        
        if (isWord && !isalnum(c) && c != '_') {
            isWord = NO;
            wordRange.length = i - wordRange.location;
            //NSString* word = [[str substringWithRange:wordRange] lowercaseString];
        }
        
        if (!isEscaped && !isComment && (c == '"' || c == '\'')) {
            if (isString) {
                stringRange.length = i - stringRange.location + 1;
                stringRange = NSMakeRange(NSNotFound, 0);
            } else {
                stringRange.location = i;
            }
            isString = !isString;
        }
        
        if (!isEscaped && c == '\\')
            isEscaped = YES;
        if (!isString && c == '/' && length > 1 && i < length - 1 && ([str characterAtIndex:i+1] == '/' || [str characterAtIndex:i+1] == '*')) {
            if ([str characterAtIndex:i+1] == '/')
                isSingleLineComment = YES;
            else
                isSingleLineComment = NO;
            isComment = YES;
            commentRange.location = i;
        }
        
        // End of a comment
        if (isComment && i < length - 1 &&
            ((isSingleLineComment && (c == '\n' || c == '\0'))||
             (!isSingleLineComment && i < length - 2 && c == '*' && [str characterAtIndex:i+1] == '/'))) {
                commentRange.length = i - commentRange.location + 1;
                commentRange = NSMakeRange(NSNotFound, 0);
                isComment = NO;
            }
        if ((!isEscaped && !isString && !isComment) && (c == ';' || c == '\n')) {
            instructionRange.length = (i - instructionRange.location);
            [self examineInstruction:[str substringWithRange:instructionRange]];
            instructionRange.location = i;
        }
        
        if ((!isEscaped && !isString && !isComment) && (c == '{')) {
            scope++;
        }
        if ((!isEscaped && !isString && !isComment) && (c == '}')) {
            scope--;
            [variables removeObjectForKey:@( scope + 1 )];
        }
    }
}

-(void)examineInstruction:(NSString *)instruction
{
    printf("Instruction is: \"%s\"\n", [instruction UTF8String]);
}

-(int)getIndentLevel
{
    NSNumber *indentLevel = [[NSUserDefaults standardUserDefaults] objectForKey:@"indent level"];
    if (indentLevel == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:@2 forKey:@"indent level"];
        indentLevel = @2;
    }
    return scope * [indentLevel integerValue];
}

-(NSArray *)getCurrentVariables
{
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (int i = 0; i <= scope; i++) {
        [ret addObjectsFromArray:[variables objectForKey:@( i )]];
    }
    return ret;
}

@end
