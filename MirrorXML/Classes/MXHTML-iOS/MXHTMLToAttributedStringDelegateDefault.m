//
//  MXHTMLToAttributedStringDelegateDefault.m
//  UTStatus
//
//  Created by Mike Spears on 2014-10-15.
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

#import "MXHTMLToAttributedStringDelegateDefault.h"


@implementation MXHTMLToAttributedStringDelegateDefault

- (instancetype) init {
    self = [super init];
    if (self) {
        self.lineBreakMode = NSLineBreakByWordWrapping;
        self.bodyFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.h1Font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
        self.h2Font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
        self.h3Font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
        self.normalParagraphSpacing = 0;
        self.normalParagraphSpacingBefore = 0;
        self.monospaceFont = [UIFont fontWithName:@"Courier" size:12];
        self.preformattedTextLineBreakMode = NSLineBreakByClipping;
        self.orderedListItemPrefixFormat = @"%ld. ";
        self.unorderedListItemPrefix = @"•  ";
        self.listItemIndentCharacterCount = 4;
    }
    
    return self;
}
- (NSDictionary<NSAttributedStringKey, id> *) initialAttributes
{
    UIFont *bodyfont = self.bodyFont;
    NSMutableParagraphStyle * ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    ps.paragraphSpacing = self.normalParagraphSpacing;
    ps.paragraphSpacingBefore = self.normalParagraphSpacingBefore;
    ps.lineBreakMode = self.lineBreakMode;
    
    return @{NSFontAttributeName: bodyfont, NSParagraphStyleAttributeName: ps};
}

- (NSDictionary<NSAttributedStringKey, id> *) attributesForTag:(NSString *) tag currentAttributes:(NSDictionary<NSAttributedStringKey, id> *) currentAttrs
{
    NSMutableDictionary * newAttrs = [currentAttrs mutableCopy];
    
    if ([tag isEqualToString:@"small"]) {
        UIFont * oldFont = currentAttrs[NSFontAttributeName];
        newAttrs[NSFontAttributeName] = [oldFont fontWithSize:oldFont.pointSize * 0.75];
    } else if ([tag isEqualToString:@"strong"] || [tag isEqualToString:@"b"]) {
        UIFont * oldFont = currentAttrs[NSFontAttributeName];
        UIFontDescriptor * descriptor = [oldFont fontDescriptor];
        UIFontDescriptor * newDescriptor = [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | descriptor.symbolicTraits];
        
        newAttrs[NSFontAttributeName] = [UIFont fontWithDescriptor:newDescriptor size:oldFont.pointSize];
        
    } else if ([tag isEqualToString:@"em"] || [tag isEqualToString:@"i"]) {
        UIFont * oldFont = currentAttrs[NSFontAttributeName];
        UIFontDescriptor * descriptor = [oldFont fontDescriptor];
        UIFontDescriptor * newDescriptor = [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic | descriptor.symbolicTraits] ;
        
        newAttrs[NSFontAttributeName] = [UIFont fontWithDescriptor:newDescriptor size:oldFont.pointSize];
        
    } else if ([tag isEqualToString:@"code"] || [tag isEqualToString:@"pre"]) {
        UIFont * oldFont = currentAttrs[NSFontAttributeName];
        NSMutableParagraphStyle * ps = [currentAttrs[NSParagraphStyleAttributeName] mutableCopy];
        // don't wrap lines for preformatted text
        ps.lineBreakMode = NSLineBreakByClipping;
        
        
        
        newAttrs[NSFontAttributeName] = [self.monospaceFont fontWithSize:oldFont.pointSize];
        newAttrs[NSParagraphStyleAttributeName] = ps;
        
    } else if ([tag isEqualToString:@"h1"]) {
        UIFont * oldFont = currentAttrs[NSFontAttributeName];
        UIFontDescriptor * descriptor = [oldFont fontDescriptor];
        UIFont * headerFont = self.h1Font;
        UIFontDescriptor * headerDescriptor = [[headerFont fontDescriptor] fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits];
        newAttrs[NSFontAttributeName] = [UIFont fontWithDescriptor:headerDescriptor size:headerFont.pointSize];
    } else if ([tag isEqualToString:@"h2"]) {
        UIFont * oldFont = currentAttrs[NSFontAttributeName];
        UIFontDescriptor * descriptor = [oldFont fontDescriptor];
        UIFont * headerFont = self.h2Font;
        UIFontDescriptor * headerDescriptor = [[headerFont fontDescriptor] fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits];
        newAttrs[NSFontAttributeName] = [UIFont fontWithDescriptor:headerDescriptor size:headerFont.pointSize];

    } else if ([tag isEqualToString:@"h3"] || [tag isEqualToString:@"h4"]) {
        UIFont * oldFont = currentAttrs[NSFontAttributeName];
        UIFontDescriptor * descriptor = [oldFont fontDescriptor];
        UIFont * headerFont = self.h3Font;
        UIFontDescriptor * headerDescriptor = [[headerFont fontDescriptor] fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits];
        newAttrs[NSFontAttributeName] = [UIFont fontWithDescriptor:headerDescriptor size:headerFont.pointSize];

    }
    
    
    return newAttrs;
}
- (NSDictionary<NSAttributedStringKey, id> *) attributesForOrderedListLevel:(NSInteger) level itemIndex:(NSInteger) index currentAttributes:(NSDictionary<NSAttributedStringKey, id> *) currentAttrs
{
    NSMutableDictionary * newAttrs = [currentAttrs mutableCopy];
    
    UIFont  * font = newAttrs[NSFontAttributeName];
    
    CGSize charSize = [@" " sizeWithAttributes:@{NSFontAttributeName: font}];
    NSMutableParagraphStyle * ps = [currentAttrs[NSParagraphStyleAttributeName] mutableCopy];
    ps.firstLineHeadIndent = ps.firstLineHeadIndent + charSize.width * self.listItemIndentCharacterCount;
    ps.headIndent = ps.firstLineHeadIndent + [[self textForOrderedListItemIndex:index atListLevel:level] sizeWithAttributes:@{NSFontAttributeName: font}].width;
    newAttrs[NSParagraphStyleAttributeName] = ps;
    return newAttrs;
    
}

