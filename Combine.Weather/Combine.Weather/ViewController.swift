//
//  ViewController.swift
//  Combine.Weather
//
//  Created by MacBook on 04.04.2022.
//

import UIKit
import Combine

enum WeatherError: Error{
    case invalidResponse
}

class ViewController: UIViewController {
    private let celsiusCharacters = "ºC"
    private let openWeatherBaseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let openWeatherAPIKey = "a0d90ccc1a2e6ccf3d2988c368cc1630"
    
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    private var cancellable: AnyCancellable?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    @IBAction func searchTap(_ sender: Any) {
        view.endEditing(true)
        
        guard let cityName = cityTextField.text else { return }
        getTemperature(for: cityName)
    }
    
    private func getTemperature(for cityName: String) {
        guard let weatherURL = URL(string: "\(openWeatherBaseURL)?APPID=\(openWeatherAPIKey)&q=\(cityName)&units=metric")
        else { return }
        
        activityIndicatorView.startAnimating()
        searchButton.isEnabled = false
        
        cancellable = URLSession.shared.dataTaskPublisher(for: weatherURL)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as?  HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                    throw WeatherError.invalidResponse
                }
                return data
            }
            .decode(type: Temperature.self, decoder: JSONDecoder())
            .catch { error in
                return Just(Temperature.placeholder)
            }
            .map { $0.main?.temp ?? 0.0 }
            .map { "\($0) \(self.celsiusCharacters)" }
            .subscribe(on: DispatchQueue(label: "Combine.Weather"))
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                self.activityIndicatorView.stopAnimating()
                self.searchButton.isEnabled = true
            }, receiveValue: { temp in
                self.temperatureLabel.text = temp
            })
        }
    }
