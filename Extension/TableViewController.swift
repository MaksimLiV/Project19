//
//  TableViewController.swift
//  Extension
//
//  Created by Maksim Li on 12/04/2025.
//

import UIKit

protocol TableViewControllerDelegate: AnyObject {
    func didSelectScript(_ script: Script)
}

class TableViewController: UITableViewController {
    var scripts = [Script]()
    weak var delegate: TableViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Saved Scripts"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissVC))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    @objc func dismissVC() {
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scripts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = scripts[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectScript(scripts[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            scripts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // Save the updated array of scripts
            let encoder = JSONEncoder()
            
            do {
                let data = try encoder.encode(scripts)
                UserDefaults.standard.set(data, forKey: "scripts")
            } catch {
                print("Failed to save scripts \(error.localizedDescription)")
            }
        }
    }
}
