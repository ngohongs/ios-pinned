//
//  ResizableView.swift
//  PinnedTests
//
//  Created by Hong Son Ngo on 23/01/2021.
//

import UIKit
import PencilKit

class ResizableView: UIView {
    private var grabber: UIView!
    var canvasView: PKCanvasView!
    private var previousHeight: CGFloat = 0
    var heightConstraint: NSLayoutConstraint? {
        get {
            return constraints.first(where: {
                $0.firstAttribute == .height && $0.relation == .equal
            })
        }
        set { setNeedsLayout() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        self.layer.cornerRadius = 4
        canvasView = PKCanvasView(frame: frame)
        canvasView.backgroundColor = .white
        canvasView.layer.cornerRadius = 4
        addSubview(canvasView)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            canvasView.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvasView.leadingAnchor.constraint(equalTo: leadingAnchor),
            canvasView.topAnchor.constraint(equalTo: topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        canvasView.drawing = PKDrawing()
        canvasView.isUserInteractionEnabled = false
        
        grabber = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width - 34, height: 20))
        grabber.backgroundColor = .orange
        grabber.layer.cornerRadius = 4
        addSubview(grabber)
        grabber.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabber.heightAnchor.constraint(equalToConstant: grabber.frame.height),
            grabber.leadingAnchor.constraint(equalTo: leadingAnchor),
            grabber.trailingAnchor.constraint(equalTo: trailingAnchor),
            grabber.centerXAnchor.constraint(equalTo: centerXAnchor),
            grabber.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        grabber.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(resizeViewPangGesture)))
        previousHeight = 220
    }
    
    @objc
    func resizeViewPangGesture(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case.began:
            print("frame", frame, "previous:", self.previousHeight)
        case .changed:
            let translation = gesture.translation(in: self)
            print(previousHeight + translation.y,"  VS  ", canvasView.drawing.bounds.height + canvasView.drawing.bounds.origin.y)
            print("origin:", canvasView.drawing.bounds.origin, "height:", canvasView.drawing.bounds.height)
            print("test", previousHeight + translation.y > canvasView.drawing.bounds.height + canvasView.drawing.bounds.origin.y, previousHeight + translation.y > 50 )
            if ( previousHeight + translation.y > canvasView.drawing.bounds.height + canvasView.drawing.bounds.origin.y  || canvasView.drawing.bounds.height + canvasView.drawing.bounds.origin.y == CGFloat.infinity ) && previousHeight + translation.y > 50 {
                constraints.last?.isActive = false
                heightAnchor.constraint(equalToConstant: previousHeight + translation.y).isActive = true
            }
        case .ended:
            previousHeight = frame.height
            print("end height:", previousHeight)
        default:
            print("default")
        }
        
        
    }
}


