;
(function() {
 // body...
 if (window.IKAJS) {
 return
 };
 window.smeHybridPlatform = "ios";
 var _callBack = {};
 var _callBackCount = 1;
 var _cacheObjCount = 1;
 var _cacheObj = {};
 
 function _resultForCallback(callbackId, retStr) {
 try {
 var callback = _callBack[callbackId];
 if (!callback) return;
 callback.apply(null, [retStr]);
 } catch (e) {}
 }
 
 function _ajaxCallBack(originObjKey, ret) {
 var orinalObj = IKAJS.cachObj[originObjKey];
 
 var data = {};
 if(ret && ret != ""){
 var decodeStr = decodeURIComponent(ret == null ? "" : ret);
 data = JSON.parse(decodeStr);
 }else{
 data.code = "-1"
 }
 
 if (data.code != null && data.code != "-1") {
 orinalObj.success(data);
 } else {
 orinalObj.error(data);
 }
 }
 
 function _call(obj, functionName, args) {
 
 var formattedArgs = [];
 
 for (var i = 0, l = args.length; i < l; i++) {
 
 var argType = typeof args[i];
 var thisArg = args[i];
 
 if (IKAIs.String(thisArg)) {
 formattedArgs.push("s");
 formattedArgs.push(thisArg);
 } else if (IKAIs.Number(thisArg)) {
 formattedArgs.push("d");
 formattedArgs.push((args[i]).toString());
 } else if (IKAIs.Boolean(thisArg)) {
 formattedArgs.push("b");
 formattedArgs.push((args[i]).toString());
 } else if (IKAIs.Undefined(thisArg) || IKAIs.Null(thisArg)) {
 formattedArgs.push("n");
 formattedArgs.push("NSNull");
 } else if (IKAIs.Array(thisArg)) {
 formattedArgs.push("a");
 formattedArgs.push(encodeURIComponent(JSON.stringify(thisArg)));
 } else if (IKAIs.Function(thisArg)) {
 var key = IKAJS.callBackCount++;
 _callBack[key.toString()] = thisArg;
 formattedArgs.push("f");
 formattedArgs.push(encodeURIComponent(key.toString()));
 } else {
 
 //only for inject http service
 formattedArgs.push("o");
 
 var key = IKAJS.cacheObjCount++;
 _cacheObj[key.toString()] = thisArg;
 
 var arr = [];
 arr.push(key.toString());
 
 var tmpStr = JSON.stringify(thisArg);
 var cloneObj = JSON.parse(tmpStr);
 
 for (var o in thisArg) {
 //{key:value}, value不支持嵌套有function的任何对象，即 value为 {key: function(){}}这种形式“
 //只对第一层嵌套有function做处理
 if (IKAIs.Function(thisArg[o])) {
 cloneObj[o] = o;
 }
 }
 arr.push(cloneObj);
 formattedArgs.push(encodeURIComponent(JSON.stringify(arr)));
 }
 }
 var argStr = (formattedArgs.length > 0 ? ":" + encodeURIComponent(formattedArgs.join("/@@/")) : "");
 
 var iframe = document.createElement("IFRAME");
 iframe.style.display = 'none'
 iframe.setAttribute("src", "ika-js-scheme:" + obj + ":" + encodeURIComponent(functionName) + argStr);
 document.documentElement.appendChild(iframe);
 iframe.parentNode.removeChild(iframe);
 iframe = null;
 
 var ret = IKAJS.retValue;
 IKAJS.retValue = undefined;
 
 if (ret) {
 return decodeURIComponent(ret == null ? "" : ret);
 }
 }
 
 function _inject(obj, methods) {
 window[obj] = {};
 var jsObj = window[obj];
 
 for (var i = 0, l = methods.length; i < l; i++) {
 (function() {
  var method = methods[i];
  var jsMethod = method.replace(new RegExp(":", "g"), "");
  jsObj[jsMethod] = function() {
  return IKAJS.call(obj, method, Array.prototype.slice.call(arguments));
  };
  })();
 }
 }
 
 var IKAIs = {
 types: ["Function", "Array", "Boolean", "Number", "Object", "String", "Undefined", "Null"]
 };
 
 for (var i = 0; i < IKAIs.types.length; i++) {
 var typeName = IKAIs.types[i];
 IKAIs[typeName] = (function(type) {
                    return function(obj) {
                    return Object.prototype.toString.call(obj) == "[object " + type + "]";
                    }
                    })(typeName);
 }
 
 
 window.IKAJS = {
 call: _call,
 inject: _inject,
 invokeCallBack: _resultForCallback,
 callBack: _callBack,
 callBackCount: _callBackCount,
 cacheObjCount: _cacheObjCount,
 cachObj: _cacheObj,
 ajaxCallBack: _ajaxCallBack
 }
 
 })();