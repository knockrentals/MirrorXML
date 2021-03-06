//
//  MXPattern.m
//  MirrorXML
//
//  Created by Mike Spears on 2014-04-17.
//  Copyright (c) 2014 samesimilar. All rights reserved.
//
/*
 Copyright (c) 2018 Michael Spears <help@samesimilar.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import <libxml/pattern.h>

#import "MXPattern.h"

NSErrorDomain MirrorXMLErrorDomain = @"com.samesimilar.MirrorXML";

@interface MXPattern ()

@property (nonatomic, assign) xmlPatternPtr patternPtr;

/* hold reference to these in case libxml doesn't copy the cstrings internally */
@property (nonatomic) NSDictionary<NSString *, NSString *> * namespaces;
@property (nonatomic) NSString * path;

@property (nonatomic, assign) int maxDepth;
@property (nonatomic, assign) int minDepth;
@property (nonatomic, assign) BOOL matchesAttribute;
@end
@implementation MXPattern

- (nullable instancetype) initWithPath:(NSString *) path
                            namespaces:(nullable NSDictionary<NSString *, NSString *> *) namespaces
                                 error:(NSError * __nullable * __null_unspecified)error
{

    self = [super init];
    if (self) {
        
        self.path = path;
        self.namespaces = namespaces ? namespaces : [NSDictionary new];
        
        const xmlChar * patternCh = (xmlChar *)[_path cStringUsingEncoding:NSUTF8StringEncoding];
        
        const xmlChar ** namespacesCh  = NULL;
        if (namespaces) {
            NSUInteger numNamespaces = [namespaces count];
            namespacesCh = calloc(numNamespaces * 2 + 2, sizeof(xmlChar *));
            const xmlChar ** iNamespace = namespacesCh;
            for (NSString * shortName in namespaces) {
                NSString * longName= namespaces[shortName];
                // stored as array of [URI, prefix]
                iNamespace[0] = (xmlChar * )[longName cStringUsingEncoding:NSUTF8StringEncoding];
                iNamespace[1] = (xmlChar * )[[shortName lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
                iNamespace += 2;
            }
            //terminator
            iNamespace[0] = NULL;
            iNamespace[1] = NULL;

        }

        self.patternPtr = xmlPatterncompile(patternCh, NULL, XML_PATTERN_XPATH, namespacesCh);
        
        free(namespacesCh);
        
        if (_patternPtr == NULL) {
            if (error) {
                *error = [NSError errorWithDomain:MirrorXMLErrorDomain code:MirrorXMLErrorPathParseFailed userInfo: @{NSLocalizedDescriptionKey: @"XML match path could not be compiled."}];
            }
            return nil;
        }
        
        // pattern must be streamable
        if (xmlPatternStreamable(_patternPtr) != 1) {
            if (error) {
                *error = [NSError errorWithDomain:MirrorXMLErrorDomain code:MirrorXMLErrorPathIsNotStreamable userInfo:@{NSLocalizedDescriptionKey: @"XML match path must be streamable."}];
            }
            return nil;
        }
        
        self.matchesAttribute = [path containsString:@"@"];
        
        self.maxDepth = xmlPatternMaxDepth(_patternPtr);
        self.minDepth = xmlPatternMinDepth(_patternPtr);        
    }
    return self;
}

- (instancetype) init
{
    return [self initWithPath:@"//*" namespaces:nil error:nil];
}

- (instancetype) copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithPath:self.path namespaces:self.namespaces error: nil];
    
}

- (void) dealloc
{
    xmlFreePattern(self.patternPtr);
}


@end
