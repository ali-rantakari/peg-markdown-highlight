/* PEG Markdown Highlight
 * Copyright 2011-2016 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * testclient.m
 * 
 * Test program that runs `highlighter` as a child process, reads and
 * parses its stdout, and highlights the given Markdown content based on
 * that.
 */

#import <Foundation/Foundation.h>
#import "ANSIEscapeHelper.h"
#import "pmh_definitions.h"


void Print(NSString *aStr)
{
    [aStr writeToFile:@"/dev/stdout" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}


void apply_highlighting(NSMutableAttributedString *attrStr, pmh_element *elem[])
{
    unsigned long sourceLength = [attrStr length];
    
    int order[] = {
        pmh_H1, pmh_H2, pmh_H3, pmh_H4, pmh_H5, pmh_H6,  
        pmh_LINK,
        pmh_AUTO_LINK_URL,
        pmh_AUTO_LINK_EMAIL,
        pmh_IMAGE,
        pmh_HTML,
        pmh_EMPH,
        pmh_STRONG,
        pmh_CODE,
        pmh_LIST_BULLET,
        pmh_LIST_ENUMERATOR,
        pmh_BLOCKQUOTE,
        pmh_VERBATIM,
        pmh_HTMLBLOCK,
        pmh_HRULE,
        pmh_REFERENCE,
        pmh_NOTE
    };
    int order_len = 22;
    
    int i;
    for (i = 0; i < order_len; i++)
    {
        pmh_element *cursor = elem[order[i]];
        while (cursor != NULL)
        {
            if (cursor->end <= cursor->pos)
                goto next;
            
            NSColor *fgColor = nil;
            NSColor *bgColor = nil;
            BOOL removeFgColor = NO;
            BOOL removeBgColor = NO;
            
            switch (cursor->type)
            {
                case pmh_H1:
                case pmh_H2:
                case pmh_H3:
                case pmh_H4:
                case pmh_H5:
                case pmh_H6:        fgColor = [NSColor blueColor]; break;
                case pmh_EMPH:      fgColor = [NSColor yellowColor]; break;
                case pmh_STRONG:    fgColor = [NSColor magentaColor]; break;
                case pmh_CODE:
                case pmh_VERBATIM:  fgColor = [NSColor greenColor]; break;
                case pmh_HRULE:     fgColor = [NSColor cyanColor]; break;
                case pmh_LIST_ENUMERATOR:
                case pmh_LIST_BULLET:fgColor = [NSColor magentaColor]; break;
                case pmh_AUTO_LINK_EMAIL:
                case pmh_AUTO_LINK_URL:fgColor = [NSColor cyanColor]; break;
                case pmh_IMAGE:
                case pmh_LINK:      bgColor = [NSColor blackColor];
                                    fgColor = [NSColor cyanColor]; break;
                case pmh_BLOCKQUOTE:removeBgColor = YES;
                                fgColor = [NSColor magentaColor]; break;
                default: break;
            }
            
            if (fgColor != nil || bgColor != nil) {
                unsigned long rangePosLimitedLow = MAX(cursor->pos, (unsigned long)0);
                unsigned long rangePos = MIN(rangePosLimitedLow, sourceLength);
                unsigned long len = cursor->end - cursor->pos;
                if (rangePos+len > sourceLength)
                    len = sourceLength-rangePos;
                NSRange range = NSMakeRange(rangePos, len);
                
                if (removeBgColor)
                    [attrStr
                        removeAttribute:NSBackgroundColorAttributeName
                        range:range
                        ];
                else if (bgColor != nil)
                    [attrStr
                        addAttribute:NSBackgroundColorAttributeName
                        value:bgColor
                        range:range
                        ];
                
                if (removeFgColor)
                    [attrStr
                        removeAttribute:NSForegroundColorAttributeName
                        range:range
                        ];
                else if (fgColor != nil)
                    [attrStr
                        addAttribute:NSForegroundColorAttributeName
                        value:fgColor
                        range:range
                        ];
            }
            
            next:
            cursor = cursor->next;
        }
    }
}

pmh_element * mk_element(int type, long pos, long end)
{
    pmh_element *result = malloc(sizeof(pmh_element));
    result->type = type;
    result->pos = pos;
    result->end = end;
    result->next = NULL;
    return result;
}


pmh_element **get_highlight_elements(NSString *markdown_str)
{
    pmh_element **elements = malloc(sizeof(pmh_element*) * pmh_NUM_TYPES);
    for (int i = 0; i < pmh_NUM_TYPES; i++)
        elements[i] = NULL;
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"highlighter"];
    
    NSPipe *inPipe = [NSPipe pipe];
    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardInput:inPipe];
    [task setStandardOutput:outPipe];
    [task setStandardError:errPipe];
    NSFileHandle *inHandle = [inPipe fileHandleForWriting];
    NSFileHandle *outHandle = [outPipe fileHandleForReading];
    NSFileHandle *errHandle = [errPipe fileHandleForReading];
    
    [task launch];
    
    NSData *inputData = [markdown_str dataUsingEncoding:NSUTF8StringEncoding];
    [inHandle writeData:inputData];
    [inHandle closeFile];
    
    NSData *outData = nil;
    NSData *errData = nil;
    
    outData = [outHandle readDataToEndOfFile];
    errData = [errHandle readDataToEndOfFile];
    [outHandle closeFile];
    [errHandle closeFile];
    
    [task waitUntilExit];
    
    if (errData && [errData length] > 0)
        NSLog(@"stderr: %@", [[[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding] autorelease]);
    int exitStatus = [task terminationStatus];
    
    if (exitStatus != 0) {
        NSLog(@"highlighter exited with status: %i", exitStatus);
    } else {
        //Print([[[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding] autorelease]);
        //Print(@"\n--------\n");
        
        NSString *outStr = [[[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding] autorelease];
        
        NSCharacterSet *digitsSet = [NSCharacterSet decimalDigitCharacterSet];
        NSMutableCharacterSet *digitsOrPipeSet = [NSMutableCharacterSet decimalDigitCharacterSet];
        [digitsOrPipeSet addCharactersInString:@"|"];
        
        NSScanner *scanner = [NSScanner scannerWithString:outStr];
        while (![scanner isAtEnd])
        {
            int type = pmh_NO_TYPE;
            [scanner scanUpToCharactersFromSet:digitsSet intoString:NULL];
            [scanner scanInt:&type];
            [scanner scanUpToCharactersFromSet:digitsSet intoString:NULL];
            while (![scanner isAtEnd] && [outStr characterAtIndex:[scanner scanLocation]] != '|')
            {
                int startIndex = -1;
                int endIndex = -1;
                [scanner scanInt:&startIndex];
                [scanner scanString:@"-" intoString:NULL];
                [scanner scanInt:&endIndex];
                [scanner scanUpToCharactersFromSet:digitsOrPipeSet intoString:NULL];
                
                pmh_element *new = mk_element(type, startIndex, endIndex);
                pmh_element *head = elements[type];
                elements[type] = new;
                new->next = head;
            }
        }
        
    }
    
    [task release];
    return elements;
}


int main(int argc, char * argv[])
{
    NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
    
    if (argc == 1)
    {
        Print(@"Argument must be path to file\n");
        return(0);
    }
    
    NSString *filePath = [NSString stringWithUTF8String:argv[argc-1]];
    NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    NSMutableAttributedString *attrStr = nil;
    
    int iterations = 1;
    if (argc > 2) {
        iterations = atoi(argv[1]);
        printf("Doing %i iterations.\n", iterations);
    }
    
    int stepProgress = 0;
    for (int i = 0; i < iterations; i++)
    {
        pmh_element **highlightElements = get_highlight_elements(contents);
        attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
        apply_highlighting(attrStr, highlightElements);
        
        if (stepProgress == 9) {
            Print(@"x");
            stepProgress = 0;
        } else {
            Print(@"-");
            stepProgress++;
        }
    }
    
    ANSIEscapeHelper *ansiHelper = [[[ANSIEscapeHelper alloc] init] autorelease];
    Print([ansiHelper ansiEscapedStringWithAttributedString:attrStr]);
    
    [autoReleasePool release];
    return(0);
}
