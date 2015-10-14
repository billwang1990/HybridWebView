//
//  ViewController.m
//  ObjCAddJSInterface
//
//  Created by wangyaqing on 15/4/8.
//  Copyright (c) 2015年 billwang1990.github.io. All rights reserved.
//

#import "ViewController.h"
#import "UIWebView+AddJavaScriptInterface.h"
#import "UINavigationItem+Addition.h"

@interface ViewController ()<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    typeof(self) wSelf = self;
    [self.webView addJavascriptInterfaces:wSelf WithName:@"ViewController"];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] 																		 pathForResource:@"test" ofType:@"html"]isDirectory:NO]]];
    
    [self.navigationItem setNavigationBarItemWithTitle:@"add" andTarget:self action:@selector(tap) isLeftItem:NO];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tap
{
    [self.navigationController pushViewController:[ViewController new] animated:YES];
}

- (void)testMethod:(id)param
{
    if ([param isKindOfClass:[NSArray class]]) {
        [param enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSLog(@"%@ is instance of %@ \n", obj, [obj class]);
        }];
    }
    
    if ([param isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = param;
        [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSLog(@"%@ is instance of %@ \n", obj, [obj class]);

        }];
    }
    
    NSLog(@"call testMethod from js  %@", [param description]);
}

- (void)testBool:(BOOL)val
{
    if (val) {
        NSLog(@"bool val");
    }
}

- (NSString*)testFloat:(CGFloat)f
{
    NSLog(@"%f",f);
    
    __block NSString *ret = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(5);
        NSLog(@"fire");
        ret = @"012343356";
    });
    
    while (!ret) {
    }
    
    return ret;
}

@end
