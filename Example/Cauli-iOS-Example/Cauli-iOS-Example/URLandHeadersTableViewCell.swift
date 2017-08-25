//
//  URLandHeadersTableViewCell.swift
//  TestApplication
//
//  Created by Pascal Stüdlein on 23.07.17.
//  Copyright © 2017 HTW Berlin. All rights reserved.
//

import UIKit

class URLandHeadersTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var headers: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func set(request: URLRequest?) {
        guard let request = request else { return }
        urlLabel.text = request.url!.absoluteString
        headers.text = (request.allHTTPHeaderFields ?? [:]).map({ "\($0)=\($1)" }).joined(separator: ", ")
    }
    
    func set(response: URLResponse?) {
        guard let response = response as? HTTPURLResponse else { return }
        urlLabel.text = response.url!.absoluteString
        headers.text = (response.allHeaderFields).map({ "\($0)=\($1)" }).joined(separator: ", ")
    }
}
