//
//  MainViewController.swift
//  Pinned
//
//  Created by Hong Son Ngo on 22/01/2021.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase
import MapKit
import UserNotifications

class NotesViewController: UIViewController {
    // Notification center
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Location permission
    private var permissionGranted: Bool = false
    
    // Alert controller for permissions
    private var settingAlertController: UIAlertController!
    
    // Location
    let locationManager = CLLocationManager()
    
    @IBOutlet var tableView: UITableView!
    
    // First section
    private var currentNotes: [Note] = []
    // Second section
    private var upcomingNotes: [Note] = []
    // Third section
    private var doneNotes: [Note] = []
    
    // Refresh repeater
    private var timer: Timer!
    
    // Fired notifications
    private var firedNotifications: [String: (Double?, Double?, Double?)] = [:]
    // Database reference
    private var userRootReference = Database.database().reference().child(Auth.auth().currentUser!.uid)
    
    // Sort out sections and notification crea
    private var userNotes: [Note] = [] {
        didSet {
            currentNotes = []
            upcomingNotes = []
            doneNotes = []
            
            for note in userNotes {
                // Both triggers set
                if let exp = note.expTime, let lat = note.lat, let lon = note.lon {
                    let diff = exp - Date().timeIntervalSince1970
                    if diff > 0 {
                        timeNotification(in: note)
                    }
                    locationNotification(in: note)
                    
                    if diff < 0 {
                        doneNotes.append(note)
                    } else if diff < 3600 {
                        currentNotes.append(note)
                    } else {
                        guard let currentLoc = locationManager.location else { upcomingNotes.append(note); continue }
                        let noteLoc = CLLocation(latitude: lat, longitude: lon)
                        let distance = currentLoc.distance(from: noteLoc)
                        if distance < 50 {
                            currentNotes.append(note)
                            continue
                        }
                        upcomingNotes.append(note)
                    }
                }
                
                // Location only set
                if note.expTime == nil && note.lat != nil && note.lon != nil {
                    if let lat = note.lat, let lon = note.lon {
                        guard let current = locationManager.location else {
                            upcomingNotes.append(note)
                            continue
                        }
                        let noteLoc = CLLocation(latitude: lat, longitude: lon)
                        let distance = current.distance(from: noteLoc)
                        if distance < 50 {
                            currentNotes.append(note)
                        } else {
                            upcomingNotes.append(note)
                        }
                        
                        locationNotification(in: note)
                    }
                }
                
                // Time only set
                if note.expTime != nil && note.lat == nil && note.lon == nil {
                    guard let exp = note.expTime else { continue }
                    let diff = exp - Date().timeIntervalSince1970
                    if diff < 0 {
                        doneNotes.append(note)
                    } else if diff < 3600 {
                        currentNotes.append(note)
                    } else {
                        upcomingNotes.append(note)
                    }
                    
                    if diff > 0 {
                        timeNotification(in: note)
                    }
                }
                
                // Nothing set
                if note.expTime == nil && note.lat == nil && note.lon == nil {
                    upcomingNotes.append(note)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            print("user", userNotes.count, "current", currentNotes.count, "upcoming", upcomingNotes.count, "done", doneNotes.count)
        }
    }
    
    // MARK: - Setup _
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        notificationCenter.delegate = self
        
        let timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(readNotes), userInfo: nil, repeats: true)
        self.timer = timer
        
        let alertController = UIAlertController(title: "Permission not granted", message: "This feature requires location and notification permissions to work properly. Please allow this permission in the Settings.", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { [weak self] (success) in
                    self?.dismiss(animated: true, completion: nil)
                })
             }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        settingAlertController = alertController
        
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { [weak self]
            granted, error in
            if error == nil {
                if !granted {
                    DispatchQueue.main.async {
                        guard let alert = self?.settingAlertController else { return }
                        self!.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                print(error!.localizedDescription)
            }
        })
        
        locationManager.requestAlwaysAuthorization()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        readNotes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        readNotes()
    }
    
    // Hide toolbar
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.isToolbarHidden = true
        
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Help functions -
    
    @objc
    func refresh() {
        if CLLocationManager.locationServicesEnabled() {
            let status = locationManager.authorizationStatus
            if status != .authorizedAlways && status != .authorizedWhenInUse {
                present(settingAlertController, animated: true, completion: nil)
            }
        }
        readNotes()
    }
    
