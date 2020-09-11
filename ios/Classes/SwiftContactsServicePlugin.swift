import Flutter
import UIKit
import Contacts
import ContactsUI

@available(iOS 9.0, *)
public class SwiftContactsServicePlugin: NSObject, FlutterPlugin, CNContactViewControllerDelegate, CNContactPickerDelegate {
    private var result: FlutterResult? = nil
    private var localizedLabels: Bool = true
    private let rootViewController: UIViewController
    static let FORM_OPERATION_CANCELED: Int = 1
    static let FORM_COULD_NOT_BE_OPEN: Int = 2
    
    static let getContactsMethod = "getContacts"
    static let getContactsByIdentifiersMethod = "getContactsByIdentifiers"
    static let getIdentifiersMethod = "getIdentifiers"
    static let getContactsSummaryMethod = "getContactsSummary"
    static let getContactsForPhoneMethod = "getContactsForPhone"
    static let getContactsForEmailMethod = "getContactsForEmail"
    static let deleteContactsByIdentifiersMethod = "deleteContactsByIdentifiers"
    
    
    static let addContactMethod = "addContact"
    static let deleteContactMethod = "deleteContact"
    static let updateContactMethod = "updateContact"
    static let openContactFormMethod = "openContactForm"
    static let openExistingContactMethod = "openExistingContact"
    static let openDeviceContactPickerMethod = "openDeviceContactPicker"
    static let addContactWithReturnIdentifierMethod = "addContactWithReturnIdentifier"
    
