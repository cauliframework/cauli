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

class MappingsListDatasource: NSObject, UITableViewDataSource {
    
    private let mapRemoteFloret: MapRemoteFloret
    private let mappings: [Mapping]
    
    init(mapRemoteFloret: MapRemoteFloret, mappings: [Mapping]) {
        self.mapRemoteFloret = mapRemoteFloret
        self.mappings = mappings
    }
    
    func setup(_ tableView: UITableView) {
        let bundle = Bundle(for: SwitchTableViewCell.self)
        tableView.register(UINib(nibName: SwitchTableViewCell.nibName, bundle: bundle), forCellReuseIdentifier: SwitchTableViewCell.reuseIdentifier)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mappings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.reuseIdentifier, for: indexPath) as! SwitchTableViewCell
        let mapping = mappings[indexPath.row]
        cell.set(title: mapping.name, switchValue: mapRemoteFloret.isMappingEnabled(mapping), description: nil)
        cell.switchValueChanged = { [weak mapRemoteFloret] newValue in
            mapRemoteFloret?.setMapping(mapping, enabled: newValue)
        }
        return cell
    }
}
