#import "RNMMKV.h"
#import "YeetJSIUtils.h"

#if __has_feature(objc_arc)
#error This file must be compiled with MRC. Use -fno-objc-arc flag.
#endif
#import <React/RCTBridge+Private.h>
#import <React/RCTUtils.h>
#import <jsi/jsi.h>

#import <MMKV.h>

using namespace facebook;
using namespace mmkv;

@implementation RNMMKV
@synthesize bridge = _bridge;
@synthesize methodQueue = _methodQueue;

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup {
    return YES;
}


static void install(jsi::Runtime & jsiRuntime)
{
    // MMKV.set(key: string, value: string | number | bool)
    auto mmkvSet = jsi::Function::createFromHostFunction(jsiRuntime,
                                                         jsi::PropNameID::forAscii(jsiRuntime, "mmkvSet"),
                                                         2,  // key, value
                                                         [](jsi::Runtime& runtime, const jsi::Value& thisValue, const jsi::Value* arguments, size_t count) -> jsi::Value {
        if (!arguments[0].isString()) throw jsi::JSError(runtime, "MMKV::set: First argument ('key') has to be of type string!");
        auto keyName = convertJSIStringToNSString(runtime, arguments[0].getString(runtime));

        if (arguments[1].isBool()) {
            MMKV::defaultMMKV()->set(arguments[1].getBool(), keyName);
        } else if (arguments[1].isNumber()) {
            MMKV::defaultMMKV()->set(arguments[1].getNumber(), keyName);
        } else if (arguments[1].isString()) {
            auto nsString = convertJSIStringToNSString(runtime, arguments[1].getString(runtime));
            MMKV::defaultMMKV()->set(static_cast<NSObject<NSCoding>*>(nsString), keyName);
        } else {
            throw jsi::JSError(runtime, "MMKV::set: 'value' argument is not of type bool, number or string!");
        }
        return jsi::Value::undefined();
    });
    jsiRuntime.global().setProperty(jsiRuntime, "mmkvSet", std::move(mmkvSet));


    // MMKV.getBoolean(key: string)
    auto mmkvGetBoolean = jsi::Function::createFromHostFunction(jsiRuntime,
                                                                jsi::PropNameID::forAscii(jsiRuntime, "mmkvGetBoolean"),
                                                                1,  // key
                                                                [](jsi::Runtime& runtime, const jsi::Value& thisValue, const jsi::Value* arguments, size_t count) -> jsi::Value {
        if (!arguments[0].isString()) throw jsi::JSError(runtime, "First argument ('key') has to be of type string!");

        auto keyName = convertJSIStringToNSString(runtime, arguments[0].getString(runtime));
        auto value = MMKV::defaultMMKV()->getBool(keyName);
        return jsi::Value(value);
    });
    jsiRuntime.global().setProperty(jsiRuntime, "mmkvGetBoolean", std::move(mmkvGetBoolean));


    // MMKV.getString(key: string)
    auto mmkvGetString = jsi::Function::createFromHostFunction(jsiRuntime,
                                                               jsi::PropNameID::forAscii(jsiRuntime, "mmkvGetString"),
                                                               1,  // key
                                                               [](jsi::Runtime& runtime, const jsi::Value& thisValue, const jsi::Value* arguments, size_t count) -> jsi::Value {
        if (!arguments[0].isString()) throw jsi::JSError(runtime, "First argument ('key') has to be of type string!");

        auto keyName = convertJSIStringToNSString(runtime, arguments[0].getString(runtime));

        auto value = MMKV::defaultMMKV()->getObject(keyName, NSString.class);
        if (value != nil)
            return convertNSStringToJSIString(runtime, value);
        else
            return jsi::Value::undefined();
    });
    jsiRuntime.global().setProperty(jsiRuntime, "mmkvGetString", std::move(mmkvGetString));


    // MMKV.getNumber(key: string)
    auto mmkvGetNumber = jsi::Function::createFromHostFunction(jsiRuntime,
                                                               jsi::PropNameID::forAscii(jsiRuntime, "mmkvGetNumber"),
                                                               1,  // key
                                                               [](jsi::Runtime& runtime, const jsi::Value& thisValue, const jsi::Value* arguments, size_t count) -> jsi::Value {
        if (!arguments[0].isString()) throw jsi::JSError(runtime, "First argument ('key') has to be of type string!");

        auto keyName = convertJSIStringToNSString(runtime, arguments[0].getString(runtime));
        auto value = MMKV::defaultMMKV()->getDouble(keyName);
        return jsi::Value(value);
    });
    jsiRuntime.global().setProperty(jsiRuntime, "mmkvGetNumber", std::move(mmkvGetNumber));


    // MMKV.delete(key: string)
    auto mmkvDelete = jsi::Function::createFromHostFunction(jsiRuntime,
                                                            jsi::PropNameID::forAscii(jsiRuntime, "mmkvDelete"),
                                                            1,  // key
                                                            [](jsi::Runtime& runtime, const jsi::Value& thisValue, const jsi::Value* arguments, size_t count) -> jsi::Value {
        if (!arguments[0].isString()) throw jsi::JSError(runtime, "First argument ('key') has to be of type string!");

        auto keyName = convertJSIStringToNSString(runtime, arguments[0].getString(runtime));
        MMKV::defaultMMKV()->removeValueForKey(keyName);
        return jsi::Value::undefined();
    });
    jsiRuntime.global().setProperty(jsiRuntime, "mmkvDelete", std::move(mmkvDelete));


    // MMKV.getAllKeys()
    auto mmkvGetAllKeys = jsi::Function::createFromHostFunction(jsiRuntime,
                                                                jsi::PropNameID::forAscii(jsiRuntime, "mmkvGetAllKeys"),
                                                                0,
                                                                [](jsi::Runtime& runtime, const jsi::Value& thisValue, const jsi::Value* arguments, size_t count) -> jsi::Value {
        auto keys = MMKV::defaultMMKV()->allKeys();
        return jsi::Value(convertNSArrayToJSIArray(runtime, keys));
    });
    jsiRuntime.global().setProperty(jsiRuntime, "mmkvGetAllKeys", std::move(mmkvGetAllKeys));
}

- (void)setBridge:(RCTBridge *)bridge
{
    _bridge = bridge;
    _setBridgeOnMainQueue = RCTIsMainQueue();

    RCTCxxBridge *cxxBridge = (RCTCxxBridge *)self.bridge;
    if (!cxxBridge.runtime) {
        return;
    }

    MMKV::defaultMMKV()->initializeMMKV(nil);
    install(*(jsi::Runtime *)cxxBridge.runtime);
}

- (void)invalidate {
    MMKV::defaultMMKV()->close();
}

@end