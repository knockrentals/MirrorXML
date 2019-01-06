//
//  MXParserContext.m
//  MirrorXML
//
//  Created by Mike Spears on 2014-04-16.
//  Copyright (c) 2014 samesimilar. All rights reserved.
//
#import <libxml/tree.h>
#import <libxml/parser.h>

#import <MirrorXML/MXParser.h>
#import <MirrorXML/MXMatchList.h>
#import <MirrorXML/MXElement.h>
#import <MirrorXML/MXAttributeElement.h>
#import <MirrorXML/MXTextElement.h>


static xmlSAXHandler simpleSAXHandlerStruct;

@interface MXElement ()

@property (nonatomic, assign) const xmlChar *xmlLocalname;
@property (nonatomic, assign) const xmlChar *xmlNamespaceURI;
@property (nonatomic, assign) int xmlNb_attributes;
@property (nonatomic, assign) const xmlChar **xmlAttributes;
@property (nonatomic, weak, nullable) id livingParserContext;


- (void)appendCharacters:(const char *)charactersFound
                  length:(NSInteger)length;

@end

@interface MXAttributeElement()

@property (nonatomic, assign) const xmlChar *xmlAttrName;
@property (nonatomic, assign) const xmlChar *xmlAttrValue;
@property (nonatomic, assign) NSUInteger xmlAttrValueLength;
@property (nonatomic, assign) const xmlChar *xmlAttrNamespace;

@end

@interface MXParser ()

@property (nonatomic, assign) xmlParserCtxtPtr context;
@property (nonatomic) MXMatchList * handlerList;
- (void) raiseError:(NSError *) error;


@end

@implementation MXParser

- (instancetype) initWithMatches:(NSArray<MXMatch *> *) matches {
    self = [super init];
    if (self) {
        self.context = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, (__bridge void *)(self), NULL, 0, NULL);
        self.handlerList = [[MXMatchList alloc] init];
        self.handlerList.handlers = matches;
    }
    return self;
}
- (instancetype) init
{
    return [self initWithMatches:@[]];
}


- (void) dealloc
{
    if (self.context != NULL) {
        xmlFreeParserCtxt(self.context);
    }
    self.context = NULL;
    [self.handlerList removeChildren];
}

- (void) parseDataChunk:(NSData *) data
{
    xmlParseChunk(self.context, (const char *)[data bytes], (int)[data length], 0);
}


- (void) dataFinished
{
    xmlParseChunk(self.context,NULL, 0, 1);
}

- (void) raiseError:(NSError *) error
{
    [self.handlerList errorRaised:error onElement:self.handlerList.elm];
    if (self.handlerList.elm.stop) {
        [self stopParsing];
    }
}

- (void) stopParsing
{
    xmlStopParser(self.context);
}

@end

#pragma mark SAX Helper Function


#pragma mark SAX Callback Implementations
static void startElementSAX (void *ctx,
                             const xmlChar *localname,
                             const xmlChar *prefix,
                             const xmlChar *URI,
                             int nb_namespaces,
                             const xmlChar **namespaces,
                             int nb_attributes,
                             int nb_defaulted,
                             const xmlChar **attributes)
{
    
    MXParser *ctxSelf = (__bridge MXParser *)ctx;

    MXElement * elm = [ctxSelf.handlerList childElement];
    elm.livingParserContext = ctxSelf;
    elm.xmlLocalname = localname;
    elm.xmlNamespaceURI = URI;
    elm.xmlNb_attributes = nb_attributes;
    elm.xmlAttributes = attributes;


    ctxSelf.handlerList = [ctxSelf.handlerList enterElement:elm];

    if (elm.stop) {
        [ctxSelf stopParsing];
    }

}

static void	endElementSAX   (void *ctx,
                             const xmlChar *localname,
                             const xmlChar *prefix,
                             const xmlChar *URI)

{
    MXParser *ctxSelf = (__bridge MXParser *)ctx;



    [ctxSelf.handlerList exitElement];
    ctxSelf.handlerList = ctxSelf.handlerList.parentList;

    if (ctxSelf.handlerList.elm.stop) {
        [ctxSelf stopParsing];
    }
}

static void	charactersFoundSAX(void *ctx,
                               const xmlChar *ch,
                               int len)
{
    MXParser *ctxSelf = (__bridge MXParser *)ctx;

    MXElement * elm = ctxSelf.handlerList.elm;
    [elm appendCharacters:(const char *)ch length:len];

    MXTextElement * telm = [ctxSelf.handlerList childTextElement];
    telm.livingParserContext = ctxSelf;
    [telm appendCharacters:(const char *)ch length:len];
    ctxSelf.handlerList = [ctxSelf.handlerList enterElement:telm];
    [ctxSelf.handlerList exitElement:telm];
    ctxSelf.handlerList = ctxSelf.handlerList.parentList;

    if (telm.stop) {
        [ctxSelf stopParsing];
    }
}


static void errorEncounteredSAX(void *ctx,
                                const char *msg,
                                ...)
{
    va_list args;
    char * fullMessage = NULL;
    if (msg)
    {
        va_start(args, msg);
        vasprintf(&fullMessage, msg, args);
        va_end(args);
    }
    
    MXParser *ctxSelf = (__bridge MXParser *)ctx;
    NSString * str = fullMessage ? [NSString stringWithUTF8String:(const char *)fullMessage] : @"libxml2 error";
    NSError * error = [NSError errorWithDomain:@"com.mirrorxml.libxml2" code:1 userInfo:@{NSLocalizedDescriptionKey:str}];
    
    [ctxSelf raiseError:error];

}



static void startDocumentSAX (void *ctx)
{
    MXParser *ctxSelf = (__bridge MXParser *)ctx;
    [ctxSelf.handlerList streamReset];
}


static xmlSAXHandler simpleSAXHandlerStruct = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,                       /* attributeDecl */
    NULL,                       /* elementDecl */
    NULL,                       /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    startDocumentSAX,              /* startDocument */
    NULL,                       /* endDocument */
    NULL,                       /* startElement*/
    NULL,                       /* endElement */
    NULL,                       /* reference */
    charactersFoundSAX,         /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncounteredSAX,        /* error */
    NULL,                       /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    charactersFoundSAX,         /* cdataBlock */
    NULL,                       /* externalSubset */
    XML_SAX2_MAGIC,             //
    NULL,
    startElementSAX,            /* startElementNs */
    endElementSAX,              /* endElementNs */
    NULL,                       /* serror */
};