- (NSDictionary *) attributesForOrderedListRemainingParagraphsAtLevel:(NSInteger) level currentAttributes:(NSDictionary *) currentAttrs {
    return [self attributesForUnorderedListRemainingParagraphsAtLevel:level currentAttributes:currentAttrs];
}

- (NSString *) textForOrderedListItemIndex:(NSInteger) index atListLevel:(NSInteger) level
{
    return [NSString stringWithFormat:self.orderedListItemPrefixFormat, (long)index];
}

- (NSDictionary<NSAttributedStringKey, id> *) attributesForUnorderedListLevel:(NSInteger) level currentAttributes:(NSDictionary<NSAttributedStringKey, id> *) currentAttrs
{
    NSMutableDictionary * newAttrs = [currentAttrs mutableCopy];
    
    UIFont  * font = newAttrs[NSFontAttributeName];
    
    CGSize charSize = [@" " sizeWithAttributes:@{NSFontAttributeName: font}];
    NSMutableParagraphStyle * ps = [currentAttrs[NSParagraphStyleAttributeName] mutableCopy];
    ps.firstLineHeadIndent = ps.firstLineHeadIndent + charSize.width * self.listItemIndentCharacterCount;
    ps.headIndent = ps.firstLineHeadIndent + [[self textForUnorderedListItemAtListLevel:level] sizeWithAttributes:@{NSFontAttributeName: font}].width;
    newAttrs[NSParagraphStyleAttributeName] = ps;
    return newAttrs;
}

- (NSDictionary<NSAttributedStringKey, id> *) attributesForUnorderedListRemainingParagraphsAtLevel:(NSInteger) level currentAttributes:(NSDictionary<NSAttributedStringKey, id> *) currentAttrs
{
    NSMutableDictionary * newAttrs = [currentAttrs mutableCopy];

    NSMutableParagraphStyle * ps = [currentAttrs[NSParagraphStyleAttributeName] mutableCopy];
    ps.firstLineHeadIndent = ps.headIndent;

    
    newAttrs[NSParagraphStyleAttributeName] = ps;
    return newAttrs;
}

