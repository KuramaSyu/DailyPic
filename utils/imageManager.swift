//
//  imageManager.swift
//  DailyPic
//
//  Created by Paul Zenker on 19.11.24.
//
import SwiftUI


// MARK: - Image Manager
class ImageManager: ObservableObject {
    @Published var images: [NamedImage] = []
    @Published private var _currentIndex: Int = 0
    
    var currentIndex: Int {
        get {
            _currentIndex
        }
        set {
            _currentIndex = newValue
            print("set Index to \(newValue)")
            loadCurrentImage()
        }
    }

    @Published var favoriteImages: Set<NamedImage> = []
    @Published var bingWallpaper: BingWallpaper
    

    private let folderPath: URL
    private let metadataPath: URL
    @Published var config: Config? = nil

    // Computed property to get the current image
    var currentImage: NamedImage? {
        guard !images.isEmpty, currentIndex >= 0, currentIndex < images.count else { return nil }
        return images[currentIndex]
    }
                    
    var currentImageUrl: URL? {
        guard !images.isEmpty, currentIndex >= 0, currentIndex < images.count else { return nil }
        return images[currentIndex].url
    }

    init() {
        bingWallpaper = BingWallpaper()
        // Path to ~/Documents/DailyPic/
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        folderPath = documentsPath.appendingPathComponent("DailyPic")
        metadataPath = folderPath.appendingPathComponent("metadata")
        initialsize_environment()
        loadImages()
        showLastImage()
        loadCurrentImage()
    }
    
    func initialsize_environment() {
        ensureFolderExists(folder: folderPath)
        ensureFileExists(
            path: folderPath.appendingPathComponent("config.json"),
            default_value: Config.getDefault()
        )
        ensureFolderExists(folder: metadataPath)
        loadConfig()
    }
        
    func isCurrentFavorite() -> Bool {
        guard images.indices.contains(currentIndex) else {
            return false
        }
        let currentImage = images[currentIndex]
        let contained = favoriteImages.contains(currentImage)
        return contained
    }
    
