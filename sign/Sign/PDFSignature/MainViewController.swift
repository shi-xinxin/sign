//
//  ViewController.swift
//  PDFSignature
//
//  Created by Rajee Jones on 3/12/18.
//  Copyright © 2018 rajeejones. All rights reserved.
//

import UIKit
import PDFKit

import SwiftSignatureView

class ImageStampAnnotation: PDFAnnotation {
    
    var image: UIImage!
    var imageWithBorder: UIImage?
    var imageWithoutBorder: UIImage?
    
    // A custom init that sets the type to Stamp on default and assigns our Image variable
    init(with image: UIImage!, forBounds bounds: CGRect, withProperties properties: [AnyHashable : Any]?) {
        super.init(bounds: bounds, forType: PDFAnnotationSubtype.stamp, withProperties: properties)
        
        self.image = image
        self.imageWithoutBorder = image
        
        // MARK: imageWithBorder - setting selection box style
        self.imageWithBorder = self.imageWithoutBorder?.imageWithBorder(width: 2, color: .red)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        
        // Get the CGImage of our image
        guard let cgImage = self.image.cgImage else { return }
        
        // Draw our CGImage in the context of our PDFAnnotation bounds
        context.draw(cgImage, in: self.bounds)
        
    }
    
    func select() {
        self.image = self.imageWithBorder
        redraw()
    }
    
    func unselect() {
        self.image = self.imageWithoutBorder
        redraw()
    }
    
    func redraw() {
        page?.removeAnnotation(self)
        page?.addAnnotation(self)
    }
    
    func isSelected() -> Bool {
        return self.image == self.imageWithBorder
    }
}


class MainViewController: UIViewController {

  
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var pdfContainerView: PDFView!
    @IBOutlet weak var pageImageView: UIImageView!
    @IBOutlet weak var signatureView: SwiftSignatureView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    @IBOutlet weak var leadingSignature: NSLayoutConstraint!
    @IBOutlet weak var trailingSignature: NSLayoutConstraint!
    @IBOutlet weak var bottomSignature: NSLayoutConstraint!
    @IBOutlet weak var topSignature: NSLayoutConstraint!
    
    @IBOutlet weak var scrollview: UIScrollView!
    
    var signedPages: [PDFPage] = [] // Used to store signed pages
    
    var currentlySelectedAnnotation: PDFAnnotation?
    var signatureImage: UIImage?
    
    var signatureX = 0.0
    var signatureY = 0.0
    
