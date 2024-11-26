//
//  Download.swift
//  DailyPic
//
//  Created by Paul Zenker on 19.11.24.
//
import Foundation


let resolutions = ["auto", "UHD", "1920x1200", "1920x1080", "1366x768", "1280x720", "1024x768", "800x600"]

let markets = ["auto", "ar-XA", "da-DK", "de-AT", "de-CH", "de-DE", "en-AU", "en-CA", "en-GB",
    "en-ID", "en-IE", "en-IN", "en-MY", "en-NZ", "en-PH", "en-SG", "en-US", "en-WW", "en-XA", "en-ZA", "es-AR",
    "es-CL", "es-ES", "es-MX", "es-US", "es-XL", "et-EE", "fi-FI", "fr-BE", "fr-CA", "fr-CH", "fr-FR",
    "he-IL", "hr-HR", "hu-HU", "it-IT", "ja-JP", "ko-KR", "lt-LT", "lv-LV", "nb-NO", "nl-BE", "nl-NL",
    "pl-PL", "pt-BR", "pt-PT", "ro-RO", "ru-RU", "sk-SK", "sl-SL", "sv-SE", "th-TH", "tr-TR", "uk-UA",
    "zh-CN", "zh-HK", "zh-TW"]

let marketName = [
    "auto", "(شبه الجزيرة العربية‎) العربية", "dansk (Danmark)", "Deutsch (Österreich)",
    "Deutsch (Schweiz)", "Deutsch (Deutschland)", "English (Australia)", "English (Canada)",
    "English (United Kingdom)", "English (Indonesia)", "English (Ireland)", "English (India)", "English (Malaysia)",
    "English (New Zealand)", "English (Philippines)", "English (Singapore)", "English (United States)",
    "English (International)", "English (Arabia)", "English (South Africa)", "español (Argentina)", "español (Chile)",
    "español (España)", "español (México)", "español (Estados Unidos)", "español (Latinoamérica)", "eesti (Eesti)",
    "suomi (Suomi)", "français (Belgique)", "français (Canada)", "français (Suisse)", "français (France)",
    "(עברית (ישראל", "hrvatski (Hrvatska)", "magyar (Magyarország)", "italiano (Italia)", "日本語 (日本)", "한국어(대한민국)",
    "lietuvių (Lietuva)", "latviešu (Latvija)", "norsk bokmål (Norge)", "Nederlands (België)", "Nederlands (Nederland)",
    "polski (Polska)", "português (Brasil)", "português (Portugal)", "română (România)", "русский (Россия)",
    "slovenčina (Slovensko)", "slovenščina (Slovenija)", "svenska (Sverige)", "ไทย (ไทย)", "Türkçe (Türkiye)",
    "українська (Україна)", "中文（中国）", "中文（中國香港特別行政區）", "中文（台灣）"
]

let BingImageURL = "https://www.bing.com/HPImageArchive.aspx";
let BingParams: [String : Any] = [ "format": "js", "idx": 0 , "n": 8 , "mbl": 1 , "mkt": "" ]

class BingWallpaper {

    // Function to Build Query String
    func buildQuery(from parameters: [String: Any]) -> String {
        return parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    }
    
    // Convert the function to an async function
    func fetchJSON(from url: URL) async throws -> Response? {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        do {
            // Print the raw data as a string for inspection
            if let jsonString = String(data: data, encoding: .utf8) {
                //print("Raw JSON Data from \(url): \(jsonString)")
            }

            let response = try JSONDecoder().decode(Response.self, from: data)
            return response
        } catch {
            print("Error decoding data: \(error)")
            throw error
        }
    }
    
    func downloadImage(of date: Date) async -> Response? {
        let url = requestUrl(of: date)  // Assuming requestUrl() returns a URL
        
        do {
            let json = try await fetchJSON(from: url)
            return json
        } catch {
            print("Error fetching or parsing JSON from \(url): \(error.localizedDescription)")
            return nil
        }
    }
    
    func daysDifference(from date: Date) -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate the difference in days
        let components = calendar.dateComponents([.day], from: date, to: today)
        
        // Return the absolute value of the difference
        return abs(components.day ?? 0)
    }
    
    
    // returns url to the bing json
    func requestUrl(of date: Date) -> URL {
        var day_offset = daysDifference(from: date)
        var parameters = getParameters(idx: day_offset)
        let query = buildQuery(from: parameters)
        let url = URL(string: "\(BingImageURL)?\(query)")
        return url!
    }
    func getParameters(idx: Int = 0) -> [String : Any]{
        [ "format": "js", "idx": idx , "n": 1 , "mbl": 1 , "mkt": "auto" ]
    }
}
