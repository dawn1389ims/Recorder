//
//  RecordController.swift
//  Recoder
//
//  Created by zhiqiang zhu on 2023/4/13.
//

import Foundation
class RecordController {
    
    var finishRecords : Array<RecordPeriodItem> = []
    var currentRecord : RecordPeriodItem?
    
    static private let instance = RecordController.init()
    class func shared() -> RecordController {
        return instance
    }
    
    func getIntentEvent(action: String) {
        print("intent event" + action)
        if action == StartKeyWord {
            if currentRecord != nil {
                print("confict exist record \(convertDBTimeToDateStr(time: (currentRecord?.content.first!.startTime)!))")
            }
            currentRecord = RecordPeriodItem.init()
            currentRecord?.onStart()
            finishRecords.append(currentRecord!)
            setDataByUserDefault(value: finishRecords)
        } else if action == EndKeyWord {
            currentRecord?.onFinish()
            currentRecord = nil
            setDataByUserDefault(value: finishRecords)
        } else if action == PauseKeyWord {
            currentRecord?.onPause()
            setDataByUserDefault(value: finishRecords)
        } else if action == ResumeKeyWord {
            currentRecord?.onResume()
            setDataByUserDefault(value: finishRecords)
        }
    }
    
    func testRecord() {
        let record = RecordPeriodItem.init()
        record.onStart()
        record.onFinish()
        finishRecords.append(record)
        setDataByUserDefault(value: finishRecords)
    }
    
    
    public func clearAllRecord() {
        finishRecords.removeAll()
        currentRecord = nil
        
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
        finishRecords = dbArray
        if finishRecords.last?.periodState != .PeriodStateFinish {
            currentRecord = finishRecords.last
        }
        return finishRecords
    }
}