    var imageStamp = ImageStampAnnotation(with: UIImage(), forBounds: CGRect(x: 0, y: 0, width: 0, height: 0), withProperties: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "PDF Viewer"
        
        scrollview.maximumZoomScale = 4
        scrollview.minimumZoomScale = 1
        scrollview.delegate = self
        scrollview.panGestureRecognizer.minimumNumberOfTouches = 2
        
        
        let barButtonItem = UIBarButtonItem(title: "Sign", style: UIBarButtonItemStyle.plain, target: self, action: #selector(showSignView))
        self.navigationItem.leftBarButtonItem = barButtonItem
        
        self.pageImageView.superview!.isHidden = true
        self.scrollview.isHidden = true
        self.confirmButton.isHidden = true
        self.clearButton.isHidden = true
        
        signatureView.delegate = self
        signatureView.strokeColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        setupPdfView()
    }
 
    // Action to be executed after triggering double fingers
    @objc func doubleTap(_ recognizer:UITapGestureRecognizer) {

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateSignatureImage()
    }
    
    func updateSignatureImage() {
        guard let signatureImage = signatureImage, let page = pdfContainerView.currentPage else { return }
        // Add the image to the center of the pdf page and set the width and height
        let imageBounds = CGRect(x: signatureX, y: signatureY, width: signatureImage.size.width, height: signatureImage.size.height)
        // Add a stamp as a comment on the current pdf page
        imageStamp = ImageStampAnnotation(with: signatureImage, forBounds: imageBounds, withProperties: nil)
        page.addAnnotation(imageStamp)
        signedPages.append(page)
    }

    func setupPdfView() {
        // Download simple pdf document
        //if let documentURL = URL(string: "総評レポート.pdf"),
        if let documentURL = Bundle.main.url(forResource: "総評レポート", withExtension: "pdf"),
            let data = try? Data(contentsOf: documentURL),
            let document = PDFDocument(data: data) {
            
            // Set document to the view, center it, and set background color
            pdfContainerView.document = document
            pdfContainerView.autoScales = true
            pdfContainerView.backgroundColor = UIColor.lightGray
            
            let panAnnotationGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanAnnotation(sender:)))
            pdfContainerView.addGestureRecognizer(panAnnotationGesture)
            let tapAnnotationGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAnnotation(sender:)))
            pdfContainerView.addGestureRecognizer(tapAnnotationGesture)
            
        }
    }
    
    func pdfThumbnail(url: URL, width: CGFloat = 240) -> UIImage? {
        guard let data = try? Data(contentsOf: url),
            let page = PDFDocument(data: data)?.page(at: 0) else {
                return nil
        }

        let pageSize = page.bounds(for: .mediaBox)
        let pdfScale = width / pageSize.width

        // Apply if you're displaying the thumbnail on screen
        let scale = UIScreen.main.scale * pdfScale
        let screenSize = CGSize(width: pageSize.width * scale,
                                height: pageSize.height * scale)

        return page.thumbnail(of: screenSize, for: .mediaBox)
    }
    
    func pdfThumbnail(width: CGFloat = 240) -> UIImage? {
        
        guard let page = pdfContainerView.currentPage else { return nil }

        let pageSize = page.bounds(for: .mediaBox)
        let pdfScale = width / pageSize.width

        // Apply if you're displaying the thumbnail on screen
        let scale = UIScreen.main.scale * pdfScale
        let screenSize = CGSize(width: pageSize.width * scale,
                                height: pageSize.height * scale)

        return page.thumbnail(of: screenSize, for: .mediaBox)
    }
    
    @IBAction func comfirSignature(_ sender: Any) {
        self.pageImageView.superview!.isHidden = true
        self.scrollview.isHidden = true
        self.confirmButton.isHidden = true
        self.clearButton.isHidden = true
        self.pdfContainerView.isHidden = false
        
        signatureImage = signatureView.getCroppedSignature()
        
        if #available(iOS 13.0, *) {
            guard let page = pdfContainerView.currentPage  else { return }
            let bounds = signatureView.getSignatureBound()
            let pageBounds = page.bounds(for: .cropBox)
            let imageBounds = pageImageView.rectOfImage()
            signatureX = pageBounds.width * (bounds?.origin.x ?? 0) / imageBounds.width
            
            let y = pageBounds.height * (bounds?.origin.y ?? 0) / imageBounds.height
            signatureY = pageBounds.height - y - (bounds?.height ?? 0) // The coordinate of PDF starts from the lower left corner
        } else {
            // Fallback on earlier versions
        }
        
        updateSignatureImage()
    }
    
    @IBAction func didTapClear() {
        signatureView.clear()
    }
    
    @objc func showSignView() {
        // MARK: Clear the previous signature before re-signing
//        pdfContainerView.currentPage?.removeAnnotation(imageStamp)
        
        let lastPage = signedPages.last
        lastPage?.removeAnnotation(imageStamp)
        
        
        let pageImage = pdfThumbnail(width: self.pageImageView.bounds.width)

        self.pageImageView.image = pageImage
        self.pageImageView.superview!.isHidden = false
        self.scrollview.isHidden = false
        self.confirmButton.isHidden = false
        self.clearButton.isHidden = false
        
        self.pdfContainerView.isHidden = true
        
        let bounds = self.pageImageView.rectOfImage()
        self.leadingSignature.constant = bounds.origin.x
        self.trailingSignature.constant = bounds.origin.x * -1
        let margin = fabs(self.pageImageView.frame.minY - bounds.minY)
        self.topSignature.constant = margin
        self.bottomSignature.constant = margin * -1
        
        self.signatureView.clear()
        
//        let story = UIStoryboard(name: "Sign", bundle: nil)
//        if let signVC = story.instantiateViewController(withIdentifier: "sign") as? SignViewController {
//            signVC.previousViewController = self
//            self.navigationController!.pushViewController(signVC, animated: true)
//        }
    }
    
    @objc func didTapAnnotation(sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: pdfContainerView)
        
        guard let page = pdfContainerView.page(for: touchLocation, nearest: true)
            else {
                return
        }
        let locationOnPage = pdfContainerView.convert(touchLocation, to: page)
        
        switch sender.state {
        case .ended:
            
            guard let annotation = page.annotation(at: locationOnPage) else {
                if let stamp = currentlySelectedAnnotation as? ImageStampAnnotation {
                    stamp.unselect()
                }
                return
            }
            
            if let stamp = annotation as? ImageStampAnnotation {
                currentlySelectedAnnotation = stamp
                stamp.select()
            }
        default:
            break
        }
    }
    
    @objc func didPanAnnotation(sender: UIPanGestureRecognizer) {
        let touchLocation = sender.location(in: pdfContainerView)
        
        guard let page = pdfContainerView.page(for: touchLocation, nearest: true)
            else {
                return
        }
        let locationOnPage = pdfContainerView.convert(touchLocation, to: page)
        
        switch sender.state {
        case .began:
            
            guard let annotation = page.annotation(at: locationOnPage) else {
                return
            }
            
            if let stamp = annotation as? ImageStampAnnotation {
                currentlySelectedAnnotation = stamp
                if !stamp.isSelected() {
                    stamp.select()
                }
            }
            
        case .changed:
            
            guard let annotation = currentlySelectedAnnotation else {
                return
            }
            let initialBounds = annotation.bounds
            // Set the center of the annotation to the spot of our finger
            annotation.bounds = CGRect(x: locationOnPage.x - (initialBounds.width / 2), y: locationOnPage.y - (initialBounds.height / 2), width: initialBounds.width, height: initialBounds.height)
            
            
            print("move to \(locationOnPage)")
        default:
            break
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSignatureSegue" {
            if let nextVC = segue.destination as? SignatureViewController {
                nextVC.previousViewController = self
            }
        }
    }
    
}

extension MainViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}

extension  MainViewController: SwiftSignatureViewDelegate {

    func swiftSignatureViewDidDrawGesture(_ view: ISignatureView, _ tap: UIGestureRecognizer) {
        print("swiftSignatureViewDidDrawGesture")
    }

    func swiftSignatureViewDidDraw(_ view: ISignatureView) {
        print("swiftSignatureViewDidDraw")
    }

}

extension UIImageView {
    func rectOfImage() -> CGRect {
        let imageViewSize = frame.size
        let imgSize = image?.size

        guard let imageSize = imgSize else {
            return CGRect.zero
        }

        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let aspect = fmin(scaleWidth, scaleHeight)

        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)
        // Center image
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2

        // Add imageView offset
        imageRect.origin.x += frame.origin.x
        imageRect.origin.y += frame.origin.y

        return imageRect
    }
}

