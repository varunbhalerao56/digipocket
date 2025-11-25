//
//  ShareViewController.swift
//  share
//
//  Created by Varun Bhalerao on 31/10/25.
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    // Your App Group ID
    let appGroupId = "group.com.vtbh.chuckit"
    
    // We declare this here so we can write to it from multiple closures
    var sharedData: [String: Any] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set background to your dark color #333A56
        view.backgroundColor = UIColor(red: 0x33/255.0, green: 0x3A/255.0, blue: 0x56/255.0, alpha: 1.0)

        // Show saving message immediately
        showSavingNotification()

        // Extract and save in background
        extractAndSaveSharedContent()
    }

    func showSavingNotification() {
        let notification = UIView()
        notification.backgroundColor = UIColor(red: 0x33/255.0, green: 0x3A/255.0, blue: 0x56/255.0, alpha: 1.0)
        notification.layer.cornerRadius = 12
        notification.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "✓ Saved to Chuck'it"
        label.textColor = UIColor(red: 0xFA/255.0, green: 0xFA/255.0, blue: 0xF6/255.0, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        notification.addSubview(label)
        view.addSubview(notification)

        NSLayoutConstraint.activate([
            notification.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notification.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            notification.widthAnchor.constraint(equalToConstant: 220),
            notification.heightAnchor.constraint(equalToConstant: 60),

            label.centerXAnchor.constraint(equalTo: notification.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: notification.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: notification.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: notification.trailingAnchor, constant: -16)
        ])

        notification.alpha = 0
        UIView.animate(withDuration: 0.3) {
            notification.alpha = 1
        }
    }

    func extractAndSaveSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequestWithDelay()
            return
        }

        sharedData["timestamp"] = Int64(Date().timeIntervalSince1970 * 1000)
        sharedData["source_app"] = "unknown"

        let group = DispatchGroup()

        // Iterate through attachments
        for attachment in attachments {
            
            // 1. Handle TEXT
            if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { [weak self] data, error in
                    if let text = data as? String {
                        // Write to dictionary on Main Thread to prevent crashes/race conditions
                        DispatchQueue.main.async {
                            self?.sharedData["text"] = text
                        }
                    }
                    group.leave()
                }
            }

            // 2. Handle URL
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, error in
                    if let url = data as? URL {
                        DispatchQueue.main.async {
                            self?.sharedData["url"] = url.absoluteString
                        }
                    }
                    group.leave()
                }
            }

            // 3. Handle IMAGE
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] data, error in
                    
                    var finalData: Data?

                    // Handle different ways iOS sends images
                    if let imageURL = data as? URL, let fileData = try? Data(contentsOf: imageURL) {
                        finalData = fileData
                    } else if let image = data as? UIImage {
                        finalData = image.jpegData(compressionQuality: 0.8)
                    } else if let rawData = data as? Data {
                        finalData = rawData
                    }

                    if let validData = finalData, let strongSelf = self {
                        if let savedPath = strongSelf.saveImage(validData) {
                            DispatchQueue.main.async {
                                strongSelf.sharedData["image_path"] = savedPath
                            }
                        }
                    }
                    group.leave()
                }
            }
        }

        // 4. WAIT FOR EVERYTHING, THEN DECIDE TYPE
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // PRIORITY LOGIC:
            // If we have an image path, IT IS AN IMAGE (even if it also has text)
            if self.sharedData["image_path"] != nil {
                self.sharedData["type"] = "image"
            }
            // Else if we have a URL, it is a URL
            else if self.sharedData["url"] != nil {
                self.sharedData["type"] = "url"
            }
            // Otherwise, it is text
            else {
                self.sharedData["type"] = "text"
            }

            print("DEBUG: Final Decision -> \(self.sharedData["type"] ?? "nil")")
            
            self.saveToQueue(self.sharedData)
            self.completeRequestWithDelay()
        }
    }

    func saveImage(_ data: Data) -> String? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }

        let imagesDir = containerURL.appendingPathComponent("images")
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDir.appendingPathComponent(filename)

        try? data.write(to: fileURL)
        return fileURL.path
    }

    func saveToQueue(_ data: [String: Any]) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return
        }

        let queueDir = containerURL.appendingPathComponent("share_queue")
        try? FileManager.default.createDirectory(at: queueDir, withIntermediateDirectories: true)

        let filename = "\(UUID().uuidString).json"
        let fileURL = queueDir.appendingPathComponent(filename)

        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) {
            try? jsonData.write(to: fileURL)
        }
    }

    func completeRequestWithDelay() {
        // Show notification for 0.8 seconds before closing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
