//
//  DownloadView.swift
//  WebSaver
//
//  Created by linhty on 10/5/20.
//  Copyright © 2020 Rin. All rights reserved.
//

import SwiftUI
import Combine
import WebKit

struct DownloadView: View {
    var chapterList: [ChapterInfor] = []
    let name: String
    @State var currentIndex = 0
    @State var currentImage: String = ""
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Spacer()
                TextField("Detail Link", text: Binding<String>.constant(chapterList[currentIndex].url))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.webSearch)
                    .autocapitalization(.none)
                    .truncationMode(.middle)
                    .font(Font.system(size: 12))
                Spacer()
                //                Button(action: {
                //                    if self.url != self.contentLink {
                //                        self.chapterList.removeAll()
                //                    }
                //                    self.contentLink = self.url
                //                }, label: {
                //                    Text("Go")
                //                        .foregroundColor(.white)
                //                        .padding()
                //                        .font(Font.system(size: 12))
                //                })
                //                    .frame(width: 100, height: 32)
                //                    .background(Color(red: 1.0, green: 0.0, blue: 0.0))
                //                    .cornerRadius(8)
                //                Spacer()
            }
            Spacer()
            Text(name + " " + currentImage).foregroundColor(Color.blue)
                .font(Font.system(size: 12))
            Divider()
            DownloadWebView(name: self.name, chapters: chapterList, currentDownload: self.$currentIndex, webTitle: self.$currentImage)
        }
    }
}

struct DownloadView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadView(chapterList: [ChapterInfor(title: "Chap 1", url: "http://www.mangago.me/read-manga/deadlock/an/ibx_chapter-35.1/pg-1/")], name: "MangaGo", currentIndex: 0)
    }
}

struct DownloadWebView: UIViewRepresentable {
    let name: String
    var chapters: [ChapterInfor]
    @Binding var currentDownload: Int
    //    @Binding var currentDownload: Int {
    //        didSet {
    //            let dataPath = URL.documentURL().appendingPathComponent(name)
    //            let subFolder = dataPath.appendingPathComponent(chapters[currentDownload].title)
    //            if !FileManager.default.fileExists(atPath: subFolder.absoluteString) {
    //                do {
    //                    try FileManager.default.createDirectory(atPath: subFolder.absoluteString, withIntermediateDirectories: true, attributes: nil)
    //                } catch {
    //                    print(error.localizedDescription);
    //                }
    //            }
    //        }
    //    }
    