    @objc
    func readNotes() {
        self.userRootReference.observe(.value, with: { [weak self] (snapshot) in
            // Get user value
            guard let value = snapshot.value else { return }
            if let notes = try? FirebaseDecoder().decode(NoteResponse.self, from: value) {
                var array = Array(notes.data.values)
                array.sort(by: { $0.createTime < $1.createTime })
                self?.userNotes = array
            }
        })
        { (error) in
            print(error.localizedDescription)
        }
        self.tableView.refreshControl?.endRefreshing()
    }
    
    func timeNotification(in note: Note) {
        if let before = firedNotifications[note.id] {
            if before.0 == note.expTime {
                print("repeat time")
                return
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = note.title
        content.body = "You should look at this note reminder."
        content.sound = UNNotificationSound.default
        let date = Date(timeIntervalSince1970: note.expTime!)
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: note.id + "t", content: content, trigger: trigger)
        
        notificationCenter.add(request, withCompletionHandler: { [weak self] error in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("time:", dateComponents)
                self?.firedNotifications[note.id] = (note.expTime, nil, nil)
            }
        })
    }
    
    func locationNotification(in note: Note) {
        if let before = firedNotifications[note.id] {
            if before.1 == note.lat && before.2 == note.lon {
                print("repeat location")
                return
            }
        }
        
        if let lat = note.lat, let lon = note.lon {
            let content = UNMutableNotificationContent()
            content.title = note.title
            content.body = "You should look at this note reminder."
            content.sound = UNNotificationSound.default
            let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = CLCircularRegion(center: center, radius: 50, identifier: note.title)

            let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
            
            let request = UNNotificationRequest(identifier: note.id + "l", content: content, trigger: trigger)
            
            notificationCenter.add(request, withCompletionHandler: { [weak self] error in
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    print("location:", region)
                    self?.firedNotifications[note.id] = (nil, note.lat, note.lon)
                }
            })
        }
    }
    
}


// MARK: - Table View Delegate and Data Source -

extension NotesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        90
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        150
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        45
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var reuseId = ""
        switch section {
            case 0:
                reuseId = "HeaderCell0"
            case 1:
                reuseId = "HeaderCell1"
            case 2:
                reuseId = "HeaderCell2"
            default:
                break
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        var reuseId = ""
        switch section {
            case 0:
                reuseId = "FooterCell0"
            case 1:
                reuseId = "FooterCell1"
            case 2:
                reuseId = "FooterCell2"
            default:
                break
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "CreateNoteViewController") as CreateNoteViewController
        var source: [Note] = []
        switch indexPath.section {
            case 0:
                source = currentNotes
            case 1:
                source = upcomingNotes
            case 2:
                source = doneNotes
            default:
                break
        }
        vc.note = source[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0:
                return currentNotes.count
            case 1:
                return upcomingNotes.count
            case 2:
                return doneNotes.count
            default:
                break
            }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuseId = ""
        var source: [Note] = []
        switch indexPath.section {
            case 0:
                source = currentNotes
                reuseId = "NoteCell0"
            case 1:
                source = upcomingNotes
                reuseId = "NoteCell1"
            case 2:
                source = doneNotes
                reuseId = "NoteCell2"
            default:
                break
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as! NoteTableViewCell
        cell.title.text = source[indexPath.row].title
        if let data = source[indexPath.row].data.first?.data {
            if let attStr = try? NSAttributedString(data: Data(data.utf8), options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                cell.textView.attributedText = attStr
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let newCount = userNotes.count - 1
            var id = ""
            switch indexPath.section {
                case 0:
                    id = currentNotes[indexPath.row].id
                case 1:
                    id = upcomingNotes[indexPath.row].id
                case 2:
                    id = doneNotes[indexPath.row].id
                default:
                    break
            
            }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [id + "t", id + "l"])
            userRootReference.child("data").child(id).removeValue()
            if newCount == 0 {
                userNotes = []
            }
            readNotes()
        }
    }
}


// MARK: - CLLocation Manager Delegate -

extension NotesViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            readNotes()
            permissionGranted = true
        case .denied, .notDetermined, .restricted:
            readNotes()
            permissionGranted = false
        default: break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("location:: \(location)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error)")
    }
}

extension NotesViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.alert, .badge, .sound])
        }
}
