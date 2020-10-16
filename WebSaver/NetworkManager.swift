//
//  NetworkManager.swift
//  WebSaver
//
//  Created by linhty on 9/11/20.
//  Copyright © 2020 Rin. All rights reserved.
//

import Foundation

class NetworkManager {
    func fetchData(from urlStr: String) {
//        let url = URL(string: urlStr)
        if let url = URL(string: "http://www.mangago.me/read-manga/falling_in_love_with_the_god_hotei_before_i_die/") {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { data, response, error in
                if error == nil, let data = data {
                    let decoder = JSONDecoder()
                    do {
                        let results = try decoder.decode(Results.self, from: data)
                    } catch {
                        print (error)
                    }
                }
            }
            task.resume()
        }
    }
}
