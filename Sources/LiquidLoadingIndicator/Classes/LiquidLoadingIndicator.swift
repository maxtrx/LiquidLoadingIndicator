//
//  LiquidLoadingIndicator.swift
//  https://github.com/Reiszecke/LiquidLoadingIndicator
//

import UIKit
import WatchKit

@objc
final public class LiquidLoadingIndicator: NSObject {

    private weak var controller: WKInterfaceController?
    private weak var image: WKInterfaceImage?
    private var imageSize: CGSize
    
    private static var dotWaitImage: UIImage?
    private static var lineWaitImage: UIImage?
    private static var progressImages = [UIImage]()
    private static var reloadImage: UIImage?

    private var circleLineLength: CGFloat = 0.9
    private var circleLineWidth: CGFloat = 1
    private var circleLineColor = UIColor(white: 1, alpha: 0.8)
    
    private var lavaLamp = false
    private var moreBubbly = false
    private var bubbleKinetic : CGFloat = 1.1

    public static var progressLineWidthOuter: CGFloat = 1
    public static var progressLineWidthInner: CGFloat = 2
    public static var progressLineColorOuter = UIColor(white: 1, alpha: 0.28)
    public static var progressLineColorInner = UIColor(white: 1, alpha: 0.70)
    
    public static var reloadLineWidth: CGFloat = 4
    public static var reloadArrowRatio: CGFloat = 3
    public static var reloadColor = UIColor.white
    
    private var currentProgressFrame = 0
    private var timer: EMTTimer?
    private var frames = [Int]()
    private var isFirstProgressUpdate = false
    private var style: EMTLoadingIndicatorWaitStyle
    
    public init(interfaceController: WKInterfaceController?, interfaceImage: WKInterfaceImage?,
        width: CGFloat, height: CGFloat, style: EMTLoadingIndicatorWaitStyle) {
            
        controller = interfaceController
        image = interfaceImage
        imageSize = CGSize(width: width, height: height)
        self.style = style
        image?.setAlpha(0)
        
        super.init()
    }
    
    public func setLineWidth(_ width: CGFloat){
        circleLineWidth = width;
    }
    
    public func setLineColor(_ color: UIColor){
        circleLineColor = color
    }
    
    public func setLineLength(_ size: CGFloat){ // 1.0: 100%, 0.2: 20%.
        circleLineLength = size
    }
    
    public func enableLavaLamp(moreBubbly: Bool) {
        lavaLamp = true
        self.moreBubbly = moreBubbly
    }
    
    public func disableLavaLamp() {
        lavaLamp = false
        self.moreBubbly = false
    }
    
    public func setKinetic(energy: CGFloat) {
        bubbleKinetic = energy
    }
    
    public func prepareImagesForWait() {
        if style == .dot {
            prepareImagesForWaitStyleDot()
        }
        else if style == .line {
            prepareImagesForWaitStyleLine()
        }
    }
    
    private func prepareImagesForWaitStyleDot() {
        if LiquidLoadingIndicator.dotWaitImage == nil {
            let bundle = Bundle(for: LiquidLoadingIndicator.self)
            let cursors: [UIImage] = (0...29).map {
                let index = $0
                return UIImage(contentsOfFile: (bundle.path(forResource: "waitIndicatorGraphic-\(index)@2x", ofType: "png"))!)!
            }
            LiquidLoadingIndicator.dotWaitImage = UIImage.animatedImage(with: cursors, duration: 1)
        }
    }
    
    private func prepareImagesForWaitStyleLine() {
        if LiquidLoadingIndicator.lineWaitImage == nil {
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            let context = UIGraphicsGetCurrentContext()!
            
            let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: imageSize)
            let center = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)
            let radius = imageSize.width / 2 - circleLineWidth / 2
            
            var driftingLength: CGFloat = 0
            var driftingSteps : CGFloat = 0.04
            
            var referenceLength: CGFloat = 0
            
            var lengthToUse : CGFloat = 0
            var kineticToUse = bubbleKinetic
            
            if(moreBubbly) {
                driftingSteps  = 0.2
                kineticToUse = kineticToUse * 2
            } else {
                driftingSteps  = 0.04 //peaks at 1.6349994
            }
            
            
            
