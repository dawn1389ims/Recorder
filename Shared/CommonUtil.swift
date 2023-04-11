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
let initDate = getInitDate()

class CommonCode {
//    let groupKeys = "group.com.zzq.record"
//    let theDataKey = "theDatas"
    let DisplayKeyWord = "RecordDisplayIntent"
    let EndKeyWord = "RecordEndIntent"
    let StartKeyWord = "RecordStartIntent"
    let NormalStartKeyWord = "RecordNormalStartIntent"
    let PauseKeyWord = "RecordPauseIntent"
    let ResumeKeyWord = "RecordResumeIntent"
    
    var finishRecords : Array<RecordPeriodItem>
    var currentRecord : RecordPeriodItem?
    
    
    init() {
        
        
        //read file
        let dbData = getDataByUserDefault()
        var dbArray = Array<RecordPeriodItem>.init()
        for aString in dbData {
            let decoder = JSONDecoder()
            do {
                try dbArray.append(decoder.decode(RecordPeriodItem.self, from: aString.data(using: .utf8) ?? Data()))
            } catch let error {
                print("decod error: ", error)
            }
        }
        finishRecords = dbArray
    }
    
    static let instance = CommonCode.init()
    class func shared() -> CommonCode {
        return instance
    }
    func getIntentEvent(action: String) {
        if action == StartKeyWord {
            currentRecord = RecordPeriodItem.init()
            currentRecord?.onStart()
        } else if action == EndKeyWord {
            currentRecord?.onFinish()
            
            if (currentRecord != nil) {
                finishRecords.append(currentRecord!)
            }
            currentRecord = nil
            setDataByUserDefault(value: finishRecords)
        } else if action == PauseKeyWord {
            currentRecord?.onPause()
        } else if action == ResumeKeyWord {
            currentRecord?.onResume()
        }
    }
    
    func testRecord() {
        let record = RecordPeriodItem.init()
        record.onStart()
        record.onFinish()
        finishRecords.append(record)
        setDataByUserDefault(value: finishRecords)
    }
}


public func clearAllRecord() {
    let group = UserDefaults.init(suiteName: groupKeys)
    group?.removeObject(forKey: theDataKey)
    group?.synchronize()
}

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
    catch {
        
    }
    group?.set(dbArray, forKey: theDataKey)
    group?.synchronize()
}
public func getDataByUserDefault() -> Array<String> {
    let group = UserDefaults.init(suiteName: groupKeys)
    let result = group?.stringArray(forKey: theDataKey)
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
