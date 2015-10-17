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
    [self.webView addJavascriptInterfaces:wSelf withName:@"ViewController"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] 																		 pathForResource:@"test" ofType:@"html"]isDirectory:NO]]];
    
    [self.navigationItem setNavigationBarItemWithTitle:@"+" andTarget:self action:@selector(createNewVC) isLeftItem:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createNewVC
{
    [self.navigationController pushViewController:[ViewController new] animated:YES];
}

- (void)passArrayFromJS:(NSArray*)arr{
    NSLog(@"%s: %@",__FUNCTION__, [arr description]);
}

- (void)passObjFromJS:(NSDictionary*)o{
    NSLog(@"%s: %@",__FUNCTION__, [o description]);
}

- (void)passStringFromJS:(NSString*)str{
    NSLog(@"%s: %@",__FUNCTION__, str);
}

- (NSArray*)callArray{
    return @[@1,@2,@"3"];
}

- (NSDictionary*)callObject{
    return @{@"name":@"nativeObj", @"type":@"object"};
}

- (NSString*)callString{
    return @"string value";
}

- (NSString*)asyncCall{
    sleep(5);
    return @"bill wang";
}

@end
