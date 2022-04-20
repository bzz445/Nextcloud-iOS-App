//
//  NCViewerPDF.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 06/02/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import PDFKit

class NCViewerPDF: UIViewController, NCViewerPDFSearchDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var metadata = tableMetadata()
    var imageIcon: UIImage?

    private var pdfView = PDFView()
    private var thumbnailViewHeight: CGFloat = 70
    private var thumbnailViewWidth: CGFloat = 80
    private var thumbnailPadding: CGFloat = 2
    private var pdfThumbnailScrollView = UIScrollView()
    private var pdfThumbnailView = PDFThumbnailView()
    private var pdfDocument: PDFDocument?
    private let pageView = UIView()
    private let pageViewLabel = UILabel()
    private var filePath = ""

    private var pageViewWidthAnchor: NSLayoutConstraint?
    private var pdfThumbnailScrollViewleadingAnchor: NSLayoutConstraint?
    private var pdfViewleadingAnchor: NSLayoutConstraint?

    // MARK: - View Life Cycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {

        filePath = CCUtility.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView)!
        pdfDocument = PDFDocument(url: URL(fileURLWithPath: filePath))
        let pageCount = CGFloat(pdfDocument?.pageCount ?? 0)

        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.document = pdfDocument
        pdfView.backgroundColor = NCBrandColor.shared.systemBackground
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.displayDirection = CCUtility.getPDFDisplayDirection()
        pdfView.backgroundColor = NCBrandColor.shared.systemBackground
        view.addSubview(pdfView)

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.orientation.isLandscape {
            pdfViewleadingAnchor = pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: thumbnailViewWidth)
        } else {
            pdfViewleadingAnchor = pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0)
        }
        pdfViewleadingAnchor?.isActive = true

        pdfThumbnailScrollView.translatesAutoresizingMaskIntoConstraints = false
        pdfThumbnailScrollView.backgroundColor = .clear
        pdfThumbnailScrollView.showsVerticalScrollIndicator = false
        pdfThumbnailScrollView.isHidden = true
        view.addSubview(pdfThumbnailScrollView)

        NSLayoutConstraint.activate([
            pdfThumbnailScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfThumbnailScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            pdfThumbnailScrollView.widthAnchor.constraint(equalToConstant: thumbnailViewWidth)
        ])
        if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.orientation.isLandscape {
            pdfThumbnailScrollViewleadingAnchor = pdfThumbnailScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0)
            pdfThumbnailScrollView.isHidden = false
        } else {
            pdfThumbnailScrollViewleadingAnchor = pdfThumbnailScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: -self.thumbnailViewWidth)
        }
        pdfThumbnailScrollViewleadingAnchor?.isActive = true

        pdfThumbnailView.translatesAutoresizingMaskIntoConstraints = false
        pdfThumbnailView.pdfView = pdfView
        pdfThumbnailView.layoutMode = .vertical
        pdfThumbnailView.thumbnailSize = CGSize(width: thumbnailViewHeight, height: thumbnailViewHeight)
        pdfThumbnailView.backgroundColor = .clear
        pdfThumbnailScrollView.addSubview(pdfThumbnailView)

        NSLayoutConstraint.activate([
            pdfThumbnailView.topAnchor.constraint(equalTo: pdfThumbnailScrollView.contentLayoutGuide.topAnchor),
            pdfThumbnailView.bottomAnchor.constraint(equalTo: pdfThumbnailScrollView.contentLayoutGuide.bottomAnchor),
            pdfThumbnailView.leadingAnchor.constraint(equalTo: pdfThumbnailScrollView.contentLayoutGuide.leadingAnchor),
            pdfThumbnailView.trailingAnchor.constraint(equalTo: pdfThumbnailScrollView.contentLayoutGuide.trailingAnchor)
        ])
        let contentViewCenterY = pdfThumbnailView.centerYAnchor.constraint(equalTo: pdfThumbnailScrollView.centerYAnchor)
        contentViewCenterY.priority = .defaultLow
        let contentViewHeight = pdfThumbnailView.heightAnchor.constraint(equalToConstant: CGFloat(pageCount * thumbnailViewHeight) + CGFloat(pageCount * thumbnailPadding) + CGFloat(thumbnailViewHeight / 2))
        contentViewHeight.priority = .defaultLow
        NSLayoutConstraint.activate([
            pdfThumbnailView.centerXAnchor.constraint(equalTo: pdfThumbnailScrollView.centerXAnchor),
            contentViewCenterY,
            contentViewHeight
        ])

        pageView.translatesAutoresizingMaskIntoConstraints = false
        pageView.layer.cornerRadius = 10
        pageView.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        view.addSubview(pageView)

        NSLayoutConstraint.activate([
            pageView.topAnchor.constraint(equalTo: pdfView.topAnchor, constant: 5),
            pageView.leftAnchor.constraint(equalTo: pdfView.leftAnchor, constant: 5),
            pageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        pageViewWidthAnchor = pageView.widthAnchor.constraint(equalToConstant: 10)
        pageViewWidthAnchor?.isActive = true

        pageViewLabel.translatesAutoresizingMaskIntoConstraints = false
        pageViewLabel.textAlignment = .center
        pageViewLabel.textColor = .gray
        pageView.addSubview(pageViewLabel)

        NSLayoutConstraint.activate([
            pageViewLabel.topAnchor.constraint(equalTo: pageView.topAnchor),
            pageViewLabel.leftAnchor.constraint(equalTo: pageView.leftAnchor),
            pageViewLabel.rightAnchor.constraint(equalTo: pageView.rightAnchor),
            pageViewLabel.bottomAnchor.constraint(equalTo: pageView.bottomAnchor)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        pdfView.addGestureRecognizer(tapGesture)

        navigationController?.navigationBar.prefersLargeTitles = false

        handlePageChange()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        appDelegate.activeViewController = self
        navigationController?.navigationBar.prefersLargeTitles = false

        NotificationCenter.default.addObserver(self, selector: #selector(favoriteFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterFavoriteFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterDeleteFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renameFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterRenameFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(moveFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMoveFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uploadedFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterUploadedFile), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(viewUnload), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMenuDetailClose), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(searchText), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMenuSearchTextPDF), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(direction(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMenuPDFDisplayDirection), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(goToPage), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMenuGotToPageInPDF), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePageChange), name: Notification.Name.PDFViewPageChanged, object: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "more")!.image(color: NCBrandColor.shared.label, size: 25), style: .plain, target: self, action: #selector(self.openMenuMore))
        navigationItem.title = metadata.fileNameView
    }

    @objc func viewUnload() {

        navigationController?.popViewController(animated: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

        ShowHideThumbnail()
    }

    deinit {
        print("deinit NCViewerPDF")

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterFavoriteFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterDeleteFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterRenameFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMoveFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterUploadedFile), object: nil)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMenuDetailClose), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMenuSearchTextPDF), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMenuPDFDisplayDirection), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMenuGotToPageInPDF), object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewPageChanged, object: nil)
    }

    // MARK: - NotificationCenter

    @objc func uploadedFile(_ notification: NSNotification) {

        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId), let errorCode = userInfo["errorCode"] as? Int {
                if errorCode == 0  && metadata.ocId == self.metadata.ocId {
                    pdfDocument = PDFDocument(url: URL(fileURLWithPath: filePath))
                    pdfView.document = pdfDocument
                    pdfView.layoutDocumentView()
                }
            }
        }
    }

    @objc func favoriteFile(_ notification: NSNotification) {

        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {

                if metadata.ocId == self.metadata.ocId {
                    self.metadata = metadata
                }
            }
        }
    }

    @objc func moveFile(_ notification: NSNotification) {

        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let ocIdNew = userInfo["ocIdNew"] as? String, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId), let metadataNew = NCManageDatabase.shared.getMetadataFromOcId(ocIdNew) {

                if metadata.ocId == self.metadata.ocId {
                    self.metadata = metadataNew
                }
            }
        }
    }

    @objc func deleteFile(_ notification: NSNotification) {

        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["OcId"] as? String {
                if ocId == self.metadata.ocId {
                    viewUnload()
                }
            }
        }
    }

    @objc func renameFile(_ notification: NSNotification) {

        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {

                if metadata.ocId == self.metadata.ocId {
                    self.metadata = metadata
                    navigationItem.title = metadata.fileNameView
                }
            }
        }
    }

    @objc func searchText() {

        let viewerPDFSearch = UIStoryboard(name: "NCViewerPDF", bundle: nil).instantiateViewController(withIdentifier: "NCViewerPDFSearch") as! NCViewerPDFSearch
        viewerPDFSearch.delegate = self
        viewerPDFSearch.pdfDocument = pdfDocument

        let navigaionController = UINavigationController(rootViewController: viewerPDFSearch)
        self.present(navigaionController, animated: true)
    }

    @objc func direction(_ notification: NSNotification) {

        if let userInfo = notification.userInfo as NSDictionary? {
            if let direction = userInfo["direction"] as? PDFDisplayDirection {
                pdfView.displayDirection = direction
                CCUtility.setPDFDisplayDirection(direction)
                handlePageChange()
            }
        }
    }

    @objc func goToPage() {

        guard let pdfDocument = pdfView.document else { return }

        let alertMessage = NSString(format: NSLocalizedString("_this_document_has_%@_pages_", comment: "") as NSString, "\(pdfDocument.pageCount)") as String
        let alertController = UIAlertController(title: NSLocalizedString("_go_to_page_", comment: ""), message: alertMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel, handler: nil))

        alertController.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("_page_", comment: "")
            textField.keyboardType = .decimalPad
        })

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { [unowned self] _ in
            if let pageLabel = alertController.textFields?.first?.text {
                self.selectPage(with: pageLabel)
            }
        }))

        self.present(alertController, animated: true)
    }

    // MARK: - Action

    @objc func openMenuMore() {
        if imageIcon == nil { imageIcon = UIImage(named: "file_pdf") }
        NCViewer.shared.toggleMenu(viewController: self, metadata: metadata, webView: false, imageIcon: imageIcon)
    }

    // MARK: - Gesture Recognizer

    @objc func didTap(_ recognizer: UITapGestureRecognizer) {

        return

        if navigationController?.isNavigationBarHidden ?? false {

            navigationController?.setNavigationBarHidden(false, animated: false)
            pdfThumbnailView.isHidden = false
            pdfView.backgroundColor = NCBrandColor.shared.systemBackground
            view.backgroundColor = NCBrandColor.shared.systemBackground

        } else {

            let point = recognizer.location(in: pdfView)
            if point.y > pdfView.frame.height - thumbnailViewHeight { return }

            navigationController?.setNavigationBarHidden(true, animated: false)
            pdfThumbnailView.isHidden = true
            pdfView.backgroundColor = .black
            view.backgroundColor = .black
        }

        handlePageChange()
    }

    @objc func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            print("Screen edge swiped!")
        }
    }

    // MARK: -

    func ShowHideThumbnail(open: Bool = false) {

        pdfThumbnailScrollView.isHidden = false

        UIView.animate(withDuration: 0.5, animations: {
            if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.orientation.isLandscape || open {
                self.pdfThumbnailScrollViewleadingAnchor?.constant = 0
                self.pdfViewleadingAnchor?.constant = self.thumbnailViewWidth
            } else {
                self.pdfThumbnailScrollViewleadingAnchor?.constant = -self.thumbnailViewWidth
                self.pdfViewleadingAnchor?.constant = 0
                self.pdfThumbnailScrollView.isHidden = true
            }
        })
    }

    @objc func handlePageChange() {

        guard let curPage = pdfView.currentPage?.pageRef?.pageNumber else { pageView.alpha = 0; return }
        guard let totalPages = pdfView.document?.pageCount else { return }

        pageView.alpha = 1
        pageViewLabel.text = String(curPage) + " " + NSLocalizedString("_of_", comment: "") + " " + String(totalPages)
        pageViewWidthAnchor?.constant = pageViewLabel.intrinsicContentSize.width + 10

        UIView.animate(withDuration: 1.0, delay: 3.0, animations: {
            self.pageView.alpha = 0
        })
    }

    func searchPdfSelection(_ pdfSelection: PDFSelection) {

        pdfSelection.color = .yellow
        pdfView.currentSelection = pdfSelection
        pdfView.go(to: pdfSelection)
    }

    private func selectPage(with label: String) {

        guard let pdf = pdfView.document else { return }

         if let pageNr = Int(label) {
             if pageNr > 0 && pageNr <= pdf.pageCount {
                 if let page = pdf.page(at: pageNr - 1) {
                     self.pdfView.go(to: page)
                 }
             } else {
                 let alertController = UIAlertController(title: NSLocalizedString("_invalid_page_", comment: ""),
                                                         message: NSLocalizedString("_the_entered_page_number_doesn't_exist_", comment: ""),
                                                         preferredStyle: .alert)
                 alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: nil))
                 self.present(alertController, animated: true, completion: nil)
             }
         }
     }
}
