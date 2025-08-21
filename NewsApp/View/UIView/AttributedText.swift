//
//  AttributedText.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 5/5/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct AttributedTextBlock {
    let content: String
    let font: Font?
    let color: Color?
}

struct AttributedText: View {
    var attributedText: NSAttributedString?
    
    private var descriptions: [AttributedTextBlock] = []
    
    init(_ attributedText: NSAttributedString?) {
        self.attributedText = attributedText
        
        self.extractDescriptions()
    }
    
    init(stringKey: String) {
        //self.init(NSAttributedString(htmlString: NSLocalizedString(stringKey, comment: "")))
        self.init(NSAttributedString(string: NSLocalizedString(stringKey, comment: "")))
        //self.init(htmlString: stringKey)
    }
    
    init(htmlString: String) {
        //self.init(NSAttributedString(htmlString: htmlString))
        //self.init(NSAttributedString(string: htmlString))
        self.init(htmlString.htmlToAttributedString)
    }
    
    private mutating func extractDescriptions()  {
        if let text = attributedText {
            text.enumerateAttributes(in: NSMakeRange(0, text.length), options: [], using: { (attribute, range, stop) in
                let substring = (text.string as NSString).substring(with: range)
                let font =  (attribute[.font] as? UIFont).map { Font.custom($0.fontName, size: 20) }//$0.pointSize
                let color = (attribute[.foregroundColor] as? UIColor).map { Color($0) }
                descriptions.append(AttributedTextBlock(content: substring,
                                                        font: font,
                                                        color: color))
            })
        }
    }
    
    var body: some View {
        descriptions.map { description in
            Text(description.content)
                //.font(Font.system(size: 30))
                .font(description.font)
                .foregroundColor(description.color)
        }.reduce(Text("")) { (result, text) in
            result + text
        }
    }
}

struct AttributedText_Previews: PreviewProvider {
    static var previews: some View {
        AttributedText(htmlString: "Hello! <b>World</b>. Click <a href=\"https://newsapp.media\">link</a>")
    }
}
