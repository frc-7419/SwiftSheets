//
//  ViewController.swift
//  SwiftSheets
//
//  Created by Wild, Sebastian on 3/20/19.
//  Copyright © 2019 SAP SE. All rights reserved.
//

import GoogleAPIClientForREST_Sheets
import GoogleSignIn
import UIKit
import Combine
import GTMSessionFetcherCore

class ViewController: UIViewController {
    
    private let service = GTLRSheetsService()
    private var signedInSubscription: AnyCancellable?
    
    @IBOutlet weak var output: UITextView!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var appendDataButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         Here we use Combine in order to react in real-time to the signed in user stored in the AppDelegate
         changing. This way the UI will update immediately and the isEnabled property will be toggled in one place.
         */
        signedInSubscription = UIApplication.appDelegate.$signedInUser.sink { [unowned self] user in
            if user != nil {
                signInButton.isEnabled = false
                appendDataButton.isEnabled = true
                logoutButton.isEnabled = true
                output.text =
                """
                Signed in!
                User granted scopes: \(user?.grantedScopes?.joined(separator: "\n") ?? "none")
                """
                // Enable later API calls to be authorized.
                // The below will add the correct headers to the outgoing request
                service.authorizer = user?.authentication.fetcherAuthorizer()
            } else {
                output.text = "Not signed in."
                signInButton.isEnabled = true
                appendDataButton.isEnabled = false
                logoutButton.isEnabled = false
            }
        }
    }
    
    @IBAction func signInWithGoogle(_ sender: Any) {
        Task {
            try? await UIApplication.appDelegate.signInOrRestore(presenting: self)
            // signedInSubscription will handle changing UI
        }
    }
    
    @IBAction func onAppendDataButtonPress(_ sender: Any) {
        Task {
            // Before we call the API it is best practice to ensure the needed scope is granted.
            // As of now, we cannot ask the user for a scope as part of the initial sign-in.
            if !(UIApplication.appDelegate.signedInUser?.hasSheetsScope ?? false) {
                _ = try? await GIDSignIn.sharedInstance.addScopes(scopes: [kGTLRAuthScopeSheetsSpreadsheets], presenting: self)
            }
            // Scopes have been granted...or the user cancelled at which point the below will fail
            
            output.text = "Appending data..."
            let spreadsheetId = "1_3wMHPrS2Wv_cfSmCq53yKdpecHgc8tyy71nwGv4jnk"
            let range = "A2:AA"
            let rangeToAppend = GTLRSheets_ValueRange.init();
            rangeToAppend.values = [["Test", "Test2", "Test3"]]
            let query = GTLRSheetsQuery_SpreadsheetsValuesAppend.query(withObject: rangeToAppend, spreadsheetId: spreadsheetId, range: range)
            query.valueInputOption = "USER_ENTERED"
            
            service.executeQuery(query) { (ticket, result, error) in
                
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    self.output.text = "Success!"
                }
            }
        }
    }
    
    @IBAction func onLogoutPress(_ sender: Any) {
        UIApplication.appDelegate.signOut()
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
