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
    
    var itemsToSave: [[String: Any]] = []
    let processingGroup = DispatchGroup()

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

        // Process each attachment separately
        for attachment in attachments {
            processingGroup.enter()
            processAttachment(attachment) { [weak self] itemData in
                if let data = itemData {
                    self?.itemsToSave.append(data)
                }
                self?.processingGroup.leave()
            }
        }

        // Wait for all attachments to be processed, then save
        processingGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Save each item to queue
            for item in self.itemsToSave {
                self.saveToQueue(item)
            }
            
            print("DEBUG: Saved \(self.itemsToSave.count) items to queue")
            self.completeRequestWithDelay()
        }
    }

    func processAttachment(_ attachment: NSItemProvider, completion: @escaping ([String: Any]?) -> Void) {
        var itemData: [String: Any] = [
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "source_app": "unknown"
        ]

        let attachmentGroup = DispatchGroup()

        // 1. Handle TEXT
        if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            attachmentGroup.enter()
            attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
                if let text = data as? String {
                    itemData["text"] = text
                }
                attachmentGroup.leave()
            }
        }

        // 2. Handle URL
        if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            attachmentGroup.enter()
            attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, error in
                if let url = data as? URL {
                    itemData["url"] = url.absoluteString
                }
                attachmentGroup.leave()
            }
        }

        // 3. Handle IMAGE
        if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            attachmentGroup.enter()
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
                        itemData["image_path"] = savedPath
                    }
                }
                attachmentGroup.leave()
            }
        }

        // 4. DETERMINE TYPE after all data is loaded
        attachmentGroup.notify(queue: .main) {
            // PRIORITY LOGIC:
            // If we have an image path, IT IS AN IMAGE (even if it also has text)
            if itemData["image_path"] != nil {
                itemData["type"] = "image"
            }
            // Else if we have a URL, it is a URL
            else if itemData["url"] != nil {
                itemData["type"] = "url"
            }
            // Else if we have text, it is text
            else if itemData["text"] != nil {
                itemData["type"] = "text"
            }
            // No valid data, skip this attachment
            else {
                completion(nil)
                return
            }
            
            print("DEBUG: Item type determined -> \(itemData["type"] ?? "nil")")
            completion(itemData)
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
