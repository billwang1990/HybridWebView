# ObjCAddJSInterface
Inject native object to javascript

最近在开发过程中，看安卓同事可以调用一个叫addJavaScriptInterface的API很方便的把Native的对象注册到js中，从而可以在js中调用Native的代码。然而，OC中本身是不支持这样的特性的。因此我做了一层封装，在UIWebView上增加了一个category，从而可以像安卓一样很方便的将Native的代码注入js。

例：


Native


	@interface ViewController : UIViewController

	- (void)testMethod:(id)param;

	@end

JS调用


	ViewController.testMehtod(param);
	
这里js一旦调用了之后，Native会执行对应的方法，并返回返回值（如果有的话）。如果你希望通过闭包的方式（比如Native是一个耗时的操作）获得返回值，可以像下面这样写，在最后传入一个闭包：

	ViewController.testMethod(param, function (ret){ 
	//do something 
	});
	
现在的代码有一定的局限性，不过对于我个人目前的项目来说足够了，会在后续进行改进
	