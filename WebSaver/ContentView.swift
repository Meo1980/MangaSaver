//
//  ContentView.swift
//  WebSaver
//
//  Created by linhty on 9/11/20.
//  Copyright © 2020 Rin. All rights reserved.
//

import SwiftUI
import Combine
import WebKit

struct ContentView: View {
    @State var url: String
    @State var contentLink: String = ""
    @State var isShowError: Bool = false
    @State var webError: String = ""
    @State var chapterList: [ChapterInfor] = []
    @State var storyName: String = ""
    
    @State var startIndex: String = "0"
    @State var count: String = "0"

    var body: some View {
        NavigationView {
            VStack {
                HStack(alignment: .center) {
                    Spacer()
                    TextField("MangaGo", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.webSearch)
                        .autocapitalization(.none)
                        .truncationMode(.middle)
                        .font(Font.system(size: 12))
                    Spacer()
                    Button(action: {
                        if self.url != self.contentLink {
                            self.chapterList.removeAll()
                            self.startIndex = "0"
                            self.count = "0"
                        }
                        self.contentLink = self.url
                    }, label: {
                        Text("Go")
                            .foregroundColor(.white)
                            .padding()
                            .font(Font.system(size: 12))
                    })
                        .frame(width: 100, height: 32)
                        .background(Color(red: 1.0, green: 0.0, blue: 0.0))
                        .cornerRadius(8)
                    Spacer()
                }
                Divider()
                ZStack {
                    MyWebView(urlString: contentLink, errorMsg: self.$webError, chapterList: self.$chapterList, webTitle: self.$storyName)
                        .alert(isPresented: Binding<Bool>.constant(!self.webError.isEmpty)) { () -> Alert in
                            return Alert(title: Text("Wrong site"), message: Text(webError), dismissButton: .default(Text("OK")))
                    }.opacity(chapterList.count > 0 ? 0 : 1)
                    
                    VStack {
                        HStack(alignment: .center) {
                            Spacer()
//                            Button(action: {
//                                self.chapterList.forEach { (chapter) in
//                                    chapter.isSelect = true
//                                }
//                            }, label: {
//                                Text("Select All")
//                                    .foregroundColor(.white)
//                                    .padding()
//                                    .font(Font.system(size: 12))
//                            })
//                                .frame(width: 120, height: 32)
//                                .background(Color(red: 0.0, green: 0.5, blue: 0.5))
//                                .cornerRadius(8)
                            TextField("Start Index", text: $startIndex)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .autocapitalization(.none)
                                .truncationMode(.middle)
                                .font(Font.system(size: 12))
                            Spacer()
//                            Button(action: {
//                                self.chapterList.forEach { (chapter) in
//                                    chapter.isSelect = false
//                                }
//                            }, label: {
//                                Text("Deselect All")
//                                    .foregroundColor(.white)
//                                    .padding()
//                                    .font(Font.system(size: 12))
//                            })
//                                .frame(width: 120, height: 32)
//                                .background(Color(red: 0.0, green: 0.5, blue: 0.5))
//                                .cornerRadius(8)
                            TextField("Count", text: $count)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .autocapitalization(.none)
                                .truncationMode(.middle)
                                .font(Font.system(size: 12))
                            Spacer()
                            NavigationLink(destination: DownloadView(chapterList: self.downloadChapters, name: storyName)) {
                                Text("Download")
                                    .foregroundColor(.white)
                                    .padding()
                                    .font(Font.system(size: 12))
                                    .frame(width: 100, height: 32.0)
                                    .background(Color(red: 1.0, green: 0.0, blue: 0.5))
                                    .cornerRadius(8)
                                Spacer()
                            }
                        }
                        Spacer()
                        List(chapterList.enumerated().map({ $0 }), id: \.element.id) { index, chapter in
                            ChapterRow(chapter: chapter, index: index)
                        }
                    }.opacity(chapterList.count > 0 ? 1 : 0)
                }
            }
        }
        .navigationBarTitle("Enter url:")
    }
    
    var downloadChapters: [ChapterInfor] {
        guard self.chapterList.count > 0 else {
            return self.chapterList
        }
        
        let startIndex = Int(self.startIndex) ?? 0
        let count = Int(self.count) ?? 0
        var endIndex = (count <= 0 ? self.chapterList.count : startIndex + count) - 1
        if endIndex < startIndex {
            endIndex = startIndex
        }
        if endIndex >= self.chapterList.count {
            endIndex = self.chapterList.count - 1
        }

        let array = Array(self.chapterList[startIndex...endIndex])
        return array
    }
}

