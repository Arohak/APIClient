//
//  DetailTabView.swift
//
//
//  Copyright © 2025 Ara Hakobyan. All rights reserved.
//

import Foundation
import SwiftUI

struct DetailTabView: View {
    let tab: DetailTab
    let model: Model

    var body: some View {
        switch tab {
        case .info: infoView
        case .request: requestView
        case .response: responseView
        }
    }

    var infoView: some View {
        VStack(alignment: .leading) {
            TabInfoRow(title: "URL", desc: model.url)
            TabInfoRow(title: "Method", desc: model.method)
            TabInfoRow(title: "Status", desc: "\(model.code)")
            TabInfoRow(title: "Time", desc: model.date.stringWithFormat(dateFormat: "MMM d yyyy - HH:mm:ss")!)
            TabInfoRow(title: "Duration", desc: model.duration?.formattedMilliseconds() ?? "")

            Spacer()
        }
        .padding()
    }

    var requestView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TabTitleRow(headers: model.request.allHTTPHeaderFields, data: model.request.httpBody)
                Spacer()
            }
        }
        .cornerRadius(10)
        .padding(.top, 20)
        .padding(.horizontal, 30)
    }

    var responseView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TabTitleRow(headers: model.responseHeaders, data: model.data)
                Spacer()
            }
        }
        .cornerRadius(10)
        .padding(.top, 20)
        .padding(.horizontal, 30)
    }
}

struct DetailTabView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DetailTabView(tab: .info, model: .mock)
            DetailTabView(tab: .request, model: .mock)
            DetailTabView(tab: .response, model: .mock)
        }
    }
}

struct TabInfoRow: View {
    let title: String
    let desc: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("[\(title)]")
                .font(.system(size: 16, weight: .bold))
            Text(desc)
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
        .padding(.bottom, 5)
    }
}

struct TabTitleRow: View {
    let headers: [String: String]?
    let data: Data?

    var body: some View {
        VStack(alignment: .leading) {
            Text("-- Headers --")
                .font(.title)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
                .padding()

            Text(attributedString(from: headers))
                .textSelection(.enabled)

            Text("-- Body --")
                .font(.title)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
                .padding()

            Text(string(from: data))
                .font(.footnote)
                .textSelection(.enabled)
        }
        .padding(.bottom, 5)
    }

    private func attributedString(from dict: [String: String]?) -> AttributedString {
        guard let dict = dict else {
            return AttributedString("-")
        }
        var result = AttributedString()
        for (key, value) in dict {
            var item = AttributedString("[\(key)]\n\(value)\n\n")
            if let range = item.range(of: "[\(key)]") {
                item[range].font = .boldSystemFont(ofSize: 16)
            }
            if let range = item.range(of: "\(value)") {
                item[range].font = .footnote
            }
            result += item
        }
        return result
    }

    private func string(from body: Data?) -> String {
        if let body = body, let json = try? JSONSerialization.jsonObject(with: body, options: []),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let string = String(data: jsonData, encoding: .utf8)
        {
            return string
        }
        return "-"
    }
}
