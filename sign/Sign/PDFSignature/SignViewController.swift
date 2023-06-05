//
//  ViewController.swift
//  SwiftSignatureView
//
//  Created by Alankar Misra on 07/17/2015.
//
// SwiftSignatureView is available under the MIT license. See the LICENSE file for more info.

import UIKit
import SwiftSignatureView

final class SignViewController: UIViewController {
    // Use signatureView.signature to get at the signature image
    @IBOutlet weak var signatureView: SwiftSignatureView!

    @IBOutlet weak var croppedSignatureView: UIImageView!
    
    var previousViewController: UIViewController?

    override public func viewDidLoad() {
        super.viewDidLoad()
        signatureView.delegate = self
        signatureView.strokeColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)

        
        if let vc = self.previousViewController as? MainViewController {
            vc.signatureImage = nil
        }
    }

    @IBAction func didTapClear() {
        signatureView.clear()
    }

    @IBAction func didTapRedo(_ sender: Any) {
        signatureView.redo()
    }

    @IBAction func didTapUndo(_ sender: Any) {
        signatureView.undo()
    }

    @IBAction func didTapRefreshCroppedSignature() {
        croppedSignatureView.image = signatureView.getCroppedSignature()
        print("fullRender \(croppedSignatureView.image?.size ?? CGSize.zero)")
    }

    @IBAction func didTapConfirm(_ sender: Any) {
        if let vc = self.previousViewController as? MainViewController {
            croppedSignatureView.image = signatureView.getCroppedSignature()?.withRenderingMode(.alwaysTemplate).imageWithBorder(width: 2, color: .red)
            vc.signatureImage = croppedSignatureView.image
        }
        
        self.navigationController?.popViewController(animated: true)
    }
}

extension  SignViewController: SwiftSignatureViewDelegate {

    func swiftSignatureViewDidDrawGesture(_ view: ISignatureView, _ tap: UIGestureRecognizer) {
        print("swiftSignatureViewDidDrawGesture")
    }

    func swiftSignatureViewDidDraw(_ view: ISignatureView) {
        print("swiftSignatureViewDidDraw")
    }

}

extension UIImage {
    func imageWithBorder(width: CGFloat, color: UIColor) -> UIImage? {
        let square = CGSize(width: size.width + width * 2, height: size.height + width * 2)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
//        imageView.contentMode = .center
        imageView.image = self
        imageView.layer.borderWidth = width
        imageView.layer.borderColor = color.cgColor
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
