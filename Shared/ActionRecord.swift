//
//  ActionRecord.swift
//  Recoder
//
//  Created by 朱志强 on 2022/3/28.
//

import Foundation
import SwiftUI

public class RecordItem : Codable {
    
    let subNote: String
    public var startTime: UInt32 = 0
    public var cost: UInt32 = 0
    public var subOtherInfo: Dictionary<String, String> = [:]
    
    enum PersonCodingKey: String, CodingKey {
        case subNote
        case startTime
        case cost
        case subOtherInfo
    }
    
    init() {
        subNote = ""
    }
}

public enum PeriodState : UInt32, Codable{
    case PeriodStateNone
    case PeriodStateStart
    case PeriodStatePause
    case PeriodStateResume
    case PeriodStateFinish
}

protocol PeriodActionProtocol {
    func onStart()
    func onPause()
    func onResume()
    func onFinish()
    func onDisplay() -> String
}

/**
 时间段记录的默认实现
 支持根据不同的启动方式扩展实现
 */
public class RecordPeriodItem : Codable, PeriodActionProtocol {
    
    public var content: Array<RecordItem> = []
    var periodState: PeriodState = .PeriodStateNone
    public var recordName: String = ""
    public var otherInfo: Dictionary<String, String> = [:]
    
    enum PersonCodingKey: String, CodingKey {
        case content
        case periodState
        case recordName
        case otherInfo
    }
    
    init() {

    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PersonCodingKey.self)
        content = try container.decode([RecordItem].self, forKey: .content)
        recordName = try container.decode(String.self, forKey: .recordName)
        otherInfo = try container.decode(Dictionary.self, forKey: .otherInfo)
        periodState = try container.decode(PeriodState.self, forKey: .periodState)
    }
    
    public  func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PersonCodingKey.self)
        try container.encode(recordName, forKey: .recordName)
        try container.encode(otherInfo, forKey: .otherInfo)
        try container.encode(content, forKey: .content)
        try container.encode(periodState, forKey: .periodState)
    }
    
    func onStart() {
        periodState = .PeriodStateStart
        
        let item = RecordItem.init();
        item.startTime = convertTimeFromDate(date: Date());
        content.append(item)
        
    }
    func onPause() {
        if periodState == .PeriodStateNone {
            return
        }
        periodState = .PeriodStatePause
        let currentItem = content.last
        currentItem?.cost = convertTimeFromDate(date: Date())-currentItem!.startTime;
    }
    func onResume() {
        periodState = .PeriodStateResume
        
        let item = RecordItem.init();
        item.startTime = convertTimeFromDate(date: Date());
        content.append(item)
    }
    
    func onFinish() {
        periodState = .PeriodStateFinish
        
        let currentItem = content.last
        currentItem?.cost = convertTimeFromDate(date: Date())-currentItem!.startTime;
    }
    
    func onDisplay() -> String {
        return periodStateStr(periodState: periodState) + timeDisplayFormat(time: getCost())
    }
    
    func getCost() -> UInt32 {
        let nowTime = convertTimeFromDate(date: Date())
        
        var sumCost : UInt32 = 0;
        for item in content {
            sumCost += item.cost
        }
        
        switch periodState {
        case .PeriodStateStart:
            sumCost += nowTime-content.last!.startTime
            break
        case .PeriodStateResume:
            sumCost += nowTime-content.last!.startTime
            break
        default:
            break
        }
        return sumCost
    }
}
