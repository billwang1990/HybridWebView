# HybridWebView

Native object inject to javascript environment.
You can call native method from UIWebView, and send the result back. It also support async callback handler.

###Usage：

First of all, you should import `UIWebView+AddJavaScriptInterface.h`

Injection:
	   
	[self.webView addJavascriptInterfaces:wSelf WithName:@"ViewController"];

	
Native code:

	@interface ViewController : UIViewController

	- (void)passArrayFromJS:(NSArray*)arr;
	- (NSArray*)callArray;

	@end

Javascript call:

	ViewController.passArrayFromJS([1, 2, "2"]);
	ViewController.callArray();

	
Async :

You can add a callback at last if you will get the result later.	

	ViewController.callArray( function(ret){console.log(ret)} );

	
###Problem
Only support pass string, array or dictionary.