    // Ensure the folder exists (creates it if necessary)
    func ensureFolderExists(folder: URL) {
        if !FileManager.default.fileExists(atPath: folder.path) {
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
                print("Folder created at: \(folder.path)")
            } catch {
                print("Failed to create folder: \(error)")
            }
        }
    }

    func loadCurrentImage() {
        images[currentIndex].getMetaData(from: metadataPath)
        if config!.toggles.set_wallpaper_on_navigation {
            WallpaperHandler().setWallpaper(image: images[currentIndex].url)
        }
    }
    
    // Load images from the folder
    @Sendable func loadImages() {
        do {
            // Retrieve file URLs with their creation date
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: [.creationDateKey])
            
            // Filter only image files (png, jpg)
            let imageFiles = fileURLs.filter {
                let ext = $0.pathExtension.lowercased()
                return ext == "png" || ext == "jpg"
            }
            
            // Map to an array of NamedImage objects
            let unsorted_images = imageFiles.compactMap { fileURL in
                if let image = NSImage(contentsOf: fileURL),
                   let creationDate = (try? fileURL.resourceValues(forKeys: [.creationDateKey]))?.creationDate {
                    return NamedImage(
                        url: fileURL,
                        creation_date: creationDate,
                        image: image
                    )
                }
                return nil
            }
            
            // sort by .getDate() property
            images = unsorted_images.sorted {
                $0.getDate() < $1.getDate()
            }
            
            // Reset current index if it is out of bounds
            if !images.indices.contains(currentIndex) {
                showLastImage()
            }
            
            print("\(images.count) images loaded.")
        } catch {
            print("Failed to load images: \(error)")
        }
    }
    

    func showLastImage() {
        currentIndex = images.count - 1
    }
    // Show the previous image
    func showPreviousImage() {
        if !images.isEmpty {
            currentIndex = (currentIndex - 1 + images.count) % images.count
        }
    }

    // Show the next image
    func showNextImage() {
        if !images.isEmpty {
            currentIndex = (currentIndex + 1) % images.count
        }
    }

    // Placeholder for favoriting functionality
    func favoriteCurrentImage() {
        print("Favorite action triggered for image at index \(currentIndex)")
        favoriteImages.insert(images[currentIndex])
        self.config?.favorites.insert(images[currentIndex].url.path())
        
    }
    
    func unFavoriteCurrentImage() {
        print("Unfavorite action triggered for image at index \(currentIndex)")
        favoriteImages.remove(images[currentIndex])
        self.config?.favorites.remove(images[currentIndex].url.path())
    }
    
    // opens the picture folder
    func openFolder() {
        NSWorkspace.shared.open(folderPath)
    }
    
    /// ensures that path exists else init it with default_value
    func ensureFileExists(path: URL, default_value: Codable) {
        guard !FileManager.default.fileExists(atPath: path.path) else { return }
    
        
        // Encode the Config instance to Data
        let encoder = JSONEncoder()
        if let configData = try? encoder.encode(default_value) {
            // Create the file with the encoded data
            FileManager.default.createFile(
                atPath: path.path,
                contents: configData,
                attributes: nil
            )
        } else {
            // Handle error if encoding fails
            print("Failed to encode path: \(path)")
        }
    }

    /// Loads favorite images from config.favorites into self.favoriteImages
    func loadFavorite() {
        if config == nil {return}
        let config = self.config!
        for favorite in config.favorites {
            if let image = NSImage(contentsOfFile: favorite) {
                print("Found favorite image: \(favorite)")
                self.favoriteImages.insert(
                    NamedImage(
                        url: URL(string: favorite)!,
                        creation_date: Date(),
                        image: image
                    )
                )
            }
        }
        print("Loaded \(favoriteImages.count) favorite images)")
    }
        
    func loadConfig() {
        print("Loading config")
        let favoritesPath = folderPath.appendingPathComponent("config.json")
        if let r_config = Config.load(from: favoritesPath) {
            config = r_config
        } else {
            print("Failed to load config, use default config")
            config = Config.getDefault()
        }
        self.loadFavorite()
    }

    func writeConfig() {
        config?.write(to: folderPath.appendingPathComponent("config.json"))
    }
    
    func makeFavorite(bool: Bool) {
        if bool {
            favoriteCurrentImage()
        } else {
            unFavoriteCurrentImage()
        }
        writeConfig()
    }
    
    // for bing download
    func runDailyTaskIfNeeded() {
        print("Trialling daily task...")
        if shouldRunDailyTask() {
            print("Running daily task after wake or app load...")
            // Example: Perform your daily task here
            loadImages() // Example task
            markDailyTaskAsRun()
        }
    }

    func shouldRunDailyTask() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let lastRunDate = UserDefaults.standard.object(forKey: "LastDailyTaskRunDate") as? Date ?? .distantPast
        return lastRunDate < today
    }

    func markDailyTaskAsRun() {
        let today = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(today, forKey: "LastDailyTaskRunDate")
    }
    
    func shuffleIndex() {
        currentIndex = Int.random(in: 0...images.count - 1)
    }
    
    func downloadImageOfToday() async {
        print("start downloading new image...")
        guard let first_image = (await self.bingWallpaper.downloadImageOfToday())?.images[0] else { return }
        let image_url = first_image.getImageURL()
        guard let image = createNSImage(from: image_url) else { return }
        let image_path = folderPath.appendingPathComponent(first_image.getImageName())
        let worked = saveImage(image, to: image_path)
        let _ = try? first_image.saveFile(to_dir: metadataPath)
        
        await MainActor.run {
            if worked {
                print("Image+Metadata saved as \(image_path)")
                loadImages()
                showLastImage()
            } else {
                print("Failed to save image as \(image_path)")
            }
        }
    }
}



// Function to create an NSImage from a URL
func createNSImage(from url: URL) -> NSImage? {
    do {
        // Fetch the image data from the URL
        // TODO: start nownload, display it, and update when its finished
        let imageData = try Data(contentsOf: url)
        
        // Create and return an NSImage from the data
        return NSImage(data: imageData)
    } catch {
        // Handle errors (e.g., if the URL is invalid or data can't be fetched)
        print("Failed to load image from URL: \(error)")
        return nil
    }
}

// Function to save an NSImage to a file at a given path
func saveImage(_ image: NSImage, to path: URL, as format: NSBitmapImageRep.FileType = .jpeg) -> Bool {
    guard let tiffData = image.tiffRepresentation else {
        print("Failed to convert NSImage to TIFF representation.")
        return false
    }
    
    guard let imageRep = NSBitmapImageRep(data: tiffData) else {
        print("Failed to create bitmap representation from TIFF data.")
        return false
    }
    
    // Convert image to the desired format (e.g., PNG or JPEG)
    guard let imageData = imageRep.representation(using: format, properties: [:]) else {
        print("Failed to convert image to specified format.")
        return false
    }
    
    // Write the data to the specified path
    do {
        try imageData.write(to: path)
        print("Image successfully saved to \(path.path)")
        return true
    } catch {
        print("Failed to write image to path: \(error)")
        return false
    }
}
