//
//  SaveViewController.swift
//  Pinned
//
//  Created by Hong Son Ngo on 06/02/2021.
//

import UIKit
import MapKit
import Firebase
import FirebaseAuth
import CodableFirebase
import UserNotifications

class SaveViewController: UIViewController {
    // Saved note
    var note: Note!
    
    // Time Control
    @IBOutlet weak var timeSwitch: UISwitch!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // Location Control
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var selectLocationButton: UIButton!
    @IBOutlet weak var selectCurrentLocationButton: UIButton!
    
    // Database reference
    private var ref: DatabaseReference!
    
    private let locationManager = CLLocationManager()
    private var permissionGranted: Bool = false
    private var settingAlertController: UIAlertController!
    
    // Selected location
    var selectedLocation: MKPlacemark! {
        didSet {
            selectLocationButton.backgroundColor = .systemGreen
            selectLocationButton.setTitle(parseAddress(selectedItem: selectedLocation), for: .normal)
            selectLocationButton.setTitleColor(.white, for: .normal)
            selectLocationButton.layer.borderWidth = 2
            selectLocationButton.layer.borderColor = UIColor.white.cgColor
        }
    }
    
    // MARK: - Setup -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeSwitch.isOn = false
        toggleTimePicker(on: false)
        datePicker.minimumDate = Date()
        
        ref = Database.database().reference().child(Auth.auth().currentUser!.uid)
        
        locationSwitch.isOn = false
        toggleLocationPicker(on: false)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        if CLLocationManager.locationServicesEnabled() {
            if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
                permissionGranted = true
            }
        }
        
        let alertController = UIAlertController(title: "Permission not granted", message: "This feature requires your location. Please allow this permission in the Settings.", preferredStyle: .alert)
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
        
        if note != nil {
            if let exp = note.expTime {
                timeSwitch.isOn = true
                toggleTimePicker(on: true)
                let diff = Date().timeIntervalSince1970 - exp
                if diff < 0 {
                    let expDate = Date(timeIntervalSince1970: exp)
                    datePicker.date = expDate
                }
            }
            if let lat = note.lat, let lon = note.lon {
                let location = CLLocation(latitude: lat, longitude: lon)
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                    if error == nil {
                        guard let clPlacemark = placemarks?[0] else { return }
                        let mkPlacemark = MKPlacemark(placemark: clPlacemark)
                        self?.selectedLocation = mkPlacemark
                        self?.locationSwitch.isOn = true
                        self?.toggleLocationPicker(on: true)
                    }
                }
                
            }
        }
    }
    
    // MARK: - Actions -
    
    @IBAction func timeToggled(_ sender: Any) {
        toggleTimePicker(on: timeSwitch.isOn)
    }
    
    @IBAction func selectLocationButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "navigationSelectLocationController") as! UINavigationController
        if selectedLocation != nil {
            if let select = vc.viewControllers.first as? SelectLocationViewController {
                select.preselectedLocation = selectedLocation
            }
        }
        present(vc, animated: true, completion: nil)
    }
    @IBAction func selectCurrentLocationPressed(_ sender: Any) {
        let status = locationManager.authorizationStatus
        if status != .authorizedAlways && status != .authorizedWhenInUse {
            present(settingAlertController, animated: true, completion: nil)
            return
        }
        guard let location = locationManager.location else { return }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if error == nil {
                guard let clPlacemark = placemarks?[0] else { return }
                let mkPlacemark = MKPlacemark(placemark: clPlacemark)
                self?.selectedLocation = mkPlacemark
            }
        }
    }
    
    @IBAction func locationToggled(_ sender: Any) {
        toggleLocationPicker(on: locationSwitch.isOn)
        if locationSwitch.isOn {
            if permissionGranted {
                locationManager.requestLocation()
            } else {
                locationSwitch.isOn = false
                toggleLocationPicker(on: locationSwitch.isOn)
                present(settingAlertController, animated: true)
            }
        }
    }
    
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        if timeSwitch.isOn {
            note = Note(id: note.id, createTime: note.createTime, expTime: datePicker.date.timeIntervalSince1970, title: note.title, lat: note.lat, lon: note.lon, data: note.data)
        } else {
            note = Note(id: note.id, createTime: note.createTime, expTime: nil, title: note.title, lat: note.lat, lon: note.lon, data: note.data)
        }
        if locationSwitch.isOn {
            if selectedLocation == nil {
                let alert = UIAlertController(title: "Location is missing", message: "Choose location before saving a note with location trigger.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                return
            }
            note = Note(id: note.id, createTime: note.createTime, expTime: note.expTime, title: note.title, lat: selectedLocation.coordinate.latitude, lon: selectedLocation.coordinate.longitude, data: note.data)
        } else {
            note = Note(id: note.id, createTime: note.createTime, expTime: note.expTime, title: note.title, lat: nil, lon: nil, data: note.data)
        }
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [note.id + "t", note.id + "l"])
        let id = note.id
        let encodedData = try! FirebaseEncoder().encode(note)
        ref.child("data").child(id).setValue(encodedData) { (error, ref) in
              if error != nil {
                  print(error?.localizedDescription ?? "Failed to update value")
              } else {
                  print("Success update newValue to database")
              }
          }
        let tabBar = presentingViewController as! UITabBarController
        let navController = tabBar.viewControllers?.first as! UINavigationController
        dismiss(animated: true, completion: nil)
        navController.popToRootViewController(animated: true)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Help functions -
    
    func toggleTimePicker(on: Bool) {
        if on {
            datePicker.isUserInteractionEnabled = true
            datePicker.alpha = 1
        } else {
            datePicker.isUserInteractionEnabled = false
            datePicker.alpha = 0.3
        }
    }
    
    func toggleLocationPicker(on: Bool) {
        if on {
            selectLocationButton.isUserInteractionEnabled = true
            selectLocationButton.alpha = 1
            selectCurrentLocationButton.isUserInteractionEnabled = true
            selectCurrentLocationButton.alpha = 1
        } else {
            selectLocationButton.isUserInteractionEnabled = false
            selectLocationButton.alpha = 0.3
            selectCurrentLocationButton.isUserInteractionEnabled = false
            selectCurrentLocationButton.alpha = 0.3
        }
    }

    func parseAddress(selectedItem:MKPlacemark) -> String {
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        let cityCountryComma = (selectedItem.locality != nil && selectedItem.country != nil) ? ", " : " "
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street name
            selectedItem.thoroughfare ?? "",
            firstSpace,
            // street number
            selectedItem.subThoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            cityCountryComma,
            // state
            selectedItem.country ?? ""
        )
        return addressLine
    }
}

// MARK: - CLLocation Manager Delegate -

extension SaveViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            permissionGranted = true
        case .denied, .notDetermined, .restricted:
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
