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
        // Create a centered toast notification
        let notification = UIView()
        // Background: #333A56
        notification.backgroundColor = UIColor(red: 0x33/255.0, green: 0x3A/255.0, blue: 0x56/255.0, alpha: 1.0)
        notification.layer.cornerRadius = 12
        notification.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "✓ Saved to Chuck'it"
        // Text color: #FAFAF6
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

        // Fade in animation
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

        var sharedData: [String: Any] = [:]
        sharedData["timestamp"] = Int64(Date().timeIntervalSince1970 * 1000)
        sharedData["source_app"] = "unknown"

        // DEBUG: Print all available data from extensionItem
        print("=== DEBUG: Extension Item Data ===")
        print("attributedTitle: \(extensionItem.attributedTitle?.string ?? "nil")")
        print("attributedContentText: \(extensionItem.attributedContentText?.string ?? "nil")")
        if let userInfo = extensionItem.userInfo {
            print("userInfo keys: \(userInfo.keys)")
            for (key, value) in userInfo {
                print("  \(key): \(value)")
            }
        }
        print("=== End Debug ===")

        let group = DispatchGroup()

        // Check each attachment
        for (index, attachment) in attachments.enumerated() {
            print("DEBUG: Attachment \(index) registered types: \(attachment.registeredTypeIdentifiers)")

            // Check for text
            if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
                    print("DEBUG: Text data: \(String(describing: data))")
                    if let text = data as? String {
                        sharedData["text"] = text
                        if sharedData["type"] == nil {
                            sharedData["type"] = "text"
                        }
                    }
                    group.leave()
                }
            }

            // Check for URL
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, error in
                    print("DEBUG: URL data: \(String(describing: data))")
                    if let url = data as? URL {
                        sharedData["url"] = url.absoluteString
                        sharedData["type"] = "url"
                    }
                    group.leave()
                }
            }

            // Check for image
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, error in
                    if let imageURL = data as? URL,
                       let imageData = try? Data(contentsOf: imageURL) {
                        if let savedPath = self.saveImage(imageData) {
                            sharedData["image_path"] = savedPath
                            sharedData["type"] = "image"
                        }
                    } else if let image = data as? UIImage,
                              let imageData = image.jpegData(compressionQuality: 0.8) {
                        if let savedPath = self.saveImage(imageData) {
                            sharedData["image_path"] = savedPath
                            sharedData["type"] = "image"
                        }
                    }
                    group.leave()
                }
            }
        }

        // Wait for all attachments, then save and close
        group.notify(queue: .main) {
            print("DEBUG: Final sharedData: \(sharedData)")
            self.saveToQueue(sharedData)
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
