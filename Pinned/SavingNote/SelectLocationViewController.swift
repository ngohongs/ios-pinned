//
//  SelectLocationViewController.swift
//  Pinned
//
//  Created by Hong Son Ngo on 07/02/2021.
//

import UIKit
import MapKit

class SelectLocationViewController: UIViewController {
    // Map, location
    @IBOutlet weak var mapView: MKMapView!
    private  let locationManager = CLLocationManager()
    
    // If placemark is already selected
    var preselectedLocation: MKPlacemark!
    
    private var resultSearchController: UISearchController!
    
    // Selected placemark
    var selectedLocation: MKPlacemark! {
        didSet {
            mapView.removeAnnotations(mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedLocation.coordinate
            annotation.title = selectedLocation.name
            if let city = selectedLocation.locality {
                annotation.subtitle = "\(city)"
            }
            mapView.addAnnotation(annotation)
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // MARK: - Setup -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.requestLocation()
        
        if let userLocation = locationManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(viewRegion, animated: true)
        }
        
        if preselectedLocation != nil {
            selectedLocation = preselectedLocation
        }
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "SearchLocationTableViewController") as! SearchLocationTableViewController
        locationSearchTable.mapView = mapView
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search a location for the trigger"
        navigationItem.titleView = resultSearchController?.searchBar

        resultSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
    }
    
    // MARK: - Actions -
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - CLLocation Managaer Delegate -

extension SelectLocationViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("Granted")
        case .denied, .notDetermined, .restricted:
            print("Denied")
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

extension SelectLocationViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = .orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: .zero, size: smallSquare))
        button.setBackgroundImage(UIImage(systemName: "pin"), for: .normal)
        button.addTarget(self, action: #selector(dismissWithPlacemark), for: .touchUpInside)
        pinView?.rightCalloutAccessoryView = button
        
        return pinView
    }
    
    @objc
    func dismissWithPlacemark() {
        if let navigationVC = presentingViewController as? UINavigationController {
            if let presenter = navigationVC.viewControllers.first as? SaveViewController {
                presenter.selectedLocation = selectedLocation
            }
        }
        dismiss(animated: true, completion: nil)
    }
}
