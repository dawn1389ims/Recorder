//
//  RecordController.swift
//  Recoder
//
//  Created by zhiqiang zhu on 2023/4/13.
//

import Foundation
class RecordController {
    
    static private let instance = RecordController.init()
    class func shared() -> RecordController {
        return instance
    }
    
    func getIntentEvent(action: String) {
        print("intent event" + action)
        let records = RecordController.shared().readDBContent()
        
        if action == StartKeyWord {
            
            var res = records
            let newItem = RecordPeriodItem.init()
            newItem.onStart()
            res.append(newItem)
            setDataByUserDefault(value: res)
        } else if action == EndKeyWord || action == PauseKeyWord {
            for item in records.reversed() {
                if item.periodState == .PeriodStateStart || item.periodState == .PeriodStateResume {
                    if action == EndKeyWord {
                        item.onFinish()
                    } else if action == PauseKeyWord {
                        item.onPause()
                    }
                    setDataByUserDefault(value: records)
                    return
                }
            }
        } else if action == ResumeKeyWord {
            for item in records.reversed() {
                if item.periodState == .PeriodStatePause {
                    item.onResume()
                    setDataByUserDefault(value: records)
                    return
                }
            }
        }
    }
    
    func testRecord() {
        getIntentEvent(action: StartKeyWord)
        getIntentEvent(action: EndKeyWord)
    }
    
    public func clearAllRecord() {
        let group = UserDefaults.init(suiteName: groupKeys)
        group?.removeObject(forKey: theDataKey)
        group?.synchronize()
    }
    
    
    public func readDBContent()->Array<RecordPeriodItem> {
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
        return dbArray
    }
}
