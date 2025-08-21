//
//  ItemInfoView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 23/4/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct ItemInfoView: View {
    let date: String
    let datePublished: String?
    let dateCreated: String?
    let views: String?
    let onlineNum: Int
    let showViewNum: Bool
    var showClosedLock = false
    var isLaunchable = false
    var paddingTop: CGFloat = 8
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if showClosedLock {
                Image(systemName: "lock.fill")
                    .renderingMode(.template)
                    .imageScale(.small)
                    .foregroundColor(Color("PrimaryColor"))
            }
            DateInfo(dateUpdated: date, datePublished: datePublished, dateCreated: dateCreated)
            if showViewNum && views != nil {
                Text(verbatim: "\(views ?? "0")")
                    .font(.system(size: 13))
                    .foregroundColor(Color("GreyFont"))
                    .padding(.leading, 16)
                    .overlay(
                        Image(systemName: "eye")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 9, alignment: .topLeading)
                            .foregroundColor(Color("GreyFont"))
                            .padding(.trailing, 2)
                        , alignment: .leading)
            }
            Spacer()
            //if newsItem.onlineNum != nil && newsItem.onlineNum != 0 {
            if onlineNum > 0 {
                Text("now_reading \(String(onlineNum))")
                    .font(.system(size: 13))
                    .foregroundColor(onlineNum >= 100 ? Color("BlueTint") : Color("PrimaryColor"))
            }
            if isLaunchable {
                Image("launch_link")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundColor(Color("GreyFont"))
                    .frame(width: 18, height: 18)
                    .offset(y: -1)
            }
        }
        .padding(.top, paddingTop)
        .padding(.horizontal, 10)
    }
    struct DateInfo: View {
        let dateUpdated: String
        let datePublished: String?
        let dateCreated: String?
        var body: some View {
            VStack(alignment: .leading, spacing: .zero) {
                Group {
                    if let datePublished = self.datePublished {
                        Text(datePublished)
                        if let dateCreated = self.dateCreated {
                            Text("date_created \(dateCreated)")
                        }
                        Text("date_updated \(dateUpdated)")
                    } else {
                        Text(dateUpdated)
                        if let dateCreated = self.dateCreated {
                            Text("date_created \(dateCreated)")
                        }
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(Color("GreyFont"))
            }
        }
    }
}

struct ItemInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ItemInfoView(date: "18:03, 24.04.2021", datePublished: "8 авг. 2022, 10:26", dateCreated: "8 авг. 2022", views: "10 923", onlineNum: 201, showViewNum: true, showClosedLock: true, isLaunchable: true)
            //.preferredColorScheme(.dark)
    }
}
