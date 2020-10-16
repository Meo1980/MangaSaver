//
//  ChapterRow.swift
//  WebSaver
//
//  Created by linhty on 10/5/20.
//  Copyright © 2020 Rin. All rights reserved.
//

import SwiftUI

struct ChapterRow: View {
    var chapter: ChapterInfor {
        didSet {
            self.isSelect = chapter.isSelect
        }
    }
    let index: Int
    @State var isSelect = false {
        didSet {
            chapter.isSelect = isSelect
        }
    }
    var body: some View {
        HStack {
            Text("Index " + String(self.index))
                .frame(width: 100)
            Divider()
            Checkbox(toggle: self.$isSelect, text: (chapter.isRaw ? "Raw " : "") + chapter.title)
            Spacer()            
        }
    }
}

struct ChapterRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChapterRow(chapter: ChapterInfor(title: "Chapter 1", url: "http", isRaw: false), index: 0)
            ChapterRow(chapter: ChapterInfor(title: "Chapter 2", url: "http", isRaw: true), index: 1)
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}

struct Checkbox: View {
    @Binding var toggle: Bool
    var text: String
    var body: some View {
        Button(action: {
            self.toggle = !self.toggle
        }) {
            Image(self.toggle ? "checkbox-on" :  "checkbox-off")
                .renderingMode(.original)
                .resizable()
                .padding(.leading, 10)
                .frame(width: 26.0, height: 16.0)
            Text(text).padding(0)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(red: 0, green: 0, blue: 0, opacity: 0.02))
        .cornerRadius(0)
    }
}
