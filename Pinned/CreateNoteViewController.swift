//
//  CreateNoteViewController.swift
//  Pinned
//
//  Created by Hong Son Ngo on 22/01/2021.
//

import UIKit
import PencilKit
import Firebase
import FirebaseDatabase
import CodableFirebase

class CreateNoteViewController: UIViewController, UITextViewDelegate, PKCanvasViewDelegate, PKToolPickerObserver {
    // Created note
    var note: Note!
    
    // Check if is only view mode
    var detailShow: Bool = false
    
    // Text formatting
    @IBOutlet weak var boldButton: UIButton!
    private var boldButtonOn = false {
        didSet {
            if boldButtonOn {
                boldButton.backgroundColor = .systemYellow
                boldButton.tintColor = .black
            } else {
                boldButton.backgroundColor = .none
                boldButton.tintColor = .yellow
            }
        }
    }
    @IBOutlet weak var italicButton: UIButton!
    private var italicButtonOn = false {
        didSet {
            if italicButtonOn {
                italicButton.backgroundColor = .systemYellow
                italicButton.tintColor = .black
            } else {
                italicButton.backgroundColor = .none
                italicButton.tintColor = .yellow
            }
        }
    }
    
    private var font: UIFont! {
        didSet {
            for view in content {
                if let textView = view as? UITextView {
                    textView.typingAttributes = [
                        NSAttributedString.Key.font: font!,
                        NSAttributedString.Key.foregroundColor: UIColor.black
                    ]
                }
            }
        }
    }
    
    
    private var alert: UIAlertController!
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var saveDoneButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet var toolBar: UIToolbar!
    private var toolPicker: PKToolPicker!
    
    // Content in note
    var content: [UIView] = []
    
    // Edit mode appearance changes
    private var editMode: Bool = false {
        didSet {
            if editMode {
                self.navigationController?.isToolbarHidden = true
                saveDoneButton.setTitle("Done", for: .normal)
            } else {
                self.navigationController?.isToolbarHidden = false
                saveDoneButton.setTitle("Save", for: .normal)
            }
        }
    }

    // MARK: - Setup -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolPicker = PKToolPicker()
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        
        boldButton.layer.cornerRadius = 4
        italicButton.layer.cornerRadius = 4
        
        font = UIFont(name: "Helvetica", size: 16)!
        
        if detailShow {
            titleButton.isUserInteractionEnabled = false
            saveDoneButton.isHidden = true
        } else {
            self.navigationController?.isToolbarHidden = false
        }
        
