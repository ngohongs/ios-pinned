//
//  SearchLocationTableViewController.swift
//  Pinned
//
//  Created by Hong Son Ngo on 07/02/2021.
//

import UIKit
import MapKit

class SearchLocationTableViewController: UITableViewController {
    // Search result for query
    private var matchingItems: [MKMapItem] = []
    // Map
    var mapView: MKMapView!
    
    // MARK: - Table View Setup -
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell")!
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        if let presenter = presentingViewController as? SelectLocationViewController {
            presenter.selectedLocation = selectedItem
        }
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Help functions -
    
    func parseAddress(selectedItem:MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
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

// MARK: - Search Results Updater -

extension SearchLocationTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView, let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _  in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}
