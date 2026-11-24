//
//  Copyright (c) 2018 cauli.works
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

internal class RecordTableViewDatasource: NSObject {

    let sections: [Section]

    init(_ sections: [Section]) {
        self.sections = sections
        super.init()
    }

    convenience init(_ record: Record) {
        let requestSection = Section(record.designatedRequest)
        let responseSection = Section(record.result, metrics: record.metrics)
        self.init([requestSection, responseSection])
    }

    func setup(_ tableView: UITableView) {
        tableView.register(RecordItemTableViewCell.self, forCellReuseIdentifier: RecordItemTableViewCell.reuseIdentifier)
    }

    func item(at indexPath: IndexPath) -> Item? {
        guard indexPath.section < sections.count,
            indexPath.row < sections[indexPath.section].items.count else { return nil }
        return sections[indexPath.section].items[indexPath.row]
    }

}

extension RecordTableViewDatasource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecordItemTableViewCell.reuseIdentifier, for: indexPath)
        guard let recordItemCell = cell as? RecordItemTableViewCell else { return cell }

        if let item = item(at: indexPath) {
            recordItemCell.textLabel?.text = item.title
            recordItemCell.detailTextLabel?.text = item.description
            recordItemCell.detailTextLabel?.numberOfLines = item.numberOfLines
            recordItemCell.detailTextLabel?.lineBreakMode = .byTruncatingTail

            if item.value != nil {
                recordItemCell.accessoryType = .disclosureIndicator
            } else {
                recordItemCell.accessoryType = .none
            }
        }

        return recordItemCell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }
}

extension RecordTableViewDatasource {

    struct Section {
        let title: String
        let items: [Item]
    }

    struct Item {
        let title: String
        let description: String
        let value: (() -> (Any))?
        /// The maximum number of lines of the description in the list.
        var numberOfLines = 15
    }
}

// swiftlint:disable trailing_closure
extension RecordTableViewDatasource.Item {
    init(title: String, description: String) {
        self.init(title: title, description: description, value: nil)
    }
    static func forBody(in response: Response) -> RecordTableViewDatasource.Item {
        RecordTableViewDatasource.Item(title: "Body", description: bodyDescription(for: response.data), value: {
            guard let data = response.data else { return nil as URL? as Any }
            let fileName = response.urlResponse.suggestedFilename ?? UUID().uuidString
            let tmpFolder = URL(fileURLWithPath: NSTemporaryDirectory())
            let filePath = tmpFolder.appendingPathComponent(fileName)
            do {
                try data.write(to: filePath)
                return filePath
            } catch {
                return nil as URL? as Any
            }
        }, numberOfLines: bodyNumberOfLines)
    }

    /// The size line and up to five lines of the body preview.
    static let bodyNumberOfLines = 6

    /// The size of a body and, if it is text, a preview of its beginning.
    static func bodyDescription(for body: Data?) -> String {
        let size = "\(body?.count ?? 0) bytes"
        guard let preview = BodyPreview.preview(of: body) else { return size }
        return "\(size)\n\(preview)"
    }
}

extension RecordTableViewDatasource.Section {

    init(_ request: URLRequest) {
        var requestItems: [RecordTableViewDatasource.Item] = []
        requestItems.append(RecordTableViewDatasource.Item(title: "Method", description: request.httpMethod ?? "-"))
        requestItems.append(RecordTableViewDatasource.Item(title: "URL", description: request.url?.absoluteString ?? "-"))
        requestItems.append(RecordTableViewDatasource.Item(title: "Header Fields", description: request.allHTTPHeaderFields?.compactMap { key, value in "\(key): \(value)" }
            .joined(separator: "\n") ?? "-", value: { request.allHTTPHeaderFields }))
        requestItems.append(RecordTableViewDatasource.Item(title: "Body", description: RecordTableViewDatasource.Item.bodyDescription(for: request.httpBody), value: { request.httpBody }, numberOfLines: RecordTableViewDatasource.Item.bodyNumberOfLines))
        requestItems.append(RecordTableViewDatasource.Item(title: "Cache Policy", description: String(request.cachePolicy.rawValue)))
        let cURLCommand = request.cURLCommand
        requestItems.append(RecordTableViewDatasource.Item(title: "cURL", description: cURLCommand, value: { cURLCommand }))
        self.init(title: "Request", items: requestItems)
    }

    init(_ result: Result<Response>?, metrics: TransferMetrics? = nil) {
        var resultItems: [RecordTableViewDatasource.Item] = []
        switch result {
        case .error(let error)?:
            resultItems.append(RecordTableViewDatasource.Item(title: "Error", description: error.localizedDescription))
        case .result(let response)?:
            resultItems.append(RecordTableViewDatasource.Item(title: "URL", description: response.urlResponse.url?.absoluteString ?? "-", value: { response.urlResponse.url }))
            if let httpUrlResponse = response.urlResponse as? HTTPURLResponse {
                resultItems.append(RecordTableViewDatasource.Item(title: "Header Fields", description: httpUrlResponse.allHeaderFields.compactMap { key, value in
                    "\(key): \(value)"
                }
                    .joined(separator: "\n"), value: { httpUrlResponse.allHeaderFields }))
                resultItems.append(RecordTableViewDatasource.Item(title: "Status Code", description: "\(httpUrlResponse.statusCode)"))
            }
            resultItems.append(RecordTableViewDatasource.Item.forBody(in: response))
        case .none: break
        }
        if let metrics = metrics {
            resultItems.append(RecordTableViewDatasource.Item(title: "Transfer", description: metrics.inspectorDescription))
        }
        self.init(title: "Response", items: resultItems)
    }

}
// swiftlint:enable trailing_closure

extension TransferMetrics {
    /// E.g. "12.4 KB received over the network, 48 KB decoded\n640 bytes sent · h2 · reused connection · 182 ms"
    var inspectorDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let received: String
        if isFromCache {
            received = "Loaded from the cache"
        } else if responseBodyBytesDecoded != responseBodyBytes {
            received = "\(formatter.string(fromByteCount: receivedBytes)) received over the network, \(formatter.string(fromByteCount: responseBodyBytesDecoded)) decoded"
        } else {
            received = "\(formatter.string(fromByteCount: receivedBytes)) received over the network"
        }
        let details = [
            "\(formatter.string(fromByteCount: sentBytes)) sent",
            networkProtocol,
            tlsVersion,
            isReusedConnection ? "reused connection" : "new connection",
            "\(Int((duration * 1_000).rounded())) ms"
        ].compactMap { $0 }
        return received + "\n" + details.joined(separator: " · ")
    }
}
