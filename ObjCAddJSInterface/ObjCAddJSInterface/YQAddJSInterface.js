
(function() {
    // body...
    "use strict";

    if (window.HybridWeb) {
        return;
    }

    window.HybridWeb = {};
    var _callBack = {};
    var _callBackCount = 1;

    function _resultForCallback(callbackId, ret) {
        try {
            var callback = _callBack[callbackId];
            if (!callback) return;
            callback.apply(null, [ret]);
        } catch (e) {}
    }

    function _call(obj, functionName, args) {

        var formattedArgs = [];

        for (var i = 0, l = args.length; i < l; i++) {

            var thisArg = args[i];

            if (JSTypeIs.Function(thisArg) && (i == args.length -1)) {
                var key = window.HybridWeb.callBackCount++;
                _callBack[key.toString()] = thisArg;
                formattedArgs.push(key.toString());
            }else{
                formattedArgs.push(thisArg);
            }
        }
        var argStr = (formattedArgs.length > 0 ? "?params=" + encodeURIComponent(JSON.stringify(formattedArgs)) : "");

        var iframe = document.createElement("IFRAME");
        iframe.style.display = "none";
        iframe.setAttribute("src", "hybrid-js-scheme://" + obj + "/" + encodeURIComponent(functionName) + argStr);
        document.documentElement.appendChild(iframe);
        iframe.parentNode.removeChild(iframe);
        iframe = null;

        var ret = window.HybridWeb.retValue;
        window.HybridWeb.retValue = undefined;

        if (ret) {
            return decodeURIComponent(ret === null ? "" : ret);
        }
    }

    function _inject(obj, methods) {
        window[obj] = {};
        var jsObj = window[obj];
        for (var i = 0, l = methods.length; i < l; i++) {
            (function() {
                var method = methods[i];
                jsObj[method] = function() {
                    return window.HybridWeb.call(obj, method, Array.prototype.slice.call(arguments));
                };
            })();
        }
    }

    var JSTypeIs = {
        types: ["Function", "Array", "Boolean", "Number", "Object", "String", "Undefined", "Null"]
    };

    for (var i = 0; i < JSTypeIs.types.length; i++) {
        var typeName = JSTypeIs.types[i];
        JSTypeIs[typeName] = (function(type) {
            return function(obj) {
                return Object.prototype.toString.call(obj) == "[object " + type + "]";
            };
        })(typeName);
    }

    window.HybridWeb = {
        call: _call,
        inject: _inject,
        invokeCallBack: _resultForCallback,
        callBack: _callBack,
        callBackCount: _callBackCount,
    };

})();