    @Binding var webTitle: String
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self.makeCoordinator(), name: "iOSNative")
        //        configuration.allowsInlineMediaPlayback = true
        //        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.preferences = preferences
        
        let webview = WKWebView(frame: .zero, configuration: configuration)
        webview.navigationDelegate = context.coordinator
        return webview
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.curPage == 0, context.coordinator.stopLoad == false {
            let urlStr = chapters[currentDownload].url
            if let url = URL(string: urlStr) {
                let request = URLRequest(url: url)
                uiView.load(request)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: DownloadWebView
        var webViewNavigationSubscriber: AnyCancellable? = nil
        var pageLinks: [String] = []
        var curPage = 0
        var stopLoad = false
        var recordFolder: URL? {
            let dataPath = URL.documentURL().appendingPathComponent(parent.name)
            var pathComponent = self.parent.chapters[self.parent.currentDownload].title + "_(\(self.pageLinks.count)_pages)"
            if self.parent.chapters[self.parent.currentDownload].isRaw {
                pathComponent = "Raw_" + pathComponent
            }
            return dataPath.appendingPathComponent(pathComponent)
        }
        
        init(_ uiWebView: DownloadWebView) {
            self.parent = uiWebView
            let dataPath = URL.documentURL().appendingPathComponent(uiWebView.name)
            if !FileManager.default.fileExists(atPath: dataPath.absoluteString) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error.localizedDescription);
                }
            }
        }
        
        deinit {
            self.stopLoad = true
            webViewNavigationSubscriber?.cancel()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Page loaded so no need to show loader anymore
            //            self.parent.viewModel.showLoader.send(false)
            guard self.stopLoad == false else {
                return
            }
            
            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()",
                                       completionHandler: { (html: Any?, error: Error?) in
                                        guard let htmlString = html as? String else {
                                            return
                                        }
                                        if let title = htmlString.childElementWith(startId: "<title>", endId: "</title>") {
                                            self.parent.webTitle = title.replacingOccurrences(of: "<title>", with: "").replacingOccurrences(of: "</title>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                        }
                                        
                                        if self.curPage == 0 {
                                            // Get pageList
                                            self.pageLinks.removeAll()
                                            if var listPages = htmlString.childElementWith(startId: "<ul id=\"dropdown-menu-page", endId: "</ul>") {
                                                var range = listPages.range(of: "href=\"")
                                                while range != nil {
                                                    listPages = String(listPages.suffix(from: range!.upperBound))
                                                    if let endRange = listPages.range(of: "\">") {
                                                        let link = "https://www.mnggo.net" + String(listPages.prefix(upTo: endRange.lowerBound))
                                                        self.pageLinks.append(link)
                                                    }
                                                    range = listPages.range(of: "href=\"")
                                                }
                                            }
                                            
                                            // Record folder
                                            if self.pageLinks.count > 0 {
                                                let subFolder = self.recordFolder!
                                                if !FileManager.default.fileExists(atPath: subFolder.absoluteString) {
                                                    do {
                                                        try FileManager.default.createDirectory(atPath: subFolder.absoluteString, withIntermediateDirectories: true, attributes: nil)
                                                    } catch {
                                                        print(error.localizedDescription);
                                                    }
                                                }
                                            }
                                        } else {
                                            if let currentLink = self.getCurrentAndNextImageLink(htmlString), let url = URL(string: currentLink) {
                                                self.downloaded(from: url, index: self.curPage)
                                            } else {
                                                print("Canvas image at page \(self.parent.webTitle)")
                                                let javaStr = "var canvas = document.getElementsByClassName(\"canvas\");var image = new Image();image.src = canvas.toDataURL(\"image/png\");return image.src;"
                                                webView.evaluateJavaScript("document.getElementsByClassName('canvas')[0].toString()",
                                                completionHandler: { (html: Any?, error: Error?) in                                        guard let htmlString2 = html as? String else {
                                                    return
                                                    
                                                }
                                                        print(htmlString2)
                                                })
                                                // Check to next chapter
                                                if self.curPage == self.pageLinks.count {
                                                    self.curPage = 0
                                                    if self.parent.currentDownload < self.parent.chapters.count - 1 {
                                                        self.parent.currentDownload += 1
                                                    } else {
                                                        self.stopLoad = true
                                                    }
                                                    return
                                                }
                                            }
                                        }
                                        
                                        if self.curPage < self.pageLinks.count {
                                            if let url = URL(string: self.pageLinks[self.curPage]) {
                                                self.curPage += 1
                                                let request = URLRequest(url: url)
                                                webView.load(request)
                                            }
                                        }
            })
        }
        
        func getCurrentAndNextImageLink(_ inHtml: String) -> String? {
            let imageTag = "<img id=\"page\(curPage)"
            var imageLink = inHtml.childElementWith(startId: imageTag, endId: ">")
            imageLink = imageLink?.childElementWith(startId: "src=\"", endId: "\">")
            imageLink = imageLink?.replacingOccurrences(of: "src=\"", with: "").replacingOccurrences(of: "\">", with: "")
            //            if let range = imageLink?.range(of: "?") {
            //                imageLink = String(imageLink?.prefix(upTo: range.lowerBound) ?? "")
            //            }
            return imageLink?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        func downloaded(from url: URL, index: Int) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data, error == nil,
                    let _ = UIImage(data: data)
                    else {
                        // Check to next chapter
                        print("Error download image \(error?.localizedDescription ?? "")")
                        if index == self.pageLinks.count {
                            self.curPage = 0
                            if self.parent.currentDownload < self.parent.chapters.count - 1 {
                                self.parent.currentDownload += 1
                            } else {
                                self.stopLoad = true
                            }
                        }
                        
                        return
                }
                
                let imageExt = url.pathExtension
                if let writeURL = self.recordFolder?.appendingPathComponent(String(format: "%03d.\(imageExt)", index)) {
                    do {
                        let fileURL = URL(fileURLWithPath: writeURL.absoluteString)
                        try data.write(to: fileURL)
                    } catch {
                        print("Error download image \(error.localizedDescription)");
                    }
                    
                    // Check to next chapter
                    if index == self.pageLinks.count {
                        self.curPage = 0
                        if self.parent.currentDownload < self.parent.chapters.count - 1 {
                            self.parent.currentDownload += 1
                        } else {
                            self.stopLoad = true
                        }
                    }
                }
            }.resume()
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
            decisionHandler(.allow)
        }
    }
}

extension DownloadWebView.Coordinator: WKScriptMessageHandler {
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
