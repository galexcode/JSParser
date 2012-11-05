//
//  STWJSParser.m
//  Side
//
//  Created by Rachel Brindle on 11/4/12.
//  Copyright (c) 2012 Rachel Brindle. All rights reserved.
//

#import "STWJSParser.h"

BOOL stringContainsSubstring(NSString *str, NSString *substring)
{
    return ([str rangeOfString:substring].location != NSNotFound);
}

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
    //BOOL (^isInputEven)(int) = ^(int input)
    int (^isCRLF)(NSUInteger);
    isCRLF = ^(NSUInteger i) {
        return (length > i+2 && (([str characterAtIndex:i] == '\r' && [str characterAtIndex:i+1] == '\n') || [str characterAtIndex:i] == '\n'));
    };
    
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
        
        // start comment
        if (!isString && !isComment && c == '/' && length > 1 && i < length - 1 && ([str characterAtIndex:i+1] == '/' || [str characterAtIndex:i+1] == '*')) {
            if ([str characterAtIndex:i+1] == '/')
                isSingleLineComment = YES;
            else
                isSingleLineComment = NO;
            isComment = YES;
            commentRange.location = i;
        }
        
        if ((!isEscaped && !isString && !isComment) && (c == ';' || c == '\n')) {
            instructionRange.length = (i - instructionRange.location) + 1;
            if (instructionRange.length != 1) {
                NSString *instruct = [str substringWithRange:instructionRange];
                instruct = [self stringByStrippingWhitespaceFromEnds:instruct];
                [self examineInstruction:[self removeMultilineCommentFromString:instruct]];
                instructionRange.location = i+1;
            }
        }
        
        if ((!isEscaped && !isString && !isComment) && (c == '{')) {
            scope++;
        }
        if ((!isEscaped && !isString && !isComment) && (c == '}')) {
            scope--;
            [variables removeObjectForKey:@( scope + 1 )];
        }
        
        // End of a comment
        if (isComment && i < length - 1 &&
            ((isSingleLineComment && (c == '\n' || c == '\0'))||
             (!isSingleLineComment && i < length - 2 && c == '*' && [str characterAtIndex:i+1] == '/'))) {
                commentRange.length = i - commentRange.location + 1;
                isComment = NO;
            }
    }
}

-(NSString *)removeMultilineCommentFromString:(NSString *)str
{
    NSRange foo = [str rangeOfString:@"/*"];
    if (foo.location == NSNotFound)
        return str;
    NSString *blargle = [str substringFromIndex:foo.location + foo.length];
    NSString *beginOfString = [str substringToIndex:foo.location];
    
    foo = [blargle rangeOfString:@"*/"];
    if (foo.location == NSNotFound)
        return beginOfString;
    NSUInteger ind = foo.location+foo.length;
    if (ind >= [blargle length])
        return beginOfString;
    NSString *endOfString = [blargle substringFromIndex:foo.location+foo.length];
    
    NSString *ret = [beginOfString stringByAppendingString:endOfString];
    return [self removeMultilineCommentFromString:ret];
}

-(NSString *)stringByStrippingWhitespaceFromEnds:(NSString *)str
{
    NSRange range = NSMakeRange(0, NSNotFound);
    NSInteger init, end;
    NSUInteger length = [str length];
    for (init = 0; init < length; init++) {
        unichar c = [str characterAtIndex:init];
        if (!isspace(c))
            break;
    }
    range.location = init;
    for (end = (length - 1); end > init; end--) {
        unichar c = [str characterAtIndex:end];
        if (!isspace(c))
            break;
    }
    range.length = (end - init) + 1;
    return [str substringWithRange:range];
}

-(void)examineInstruction:(NSString *)instruction
{
    if (instruction.length < 2 || [instruction hasPrefix:@"//"]) // because apparently, my comment catching algorithm is bad, mkay.
        return;
    if (stringContainsSubstring(instruction, @"var") || stringContainsSubstring(instruction, @"function")) {
        printf("Instruction contains new variables! Instruction: \"%s\"", [instruction UTF8String]);
    } //else
     //   printf("Instruction is: \"%s\"\n", [instruction UTF8String]);
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
