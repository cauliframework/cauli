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

import Foundation

class RecordTableViewDatasource: NSObject {

    let sections: [Section]

    init(_ sections: [Section]) {
        self.sections = sections
        super.init()
    }

    convenience init(_ record: Record) {
        let requestSection = Section(record.designatedRequest)
        let responseSection = Section(record.result)
        self.init([requestSection, responseSection])
    }

    func setup(_ tableView: UITableView) {
        tableView.register(RecordItemTableViewCell.self, forCellReuseIdentifier: RecordItemTableViewCell.reuseIdentifier)
    }

}

extension RecordTableViewDatasource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecordItemTableViewCell.reuseIdentifier, for: indexPath) as! RecordItemTableViewCell
        let item = sections[indexPath.section].items[indexPath.row]

        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.description
        cell.detailTextLabel?.numberOfLines = 15

        if item.value == nil {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
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
        let value: Any?
    }
}

extension RecordTableViewDatasource.Item {
    init(title: String, description: String) {
        self.init(title: title, description: description, value: nil)
    }
}

extension RecordTableViewDatasource.Section {

    init(_ request: URLRequest) {
        var requestItems: [RecordTableViewDatasource.Item] = []
        requestItems.append(RecordTableViewDatasource.Item(title: "Method", description: request.httpMethod ?? "-"))
        requestItems.append(RecordTableViewDatasource.Item(title: "URL", description: request.url?.absoluteString ?? "-"))
        requestItems.append(RecordTableViewDatasource.Item(title: "Header Fields", description: request.allHTTPHeaderFields?.compactMap { key, value in
            "\(key) : \(value)"
        }.joined(separator: "\n") ?? "-", value: request.allHTTPHeaderFields))
        requestItems.append(RecordTableViewDatasource.Item(title: "Body", description: "\(request.httpBody?.count ?? 0) bytes", value: request.httpBody))
        self.init(title: "Request", items: requestItems)
    }

    init(_ result: Result<Response>?) {
        var resultItems: [RecordTableViewDatasource.Item] = []
        switch result {
        case .error(let error)?:
            resultItems.append(RecordTableViewDatasource.Item(title: "Error", description: error.localizedDescription))
        case .result(let response)?:
            resultItems.append(RecordTableViewDatasource.Item(title: "URL", description: response.urlResponse.url?.absoluteString ?? "-"))
            if let httpUrlResponse = response.urlResponse as? HTTPURLResponse {
                resultItems.append(RecordTableViewDatasource.Item(title: "Header Fields", description: httpUrlResponse.allHeaderFields.compactMap { key, value in
                    "\(key) : \(value)"
                }.joined(separator: "\n"), value: httpUrlResponse.allHeaderFields))
                resultItems.append(RecordTableViewDatasource.Item(title: "Status Code", description: "\(httpUrlResponse.statusCode)"))
            }
            resultItems.append(RecordTableViewDatasource.Item(title: "Body", description: "\(response.data?.count ?? 0) bytes", value: response.data))
        case .none: break
        }
        self.init(title: "Response", items: resultItems)
    }

}
