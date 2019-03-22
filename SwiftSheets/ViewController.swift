//
//  ViewController.swift
//  SwiftSheets
//
//  Created by Wild, Sebastian on 3/20/19.
//  Copyright © 2019 SAP SE. All rights reserved.
//

import GoogleAPIClientForREST
import GoogleSignIn
import UIKit

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {

    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app. kGTLRAuthScopeSheetsSpreadsheetsReadonly
    private let scopes = [kGTLRAuthScopeSheetsSpreadsheets]

    private let service = GTLRSheetsService()
    let signInButton = GIDSignInButton()
    let output = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure Google Sign-in.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signInSilently()

        // Add the sign-in button.
        view.addSubview(signInButton)

        // Add a UITextView to display output.
        output.frame = view.bounds
        output.isEditable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        output.isHidden = true
        view.addSubview(output);
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
        } else {
            self.signInButton.isHidden = true
            self.output.isHidden = false
            self.service.authorizer = user.authentication.fetcherAuthorizer()
            listMajors()
        }
    }

    // Display (in the UITextView) the names and majors of students in a sample
    // spreadsheet:
    // https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit
    func listMajors() {
        output.text = "Getting sheet data..."
        let spreadsheetId = "1ihIqjfyrQxWYw8YMFR2Z7aKJuv65Z4lUhxn8Eug2CCE"
        let range = "Team Name!A2:E"
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: spreadsheetId, range:range)
//        service.executeQuery(query,
//                             delegate: self,
//                             didFinish: Selector("displayResultWithTicket:finishedWithObject:error:")
//        )
        
        service.executeQuery(query) { (ticket, result, error) in
            
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            guard let result = result as? GTLRSheets_ValueRange else {
                return
            }
            
            var majorsString = ""
            let rows = result.values!
            
            if rows.isEmpty {
                self.output.text = "No data found."
                return
            }
            
            majorsString += "Name, Major:\n"
            for row in rows {
                let name = row[0]
                let major = row[4]
                
                majorsString += "\(name), \(major)\n"
            }
            
            self.output.text = majorsString
        }
    }

    // Process the response and display output
    func displayResultWithTicket(ticket: GTLRServiceTicket,
                                 finishedWithObject result : GTLRSheets_ValueRange,
                                 error : NSError?) {

        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }

        var majorsString = ""
        let rows = result.values!

        if rows.isEmpty {
            output.text = "No data found."
            return
        }

        majorsString += "Name, Major:\n"
        for row in rows {
            let name = row[0]
            let major = row[4]

            majorsString += "\(name), \(major)\n"
        }

        output.text = majorsString
    }



    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: UIAlertController.Style.alert
        )
        let ok = UIAlertAction(
                title: "OK",
                style: UIAlertAction.Style.default,
                handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}

