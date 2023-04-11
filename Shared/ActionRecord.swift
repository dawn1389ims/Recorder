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
//    public func encode(to encoder: Encoder) throws {
//        //
//    }
//    required public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: PersonCodingKey.self)
//        subNote = try container.decode(String.self, forKey: .subNote)
//        startTime = UInt32(try container.decode(Int.self, forKey: .startTime))
//        cost = UInt32(try container.decode(String.self, forKey: .cost)) ?? 0
//        subOtherInfo = try container.decode(Dictionary.self, forKey: .subOtherInfo)
//    }
}

enum PeriodState {
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
    }
    
    public  func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PersonCodingKey.self)
        try container.encode(recordName, forKey: .recordName)
        try container.encode(otherInfo, forKey: .otherInfo)
        try container.encode(content, forKey: .content)
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
        
        return state + String(getCost()/60) + "分钟"
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
