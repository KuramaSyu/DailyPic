//
//  DailyPicApp.swift
//  DailyPic
//
//  Created by Paul Zenker on 17.11.24.
//
import SwiftUI

class NamedImage: Hashable, CustomStringConvertible  {
    var image: NSImage?
    let url: URL
    let creation_date: Date
    var metadata: BingImage?
    
    init(url: URL, creation_date: Date, image: NSImage? = nil) {
        if let image {
            self.image = image
        }
        self.url = url
        self.creation_date = creation_date
    }
    
    /// get metadata form metadata/YYYYMMDD_name.json
    /// and store it in .metadata. Can fail
    /// needs the
    func getMetaData(from metadata_dir: URL) {
        // strip _UHD.jpeg from image
        let image_name = String(url.lastPathComponent.removingPercentEncoding!.split(separator: "_UHD").first!)
        let metadata_path = metadata_dir.appendingPathComponent("\(image_name).json")
        let metadata = try? JSONDecoder().decode(BingImage.self, from: Data(contentsOf: metadata_path))
        if let metadata = metadata {
            self.metadata = metadata
            print("loaded Metadata for \(metadata.title)")
        } else {
            print("failed to load metadata from \(metadata_path)")
        }
    }
    
    // Implement the required `==` operator for equality comparison
    static func ==(lhs: NamedImage, rhs: NamedImage) -> Bool {
        return lhs.url.lastPathComponent == rhs.url.lastPathComponent
    }

    // Implement the required `hash(into:)` method
    func hash(into hasher: inout Hasher) {
        hasher.combine(url.lastPathComponent)
    }
    
    // Implement the description property for custom printing
    var description: String {
        return "NamedImage(url: \(url))"
    }
    
    func getDate() -> Date {
        let string: String = metadata?.enddate ?? String(url.lastPathComponent)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd" // Format of the date in the string
        
        var parsedDate: Date = creation_date
        
        // parse the string
        if let extracted_date = _stringToDate(from: string) {
            parsedDate = extracted_date
        }

        return parsedDate
    }
    
    /// loads image from .url
    func loadImage() {
        print("NamedImage.laodImage is deprecated. Use NamedImage.loadCGImage")
//        if let loaded_image = NSImage(contentsOf: url) {
//            image = loaded_image
//        }
    }
    /// loads image without RAM footprint
    func loadCGImage() -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
    
    /// sets image to nil
    func unloadImage() {
        image = nil
    }
    
    /// Format the date to "24th November" format
    func prettyDate(from date: Date) -> String {
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d'\(ordinalSuffix(for: date))' MMMM"
        return outputFormatter.string(from: date)
    }
    
    /// converts a string containing yyyyMMdd to a Date object
    func _stringToDate(from string: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd" // Format of the date in the string
        
        // Extract date string from the input
        let pattern = "\\d{8}" // Matches 8-digit sequences (YYYYMMDD)
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: string.utf16.count)
        
        if let match = regex?.firstMatch(in: string, options: [], range: range),
           let matchRange = Range(match.range, in: string) {
            let datePart = String(string[matchRange])
            return dateFormatter.date(from: datePart)
        }
        return nil
    }
    
    // Helper function to determine the ordinal suffix for a day
    func ordinalSuffix(for date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let day = calendar.component(.day, from: date)
        switch day % 10 {
        case 1 where day != 11: return "st"
        case 2 where day != 12: return "nd"
        case 3 where day != 13: return "rd"
        default: return "th"
        }
    }
}


class WakeObserver {
    private var onWake: () -> Void
    
    init(onWake: @escaping () -> Void) {
        self.onWake = onWake
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWakeNotification),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLaunchNotification),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
    }
    
    @objc private func handleWakeNotification() {
        print("Handle Wake")
        onWake()
    }
    
    @objc private func handleLaunchNotification() {
        print("Handle Launch")
        onWake()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}




// MARK: DailyPicApp
@main
struct DailyPicApp: App {
    // 2 variables to set default focus https://developer.apple.com/documentation/swiftui/view/prefersdefaultfocus(_:in:)
    @Namespace var mainNamespace
    @Environment(\.resetFocus) var resetFocus
    