            let images: [UIImage] = (0...59).map {
                if(lavaLamp) {
                    if($0 <= 30) {
                        if(!moreBubbly) {
                            driftingLength +=   driftingSteps
                            driftingSteps += 0.001
                        } else {
                            driftingSteps += 0.01
                            driftingLength =  driftingLength + pow(driftingSteps, 1.3)
                        }
                    } else {
                        if(!moreBubbly) {
                            driftingLength +=  -driftingSteps
                            driftingSteps += -0.001
                        } else {
                            referenceLength =  referenceLength + pow(driftingSteps, 5.88)
                            driftingLength = driftingLength - referenceLength
                        }
                    }
                    
                    if(!moreBubbly){
                        lengthToUse = driftingLength
                    } else {
                        lengthToUse = driftingLength / 7
                    }
                }
                
                //let degree = CGFloat(-90 + 6 * $0)
                let degree = CGFloat(0 + 6 * $0)
                let startDegree = (CGFloat.pi / 180 * degree)                   + lengthToUse
                let endDegree = startDegree + CGFloat.pi * 2 * circleLineLength - lengthToUse*kineticToUse
                
                //  print(degree)
                //  print(startDegree)
                //  print(endDegree)
                
                let path:UIBezierPath = UIBezierPath(arcCenter: center,
                                                     radius: radius,
                                                     startAngle: startDegree,
                                                     endAngle: endDegree,
                                                     clockwise: true)
                path.lineWidth = circleLineWidth
                path.lineCapStyle = CGLineCap.square
                path.lineJoinStyle = CGLineJoin.miter
                circleLineColor.setStroke()
                path.stroke()
                
                let currentFrameImage = UIGraphicsGetImageFromCurrentImageContext()
                context.clear(rect)
                
                return currentFrameImage!
            }
            UIGraphicsEndImageContext()
            