- (NSString *) textForUnorderedListItemAtListLevel:(NSInteger) level
{
    return self.unorderedListItemPrefix;
}
- (NSDictionary<NSAttributedStringKey, id> *) attributesForAnchorElementWithHTMLAttributes:(NSDictionary<NSString *, NSString *> *) htmlAttributes currentTextAttributes:(NSDictionary<NSAttributedStringKey, id> *) currentAttrs
{
    NSMutableDictionary * newAttrs = [currentAttrs mutableCopy];

    if (htmlAttributes[@"href"] != nil) {
        NSString *trimmedHref = [htmlAttributes[@"href"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        NSUInteger hrefLength = trimmedHref.length;
        if (hrefLength == 0) {
            return newAttrs;
        }

        //  RFC 1808, 1738 and 2732 attempt
        NSURL *parsedURL = [NSURL URLWithString:trimmedHref];

        if (parsedURL == nil) {
            // RFC 3986 attempt
            NSURLComponents *urlComponents = [NSURLComponents componentsWithString:trimmedHref];
            parsedURL = urlComponents.URL;
        }

        if (parsedURL == nil) {
            // Since Knock does not return valid hrefs, NSURLComponents won't parse this, and we can't just use all of the URL character sets at once
            // This is a horrible hack, bound to break, and to possibly generate broken links
            // Ideally this would use a WhatWG compatible URL parser, such as `Skyr`, as Webkit's URL.h is not easily extractible
            // Please forgive me for writing this...
            // https://knockr.atlassian.net/browse/CP-878

            NSURLComponents *urlComponents = [[NSURLComponents alloc] init];

            NSString *remainingURLString = trimmedHref;

            // Encode fragment
            NSString *separator = @"#";
            NSArray *components = [remainingURLString componentsSeparatedByString:separator];
            if (components.count == 2) {
                urlComponents.fragment = components.lastObject;
                NSMutableArray *mutableComponents = [components mutableCopy];
                [mutableComponents removeLastObject];
                remainingURLString = [mutableComponents componentsJoinedByString:@""];
            }

            // Encode query
            separator = @"?";
            components = [remainingURLString componentsSeparatedByString:separator];
            if (components.count == 2) {
                urlComponents.query = components.lastObject;
                NSMutableArray *mutableComponents = [components mutableCopy];
                [mutableComponents removeLastObject];
                remainingURLString = [mutableComponents componentsJoinedByString:@""];
            }

            // Encode host
            separator = @"://";
            components = [remainingURLString componentsSeparatedByString:separator];
            // Note the >=, as it will match '://' for the host
            if (components.count == 2) {
                NSString *afterScheme = components.lastObject;

                NSString *hostSeparator = @"/";
                NSMutableArray *hostComponents = [[afterScheme componentsSeparatedByString:hostSeparator] mutableCopy];
                NSUInteger hostComponentsCount = hostComponents.count;

                NSString *hostString = hostComponents.firstObject;

                // Note the >= 2
                if (hostComponentsCount >= 2) {
                    [hostComponents removeObjectAtIndex:0];

                    NSString *pathString = [hostComponents componentsJoinedByString:hostSeparator];
                    urlComponents.path = [NSString stringWithFormat:@"/%@", pathString];
                }

                NSString *credentialsSeparator = @"@";
                NSArray *credentialComponents = [hostString componentsSeparatedByString:credentialsSeparator];
                if (credentialComponents.count == 2) {
                    NSString *credentialString = credentialComponents.firstObject;

                    NSString *hostString = credentialComponents.lastObject;

                    urlComponents.host = hostString;

                    NSString *subCredentialsSeparator = @":";
                    NSArray *subCredentialComponents = [credentialString componentsSeparatedByString:subCredentialsSeparator];
                    if (subCredentialComponents.count == 2) {
                        NSString *userString = subCredentialComponents.firstObject;
                        NSString *passwordString = subCredentialComponents.lastObject;

                        urlComponents.password = passwordString;
                        urlComponents.user = userString;
                    }
                } else {
                    urlComponents.host = hostString;
                }

                NSString *scheme = components.firstObject;
                urlComponents.scheme = scheme;
            }

            parsedURL = urlComponents.URL;
            if (parsedURL == nil) {
                NSLog(@"WARNING: Could not parse url: '%@'.\nBest attempt: '%@'", htmlAttributes[@"href"], urlComponents);
            }
        }

        newAttrs[NSLinkAttributeName] = parsedURL;
    }

    return newAttrs;

}





@end
