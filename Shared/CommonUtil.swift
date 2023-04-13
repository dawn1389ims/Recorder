//
//  CommonUtil.swift
//  Recoder
//
//  Created by 朱志强 on 2022/3/26.
//

import Foundation
import Dispatch
import Intents
import UIKit
let groupKeys = "group.com.zzq.record"
let theDataKey = "theDatas"
let DisplayKeyWord = "RecordDisplayIntent"
let EndKeyWord = "RecordEndIntent"
let StartKeyWord = "RecordStartIntent"
let NormalStartKeyWord = "RecordNormalStartIntent"
let PauseKeyWord = "RecordPauseIntent"
let ResumeKeyWord = "RecordResumeIntent"
let initDate = getInitDate()

public func setDataByUserDefault(value:Array<RecordPeriodItem>) {
    let group = UserDefaults.init(suiteName: groupKeys)
    let encoder = JSONEncoder();
    var dbArray = Array<String>.init()
    do {
        var data : Data?
        for item in value {
            try data = encoder.encode(item)
            let string = String(data: data ?? Data(), encoding: .utf8);
            if string?.count ?? 0 > 0 {
                dbArray.append(string!)
            }
        }
    }
    catch let error {
        print("encoder error: ", error)
    }
    group?.set(dbArray, forKey: theDataKey)
    group?.synchronize()
    print("db set: ", dbArray)
}
public func getDataByUserDefault() -> Array<String> {
    let group = UserDefaults.init(suiteName: groupKeys)
    let result = group?.stringArray(forKey: theDataKey)
    print("db get: ", result as Any)
    return result ?? Array<String>.init()
}

/// 字符串转换为类
///
/// - Parameter className: 类名字符串
/// - Returns: 类对象
public func stringClassObjectFromString(className: String) -> INIntent! {
    
    /// 获取命名空间
    let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String;
    
    /// 根据命名空间传来的字符串先转换成anyClass
    let cls: AnyClass = NSClassFromString(namespace + "." + className)!;
    
    // 在这里已经可以return了   返回类型:AnyClass!
    //return cls;
    
    /// 转换成 明确的类
    let vcClass = cls as! INIntent.Type;
    
    /// 返回这个类的对象
    return vcClass.init();
}

public func convertDBTimeToDate(time: UInt32) -> Date {
    let result = Date.init(timeInterval: TimeInterval(time), since: initDate)
    return result
}

public func convertDBTimeToDateStr(time: UInt32) -> String {
    let date = convertDBTimeToDate(time: time)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    formatter.timeZone = TimeZone(secondsFromGMT: 8*60*60)
    let result = formatter.string(from: date)
    return result
}

public func convertTimeFromDate(date : Date) -> UInt32 {
    return UInt32(date.timeIntervalSince(initDate))
}

public func getInitDate()->Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZ"
    let date = dateFormatter.date(from: "2022-03-14 12:35:00 UTC")
    return date!
}

public func timeDisplayFormat(time : UInt32)->String {
    if time >= 60 {
        return  "\(time/60) 分 \(time%60) 秒"
    } else {
        return "\(time) 秒"
    }
}

public func periodStateStr(periodState: PeriodState) -> String {
    var state = ""
    switch periodState {
    case .PeriodStateNone:
        state = "None"
    case .PeriodStateStart:
        state = "开始中"
    case .PeriodStatePause:
        state = "暂停中"
    case .PeriodStateResume:
        state = "恢复中"
    case .PeriodStateFinish:
        state = "结束"
    }
    return state
}
