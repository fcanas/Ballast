//
//  DispatchTime_TimeInterval.swift
//  
//  Created by Fabián Cañas on 10/10/21.
//

import Foundation

// https://stackoverflow.com/questions/47714560/how-to-convert-dispatchtimeinterval-to-nstimeinterval-or-double
extension DispatchTimeInterval {
    func timeInterval() -> TimeInterval? {
        let result: TimeInterval?

        switch self {
        case .seconds(let value):
            result = TimeInterval(value)
        case .milliseconds(let value):
            result = TimeInterval(value) / 1_000
        case .microseconds(let value):
            result = TimeInterval(value) / 1_000_000
        case .nanoseconds(let value):
            result = TimeInterval(value) / 1_000_000_000
        case .never:
            result = nil
        @unknown default:
            fatalError()
        }

        return result
    }
}
