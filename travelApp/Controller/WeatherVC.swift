    //
    //  WeatherVC.swift
    //  travelApp
    //
    //  Created by Merouane Bellaha on 14/07/2020.
    //  Copyright © 2020 Merouane Bellaha. All rights reserved.
    //

    import UIKit
    import CoreLocation

    class WeatherVC: UIViewController {

        // MARK: - IBOutlet properties

        @IBOutlet weak var searchBar: UISearchBar!
        @IBOutlet var cityLabels: [UILabel]!
        @IBOutlet var conditionLabels: [UILabel]!
        @IBOutlet var temperaturesLabels: [UILabel]!
        @IBOutlet var weatherIcons: [UIImageView]!

        // MARK: - Properties

        private var httpClient = HTTPClient()
        private var weatherData: WeatherModel!
        private var defaults = UserDefaults.standard
        private var activityIndicator: UIAlertController!
        private let locationManager = CLLocationManager()

        // MARK: - ViewLifeCycle

        override func viewDidLoad() {
            super.viewDidLoad()
            setDelegates()
            locationManager.requestWhenInUseAuthorization()
            hideKeyboardWhenTappedAround()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            performRequestWithUserCity()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.getUserLocation()
            }
        }

        // MARK: - IBAction methods

        @IBAction func getUserLocation(_ sender: UIButton? = nil) {
            setActivityAlert(withTitle: K.wait, message: K.localForecast) { alertController in
                self.locationManager.requestLocation()
                self.activityIndicator = alertController
            }
        }

        @IBAction func searchPressed(_ sender: UIButton) {
            performRequestWithSearBarText()
        }

        // MARK: - Methods

        private func manageResult(with result: Result<WeatherData, RequestError>, forUserCity: Bool = false) {
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    guard error != .error else { return }
                    var message: String {
                        if error == .incorrectResponse {
                            return forUserCity ? K.cityErrorSettings : K.cityErrorSearched
                        } else { return error.description }
                    }
                    self.setAlertVc(with: message)
                }
            case .success(let weatherData):
                DispatchQueue.main.async {
                    var index: Int { forUserCity ? 1 : 0 }
                    self.weatherData = WeatherModel(weatherData: weatherData)
                    self.weatherIcons[index].image = UIImage(named: self.weatherData.conditionName)
                    self.cityLabels[index].text = self.weatherData.cityName
                    self.temperaturesLabels[index].text = self.weatherData.temperatureString
                    self.conditionLabels[index].text = self.weatherData.description
                }
            }
        }

        private func performRequestWithSearBarText() {
            guard let city = searchBar.text else { return }
            httpClient.request(baseUrl: K.baseURLweather, parameters: [K.weatherQuery, K.metric, (K.query, city)]) { self.manageResult(with: $0) }
        }

        private func performRequestWithUserCity() {
            let userCity = defaults.string(forKey: K.city) ?? K.defaultCity
            httpClient.request(baseUrl: K.baseURLweather, parameters: [K.weatherQuery, K.metric, (K.query, userCity)]) { self.manageResult(with: $0, forUserCity: true) }
        }

        private func setDelegates() {
            locationManager.delegate = self
            searchBar.delegate = self
        }
    }

    // MARK: - UISearchBarDelegate

    extension WeatherVC: UISearchBarDelegate {
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            view.endEditing(true)
            performRequestWithSearBarText()
        }
    }

    // MARK: - CLLocationManagerDelegate

    extension WeatherVC: CLLocationManagerDelegate {
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let currentLocation = locations.last else { return }
            locationManager.stopUpdatingLocation()
            let lon = String(currentLocation.coordinate.longitude)
            let lat = String(currentLocation.coordinate.latitude)
            activityIndicator.dismiss(animated: true)
            httpClient.request(baseUrl: K.baseURLweather, parameters: [K.weatherQuery, K.metric, (K.queryLat, lat), (K.queryLon, lon)]) { [unowned self] result in
                self.manageResult(with: result)
            }
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { print(error) }
    }
