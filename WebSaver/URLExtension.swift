//
//  URLExtension.swift
//  WebSaver
//
//  Created by linhty on 10/5/20.
//  Copyright © 2020 Rin. All rights reserved.
//

import Foundation

extension URL {
    static func documentURL() -> URL {
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return URL(string: documentsDirectory)!
    }
}