    @State var currentNumber: String = "1" // Example state variable
    @StateObject private var imageManager = ImageManager.getInstance()
    // @State private var wakeObserver: WakeObserver?
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        
        MenuBarExtra("DailyPic", systemImage: "photo") {
            // Title
            Text(self.getTitleText())
                .font(.headline)
                .padding(.top, 15)
            if let metadata = imageManager.currentImage?.metadata {
                Text(metadata.title)
                    .font(.subheadline)
            }
            
            if let nextImage = ImageManager.shared.revealNextImage {
                RevealNextImageView(revealNextImage: nextImage)
            }
            // Image Data
            VStack(alignment: .center) {
                if let current_image = imageManager.currentImage {
                    DropdownWithToggles(
                        bingImage: imageManager.currentImage?.metadata, image: current_image,
                        imageManager: imageManager
                    )
                }
                
                // Image Preview
                if let current_image = imageManager.currentImage {
                    Image(decorative: current_image.loadCGImage()!, scale: 1.0, orientation: .up)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(20)
                        .shadow(radius: 3)
                        .layoutPriority(2)
                } else {
                    VStack(alignment: .center) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.icloud")
                            .resizable()
                            .scaledToFit()
                            .frame(minWidth: 50, minHeight: 50)
                            .padding(.top, 10)
                        Text("No image available.")
                            .font(.headline)
                            .padding(10)
                        Text("Downloading images from last 7 days...")
                            .font(.headline)
                            .padding(10)
                    }
                    .scaledToFit()
                    .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 200, alignment: .center)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                
                ImageNavigation(imageManager: imageManager)
                    .scaledToFit()  // make it not overflow the box
                
                QuickActions(imageManager: imageManager)
                    //.scaledToFit()
                    .layoutPriority(2)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 15)
            .frame(width: 350, height: 450)
            .focusScope(mainNamespace)
            .onAppear {
                // dummyFocus = nil // Clear any default focus
                imageManager.initialsize_environment()
                imageManager.loadImages()
                imageManager.loadCurrentImage()
                //imageManager.runDailyTaskIfNeeded()
                loadPreviousBingImages()
            }
            .focusEffectDisabled(true)
            .onDisappear {
                print("Unload images")
                imageManager.onDisappear();
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    func getTitleText() -> String {
        let wrap_text = { (date: String) in return "Picture of \(date)" }
        
        guard let image = imageManager.currentImage else {
            // no image
            return wrap_text(_formatDate(from: Date())!)
        }
        return wrap_text(image.prettyDate(from: image.getDate()))
    }
    
    func _formatDate(from date: Date? = nil, or string: String? = nil) -> String? {
        guard date != nil || string != nil else {
            print("Error: Either a date or a string must be provided.")
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        var parsedDate: Date?
        
        if let date = date {
            parsedDate = date
        }
        
        // parse date out of string
        else if let string = string {
            // Extract date string from the input
            let pattern = "\\d{8}" // Matches 8-digit sequences (YYYYMMDD)
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: string.utf16.count)
            
            if let match = regex?.firstMatch(in: string, options: [], range: range),
               let matchRange = Range(match.range, in: string) {
                let datePart = String(string[matchRange])
                parsedDate = dateFormatter.date(from: datePart)
            }
        }
        
        // If no valid date is parsed
        guard let finalDate = parsedDate else {
            print("Error: Unable to parse date from input.")
            return nil
        }
        
        // Format the date to "24th November" format
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d'\(ordinalSuffix(for: finalDate))' MMMM"
        return outputFormatter.string(from: finalDate)
    }
    
    // set st, nd, rd or th according to day
    func ordinalSuffix(for date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let day = calendar.component(.day, from: date)
        switch day % 10 {
        case 1 where day != 11: return "st"
        case 2 where day != 12: return "nd"
        case 3 where day != 13: return "rd"
        default: return "th"
        }
    }

    func loadPreviousBingImages() {
        Task {
            if imageManager.getMissingDates().isEmpty { return }
            
            let dates = await imageManager.downloadMissingImages()
            await MainActor.run {
                print("downloaded bing wallpapers from these days: \(dates)")
                
                // save the url of the current image
                let current_image_url = imageManager.currentImage?.url
                
                // reload images
                imageManager.loadImages()
                
                // set index where last picture is now
                if let url = current_image_url {
                    imageManager.setIndexByUrl(url)
                }
            }
        }
    }
}



extension Array {
    func element(at index: Int, default defaultValue: Element) -> Element {
        return indices.contains(index) ? self[index] : defaultValue
    }
}