            LiquidLoadingIndicator.lineWaitImage = UIImage.animatedImage(with: images, duration: 1)
        }
    }
    
    public func prepareImagesForProgress() {
        if LiquidLoadingIndicator.progressImages.count == 0 {
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            let context = UIGraphicsGetCurrentContext()!
            
            let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: imageSize)
            let center = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)
            let radius = imageSize.width / 2 - LiquidLoadingIndicator.progressLineWidthOuter / 2
            let progressRadius = radius - LiquidLoadingIndicator.progressLineWidthInner / 2
            
            let images: [UIImage] = (0...60).map {
                
                let path = UIBezierPath(arcCenter: center,
                                        radius: radius,
                                        startAngle: 0,
                                        endAngle: CGFloat.pi * 2,
                                        clockwise: true)
                
                path.lineWidth = LiquidLoadingIndicator.progressLineWidthOuter
                path.lineCapStyle = CGLineCap.round
                LiquidLoadingIndicator.progressLineColorOuter.setStroke()
                path.stroke()

                let degree = 6 * CGFloat($0)
                let startDegree = -CGFloat.pi / 2
                let endDegree = startDegree + CGFloat.pi / 180 * degree
                
                let progressPath:UIBezierPath = UIBezierPath(arcCenter: center,
                                                             radius: progressRadius,
                                                             startAngle: startDegree,
                                                             endAngle: endDegree,
                                                             clockwise: true)
                progressPath.lineWidth = LiquidLoadingIndicator.progressLineWidthInner
                progressPath.lineCapStyle = CGLineCap.butt
                LiquidLoadingIndicator.progressLineColorInner.setStroke()
                progressPath.stroke()
                
                let currentFrameImage = UIGraphicsGetImageFromCurrentImageContext()
                context.clear(rect)
                
                return currentFrameImage!
            }
            UIGraphicsEndImageContext()
            
            LiquidLoadingIndicator.progressImages = images
        }
    }
    
    public func prepareImagesForReload() {
        if LiquidLoadingIndicator.reloadImage == nil {
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            let context = UIGraphicsGetCurrentContext()!

            let triangleSideLength = LiquidLoadingIndicator.reloadLineWidth * LiquidLoadingIndicator.reloadArrowRatio
            let center = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)
            let radius = imageSize.width / 2 - triangleSideLength / 2
            let startDegree: CGFloat = 0
            let endDegree = startDegree + CGFloat.pi * 1.5
            
            let path:UIBezierPath = UIBezierPath(arcCenter: center,
                                                 radius: radius,
                                                 startAngle: startDegree,
                                                 endAngle: endDegree,
                                                 clockwise: true)
            path.lineWidth = LiquidLoadingIndicator.reloadLineWidth
            path.lineCapStyle = CGLineCap.square
            path.lineJoinStyle = CGLineJoin.miter
            LiquidLoadingIndicator.reloadColor.setStroke()
            path.stroke()
            
            context.setFillColor(LiquidLoadingIndicator.reloadColor.cgColor)
            context.move(to: CGPoint(x: center.x, y: 0))
            context.addLine(to: CGPoint(x: center.x + triangleSideLength * 0.866, y: triangleSideLength / 2))
            context.addLine(to: CGPoint(x: center.x, y: triangleSideLength))
            context.closePath()
            context.fillPath()
            
            LiquidLoadingIndicator.reloadImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
        }
    }

    public func showWait() {
        prepareImagesForWait()

        image?.setImage(style == .dot ? LiquidLoadingIndicator.dotWaitImage : LiquidLoadingIndicator.lineWaitImage)
        image?.startAnimating()
        
        if let controller = controller, let image = image {
            controller.animate(withDuration: 0.3, animations: {
                image.setAlpha(1)
            })
        }
        else {
            image?.setAlpha(1)
        }
    }
    
    public func showReload() {
        prepareImagesForReload()
        image?.stopAnimating()
        image?.setImage(LiquidLoadingIndicator.reloadImage)
        
        if let controller = controller, let image = image {
            controller.animate(withDuration: 0.3, animations: {
                image.setAlpha(1)
            })
        }
        else {
            image?.setAlpha(1)
        }
    }
    
    public func showProgress(startPercentage: Float) {
        prepareImagesForProgress()
        image?.setImage(nil)
        currentProgressFrame = 0
        isFirstProgressUpdate = true

        let startFrame = getCurrentFrameIndex(forPercentage: startPercentage)
        setProgressImage(toFrame: startFrame)
        
        if let controller = controller, let image = image {
            controller.animate(withDuration: 0.3, animations: {
                image.setAlpha(1)
            })
        }
        else {
            image?.setAlpha(1)
        }
    }

    public func updateProgress(percentage: Float) {

        let toFrame = getCurrentFrameIndex(forPercentage: percentage)
        
        frames.removeAll()
        frames = (1...10).map {
            var t = 0.3 / 10 * Float($0)
            let b = Float(currentProgressFrame)
            let c = Float(toFrame) - b
            let d: Float = 0.3
            t /= d
            return Int(b - c * t * (t - 2))
        }
        
        clearTimer()
        timer = EMTTimer(
                    interval: 0.033,
                    callback: { [weak self] timer in
                        self?.nextFrame(timer: timer)
                    },
                    userInfo: nil,
                    repeats: true)
        updateProgressImage()
    }
    
    public func nextFrame(timer: Timer) {
        updateProgressImage()
    }
    
    public func updateProgressImage() {
        let toFrame = frames[0]
        setProgressImage(toFrame: toFrame)
        
        frames.remove(at: 0)
        if frames.count == 0 {
            clearTimer()
        }
    }

    private func clearTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func setProgressImage(toFrame: Int) {
        if !isFirstProgressUpdate && currentProgressFrame == toFrame {
            return
        }
        isFirstProgressUpdate = false
        currentProgressFrame = toFrame
        image?.setImage(LiquidLoadingIndicator.progressImages[currentProgressFrame])
    }
    
    public func hide() {
        image?.stopAnimating()
        
        if let controller = controller, let image = image {
            controller.animate(withDuration: 0.3, animations: {
                image.setAlpha(0)
            })
        }
        else {
            image?.setAlpha(0)
        }
    }
    
    private func getCurrentFrameIndex(forPercentage: Float) -> Int {
        if forPercentage < 0 {
           return 0
        }
        else if forPercentage > 100 {
           return 60
        }
        return Int(60.0 * forPercentage / 100.0)
    }

    public func clearWaitImage(type: EMTLoadingIndicatorWaitStyle) {
        if style == .dot {
            LiquidLoadingIndicator.dotWaitImage = nil
        }
        else if style == .line {
            LiquidLoadingIndicator.lineWaitImage = nil
        }
    }
    
    public func clearReloadImage() {
        LiquidLoadingIndicator.reloadImage = nil
    }
    
    public func clearProgressImage() {
        LiquidLoadingIndicator.progressImages.removeAll()
    }
    
    deinit {
        clearTimer()
        image?.stopAnimating()
    }
}

@objc
public enum EMTLoadingIndicatorWaitStyle: Int {
    case dot
    case line
}
