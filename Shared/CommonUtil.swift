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

class CommonCode {
    let groupKeys: String
    let theDataKey: String
    public var allIntentDataKeys = ["RecordDisplayIntent",
                                    "RecordEndIntent",
                                    "RecordNaiLeftStartIntent",
                                    "RecordNaiRightStartIntent",
                                    "RecordNormalStartIntent",
                                    "RecordPauseIntent",
                                    "RecordResumeIntent"]
    var initDate : Date
    
    init() {
        groupKeys = "group.com.zzq.record"
        theDataKey = "theDatas"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZ"
        let date = dateFormatter.date(from: "2022-03-14 12:35:00 UTC")
        initDate = date!
        
        if getDataByUserDefault().count == 0 {
            var theDefault = Dictionary<String,Array<UInt32>>.init()
            for key in allIntentDataKeys {
                theDefault[key] = Array<UInt32>.init()
            }
            setDataByUserDefault(value: theDefault)
        }
    }
    
    static let instance = CommonCode.init()
    class func shared() -> CommonCode {
        return instance
    }
    func setRecord(action: String) {
        let dbData = getDataByUserDefault()
        var dic = Dictionary<String,Array<UInt32>>.init()
        for (key,value) in dbData {
            var arr = Array<UInt32>.init()
            let cacheArr = value
            for time in cacheArr {
                arr.append(time)
            }
            if action == key {
                let now = Date();
                let time = UInt32(now.timeIntervalSince(initDate))
                arr.append(time)
            }
            dic[key]=arr
        }
        setDataByUserDefault(value: dic)
    }
    
    func clearAllRecord() {
        let group = UserDefaults.init(suiteName: groupKeys)
        group?.removeObject(forKey: theDataKey)
        group?.synchronize()
    }
    
    func setDataByUserDefault(value:Dictionary<String,Array<UInt32>>) {
        let group = UserDefaults.init(suiteName: groupKeys)
        group?.set(value, forKey: theDataKey)
        group?.synchronize()
    }
    func getDataByUserDefault() -> Dictionary<String,Array<UInt32>> {
        let group = UserDefaults.init(suiteName: groupKeys)
        let result = group?.dictionary(forKey: theDataKey)
        if result?.count ?? 0 > 0 {
            return result as!  Dictionary<String, Array<UInt32>>
        }
        return Dictionary<String, Array<UInt32>>.init()
    }
    
    /**
     业务数据格式:
     [
     //ActionRecord
        name
        cost:xx,start:xx // RecordPeriodItem
     ]
     */
    func getNaiRecord() -> Array<ActionRecord> {
        let dbData = getDataByUserDefault()
        /**
         左边开始，右边开始 为开始事件
         结束
         */
        var result = Array<ActionRecord>.init()
        
        //喂奶
        //平铺结束时间
        var endPlatTimes = Array<UInt32>.init()
        for endKey in periodEndKeys {
            for endTime in dbData[endKey] ?? [] {
                endPlatTimes.append(endTime)
            }
        }
        var sortedEndPlatTimes = endPlatTimes.sorted()
        var aStartItems = Array<RecordPeriodNaiItem>.init()
        for (keyIndex, startKey) in periodStartKeys.enumerated() {
            let startTimes = dbData[startKey]
            for startTime in startTimes ?? [] {
                for (index, endTime) in sortedEndPlatTimes.enumerated() {
                    if endTime > startTime {
                        let recordItem = RecordPeriodNaiItem.init(beginForLeft: true)
                        recordItem.startTime = startTime
                        recordItem.cost = endTime - startTime
                        recordItem.leftOrRight = keyIndex == 0
                        aStartItems.append(recordItem)
                        sortedEndPlatTimes.remove(at: index)
                        break
                    }
                }
            }
        }
        aStartItems.sort { (item1, item2) -> Bool in
            return item1.startTime < item2.startTime
        }
        let record = ActionRecord.init(name: "喂奶", recordTimes: aStartItems)
        result.append(record)
        return result
    }
    
    /// 字符串转换为类
    ///
    /// - Parameter className: 类名字符串
    /// - Returns: 类对象
    func stringClassObjectFromString(className: String) -> INIntent! {
        
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
    
    func convertDBTimeToDate(time: UInt32) -> Date {
        let result = Date.init(timeInterval: TimeInterval(time), since: initDate)
        return result
    }
    
    func convertDBTimeToDateStr(time: UInt32) -> String {
        let date = convertDBTimeToDate(time: time)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: 8*60*60)
        let result = formatter.string(from: date)
        return result
    }
    
    func convertTimeFromDate(date : Date) -> UInt32 {
        return UInt32(date.timeIntervalSince(initDate))
    }
    
}
