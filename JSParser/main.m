//
//  main.m
//  JSParser
//
//  Created by Rachel Brindle on 11/5/12.
//  Copyright (c) 2012 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STWJSParser.h"

// This is a sample application I wrote to test the javascript parser I wrote for SIDE.

int main(int argc, const char * argv[])
{

    @autoreleasepool {
                
        if (argc != 2) {
            printf("Error! Expected a file to parse.\nUsage: %s <javascript file to parse>\n", argv[0]);
            return 1;
        }
        
        NSString *filename = @( argv[1] );
        NSString *string = [[NSString alloc] initWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
        
        STWJSParser *js = [[STWJSParser alloc] init];
        [js processString:string];
        
        // demo for my javascript parser.
        
    }
    return 0;
}

