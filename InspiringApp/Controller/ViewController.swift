//
//  ViewController.swift
//  InspiringApp
//
//  Created by Jun Kakeno on 5/19/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import UIKit

enum Message:String{
    case download = "Tap the download button \n to download the file."
    case wait = "Downloading ---> Analyzing \n please wait..."
}


class ViewController: UIViewController {

    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var countedSequences = [(String,Int)]()
    let client = Client()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        message.text = Message.download.rawValue
        indicator.isHidden = true
        downloadBtn.addTarget(self, action: #selector(download(_:)), for: .touchUpInside)
    }
    
    @objc func download(_ sender: UIButton) {
        message.text = Message.wait.rawValue
        downloadBtn.isEnabled = false
        indicator.isHidden = false
        indicator.startAnimating()
        
        client.downloadData() { [unowned self] data, error in
            if let data = data{
                let unsortedList = self.splitString(with: data)
                let sortedList = self.sortList(with: unsortedList)
                let sequences = self.groupPageSequence(with: sortedList)
                self.countedSequences = self.countOccurances(for: sequences)
                
                DispatchQueue.main.async { [weak self] in
                    self?.indicator.stopAnimating()
                    self?.indicator.isHidden = true
                    self?.message.isHidden = true
    
                    let tableVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TableViewController") as! TableViewController
                    tableVC.sequences = self!.countedSequences
                    self!.present(tableVC, animated: true, completion: nil)
                }
                
            }else {
                self.indicator.stopAnimating()
                self.indicator.isHidden = true
                self.message.isHidden = true
                
                let error = error as! NetworkError
                switch(error){
                case .noInternetConnection:
                    self.showErrorAlert(for: "Sorry could not connect to the internet. Please check your connection and try it again.")
                case .requestFailed:
                    self.showErrorAlert(for: "Sorry something went wrong with the server. Please try again later.")
                case .responseUnsuccessful(let code):
                    self.showErrorAlert(for: "Received code \(code) from the server. Please try again later.")
                }
            }
        }
    }
    
    func splitString(with data: String)->[Entry]{
        let list = data.split(separator: "\n")
        var entryList = [Entry]()
        for entry in list{
            let ipAddress = entry.components(separatedBy: "- -")[0]
            let pagePartial = entry.components(separatedBy: "GET")[1]
            let page = pagePartial.components(separatedBy: "HTTP")[0]
            let entry = Entry(ipAddress: ipAddress,page:page)
            entryList.append(entry)
        }
        return entryList
    }
    
    func sortList(with list:[Entry])->[Entry]{
        return list.sorted(by: { $0.ipAddress > $1.ipAddress })
    }
    
    func groupPageSequence(with list:[Entry])->[String]{
        var sequences = [String]()
        for i in 0..<list.count-2{
            let user1 = list[i].ipAddress
            let user2 = list[i+1].ipAddress
            let user3 = list[i+2].ipAddress
            if (user1 == user2 && user1 == user3){
                let page1 = list[i].page
                let page2 = list[i+1].page
                let page3 = list[i+2].page
                let sequence = page1 + "->" + page2 + "->" + page3
                sequences.append(sequence)
            }
        }
        return sequences
    }
    
    func countOccurances(for list: [String])->[(String,Int)]{
        var counts: [String: Int] = [:]
        list.forEach { counts[$0, default: 0] += 1 }
        let sortedCounts = counts.sorted(by: { $0.value > $1.value })
        return sortedCounts
    }
    
    func showErrorAlert(for message:String){
        DispatchQueue.main.async { [weak self] in
            let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "DISMISS", style: .default))
            self?.present(ac, animated: true)
        }
    }
}

