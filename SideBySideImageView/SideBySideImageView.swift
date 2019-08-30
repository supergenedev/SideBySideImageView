//
//  SideBySideImageView.swift
//  SideBySideImageView
//
//  Created by Heath Hwang on 29/08/2019.
//  Copyright © 2019 HeathHwang. All rights reserved.
//

import UIKit

class SideBySideImageView: UIView {

    private var leftImageView = UIImageView()
    private var rightImageView = UIImageView()
    private var leftScrollView = UIScrollView()
    private var rightScrollView = UIScrollView()
    private var stackView: UIStackView!
    
    private var handleBaseView: UIView!
    private var handleView = UIView()
    
    private var handleBottomContraint: NSLayoutConstraint!
    
    private var initialDisplaySize: CGSize = .zero
    private var initialContentOffset: CGPoint = .zero
    
    var minimumHeight: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initControls()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initControls()
    }
    
    func setImage(left: UIImage, right: UIImage, displaySize: CGSize) -> Bool {
        if left.size.equalTo(right.size) == false {
            return false
        }
        
        layoutIfNeeded()
        
        let scrollViewSize = leftScrollView.frame.size
        
        initialDisplaySize = displaySize
        initialContentOffset = CGPoint(x: (displaySize.width - scrollViewSize.width) / 2.0, y: (displaySize.height - scrollViewSize.height) / 2.0)
        
        leftImageView.image = left
        leftImageView.frame = CGRect(origin: .zero, size: displaySize)
        rightImageView.image = right
        rightImageView.frame = CGRect(origin: .zero, size: displaySize)
        
        leftScrollView.contentSize = self.initialDisplaySize
        leftScrollView.contentOffset = self.initialContentOffset
        rightScrollView.contentSize = self.initialDisplaySize
        rightScrollView.contentOffset = self.initialContentOffset

        
        return true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    private func initControls() {
        
        leftImageView.contentMode = .scaleAspectFit
        rightImageView.contentMode = .scaleAspectFit
        
        leftScrollView.addSubview(leftImageView)
        rightScrollView.addSubview(rightImageView)
        
//        leftScrollView.bounces = false
        leftScrollView.bouncesZoom = false
        leftScrollView.maximumZoomScale = 3.0
        leftScrollView.showsVerticalScrollIndicator = false
        leftScrollView.showsHorizontalScrollIndicator = false
        leftScrollView.delegate = self
        
//        rightScrollView.bounces = false
        rightScrollView.bouncesZoom = false
        rightScrollView.maximumZoomScale = 3.0
        rightScrollView.showsVerticalScrollIndicator = false
        rightScrollView.showsHorizontalScrollIndicator = false
        rightScrollView.delegate = self
        
        stackView = {
            let stackView = UIStackView(arrangedSubviews: [leftScrollView, rightScrollView])
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.alignment = .fill
            stackView.distribution = .fillEqually
            stackView.spacing = 3.0
            addSubview(stackView)
        
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[stack]-0-|", options: [], metrics: nil, views: ["stack": stackView]))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[stack]", options: [], metrics: nil, views: ["stack": stackView]))
            
            return stackView
        }()
        
        handleBaseView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": view]))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=0)-[view]", options: [], metrics: nil, views: ["view": view]))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[stack]-0-[view(30)]-(>=0)-|", options: [], metrics: nil, views: ["view": view, "stack": stackView!]))

            handleBottomContraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
            addConstraint(handleBottomContraint)
            
            handleView.translatesAutoresizingMaskIntoConstraints = false
            handleView.backgroundColor = .black
            view.addSubview(handleView)
            handleView.layer.cornerRadius = 1.0
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[super]-(<=1)-[handle(30)]", options: .alignAllCenterY,
                                                               metrics: nil, views: ["super": view, "handle": handleView]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[super]-(<=1)-[handle(2)]", options: .alignAllCenterX,
                                                               metrics: nil, views: ["super": view, "handle": handleView]))
            return view
        }()
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
        handleBaseView.addGestureRecognizer(gesture)
    }

    @objc func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            let translation = recognizer.translation(in: self)
            let constant = handleBottomContraint.constant + translation.y
            let limit = self.frame.height - minimumHeight - handleBaseView.frame.height
            
            let zoomedInitialSize = initialDisplaySize.applying(CGAffineTransform(scaleX: leftScrollView.zoomScale, y: leftScrollView.zoomScale))
            
            var contentSize: CGSize = .zero
            var contentOffset: CGPoint = .zero
            
            if constant >= -limit && constant <= 0 {
                let shrinkRatio = (leftImageView.frame.size.height + translation.y) / leftImageView.frame.size.height
                let transform = CGAffineTransform(scaleX: shrinkRatio, y: shrinkRatio)
                contentSize = leftScrollView.contentSize.applying(transform)
                contentOffset = leftScrollView.contentOffset.applying(transform)
                print("contentSize = \(contentSize)")
                handleBottomContraint.constant = constant
                recognizer.setTranslation(.zero, in: self)
            } else if constant < -limit {
                let shrinkRatio = (zoomedInitialSize.height - limit) / leftImageView.frame.size.height
                let transform = CGAffineTransform(scaleX: shrinkRatio, y: shrinkRatio)
                contentSize = leftScrollView.contentSize.applying(transform)
                contentOffset = leftScrollView.contentOffset.applying(transform)
                handleBottomContraint.constant = -limit
            } else if constant > 0 {
//                let shrinkRatio = zoomedInitialSize.height / leftImageView.frame.size.height
                contentSize = zoomedInitialSize
                contentOffset = leftScrollView.contentOffset
                handleBottomContraint.constant = 0
            }
            
            contentOffset = CGPoint(x: max(contentOffset.x, 0), y: max(contentOffset.y, 0))
            
            leftScrollView.contentSize = contentSize
            leftScrollView.contentOffset = contentOffset
            rightScrollView.contentSize = contentSize
            rightScrollView.contentOffset = contentOffset
            leftImageView.frame.size = contentSize
            rightImageView.frame.size = contentSize

        default:
            break
        }
    }
    
    private var triggerScrollView: UIScrollView? = nil
}

extension SideBySideImageView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView == leftScrollView {
            return leftImageView
        } else if scrollView == rightScrollView {
            return rightImageView
        }
        return nil
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        triggerScrollView = scrollView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != triggerScrollView {
            return
        }
        if scrollView == leftScrollView {
            rightScrollView.contentOffset = leftScrollView.contentOffset
            rightScrollView.zoomScale = leftScrollView.zoomScale
        } else if scrollView == rightScrollView {
            leftScrollView.contentOffset = rightScrollView.contentOffset
            leftScrollView.zoomScale = rightScrollView.zoomScale
        }
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        triggerScrollView = scrollView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView != triggerScrollView {
            return
        }
        if scrollView == leftScrollView {
            rightScrollView.contentOffset = leftScrollView.contentOffset
            rightScrollView.zoomScale = leftScrollView.zoomScale
        } else if scrollView == rightScrollView {
            leftScrollView.contentOffset = rightScrollView.contentOffset
            leftScrollView.zoomScale = rightScrollView.zoomScale
        }
    }
}
