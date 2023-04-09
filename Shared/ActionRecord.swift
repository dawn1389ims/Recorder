//
//  ActionRecord.swift
//  Recoder
//
//  Created by 朱志强 on 2022/3/28.
//

import Foundation
import SwiftUI

public class RecordItem {
    public enum RecordType {
        case PeriodType //时间段，RecordPeriodItem
        case MomentType //时间点
    }
    
    let name: String
    let recordType: RecordType
    let moreInfo: String
    
    enum PersonCodingKey: String, CodingKey {
        case name
        case recordType
        case moreInfo
    }
    
    init() {
        name = ""
        recordType = .PeriodType
        moreInfo = ""
    }
//    required public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: PersonCodingKey.self)
//        name = try container.decode(String.self, forKey: .name)
//        recordType = try container.decode(Int.self, forKey: .recordType)
//        moreInfo = try container.decode(String.self, forKey: .moreInfo)
//    }
}
enum PeriodState {
    case PeriodStateNone
    case PeriodStateStart
    case PeriodStatePause
    case PeriodStateResume
    case PeriodStateFinish
}
protocol PeriodInterfaceProtocol {
    var startTime: UInt32 { get }
    func getCost() -> UInt32
    var periodState: PeriodState { get }
}

protocol PeriodActionProtocol {
    func onStart(arg : String)
    func onPause()
    func onResume()
    func onFinish()
    func onDisplay() -> String
}
/**
 时间段记录的默认实现
 支持根据不同的启动方式扩展实现
 */
public class RecordPeriodItem : RecordItem, PeriodActionProtocol, PeriodInterfaceProtocol {
    
    public var cost: UInt32 = 0
    public var startTime: UInt32 = 0
    var periodState: PeriodState = .PeriodStateNone
    
    private var pauseStartTime: UInt32 = 0
    private var pauseCost: UInt32 = 0
    
    func onStart(arg : String) {
        periodState = .PeriodStateStart
        if startTime == 0 {
            startTime = CommonCode.shared().convertTimeFromDate(date: Date())
        }
    }
    func onPause() {
        if periodState == .PeriodStateNone {
            return
        }
        periodState = .PeriodStatePause
        if pauseStartTime == 0 {
            pauseStartTime = CommonCode.shared().convertTimeFromDate(date: Date())
        }
    }
    func onResume() {
        periodState = .PeriodStateResume
        if pauseStartTime != 0 {
            pauseCost = pauseCost + CommonCode.shared().convertTimeFromDate(date: Date()) - pauseStartTime
            pauseStartTime = 0
        }
    }
    
    func onFinish() {
        periodState = .PeriodStateFinish
        cost = CommonCode.shared().convertTimeFromDate(date: Date()) - startTime - pauseCost
    }
    
    func onDisplay() -> String {
        var state = ""
        let nowTime = CommonCode.shared().convertTimeFromDate(date: Date())
        var costTime : UInt32 = 0
        switch periodState {
        case .PeriodStateNone:
            state = "None"
            costTime = nowTime - startTime - pauseCost
        case .PeriodStateStart:
            state = "开始中"
            costTime = nowTime - startTime - pauseCost
        case .PeriodStatePause:
            state = "暂停中"
            costTime = pauseStartTime - startTime - pauseCost
        case .PeriodStateResume:
            state = "恢复中"
            costTime = nowTime - startTime - pauseCost
        case .PeriodStateFinish:
            state = "结束"
            costTime = cost
        }
        
        return state + String(costTime/60) + "分钟"
    }
    
    func getCost() -> UInt32 {
        return cost
    }
}

/**
 分别为左边，右边记录时间，表现在持久化和展示时
 */
public class RecordPeriodNaiItem : RecordItem, PeriodActionProtocol, PeriodInterfaceProtocol {
    public var startTime: UInt32 = 0
    var periodState: PeriodState = .PeriodStateNone
    
    private var isCurrentLeft: Bool = true
    private var leftPeriodRecord: RecordPeriodItem
    private var rightPeriodRecord: RecordPeriodItem
    
    init(beginForLeft : Bool) {
        leftPeriodRecord = RecordPeriodItem()
        rightPeriodRecord = RecordPeriodItem()
    }
    
    func onStart(arg : String) {
        periodState = .PeriodStateStart
        isCurrentLeft = arg == "左"
        if startTime == 0 {
            startTime = CommonCode.shared().convertTimeFromDate(date: Date())
        }
        if isCurrentLeft == true {
            leftPeriodRecord.onStart(arg: arg)
            rightPeriodRecord.onPause()
        } else {
            rightPeriodRecord.onStart(arg: arg)
            leftPeriodRecord.onPause()
        }
    }
    
    func onPause() {
        periodState = .PeriodStatePause
        let item = isCurrentLeft ? leftPeriodRecord : rightPeriodRecord
        item.onPause()
    }
    
    func onResume() {
        periodState = .PeriodStateResume
        let item = isCurrentLeft ? leftPeriodRecord : rightPeriodRecord
        item.onResume()
    }
    
    func onFinish() {
        periodState = .PeriodStateFinish
        leftPeriodRecord.onFinish()
        rightPeriodRecord.onFinish()
    }
    
    func onDisplay() -> String {
        return "left" + leftPeriodRecord.onDisplay() + ", right" + rightPeriodRecord.onDisplay()
    }
    
    func getCost() -> UInt32 {
        return leftPeriodRecord.cost + rightPeriodRecord.cost
    }
}

public struct ActionRecord {
    public let name: String//记录的内容标题
    public let recordTimes: Array<RecordPeriodNaiItem>//记录的内容，暂时只记录喂奶，后面需要扩展参数类型
    
    public init(name: String, recordTimes: Array<RecordPeriodNaiItem>)  {
        self.name = name
        self.recordTimes = recordTimes
    }
}

