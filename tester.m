/* PEG Markdown Highlight
 * Copyright 2011-2016 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * tester.m
 * 
 * Test program that runs the parser on the given Markdown document and
 * highlights the contents using Cocoa's NSMutableAttributedString, outputting
 * the results as ANSI escape -formatted text into stdout.
 */

#include <sys/time.h>
#import <Foundation/Foundation.h>
#import "ANSIEscapeHelper.h"
#import "pmh_parser.h"


// Convert unicode code point offsets (this is what we get from the parser) to
// NSString character offsets (NSString uses UTF-16 units as characters, so
// sometimes two characters (a "surrogate pair") are needed to represent one
// code point):
void convertOffsets(pmh_element **elements, NSString *str)
{
    // Walk through the whole string only once, and gather all surrogate pair indexes
    // (technically, the indexes of the high characters (which come before the low
    // characters) in each pair):
    NSMutableArray *surrogatePairIndexes = [NSMutableArray arrayWithCapacity:(str.length / 4)];
    NSUInteger strLen = str.length;
    NSUInteger i = 0;
    while (i < strLen)
    {
        if (CFStringIsSurrogateHighCharacter([str characterAtIndex:i]))
            [surrogatePairIndexes addObject:[NSNumber numberWithUnsignedInteger:i]];
        i++;
    }
    
    // If the text does not contain any surrogate pairs, we're done (the indexes
    // are already correct):
    if (surrogatePairIndexes.count == 0)
        return;
    
    // Use our list of surrogate pair indexes to shift the indexes of all
    // language elements:
    for (int langType = 0; langType < pmh_NUM_LANG_TYPES; langType++)
    {
        pmh_element *cursor = elements[langType];
        while (cursor != NULL)
        {
            NSUInteger posShift = 0;
            NSUInteger endShift = 0;
            NSUInteger passedPairs = 0;
            for (NSNumber *pairIndex in surrogatePairIndexes)
            {
                NSUInteger u = [pairIndex unsignedIntegerValue] - passedPairs;
                if (u < cursor->pos)
                {
                    posShift++;
                    endShift++;
                }
                else if (u < cursor->end)
                {
                    endShift++;
                }
                else
                    break;
                passedPairs++;
            }
            cursor->pos += posShift;
            cursor->end += endShift;
            cursor = cursor->next;
        }
    }
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
        pmh_COMMENT,
        pmh_CODE,
        pmh_LIST_BULLET,
        pmh_LIST_ENUMERATOR,
        pmh_VERBATIM,
        pmh_HTMLBLOCK,
        pmh_HRULE,
        pmh_REFERENCE,
        pmh_NOTE,
        pmh_HTML_ENTITY,
        pmh_BLOCKQUOTE,
        pmh_STRIKE,
    };
    int order_len = 25;
    
    int i;
    for (i = 0; i < order_len; i++)
    {
        //pmh_PRINTF("apply_highlighting: %i\n", i);
        
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
                case pmh_COMMENT:   fgColor = [NSColor blackColor]; break;
                case pmh_CODE:
                case pmh_VERBATIM:  fgColor = [NSColor greenColor]; break;
                case pmh_HTML_ENTITY:
                case pmh_HRULE:     fgColor = [NSColor cyanColor]; break;
                case pmh_REFERENCE: fgColor = [NSColor colorWithCalibratedHue:0.67 saturation:0.5 brightness:1.0 alpha:1.0]; break;
                case pmh_LIST_ENUMERATOR:
                case pmh_LIST_BULLET:fgColor = [NSColor magentaColor]; break;
                case pmh_AUTO_LINK_EMAIL:
                case pmh_AUTO_LINK_URL:fgColor = [NSColor cyanColor]; break;
                case pmh_IMAGE:
                case pmh_LINK:      bgColor = [NSColor blackColor];
                                    fgColor = [NSColor cyanColor]; break;
                case pmh_BLOCKQUOTE:fgColor = [NSColor magentaColor]; break;
                case pmh_HTMLBLOCK: fgColor = [NSColor magentaColor]; break;
                case pmh_HTML:      fgColor = [NSColor cyanColor]; break;
                case pmh_STRIKE:    fgColor = [NSColor blackColor]; bgColor = [NSColor grayColor]; break;
                default: break;
            }
            
            //pmh_PRINTF("  %i-%i\n", cursor->pos, cursor->end);
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
        
        elem[order[i]] = NULL;
    }
}



NSAttributedString *highlight(NSString *str, NSMutableAttributedString *attrStr)
{
    pmh_element **result;
    
    char *md_source = (char *)[str UTF8String];
    pmh_markdown_to_elements(md_source, pmh_EXT_STRIKE, &result);
    convertOffsets(result, str);
    
    if (attrStr == nil)
        attrStr = [[[NSMutableAttributedString alloc] initWithString:str] autorelease];
    apply_highlighting(attrStr, result);
    
    pmh_free_elements(result);
    return attrStr;
}


void print_result_debug_info(pmh_element *elem[])
{
    fprintf(stderr, "\n");
    
    for (int i = 0; i < pmh_NUM_TYPES; i++)
    {
        pmh_element *cursor = elem[i];
        while (cursor != NULL)
        {
            fprintf(stderr, "[%ld-%ld] 0x%x: %s\n", cursor->pos, cursor->end, (int)cursor, pmh_element_name_from_type(cursor->type));
            
            if (cursor->label != NULL)
                fprintf(stderr, "  label: '%s'\n", cursor->label);
            if (cursor->address != NULL)
                fprintf(stderr, "  address: '%s'\n", cursor->address);
            
            cursor = cursor->next;
        }
    }
}

void Print(NSString *aStr)
{
    [aStr writeToFile:@"/dev/stdout" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}

void PrintErr(NSString *aStr)
{
    [aStr writeToFile:@"/dev/stderr" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}

double get_time()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec*1e-6;
}

int main(int argc, char * argv[])
{
    NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
    
    if (argc == 1)
    {
        Print(@"Argument must be path to file\n");
        return(0);
    }
    
    ANSIEscapeHelper *ansiHelper = [[[ANSIEscapeHelper alloc] init] autorelease];
    NSString *filePath = [NSString stringWithUTF8String:argv[argc-1]];
    NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    
    if (argc > 2)
    {
        if (strcmp(argv[1], "-d") == 0)
        {
            pmh_element **result;
            pmh_markdown_to_elements((char *)[contents UTF8String], pmh_EXT_STRIKE, &result);
            print_result_debug_info(result);
        }
        else
        {
            int iterations = atoi(argv[1]);
            fprintf(stderr, "Doing %i iterations.\n", iterations);
            
            NSAttributedString *attrStr = nil;
            
            NSMutableAttributedString *as[iterations];
            for (int j = 0; j < iterations; j++) {
                as[j] = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
            }
            
            double starttime = get_time();
            int stepProgress = 0;
            for (int i = 0; i < iterations; i++)
            {
                attrStr = highlight(contents, as[i]);
                
                if (stepProgress == 9) {
                    PrintErr([NSString stringWithFormat:@"%i", i+1]);
                    stepProgress = 0;
                } else {
                    PrintErr(@"-");
                    stepProgress++;
                }
            }
            double endtime = get_time();
            
            PrintErr(@"\n");
            printf("%f\n", (endtime-starttime));
        }
    }
    else
    {
        Print([ansiHelper ansiEscapedStringWithAttributedString:highlight(contents, nil)]);
    }
    
    [autoReleasePool release];
    return(0);
}