        let alertController = UIAlertController(title: "Change title", message: "Enter desired title", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { textField in
            textField.placeholder = "Enter title here"
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let changeAction = UIAlertAction(title: "Change title", style: .default, handler: { [weak self] _ in
            let textField = alertController.textFields![0] as UITextField
            let text = textField.text
            self?.titleButton.setTitle(text, for: .normal)
            })
        alertController.addAction(cancelAction)
        alertController.addAction(changeAction)
        alert = alertController
        
        if note != nil {
            loadContent(in: note!)
        } else {
            _ = createTextView()
        }
    }
    
    // MARK: - View adding -
    
    // Add text view
    func createTextView() -> UITextView? {
        if content.last is UITextView { return nil }
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
        var lastView: UIView
        var constraints: [NSLayoutConstraint]
        if content.isEmpty {
            lastView = contentView
            constraints = [
                textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 17),
                textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -17),
                textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
                textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
            ]
        } else {
            lastView = content.last!
            constraints = [
                textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 17),
                textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -17),
                textView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 10),
                textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
                textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
            ]
            contentView.constraints.last?.isActive = false
        }
        textView.typingAttributes = [
            NSAttributedString.Key.font: font!,
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        textView.tintColor = .black
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.inputAccessoryView = toolBar
        textView.backgroundColor = .systemYellow
        textView.layer.cornerRadius = 4
        textView.translatesAutoresizingMaskIntoConstraints = false
        content.append(textView)
        contentView.addSubview(textView)
        NSLayoutConstraint.activate(constraints)
        return textView
    }
    
    // Add canvas view
    func createCanvasView() -> ResizableView? {
        if content.last is ResizableView { return nil }
        let canvasView = ResizableView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
        var lastView: UIView
        var constraints: [NSLayoutConstraint]
        lastView = content.last!
        constraints = [
            canvasView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 17),
            canvasView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -17),
            canvasView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 10),
            canvasView.heightAnchor.constraint(equalToConstant: 200),
            canvasView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ]
        contentView.constraints.last?.isActive = false
        canvasView.canvasView.delegate = self
        canvasView.canvasView.alwaysBounceVertical = true
        canvasView.backgroundColor = .darkGray
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        content.append(canvasView)
        contentView.addSubview(canvasView)
        NSLayoutConstraint.activate(constraints)
        toolPicker.addObserver(canvasView.canvasView)
        return canvasView
    }
    
    // Add image view
    func createImageView(image: UIImage) -> UIImageView? {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
        var lastView: UIView
        var constraints: [NSLayoutConstraint]
        lastView = content.last!
        constraints = [
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 17),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -17),
            imageView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 10),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ]
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        contentView.constraints.last!.isActive = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        content.append(imageView)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate(constraints)
        return imageView
    }

    // Remove last view
    func deleteLastView() {
        if content.count == 1 {
            return
        }
        let last = content.last!
        let secondLast = content[content.count-2]
        last.removeFromSuperview()
        NSLayoutConstraint.activate([
            secondLast.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        _ = content.popLast()
    }
    
    // MARK: - Actions -
    
    @IBAction func doneSaveButtonPressed(_ sender: Any) {
        if editMode {
            dismissEditMode()
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "NavigationSaveController") as! UINavigationController
            let saveVC = vc.viewControllers.first as! SaveViewController
            saveVC.note = save()
            present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func titleButtonPressed(_ sender: Any) {
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func dismissKeyboard(_ sender: Any) {
        dismissEditMode()
    }
    
    @IBAction func textPress(_ sender: Any) {
        _ = createTextView()
    }
    
    @IBAction func canvasPress(_ sender: Any) {
        _ = createCanvasView()
        showToolPicker()
    }
    
    @IBAction func removeLastView(_ sender: Any) {
        deleteLastView()
    }
    
    @IBAction func boldButtonPressed(_ sender: Any) {
        let font = UIFont(name: "Helvetica", size: 16)!
        boldButtonOn.toggle()
        if boldButtonOn && italicButtonOn {
            self.font = font.boldItalics()
        } else if boldButtonOn && !italicButtonOn {
            self.font = font.bold()
        } else if !boldButtonOn && italicButtonOn {
            self.font = font.italics()
        } else {
            self.font = font
        }
    }
    
    @IBAction func italicButtonPressed(_ sender: Any) {
        let font = UIFont(name: "Helvetica", size: 16)!
        italicButtonOn.toggle()
        if boldButtonOn && italicButtonOn {
            self.font = font.boldItalics()
        } else if boldButtonOn && !italicButtonOn {
            self.font = font.bold()
        } else if !boldButtonOn && italicButtonOn {
            self.font = font.italics()
        } else {
            self.font = font
        }
    }
    @IBAction func addImageButtonPressed(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    // MARK: - Help functions -
    
    // Change into edit mode while typing
    func textViewDidBeginEditing(_ textView: UITextView) {
        editMode = true
    }
    
    func dismissEditMode() {
        view.endEditing(true)
        for view in content {
            if let canvas = view as? ResizableView {
                canvas.canvasView.isUserInteractionEnabled = false
            }
        }
        editMode = false
    }
    
    func showToolPicker() {
        editMode = true
        for view in content {
            if let canvas = view as? ResizableView {
                canvas.canvasView.isUserInteractionEnabled = true
            }
        }
        _ = createCanvasView()
        let lastCanvasView = content.last as! ResizableView
        toolPicker.setVisible(true, forFirstResponder: lastCanvasView.canvasView)
        lastCanvasView.canvasView.becomeFirstResponder()
    }
    
    // Save content for database
    func save() -> Note {
        var data: [Content] = []
        for c in content {
            if let textView = c as? UITextView {
                let string = textView.attributedText ?? NSAttributedString(string: "")
                let stringData = string.attributedStringToHtml!
                data.append(Content(type: "text", data: stringData, ratio: nil))
            }
            if let canvasView = c as? ResizableView {
                let drawing = canvasView.canvasView.drawing
                let stringData = drawing.dataRepresentation().base64EncodedString(options: [])
                let ratio = canvasView.heightConstraint!.constant / canvasView.frame.width
                data.append(Content(type: "drawing", data: stringData, ratio: ratio))
            }
            if let imaveView = c as? UIImageView {
                let image = imaveView.image!
                let imageData = image.jpegData(compressionQuality: 1)?.base64EncodedString()
                data.append(Content(type: "image", data: imageData ?? "", ratio: nil))
            }
        }
        let noteTitle = titleButton.currentTitle ?? ""
        if note == nil {
            let ref = Database.database().reference().child(Auth.auth().currentUser!.uid)
            let id = ref.child("data").childByAutoId().key!
            note = Note(id: id, createTime: Date().timeIntervalSince1970, expTime: nil, title: noteTitle, lat: nil, lon: nil, data: data)
        } else {
            let newNote = Note(id: note.id, createTime: Date().timeIntervalSince1970, expTime: note.expTime, title: noteTitle, lat: note.lat, lon: note.lon, data: data)
            note = newNote
        }
        return note
    }
    
    // Load content from data
    func loadContent(in note: Note) {
        content = []
        titleButton.setTitle(note.title, for: .normal)
        for c in note.data {
            if c.type == "text" {
                let data = Data(c.data.utf8)
                if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                    guard let textView = createTextView() else { continue }
                    textView.attributedText = attributedString
                }
            }
            if c.type == "drawing" {
                guard let data = Data(base64Encoded: c.data) else {
                        continue
                }
                if let drawing = try? PKDrawing(data: data) {
                    guard let canvasView = createCanvasView() else { continue }
                    canvasView.canvasView.drawing = drawing
                    canvasView.heightConstraint!.constant = c.ratio! * view.frame.width
                }
            }
            
            if c.type == "image" {
                let imageData = Data(base64Encoded: c.data) ?? Data()
                let image = UIImage(data: imageData) ?? UIImage()
                _ = createImageView(image: image)
                
            }
        }
        if detailShow {
            for c in content {
                c.isUserInteractionEnabled = false
            }
        }
    }
}


// Scroll view with gestures
extension CreateNoteViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
}

// MARK: - Image picker -

extension CreateNoteViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        _ = createImageView(image: image)
        dismiss(animated: true, completion: nil)
    }
}