    static var noteEntitlementEnabled = true
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "github.com/clovisnicolas/flutter_contacts", binaryMessenger: registrar.messenger())
        let rootViewController = UIApplication.shared.delegate!.window!!.rootViewController!;
        let instance = SwiftContactsServicePlugin(rootViewController)
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.preLoadContactView()
    }

    init(_ rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case SwiftContactsServicePlugin.getIdentifiersMethod:
            let arguments = call.arguments as! [String:Any]
            result(getIdentifiers(orderByGivenName: arguments["orderByGivenName"] as! Bool))
        case SwiftContactsServicePlugin.getContactsMethod, SwiftContactsServicePlugin.getContactsByIdentifiersMethod, SwiftContactsServicePlugin.getContactsSummaryMethod:
            let arguments = call.arguments as! [String:Any]
            result(getContacts(methodName:call.method, query: (arguments["query"] as? String), withThumbnails: arguments["withThumbnails"] as! Bool,
                               photoHighResolution: arguments["photoHighResolution"] as! Bool, phoneQuery:  false, orderByGivenName: arguments["orderByGivenName"] as! Bool,
                               localizedLabels: arguments["iOSLocalizedLabels"] as! Bool, identifiers: (arguments["identifiers"] as? String) ))
            
        case SwiftContactsServicePlugin.getContactsForPhoneMethod:
            let arguments = call.arguments as! [String:Any]
            result(
                getContacts(methodName:call.method,
                    query: (arguments["phone"] as? String),
                    withThumbnails: arguments["withThumbnails"] as! Bool,
                    photoHighResolution: arguments["photoHighResolution"] as! Bool,
                    phoneQuery: true,
                    orderByGivenName: arguments["orderByGivenName"] as! Bool,
                    localizedLabels: arguments["iOSLocalizedLabels"] as! Bool,
                    identifiers: nil
                )
            )
        case SwiftContactsServicePlugin.getContactsForEmailMethod:
            let arguments = call.arguments as! [String:Any]
            result(
                getContacts(methodName:call.method,
                    query: (arguments["email"] as? String),
                    withThumbnails: arguments["withThumbnails"] as! Bool,
                    photoHighResolution: arguments["photoHighResolution"] as! Bool,
                    phoneQuery: false,
                    emailQuery: true,
                    orderByGivenName: arguments["orderByGivenName"] as! Bool,
                    localizedLabels: arguments["iOSLocalizedLabels"] as! Bool,
                    identifiers: nil
                )
            )
        case SwiftContactsServicePlugin.addContactMethod:
            let contact = dictionaryToContact(dictionary: call.arguments as! [String : Any])

            let addResult = addContact(contact: contact)
            if (addResult == "") {
                result(nil)
            }
            else {
                result(FlutterError(code: "", message: addResult, details: nil))
            }
        case SwiftContactsServicePlugin.addContactWithReturnIdentifierMethod:
            let contact = dictionaryToContact(dictionary: call.arguments as! [String : Any])

            let addResult = addContactWithReturnIdentifier(contact: contact)
            if (!addResult.starts(with: "Error:")) {
                var resultDict = [[String:Any]]()
                resultDict.append(["identifier": addResult])
                result(resultDict)
            } else {
                let error = addResult.replacingOccurrences(of: "Error:", with: "")
                result(FlutterError(code: "", message: error, details: nil))
            }
        case SwiftContactsServicePlugin.deleteContactsByIdentifiersMethod:
            if(deleteContactsByIdentifiers(dictionary: call.arguments as! [String : Any])){
                result(nil)
            }
            else{
                result(FlutterError(code: "", message: "Failed to delete contacts, make sure they have valid identifiers", details: nil))
            }
        case SwiftContactsServicePlugin.deleteContactMethod:
            if(deleteContact(dictionary: call.arguments as! [String : Any])){
                result(nil)
            }
            else{
                result(FlutterError(code: "", message: "Failed to delete contact, make sure it has a valid identifier", details: nil))
            }
        case SwiftContactsServicePlugin.updateContactMethod:
            if(updateContact(dictionary: call.arguments as! [String: Any])) {
                result(nil)
            }
            else {
                result(FlutterError(code: "", message: "Failed to update contact, make sure it has a valid identifier", details: nil))
            }
        case SwiftContactsServicePlugin.openContactFormMethod:
            let arguments = call.arguments as! [String:Any]
            localizedLabels = arguments["iOSLocalizedLabels"] as! Bool
            self.result = result
            _ = openContactForm()
        case SwiftContactsServicePlugin.openExistingContactMethod:
            let arguments = call.arguments as! [String : Any]
            let contact = arguments["contact"] as! [String : Any]
            localizedLabels = arguments["iOSLocalizedLabels"] as! Bool
            self.result = result
            _ = openExistingContact(contact: contact, result: result)
        case SwiftContactsServicePlugin.openDeviceContactPickerMethod:
            let arguments = call.arguments as! [String : Any]
            openDeviceContactPicker(arguments: arguments, result: result);
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func getIdentifiers(orderByGivenName: Bool = true) -> [[String:Any]] {
        var result = [[String:Any]]()
        let store = CNContactStore()
        do {
            var contactIdentifiers = [String]()
            
            let fetchRequest = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor])
            if (orderByGivenName) {
                fetchRequest.sortOrder = CNContactSortOrder.givenName
            }

            try store.enumerateContacts(with: fetchRequest, usingBlock: { contact, error -> Void in
                contactIdentifiers.append(contact.identifier)
            })
            
            let map = ["identifiers" : contactIdentifiers]
            result.append(map)
        } catch let error as NSError {
            print(error.localizedDescription)
            return result
        }

        return result
    }
    
    func getContacts(methodName:String, query : String?, withThumbnails: Bool, photoHighResolution: Bool, phoneQuery: Bool = false, emailQuery: Bool = false, orderByGivenName: Bool = true, localizedLabels: Bool = true, identifiers: String?) -> [[String:Any]]{

        var contacts : [CNContact] = []
        var result = [[String:Any]]()

        //Create the store, keys & fetch request
        let store = CNContactStore()
        
        var keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName) as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactMiddleNameKey as CNKeyDescriptor,
                CNContactNamePrefixKey as CNKeyDescriptor,
                CNContactNameSuffixKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactJobTitleKey as CNKeyDescriptor,
                CNContactDepartmentNameKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactNicknameKey as CNKeyDescriptor,
                CNContactPreviousFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneticGivenNameKey as CNKeyDescriptor,
                CNContactPhoneticMiddleNameKey as CNKeyDescriptor,
                CNContactPhoneticFamilyNameKey as CNKeyDescriptor,
                CNContactNonGregorianBirthdayKey as CNKeyDescriptor,
                CNContactTypeKey as CNKeyDescriptor,
                CNContactDatesKey as CNKeyDescriptor,
                CNContactUrlAddressesKey as CNKeyDescriptor,
                CNContactRelationsKey as CNKeyDescriptor,
                CNContactSocialProfilesKey as CNKeyDescriptor,
                CNContactInstantMessageAddressesKey as CNKeyDescriptor
        ] as [CNKeyDescriptor]

        if SwiftContactsServicePlugin.noteEntitlementEnabled {
            keys.append(CNContactNoteKey as CNKeyDescriptor)
        }
        
        var contactIdentifiers: [String]?
        if (methodName == SwiftContactsServicePlugin.getContactsSummaryMethod) {
            keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName) as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactMiddleNameKey as CNKeyDescriptor,
                CNContactNamePrefixKey as CNKeyDescriptor,
                CNContactNameSuffixKey as CNKeyDescriptor,
            ] as [CNKeyDescriptor]
            if let allIdentifiers = identifiers {
                contactIdentifiers = allIdentifiers.split(separator: "|").map(String.init)
            }
        } else if (methodName == SwiftContactsServicePlugin.getContactsByIdentifiersMethod) {
            if let allIdentifiers = identifiers {
                contactIdentifiers = allIdentifiers.split(separator: "|").map(String.init)
            }
        }
        
        if(withThumbnails){
            if(photoHighResolution){
                keys.append(CNContactImageDataKey as CNKeyDescriptor)
            } else {
                keys.append(CNContactThumbnailImageDataKey as CNKeyDescriptor)
            }
        }

        let fetchRequest = CNContactFetchRequest(keysToFetch: keys)

        var contactIds: [String] = []
        
        do {
            let allContainers: [CNContainer] = try store.containers(matching: nil)
            for container in allContainers {
                fetchRequest.predicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                
                if let byContactIdentifiers = contactIdentifiers { // contact by identifiers
                    fetchRequest.predicate = CNContact.predicateForContacts(withIdentifiers: byContactIdentifiers)

                } else {
                    // Set the predicate if there is a query
                    if query != nil && !phoneQuery && !emailQuery {
                        fetchRequest.predicate = CNContact.predicateForContacts(matchingName: query!)
                    }

                    if #available(iOS 11, *) {
                        if query != nil && phoneQuery {
                            let phoneNumberPredicate = CNPhoneNumber(stringValue: query!)
                            fetchRequest.predicate = CNContact.predicateForContacts(matching: phoneNumberPredicate)
                        } else if query != nil && emailQuery {
                            fetchRequest.predicate = CNContact.predicateForContacts(matchingEmailAddress: query!)
                        }
                    }
                }
                
                if (orderByGivenName) {
                    fetchRequest.sortOrder = CNContactSortOrder.givenName
                }
                
                do {
                    try store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) -> Void in
                        if (!contactIds.contains(contact.identifier)) {
                            contactIds.append(contact.identifier)
                            contacts.append(contact)
                        }
                    })
                } catch let error as NSError {
                    print(" Error in getContact: \(error.code), \(error.localizedDescription)")
                    if (error.code == 102) {// iOS13, the note entitilement is introduced. Need to remove note as the entitlemnt is not yet aprroved or appended with plist
                        SwiftContactsServicePlugin.noteEntitlementEnabled = false
                        keys = keys.filter { !$0.isEqual(CNContactNoteKey) }
                        do{
                            fetchRequest.keysToFetch = keys
                            try store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) -> Void in
                                if (!contactIds.contains(contact.identifier)) {
                                    contactIds.append(contact.identifier)
                                    contacts.append(contact)
                                }
                            })
                        } catch let error as NSError {
                            print(" Error after removing note key in getContact: \(error.code), \(error.localizedDescription)")
                            return result
                        }
                    }
                }
            }
        } catch let error as NSError {
            print(" Error in getContact: \(error.code), \(error.localizedDescription)")
            if (error.code == 102) {// iOS13, the note entitilement is introduced. Need to remove note as the entitlemnt is not yet aprroved or appended with plist
                SwiftContactsServicePlugin.noteEntitlementEnabled = false
                keys = keys.filter { !$0.isEqual(CNContactNoteKey) }
                do{
                    fetchRequest.keysToFetch = keys
                    try store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) -> Void in
                        if (!contactIds.contains(contact.identifier)) {
                            contactIds.append(contact.identifier)
                            contacts.append(contact)
                        }
                    })
                } catch let error as NSError {
                    print(" Error after removing note key in getContact: \(error.code), \(error.localizedDescription)")
                    return result
                }
            }
        }
        
        contacts = contacts.sorted { (contactA, contactB) -> Bool in
             contactA.givenName.lowercased() < contactB.givenName.lowercased()
        }
        
        if (methodName == SwiftContactsServicePlugin.getContactsSummaryMethod) {
            for contact : CNContact in contacts{
                result.append(contactToSummaryDictionary(contact: contact))
            }
        } else {
            for contact : CNContact in contacts{
                result.append(contactToDictionary(contact: contact, localizedLabels: localizedLabels))
            }
        }
        
        return result
    }

    private func has(contact: CNContact, phone: String) -> Bool {
        if (!contact.phoneNumbers.isEmpty) {
            let phoneNumberToCompareAgainst = phone.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
            for phoneNumber in contact.phoneNumbers {

                if let phoneNumberStruct = phoneNumber.value as CNPhoneNumber? {
                    let phoneNumberString = phoneNumberStruct.stringValue
                    let phoneNumberToCompare = phoneNumberString.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
                    if phoneNumberToCompare == phoneNumberToCompareAgainst {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func addContact(contact : CNMutableContact) -> String {
        let store = CNContactStore()
        do {
            let saveRequest = CNSaveRequest()
            saveRequest.add(contact, toContainerWithIdentifier: nil)
            try store.execute(saveRequest)
        }
        catch {
            return error.localizedDescription
        }
        return ""
    }
    
    func addContactWithReturnIdentifier(contact : CNMutableContact) -> String {
        let store = CNContactStore()
        do {
            let saveRequest = CNSaveRequest()
            saveRequest.add(contact, toContainerWithIdentifier: nil)
            try store.execute(saveRequest)
            return contact.identifier
        }
        catch {
            return "Error:\(error.localizedDescription)"
        }
    }

    func openContactForm() -> [String:Any]? {
        let contact = CNMutableContact.init()
        let controller = CNContactViewController.init(forNewContact:contact)
        controller.delegate = self
        DispatchQueue.main.async {
         let navigation = UINavigationController .init(rootViewController: controller)
         let viewController : UIViewController? = UIApplication.shared.delegate?.window??.rootViewController
            viewController?.present(navigation, animated:true, completion: nil)
        }
        return nil
    }
    
    func preLoadContactView() {
        DispatchQueue.main.asyncAfter(deadline: .now()+5) {
            NSLog("Preloading CNContactViewController")
            _ = CNContactViewController.init(forNewContact: nil)
        }
    }
    
    @objc func cancelContactForm() {
        if let result = self.result {
            let viewController : UIViewController? = UIApplication.shared.delegate?.window??.rootViewController
            viewController?.dismiss(animated: true, completion: nil)
            result(SwiftContactsServicePlugin.FORM_OPERATION_CANCELED)
            self.result = nil
        }
    }
    
    public func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true, completion: nil)
        if let result = self.result {
            if let contact = contact {
                result(contactToDictionary(contact: contact, localizedLabels: localizedLabels))
            } else {
                result(SwiftContactsServicePlugin.FORM_OPERATION_CANCELED)
            }
            self.result = nil
        }
    }

    func openExistingContact(contact: [String:Any], result: FlutterResult ) ->  [String:Any]? {
         let store = CNContactStore()
         do {
            // Check to make sure dictionary has an identifier
             guard let identifier = contact["identifier"] as? String else{
                 result(SwiftContactsServicePlugin.FORM_COULD_NOT_BE_OPEN)
                 return nil;
             }
            let backTitle = contact["backTitle"] as? String
            
             let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                                CNContactIdentifierKey,
                                CNContactEmailAddressesKey,
                                CNContactBirthdayKey,
                                CNContactImageDataKey,
                                CNContactPhoneNumbersKey,
                                CNContactViewController.descriptorForRequiredKeys()
                ] as! [CNKeyDescriptor]
            let cnContact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
            let viewController = CNContactViewController(for: cnContact)

            viewController.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: backTitle == nil ? "Cancel" : backTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancelContactForm))
             viewController.delegate = self
            DispatchQueue.main.async {
                let navigation = UINavigationController .init(rootViewController: viewController)
                var currentViewController = UIApplication.shared.keyWindow?.rootViewController
                while let nextView = currentViewController?.presentedViewController {
                    currentViewController = nextView
                }
                let activityIndicatorView = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.gray)
                activityIndicatorView.frame = (UIApplication.shared.keyWindow?.frame)!
                activityIndicatorView.startAnimating()
                activityIndicatorView.backgroundColor = UIColor.white
                navigation.view.addSubview(activityIndicatorView)
                currentViewController!.present(navigation, animated: true, completion: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5 ){
                    activityIndicatorView.removeFromSuperview()
                }
            }
            return nil
         } catch {
            NSLog(error.localizedDescription)
            result(SwiftContactsServicePlugin.FORM_COULD_NOT_BE_OPEN)
            return nil
         }
     }
     
    func openDeviceContactPicker(arguments: [String:Any], result: @escaping FlutterResult) {
        localizedLabels = arguments["iOSLocalizedLabels"] as! Bool
        self.result = result
        
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        //contactPicker!.displayedPropertyKeys = [CNContactPhoneNumbersKey];
        DispatchQueue.main.async {
            self.rootViewController.present(contactPicker, animated: true, completion: nil)
        }
    }

    //MARK:- CNContactPickerDelegate Method

    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        if let result = self.result {
            result(contactToDictionary(contact: contact, localizedLabels: localizedLabels))
            self.result = nil
        }
    }

    public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        if let result = self.result {
            result(SwiftContactsServicePlugin.FORM_OPERATION_CANCELED)
            self.result = nil
        }
    }
    
    func deleteContactsByIdentifiers(dictionary : [String:Any]) -> Bool{
        guard let identifiers = dictionary["identifiers"] as? String else{
            return false;
        }
        
        let contactIdentifiers = identifiers.split(separator: "|").map(String.init)
        
        if contactIdentifiers.count > 0 {
            let store = CNContactStore()
            let keys = [CNContactIdentifierKey as NSString]
            do{
                let predicate = CNContact.predicateForContacts(withIdentifiers: contactIdentifiers)

                let nativeContacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
                for contact in nativeContacts {
                    let request = CNSaveRequest()
                    request.delete(contact.mutableCopy() as! CNMutableContact)
                    try store.execute(request)
                }
            }
            catch{
                print(error.localizedDescription)
                return false;
            }
        }
        
        return true;
    }

    func deleteContact(dictionary : [String:Any]) -> Bool{
        guard let identifier = dictionary["identifier"] as? String else{
            return false;
        }
        let store = CNContactStore()
        let keys = [CNContactIdentifierKey as NSString]
        do{
            if let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keys).mutableCopy() as? CNMutableContact{
                let request = CNSaveRequest()
                request.delete(contact)
                try store.execute(request)
            }
        }
        catch{
            print(error.localizedDescription)
            return false;
        }
        return true;
    }

    func updateContact(dictionary : [String:Any]) -> Bool{

        // Check to make sure dictionary has an identifier
        guard let identifier = dictionary["identifier"] as? String else{
            return false;
        }

        let store = CNContactStore()
        
        var keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName) as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactMiddleNameKey as CNKeyDescriptor,
                CNContactNamePrefixKey as CNKeyDescriptor,
                CNContactNameSuffixKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactJobTitleKey as CNKeyDescriptor,
                CNContactDepartmentNameKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactNicknameKey as CNKeyDescriptor,
                CNContactPreviousFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneticGivenNameKey as CNKeyDescriptor,
                CNContactPhoneticMiddleNameKey as CNKeyDescriptor,
                CNContactPhoneticFamilyNameKey as CNKeyDescriptor,
                CNContactNonGregorianBirthdayKey as CNKeyDescriptor,
                CNContactTypeKey as CNKeyDescriptor,
                CNContactDatesKey as CNKeyDescriptor,
                CNContactUrlAddressesKey as CNKeyDescriptor,
                CNContactRelationsKey as CNKeyDescriptor,
                CNContactSocialProfilesKey as CNKeyDescriptor,
                CNContactInstantMessageAddressesKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
        ] as [CNKeyDescriptor]

        if SwiftContactsServicePlugin.noteEntitlementEnabled {
            keys.append(CNContactNoteKey as CNKeyDescriptor)
        }
        
        do {
            // Check if the contact exists
            if let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keys).mutableCopy() as? CNMutableContact{

                setDictionaryToContact(dictionary: dictionary, contact: contact)

                // Attempt to update the contact
                let request = CNSaveRequest()
                request.update(contact)
                try store.execute(request)
            }
        }
        catch let error as NSError {
            print("\(error.code), \(error.localizedDescription)")
            if (error.code == 102) {// iOS13, the note entitilement is introduced. Need to remove note as the entitlemnt is not yet aprroved or appended with plist
                SwiftContactsServicePlugin.noteEntitlementEnabled = false
                keys = keys.filter { !$0.isEqual(CNContactNoteKey) }
                do {
                    if let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keys).mutableCopy() as? CNMutableContact{

                        setDictionaryToContact(dictionary: dictionary, contact: contact)

                        // Attempt to update the contact
                        let request = CNSaveRequest()
                        request.update(contact)
                        try store.execute(request)
                    }
                } catch let error as NSError {
                    print("\(error.code), \(error.localizedDescription)")
                    return false;
                }
            } else {
                return false;
            }
        }
        return true;
    }

    func dictionaryToContact(dictionary : [String:Any]) -> CNMutableContact{
        let contact = CNMutableContact()

        setDictionaryToContact(dictionary: dictionary, contact: contact)

        return contact
    }
    
    func setDictionaryToContact(dictionary: [String:Any], contact: CNMutableContact) {
        //Simple fields
        contact.givenName = dictionary["givenName"] as? String ?? ""
        contact.familyName = dictionary["familyName"] as? String ?? ""
        contact.middleName = dictionary["middleName"] as? String ?? ""
        contact.namePrefix = dictionary["prefix"] as? String ?? ""
        contact.nameSuffix = dictionary["suffix"] as? String ?? ""
        contact.organizationName = dictionary["company"] as? String ?? ""
        contact.jobTitle = dictionary["jobTitle"] as? String ?? ""
        contact.nickname = dictionary["nickname"] as? String ?? ""
        contact.phoneticGivenName = dictionary["phoneticGivenName"] as? String ?? ""
        contact.phoneticMiddleName = dictionary["phoneticMiddleName"] as? String ?? ""
        contact.phoneticFamilyName = dictionary["phoneticFamilyName"] as? String ?? ""
        contact.departmentName = dictionary["department"] as? String ?? ""
        
        if SwiftContactsServicePlugin.noteEntitlementEnabled {
            contact.note = dictionary["note"] as? String ?? ""
        }

        if let image = (dictionary["avatar"] as? FlutterStandardTypedData)?.data, image.count > 0 {
            contact.imageData = image
        }

        //Phone numbers
        if let phoneNumbers = dictionary["phones"] as? [[String:String]]{
            var updatedPhoneNumbers = [CNLabeledValue<CNPhoneNumber>]()
            for phone in phoneNumbers where phone["value"] != nil {
                updatedPhoneNumbers.append(CNLabeledValue(label:getPhoneLabel(label: phone["label"]),value:CNPhoneNumber(stringValue: phone["value"]!)))
//                contact.phoneNumbers.append(CNLabeledValue(label:getPhoneLabel(label:phone["label"]),value:CNPhoneNumber(stringValue:phone["value"]!)))
            }
            contact.phoneNumbers = updatedPhoneNumbers
        }

        
        //Emails
        if let emails = dictionary["emails"] as? [[String:String]]{
            var updatedEmails = [CNLabeledValue<NSString>]()
            for email in emails where nil != email["value"] {
                let emailLabel = email["label"] ?? ""
                updatedEmails.append(CNLabeledValue(label: getCommonLabel(label: emailLabel), value: email["value"]! as NSString))
//                contact.emailAddresses.append(CNLabeledValue(label:getCommonLabel(label: emailLabel), value:email["value"]! as NSString))
            }
            contact.emailAddresses = updatedEmails
        }

        //Postal addresses
        if let postalAddresses = dictionary["postalAddresses"] as? [[String:String]]{
            var updatedPostalAddresses = [CNLabeledValue<CNPostalAddress>]()

            for postalAddress in postalAddresses{
                let newAddress = CNMutablePostalAddress()
                newAddress.street = postalAddress["street"] ?? ""
                if #available(iOS 10.3, *) {
                    newAddress.subLocality = postalAddress["locality"] ?? ""
                } else {
                    var street = ""
                    if let s = postalAddress["street"] {
                        street = s
                    }
                    if let l = postalAddress["locality"] {
                        if street.isEmpty {
                            street = l
                        } else {
                            street = "\(street)\n\(l)"
                        }
                    }
                    newAddress.street = street
                }
                newAddress.city = postalAddress["city"] ?? ""
                newAddress.postalCode = postalAddress["postcode"] ?? ""
                newAddress.country = postalAddress["country"] ?? ""
                newAddress.state = postalAddress["region"] ?? ""
                let label = postalAddress["label"] ?? ""
//                contact.postalAddresses.append(CNLabeledValue(label: getCommonLabel(label: label), value: newAddress))
                updatedPostalAddresses.append(CNLabeledValue(label: getCommonLabel(label: label), value: newAddress))
            }
            contact.postalAddresses = updatedPostalAddresses
        }

        //BIRTHDAY
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let birthday = dictionary["birthday"] as? String {
            let birthComponents = birthday.split(separator: "-")
            if birthComponents.count == 3 {
                var d = DateComponents()
                d.year = Int(birthComponents[0])
                d.month = Int(birthComponents[1])
                d.day = Int(birthComponents[2])
                contact.birthday = d
            } else if birthComponents.count == 2 {
                var d = DateComponents()
                d.month = Int(birthComponents[0])
                d.day = Int(birthComponents[1])
                contact.birthday = d
            }
        }
        
        //Relations
        if let relations = dictionary["relations"] as? [[String:String]]{
            var updatedRelations = [CNLabeledValue<CNContactRelation>]()

            for relation in relations where nil != relation["value"] {
                let relationLabel = relation["label"] ?? ""
//                contact.contactRelations.append(CNLabeledValue(label:getRelationsLabel(label: relationLabel), value:CNContactRelation(name: relation["value"]! as String)))
                updatedRelations.append(CNLabeledValue(label:getRelationsLabel(label: relationLabel), value:CNContactRelation(name: relation["value"]! as String)))
            }
            contact.contactRelations = updatedRelations
        }
        
        //Instant message address
        if let instantMessageAddresses = dictionary["instantMessageAddresses"] as? [[String:String]]{
            var updatedIms = [CNLabeledValue<CNInstantMessageAddress>]()

            for im in instantMessageAddresses where nil != im["value"] {
                let imLabel = im["label"] ?? ""
//                contact.instantMessageAddresses.append(CNLabeledValue(label:getInstantMessageLabel(label: imLabel), value:CNInstantMessageAddress(username: im["value"]! as String, service: im["label"]! as String)))
                updatedIms.append(CNLabeledValue(label:getInstantMessageLabel(label: imLabel), value:CNInstantMessageAddress(username: im["value"]! as String, service: im["label"]! as String)))
            }
            contact.instantMessageAddresses = updatedIms
        }

        //Dates
        if let dates = dictionary["dates"] as? [[String:String]]{
            var updatedDates = [CNLabeledValue<NSDateComponents>]()
            for date in dates where nil != date["value"] {

                let dateLabel = date["label"] ?? ""
                let dateValue = date["value"] ?? ""

                let dateComponents = dateValue.split(separator: "-")
                if dateComponents.count == 3 {
                    var d = DateComponents()
                    d.year = Int(dateComponents[0])
                    d.month = Int(dateComponents[1])
                    d.day = Int(dateComponents[2])
//                    contact.dates.append(CNLabeledValue(label: getDatesLabel(label: dateLabel), value: d as NSDateComponents))
                    updatedDates.append(CNLabeledValue(label: getDatesLabel(label: dateLabel), value: d as NSDateComponents))
                } else if dateComponents.count == 2 {
                    var d = DateComponents()
                    d.month = Int(dateComponents[0])
                    d.day = Int(dateComponents[1])
//                    contact.dates.append(CNLabeledValue(label: getDatesLabel(label: dateLabel), value: d as NSDateComponents))
                    updatedDates.append(CNLabeledValue(label: getDatesLabel(label: dateLabel), value: d as NSDateComponents))
                }
            }
            contact.dates = updatedDates
        }
        
        //Social profile
        if let profiles = dictionary["socialProfiles"] as? [[String:String]]{
            var updatedProfiles = [CNLabeledValue<CNSocialProfile>]()

            for profile in profiles where nil != profile["userName"] {
                let label = profile["label"] ?? ""
                let service = (profile["service"] != nil && !profile["service"]!.isEmpty) ? profile["service"] : getSocialProfileLabel(label: label)
                let userName = profile["userName"] ?? ""
                let userIdentifier = profile["userIdentifier"] ?? ""
                var urlString = ""
                if let urlStringFromMap = profile["urlString"], !urlStringFromMap.isEmpty {
                    urlString = getSocialProfileUrl(label: label, userName: userName)
                }
                
                updatedProfiles.append(CNLabeledValue(label:getSocialProfileLabel(label: label), value:CNSocialProfile(urlString: urlString, username: userName, userIdentifier: userIdentifier, service: service)))
            }
            contact.socialProfiles = updatedProfiles
        }
        
        //Websites
        if let websites = dictionary["websites"] as? [[String:String]]{
            var updatedWebsites = [CNLabeledValue<NSString>]()
            for website in websites where nil != website["value"] {
                let label = website["label"] ?? ""
                let url = website["value"] ?? ""
//                contact.urlAddresses.append(CNLabeledValue(label:getWebsitesLabel(label: label), value:url as NSString))
                updatedWebsites.append(CNLabeledValue(label:getWebsitesLabel(label: label), value:url as NSString))
            }
            contact.urlAddresses = updatedWebsites
        }
    }
    
    func contactToSummaryDictionary(contact: CNContact) -> [String:Any]{
        var result = [String:Any]()

        //Simple fields
        result["identifier"] = contact.identifier
        result["displayName"] = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName)
        result["givenName"] = contact.givenName
        result["middleName"] = contact.middleName
        result["familyName"] = contact.familyName
        result["prefix"] = contact.namePrefix
        result["suffix"] = contact.nameSuffix

        if contact.isKeyAvailable(CNContactThumbnailImageDataKey) {
            if let avatarData = contact.thumbnailImageData {
                result["avatar"] = FlutterStandardTypedData(bytes: avatarData)
            }
        }
        if contact.isKeyAvailable(CNContactImageDataKey) {
            if let avatarData = contact.imageData {
                result["avatar"] = FlutterStandardTypedData(bytes: avatarData)
            }
        }

        return result
    }

    func contactToDictionary(contact: CNContact, localizedLabels: Bool) -> [String:Any]{

        var result = [String:Any]()

        //Simple fields
        result["identifier"] = contact.identifier
        result["displayName"] = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName)
        result["givenName"] = contact.givenName
        result["familyName"] = contact.familyName
        result["middleName"] = contact.middleName
        result["phoneticGivenName"] = contact.phoneticGivenName
        result["phoneticMiddleName"] = contact.phoneticMiddleName
        result["phoneticFamilyName"] = contact.phoneticFamilyName
        result["prefix"] = contact.namePrefix
        result["suffix"] = contact.nameSuffix
        result["company"] = contact.organizationName
        result["jobTitle"] = contact.jobTitle
        result["department"] = contact.departmentName
        result["nickname"] = contact.nickname
        result["sip"] = ""
        if SwiftContactsServicePlugin.noteEntitlementEnabled {
            result["note"] = contact.note
        } else {
            result["note"] = ""
        }

        if contact.isKeyAvailable(CNContactThumbnailImageDataKey) {
            if let avatarData = contact.thumbnailImageData {
                result["avatar"] = FlutterStandardTypedData(bytes: avatarData)
            }
        }
        if contact.isKeyAvailable(CNContactImageDataKey) {
            if let avatarData = contact.imageData {
                result["avatar"] = FlutterStandardTypedData(bytes: avatarData)
            }
        }

        //Phone numbers
        var phoneNumbers = [[String:String]]()
        for phone in contact.phoneNumbers{
            var phoneDictionary = [String:String]()
            phoneDictionary["identifier"] = phone.identifier
            phoneDictionary["value"] = phone.value.stringValue
            phoneDictionary["label"] = "other"
            if let label = phone.label{
                phoneDictionary["label"] = localizedLabels ? CNLabeledValue<NSString>.localizedString(forLabel: label) : getRawPhoneLabel(label);
            }
            phoneNumbers.append(phoneDictionary)
        }
        result["phones"] = phoneNumbers

        //Emails
        var emailAddresses = [[String:String]]()
        for email in contact.emailAddresses{
            var emailDictionary = [String:String]()
            emailDictionary["identifier"] = email.identifier
            emailDictionary["value"] = String(email.value)
            emailDictionary["label"] = "other"
            if let label = email.label{
                emailDictionary["label"] = localizedLabels ? CNLabeledValue<NSString>.localizedString(forLabel: label) : getRawCommonLabel(label);
            }
            emailAddresses.append(emailDictionary)
        }
        result["emails"] = emailAddresses

        //Postal addresses
        var postalAddresses = [[String:String]]()
        for address in contact.postalAddresses{
            var addressDictionary = [String:String]()
            addressDictionary["identifier"] = address.identifier
            addressDictionary["label"] = "other"
            if let label = address.label{
                addressDictionary["label"] = localizedLabels ? CNLabeledValue<NSString>.localizedString(forLabel: label) : getRawCommonLabel(label);
            }
            addressDictionary["street"] = address.value.street
            if #available(iOS 10.3, *) {
                addressDictionary["locality"] = address.value.subLocality
            } else {
                addressDictionary["locality"] = ""
            }
            addressDictionary["city"] = address.value.city
            addressDictionary["postcode"] = address.value.postalCode
            addressDictionary["region"] = address.value.state
            addressDictionary["country"] = address.value.country

            postalAddresses.append(addressDictionary)
        }
        result["postalAddresses"] = postalAddresses

        //BIRTHDAY
        if let birthday : Date = contact.birthday?.date {
            let formatter = DateFormatter()
            let year = Calendar.current.component(.year, from: birthday)
            formatter.dateFormat = year == 1 ? "--MM-dd" : "yyyy-MM-dd";
            result["birthday"] = formatter.string(from: birthday)
        }
        
        //Relations
        var relations = [[String:String]]()
        for relation in contact.contactRelations{
            var relationDictionary = [String:String]()
            relationDictionary["identifier"] = relation.identifier
            relationDictionary["value"] = String(relation.value.name)
            relationDictionary["label"] = "other"
            if let label = relation.label{
                relationDictionary["label"] = localizedLabels ? CNLabeledValue<NSString>.localizedString(forLabel: label) : getRawRelationsLabel(label: label);
            }
            relations.append(relationDictionary)
        }
        result["relations"] = relations
        
        //Instant message
        var instantMessageAddresses = [[String:String]]()
        for im in contact.instantMessageAddresses{
            var imDictionary = [String:String]()
            imDictionary["identifier"] = im.identifier
            imDictionary["value"] = String(im.value.username)
            if let label = im.label{
                imDictionary["label"] = localizedLabels ? CNLabeledValue<NSString>.localizedString(forLabel: label) : getRawInstantMessageLabel(label: label);
            }
            instantMessageAddresses.append(imDictionary)
        }
        result["instantMessageAddresses"] = instantMessageAddresses
        
        //Social profile
        var profiles = [[String:String]]()
        for profile in contact.socialProfiles{
            var profileDictionary = [String:String]()
            profileDictionary["identifier"] = profile.identifier
            profileDictionary["service"] = String(profile.value.service)
            profileDictionary["urlString"] = String(profile.value.urlString)
            profileDictionary["userIdentifier"] = String(profile.value.userIdentifier)
            profileDictionary["userName"] = String(profile.value.username)
            if let label = profile.label{
                profileDictionary["label"] = localizedLabels ? CNLabeledValue<NSString>.localizedString(forLabel: label) : getRawSocialProfileLabel(label: label);
            } else {
                profileDictionary["label"] = localizedLabels ? CNLabeledValue<NSString>.localizedString(forLabel: String(profile.value.service)) : getRawSocialProfileLabel(label: String(profile.value.service));
            }
            profiles.append(profileDictionary)
        }
        result["socialProfiles"] = profiles
        
        //Dates
        var dates = [[String:String]]()
        let formatter = DateFormatter()
        for date in contact.dates{
            var dateDictionary = [String:String]()
            dateDictionary["identifier"] = date.identifier
            
            if let aDate = date.value.date {
                let year = Calendar.current.component(.year, from: aDate)
                formatter.dateFormat = year == 1 ? "--MM-dd" : "yyyy-MM-dd";
                dateDictionary["value"] = formatter.string(from: aDate)
            }
            
            if let label = date.label{
                dateDictionary["label"] = localizedLabels ? CNLabeledValue<NSString>.localizedString(forLabel: label) : getRawDatesLabel(label: label);
            }
            dates.append(dateDictionary)
        }
        result["dates"] = dates

        //Websites
        var websites = [[String:String]]()
        for website in contact.urlAddresses{
            var websiteDictionary = [String:String]()
            websiteDictionary["identifier"] = website.identifier
            websiteDictionary["value"] = String(website.value)
            websiteDictionary["label"] = "other"
            if let label = website.label{
                websiteDictionary["label"] = localizedLabels ? CNLabeledValue<NSString>.localizedString(forLabel: label) : getRawWebsitesLabel(label: label);
            }
            websites.append(websiteDictionary)
        }
        result["websites"] = websites

        //Labels
        result["labels"] = [String]()
        return result
    }

    func getPhoneLabel(label: String?) -> String{
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case "main": return CNLabelPhoneNumberMain
            case "mobile": return CNLabelPhoneNumberMobile
            case "iphone": return CNLabelPhoneNumberiPhone
            case "work": return CNLabelWork
            case "home": return CNLabelHome
            case "other": return CNLabelOther
            default: return labelValue
        }
    }

    func getCommonLabel(label:String?) -> String{
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case "work": return CNLabelWork
            case "home": return CNLabelHome
            case "other": return CNLabelOther
            default: return labelValue
        }
    }
    
    func getInstantMessageLabel(label: String?) -> String {
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case "aim": return CNInstantMessageServiceAIM
            case "facebook": return CNInstantMessageServiceFacebook
            case "gadu gadu": return CNInstantMessageServiceGaduGadu
            case "google talk": return CNInstantMessageServiceGoogleTalk
            case "icq": return CNInstantMessageServiceICQ
            case "jabber": return CNInstantMessageServiceJabber
            case "msn": return CNInstantMessageServiceMSN
            case "qq": return CNInstantMessageServiceQQ
            case "skype": return CNInstantMessageServiceSkype
            case "yahoo": return CNInstantMessageServiceYahoo
            default: return labelValue
        }
    }
    
    func getRelationsLabel(label: String?) -> String {
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case "assistant": return CNLabelContactRelationAssistant
            case "manager": return CNLabelContactRelationManager
            case "brother": return CNLabelContactRelationBrother
            case "sister": return CNLabelContactRelationSister
            case "friend": return CNLabelContactRelationFriend
            case "spouse": return CNLabelContactRelationSpouse
            case "partner": return CNLabelContactRelationPartner
            case "parent": return CNLabelContactRelationParent
            case "mother": return CNLabelContactRelationMother
            case "father": return CNLabelContactRelationFather
            case "child": return CNLabelContactRelationChild
            default:
                if #available(iOS 11.0, *) {
                    switch labelValue.lowercased() {
                        case "daughter": return CNLabelContactRelationDaughter
                        case "son": return CNLabelContactRelationSon
                        default: return labelValue
                    }
                }
                if #available(iOS 13.0, *) {
                    switch labelValue.lowercased() {
                        //TODO. add all iOS 13 cases
                        default: return labelValue
                    }
                }
                return labelValue
        }
    }
    
    func getSocialProfileLabel(label: String?) -> String {
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case "flickr": return CNSocialProfileServiceFlickr
            case "facebook": return CNSocialProfileServiceFacebook
            case "linkedin": return CNSocialProfileServiceLinkedIn
            case "myspace": return CNSocialProfileServiceMySpace
            case "sina weibo": return CNSocialProfileServiceSinaWeibo
            case "tancent weibo": return CNSocialProfileServiceTencentWeibo
            case "twitter": return CNSocialProfileServiceTwitter
            case "yelp": return CNSocialProfileServiceYelp
            case "game center": return CNSocialProfileServiceGameCenter
            default: return labelValue
        }
    }
    
    func getSocialProfileUrl(label: String?, userName: String?) -> String {
        let labelValue = label ?? ""
        let userName = userName ?? ""

        switch(labelValue.lowercased()){
            case "flickr": return "http://flickr.com/\(userName)"
            case "facebook": return "http://facebook.com/\(userName)"
            case "linkedin": return "http://linkedin.com/in/\(userName)"
            case "myspace": return "http://myspace.com/\(userName)"
            case "sina weibo": return "http://weibo.com/n/\(userName)"
            case "twitter": return "https://twitter.com/\(userName)"
            default: return "x-apple:\(userName)"
        }
    }
    
    func getDatesLabel(label: String?) -> String {
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case "anniversary": return CNLabelDateAnniversary
            case "other": return CNLabelOther
            default: return labelValue
        }
    }
    
    func getWebsitesLabel(label: String?) -> String {
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case "homepage": return CNLabelURLAddressHomePage
            case "work": return CNLabelWork
            case "home": return CNLabelHome
            case "other": return CNLabelOther
            default: return labelValue
        }
    }

    func getRawPhoneLabel(_ label: String?) -> String{
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case CNLabelPhoneNumberMain.lowercased(): return "main"
            case CNLabelPhoneNumberMobile.lowercased(): return "mobile"
            case CNLabelPhoneNumberiPhone.lowercased(): return "iPhone"
            case CNLabelWork.lowercased(): return "work"
            case CNLabelHome.lowercased(): return "home"
            case CNLabelOther.lowercased(): return "other"
            default: return labelValue
        }
    }

    func getRawCommonLabel(_ label: String?) -> String{
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case CNLabelWork.lowercased(): return "work"
            case CNLabelHome.lowercased(): return "home"
            case CNLabelOther.lowercased(): return "other"
            default: return labelValue
        }
    }

    func getRawInstantMessageLabel(label: String?) -> String {
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case CNInstantMessageServiceAIM.lowercased(): return "aim"
            case CNInstantMessageServiceFacebook.lowercased(): return "facebook"
            case CNInstantMessageServiceGaduGadu.lowercased(): return "gadu gadu"
            case CNInstantMessageServiceGoogleTalk.lowercased(): return "google talk"
            case CNInstantMessageServiceICQ: return "icq"
            case CNInstantMessageServiceJabber: return "jabber"
            case CNInstantMessageServiceMSN: return "msn"
            case CNInstantMessageServiceQQ: return "qq"
            case CNInstantMessageServiceSkype: return "skype"
            case CNInstantMessageServiceYahoo: return "yahoo"
            default: return labelValue
        }
    }
    
    func getRawRelationsLabel(label: String?) -> String {
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case CNLabelContactRelationAssistant: return "assistant"
            case CNLabelContactRelationManager: return "manager"
            case CNLabelContactRelationBrother: return "brother"
            case CNLabelContactRelationSister: return "sister"
            case CNLabelContactRelationFriend: return "friend"
            case CNLabelContactRelationSpouse: return "spouse"
            case CNLabelContactRelationPartner: return "partner"
            case CNLabelContactRelationParent: return "parent"
            case CNLabelContactRelationMother: return "mother"
            case CNLabelContactRelationFather: return "father"
            case CNLabelContactRelationChild: return "child"
            default:
                if #available(iOS 11.0, *) {
                    switch(labelValue.lowercased()){
                        case CNLabelContactRelationDaughter: return "daughter"
                        case CNLabelContactRelationSon: return "son"
                        default: return labelValue
                    }
                }
                if #available(iOS 13.0, *) {
                    switch labelValue.lowercased() {
                        //TODO. add all iOS 13 cases
                    default:
                        return labelValue
                    }
                }
                return labelValue
        }
    }
    
    func getRawSocialProfileLabel(label: String?) -> String {
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case CNSocialProfileServiceFlickr.lowercased(): return "flickr"
            case CNSocialProfileServiceFacebook.lowercased(): return "facebook"
            case CNSocialProfileServiceLinkedIn.lowercased(): return "linkedin"
            case CNSocialProfileServiceMySpace.lowercased(): return "myspace"
            case CNSocialProfileServiceSinaWeibo.lowercased(): return "sina weibo"
            case CNSocialProfileServiceTencentWeibo.lowercased(): return "tancent weibo"
            case CNSocialProfileServiceTwitter.lowercased(): return "twitter"
            case CNSocialProfileServiceYelp.lowercased(): return "yelp"
            case CNSocialProfileServiceGameCenter.lowercased(): return "game center"
            default: return labelValue
        }
    }
    
    func getRawDatesLabel(label: String?) -> String {
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            
            case CNLabelDateAnniversary.lowercased(): return "anniversary"
            case CNLabelOther.lowercased(): return "other"
            default: return labelValue
        }
    }
    
    func getRawWebsitesLabel(label: String?) -> String {
        let labelValue = label ?? ""
        switch(labelValue.lowercased()){
            case CNLabelURLAddressHomePage.lowercased(): return "homepage"
            case CNLabelWork.lowercased(): return "work"
            case CNLabelHome.lowercased(): return "home"
            case CNLabelOther.lowercased(): return "other"
            default: return labelValue
        }
    }

}
