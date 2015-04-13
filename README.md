# ObjCAddJSInterface
Inject native object to javascript

在开发安卓项目的时候，有个叫做addJavaScriptInterface的API可以很方便的把Native的对象注册到js中，从而可以在js中很方便的调用Native的方法。然而，OC中本身是不支持这样的特性的。因此我做了以层封装，在UIWebView上增加了一个category，从而可以像安卓一样很方便的将Native的代码注入进入。

例：


Native


	@interface ViewController : UIViewController

	- (void)testMethod:(id)param;

	@end

JS调用


	ViewController.testMehtod(param);
	
这里js一旦调用了之后就会从Native执行对应的方法，并取得返回值。如果，你希望通过闭包的方式（比如Native是一个耗时的操作）获得返回值，可以像下面这样写，在最后传入一个闭包：

	ViewController.testMethod(param, function (ret){ 
	//do something 
	});
	
现在的代码有一定的局限性，不过对于我个人目前的项目来说足够了，会在后续进行改进
	