extension View {
    func hideKeyboad() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(url: "http://www.mangago.me/read-manga/deadlock/")
    }
}

struct MyWebView: UIViewRepresentable {
    var urlString: String?
    @Binding var errorMsg: String
    @Binding var chapterList: [ChapterInfor]
    @Binding var webTitle: String
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self.makeCoordinator(), name: "iOSNative")
        configuration.preferences = preferences
        
        let webview = WKWebView(frame: .zero, configuration: configuration)
        webview.navigationDelegate = context.coordinator
        return webview
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let urlStr = urlString, let url = URL(string: urlStr) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MyWebView
        var webViewNavigationSubscriber: AnyCancellable? = nil
        
        init(_ uiWebView: MyWebView) {
            self.parent = uiWebView
        }
        
        deinit {
            webViewNavigationSubscriber?.cancel()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Page loaded so no need to show loader anymore
            //            self.parent.viewModel.showLoader.send(false)
            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()",
                                       completionHandler: { (html: Any?, error: Error?) in
                                        guard var htmlString = html as? String else {
                                            return
                                        }
                                        self.parent.chapterList.removeAll()
                                        if let title = htmlString.childElementWith(startId: "<title>", endId: "</title>") {
                                            self.parent.webTitle = title.replacingOccurrences(of: "<title>", with: "").replacingOccurrences(of: "</title>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                        }
                                        
                                        guard let range = htmlString.range(of: "<h4 class=\"uk-h4\">Chapters") else {
                                            return
                                        }
                                        htmlString = String(htmlString.suffix(from: range.lowerBound))
                                        if let chapterString = htmlString.childElementWith(startId: "<table class=\"uk-table uk-table-small uk-table-justify\">", endId: "</table>") {
                                            self.parent.chapterList.append(contentsOf: self.chapterListFrom(chapterString, isRaw: false))
                                        }
                                        
                                        guard let rawRange = htmlString.range(of: "<h4 class=\"uk-h4\">Raws") else {
                                            return
                                        }
                                        htmlString = String(htmlString.suffix(from: rawRange.lowerBound))
                                        if let rawString = htmlString.childElementWith(startId: "<table class=\"uk-table uk-table-small uk-table-justify\">", endId: "</table>") {
                                            self.parent.chapterList.append(contentsOf: self.chapterListFrom(rawString, isRaw: true))
                                        }
                                        
                                        
            })
        }
        
        func chapterListFrom(_ inHtml: String, isRaw: Bool) -> [ChapterInfor] {
            var outChapters = [ChapterInfor]()
            
            var originHtml = inHtml
            var link = originHtml.childElementWith(startId: "<a ", endId: "</a>")
            while link != nil {
                var url = link?.childElementWith(startId: "href=\"", endId: "\"")
                url = url?.replacingOccurrences(of: "href=\"", with: "")
                url = url?.replacingOccurrences(of: "\"", with: "")
                var title = link?.childElementWith(startId: ">", endId: "<")
                title = title?.replacingOccurrences(of: ">", with: "")
                title = title?.replacingOccurrences(of: "<", with: "")
                title = title?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let url = url {
                    outChapters.append(ChapterInfor(title: title ?? "No Title", url: url, isRaw: isRaw))
                }
                
                originHtml = originHtml.replacingOccurrences(of: link!, with: "")
                link = originHtml.childElementWith(startId: "<a ", endId: "</a>")
            }
            
            return outChapters
        }
        
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        }
        
        // This function is essential for intercepting every navigation in the webview
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Suppose you don't want your user to go a restricted site
            if let host = navigationAction.request.url?.host {
                if !host.contains("mangago.me") {
                    self.parent.errorMsg = "This is not a MangaGo website"
                    decisionHandler(.cancel)
                    return
                }
            }
            
            self.parent.errorMsg = ""
            decisionHandler(.allow)
        }
    }
}

extension MyWebView.Coordinator: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message)
    }
//
//    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        if(challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust)
//        {
//            let cred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
//            completionHandler(.useCredential, cred)
//        }
//        else
//        {
//            completionHandler(.performDefaultHandling, nil)
//        }
//    }
}

class ChapterInfor: Identifiable {
    var id: String {
        return String(isRaw) + title
    }
    
    let title: String
    let url: String
    let isRaw: Bool
    var isSelect: Bool = false
    
    init(title: String, url: String, isRaw: Bool = false, isSelect: Bool = false) {
        self.title = title
        self.url = url
        self.isRaw = isRaw
        self.isSelect = isSelect
    }
    
}



