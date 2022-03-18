//
//  NCShareNewUserAddComment.swift
//  Nextcloud
//
//  Created by TSI-mc on 21/06/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//  Copyright © 2021 TSI-mc. All rights reserved.
//

import UIKit
import NCCommunication
import SVGKit

class NCShareNewUserAddComment: UIViewController, UITextViewDelegate, NCShareDetail {

    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var sharingLabel: UILabel!
    @IBOutlet weak var sharingNote: UILabel!
    @IBOutlet weak var noteTextField: UITextView!

    var onDismiss: (() -> Void)?

    public var share: TableShareable!
    public var metadata: tableMetadata!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationTitle()
        guard let headerView = (Bundle.main.loadNibNamed("NCShareAdvancePermissionHeader", owner: self, options: nil)?.first as? NCShareAdvancePermissionHeader) else { return }
        headerContainerView.addSubview(headerView)
        headerView.frame = headerContainerView.frame
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.topAnchor.constraint(equalTo: headerContainerView.topAnchor).isActive = true
        headerView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor).isActive = true
        headerView.leftAnchor.constraint(equalTo: headerContainerView.leftAnchor).isActive = true
        headerView.rightAnchor.constraint(equalTo: headerContainerView.rightAnchor).isActive = true

        headerView.setupUI(with: metadata)

        sharingLabel.text = NSLocalizedString("_sharing_", comment: "")
        sharingNote.text = NSLocalizedString("_share_note_recipient_", comment: "")

        noteTextField.text = share.note
        noteTextField.delegate = self
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        print(#function)
//        share.note = noteTextField.text
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        share.note = noteTextField.text
        onDismiss?()
    }
}
