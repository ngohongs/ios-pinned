//
//  MapViewController.swift
//  Pinned
//
//  Created by Hong Son Ngo on 22/01/2021.
//

import UIKit
import MapKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase
import UserNotifications

class MapViewController: UIViewController {
    // Seleceted pin for detail
    private var selectedPinNote: Note!
    
    // Map, location
    @IBOutlet weak var mapView: MKMapView!
    private let locationManagar = CLLocationManager()
    
    // Database referece
    private let userRootReference = Database.database().reference().child(Auth.auth().currentUser!.uid)
    
    // Location permission
    private var permissionGranted = false
    
    // Load pin repeater
    private var timer: Timer!
    
    // Pins to display
    private var userNotes: [Note] = [] {
        didSet {
            mapView.removeAnnotations(mapView.annotations)
            for note in userNotes {
                if let lat = note.lat, let lon = note.lon {
                    let location = CLLocation(latitude: lat, longitude: lon)
                    let geocoder = CLGeocoder()
                    geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                        if error == nil {
                            guard let clPlacemark = placemarks?[0] else { return }
                            let mkPlacemark = MKPlacemark(placemark: clPlacemark)
                            let annotation = NoteAnnotation()
                            annotation.note = note
                            annotation.coordinate = mkPlacemark.coordinate
                            annotation.title = note.title
                            if let city = mkPlacemark.locality {
                                annotation.subtitle = mkPlacemark.name ?? "" + " \(city)"
                            }
                            self?.mapView.addAnnotation(annotation)
                        }
                    }
                }
            }
        }
    }
    
    private let center = UNUserNotificationCenter.current()
    // MARK: - Setup -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManagar.delegate = self
        if CLLocationManager.locationServicesEnabled() {
            if locationManagar.authorizationStatus == .authorizedAlways || locationManagar.authorizationStatus == .authorizedWhenInUse {
                permissionGranted = true
            }
        }
        let timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(readNotes), userInfo: nil, repeats: true)
        self.timer = timer
        
        center.delegate = self
        readNotes()
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        readNotes()
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    // MARK: - Help functions -
    
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
    }
}
    


// MARK: - CLLocation Manager Delegate -

extension MapViewController: CLLocationManagerDelegate {
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

// MARK: - Map View Delegate -

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let noteAnnotation = view.annotation as? NoteAnnotation else { return }
        selectedPinNote = noteAnnotation.note
        return
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        guard let noteAnnotation = annotation as? NoteAnnotation else { return nil }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = .orange
        pinView?.canShowCallout = true

        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: .zero, size: smallSquare))
        button.setBackgroundImage(UIImage(systemName: "pin"), for: .normal)
        button.addTarget(self, action: #selector(showDetailNote), for: .touchUpInside)
        pinView?.rightCalloutAccessoryView = button
        selectedPinNote = noteAnnotation.note
        return pinView
    }
    
    @objc
    func showDetailNote() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nav = UINavigationController()
        let vc = storyboard.instantiateViewController(identifier: "CreateNoteViewController") as CreateNoteViewController
        vc.note = selectedPinNote
        vc.detailShow = true
        nav.viewControllers = [vc]
        present(nav, animated: true, completion: nil)
    }
    
    
    @objc
    func dissmissVC() {
        dismiss(animated: true, completion: nil)
    }
}

extension MapViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.alert, .badge, .sound])
        }
}


// MARK: - Note Annotation -

class NoteAnnotation: MKPointAnnotation {
    var note: Note!
}

