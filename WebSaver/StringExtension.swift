//
//  StringExtension.swift
//  WebSaver
//
//  Created by linhty on 10/2/20.
//  Copyright © 2020 Rin. All rights reserved.
//

import Foundation

extension String {
    
    func childElementWith(startId: String, endId: String) -> String? {
        guard let range = self.range(of: startId) else {
            return nil
        }
        
        var retStr = String(self.suffix(from: range.lowerBound))
        if startId.contains(endId) {
            let newRet = String(self.suffix(from: range.upperBound))
            if let rangeEnd = newRet.range(of: endId) {
                retStr = startId + String(newRet.prefix(upTo: rangeEnd.upperBound))
            }
        } else {
            if let rangeEnd = retStr.range(of: endId) {
                retStr = String(retStr.prefix(upTo: rangeEnd.upperBound))
            }
        }
        
        return retStr
    }
}
