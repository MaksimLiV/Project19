//
//  ActionViewController.swift
//  Extension
//
//  Created by Maksim Li on 08/04/2025.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    @IBOutlet var script: UITextView!
    
    var pageTitle = ""
    var pageURL = ""
    var scripts = [Script]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the Done button
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        // Add the Examples button for selecting from predefined scripts
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Examples", style: .plain, target: self, action: #selector(chooseExample))
        
        // Add the Scripts button for saved scripts
        let scriptsButton = UIBarButtonItem(title: "Scripts", style: .plain, target: self, action: #selector(showScripts))
        
        // Create the Save button for saving a script
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveScript))
        
        // Set the array of buttons to the top navigation bar
        navigationItem.leftBarButtonItems = [navigationItem.leftBarButtonItem!, saveButton, scriptsButton]
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier) { [weak self] (dict, error) in
                    guard let itemDictionary = dict as? NSDictionary else { return }
                    guard let javaScriptValues = itemDictionary["NSExtensionJavaScriptPreprocessingResultsKey"] as? NSDictionary else { return }
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.title = self?.pageTitle
                        self?.loadSavedScriptForCurrentPage()
                    }
                }
            }
        }
        
        loadScripts()
    }
    
    // Load saved scripts from UserDefaults
    func loadScripts() {
        let defaults = UserDefaults.standard
        if let savedScripts = defaults.object(forKey: "scripts") as? Data {
            let decoder = JSONDecoder()
            
            do {
                scripts = try decoder.decode([Script].self, from: savedScripts)
            } catch {
                print("Failed to load scripts: \(error.localizedDescription)")
            }
        }
    }
    
    // Save scripts to UserDefaults
    func saveScripts() {
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(scripts)
            UserDefaults.standard.set(data, forKey: "scripts")
        } catch {
            print("Failed to save scripts: \(error.localizedDescription)")
        }
    }
    
    // Load the saved script for the current page
    func loadSavedScriptForCurrentPage() {
        guard let host = URL(string: pageURL)?.host else { return }
        
        let defaults = UserDefaults.standard
        if let savedScript = defaults.string(forKey: "script-\(host)") {
            script.text = savedScript
        }
    }
    
    @IBAction func done() {
        if let host = URL(string: pageURL)?.host {
            let defaults = UserDefaults.standard
            defaults.set(script.text, forKey: "script-\(host)")
        }
        
        let item = NSExtensionItem()
        let argument: NSDictionary = ["customJavaScript": script.text ?? ""]
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: UTType.propertyList.identifier)
        item.attachments = [customJavaScript]
        extensionContext?.completeRequest(returningItems: [item])
    }
    
    @objc func adjustForKeyboard(_ notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        script.scrollIndicatorInsets = script.contentInset
        
        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange)
    }
    
    // Function to choose a predefined script example
    @objc func chooseExample() {
        let ac = UIAlertController(title: "Choose example", message: nil, preferredStyle: .actionSheet)
        
        ac.addAction(UIAlertAction(title: "Clear page", style: .default) { [weak self] _ in
            self?.script.text = """
                         document.body.innerHTML = "";
                         """
        })
        
        ac.addAction(UIAlertAction(title: "Alert document URL", style: .default) { [weak self] _ in
            self?.script.text = """
                         alert(document.URL);
                         """
        })
        
        ac.addAction(UIAlertAction(title: "Change background color", style: .default) { [weak self] _ in
            self?.script.text = """
                         document.body.style.backgroundColor = "red";
                         """
        })
        
        ac.addAction(UIAlertAction(title: "Highlight all links", style: .default) { [weak self] _ in
            self?.script.text = """
                         var links = document.getElementsByTagName("a");
                         for (var i = 0; i < links.length; i++) {
                             links[i].style.backgroundColor = "yellow";
                         }
                         """
        })
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad, a source must be specified for the popover menu
        if let popoverController = ac.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.leftBarButtonItem
        }
        
        present(ac, animated: true)
    }
    
    // Function to save the current script
    @objc func saveScript() {
        let ac = UIAlertController(title: "Save script", message: "Enter a name for your script", preferredStyle: .alert)
        ac.addTextField()
        
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak ac] _ in
            guard let name = ac?.textFields?[0].text, !name.isEmpty else { return }
            
            let newScript = Script(name: name, code: self?.script.text ?? "")
            self?.scripts.append(newScript)
            self?.saveScripts()
        })
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    // Function to display the list of saved scripts
    @objc func showScripts() {
        let vc = TableViewController()
        vc.scripts = scripts
        vc.delegate = self
        
        let navController = UINavigationController(rootViewController: vc)
        present(navController, animated: true)
    }
}

// Delegate for interacting with TableViewController
extension ActionViewController: TableViewControllerDelegate {
    func didSelectScript(_ script: Script) {
        dismiss(animated: true)
        self.script.text = script.code
    }
}
