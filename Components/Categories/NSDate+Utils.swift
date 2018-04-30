//
//  NSDate+Util.swift
//  vk
//
//  Created by Jasf on 30.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc extension NSDate {
    func utils_dayDifferenceFromNow() -> String
    {
        let calendar = NSCalendar.current
        let date = self as Date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        
        if calendar.isDateInYesterday(date) {
            return "yesterday_at_".localized + dateFormatter.string(from:date)
            
        }
        else if calendar.isDateInToday(date) {
            return dateFormatter.string(from:date)
        }
        
        dateFormatter.dateFormat = "dd MMM"
        dateFormatter.locale = Locale.init(identifier: "ru_RU")
        return dateFormatter.string(from:date)
    }
}
