//
//  MyContacyVC.swift
//  SuccessEnSwift
//
//  Created by Milind Kudale on 28/03/18.
//  Copyright © 2018 milind.kudale. All rights reserved.
//

import UIKit
import LUExpandableTableView
import SwiftMultiSelect
import Alamofire
import SwiftyJSON

class MyContactVC: SliderVC, UITextFieldDelegate, UIDocumentPickerDelegate, UIDocumentMenuDelegate  {

    var items:[SwiftMultiSelectItem] = [SwiftMultiSelectItem]()
    var initialValues:[SwiftMultiSelectItem] = [SwiftMultiSelectItem]()
    var selectedItems:[SwiftMultiSelectItem] = [SwiftMultiSelectItem]()
    var arrImpFname = [String]()
    var arrImpMiddle = [String]();
    var arrImpLname = [String]();
    var arrImpEmail = [String]();
    var arrImpPhone = [String]();
    var arrPhoneContacts = [AnyObject]();
    var contactCsvArray:[Dictionary<String, AnyObject>] =  Array()
    
    var selectedTag = ""
    var selectAllRecords = false
    @IBOutlet var txtSearch : UITextField!
    @IBOutlet var tblContactList : LUExpandableTableView!
    @IBOutlet var btnMove : UIButton!
    @IBOutlet var btnDelete : UIButton!
    @IBOutlet weak var actionViewHeight: NSLayoutConstraint!
    @IBOutlet var noRecView : UIView!
    
    var isFilter = false;
    let cellReuseIdentifier = "CrmCell"
    let sectionHeaderReuseIdentifier = "MyCrmHeader"
    
    var arrContactData = [AnyObject]()
    var arrFirstName = [String]()
    var arrLastName = [String]()
    var arrEmail = [String]()
    var arrPhone = [String]()
    var arrContactId = [String]()
    var arrMiddleName = [String]()
    var arrCategory = [String]()
    
    var arrFirstNameSearch = [String]()
    var arrLastNameSearch = [String]()
    var arrEmailSearch = [String]()
    var arrPhoneSearch = [String]()
    var arrMiddleNameSearch = [String]()
    var arrCategorySearch = [String]()
    var arrContactIdSearch = [String]()
    
    var arrSelectedContact = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "My Contacts"
        tblContactList.register(MyCrmCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tblContactList.register(UINib(nibName: "CrmHeader", bundle: Bundle.main), forHeaderFooterViewReuseIdentifier: sectionHeaderReuseIdentifier)
        tblContactList.tableFooterView = UIView()
        isFilter = false;
        noRecView.isHidden = true
        
        actionViewHeight.constant = 0.0
        btnMove.layer.cornerRadius = 5.0
        btnDelete.layer.cornerRadius = 5.0
        btnMove.clipsToBounds = true
        btnDelete.clipsToBounds = true
        
        Config.doneString = ""
        SwiftMultiSelect.dataSource     = self
        SwiftMultiSelect.delegate       = self
        SwiftMultiSelect.dataSourceType = .phone
        
        let actionButton = JJFloatingActionButton()
        actionButton.buttonColor = APPORANGECOLOR
        actionButton.addItem(title: "", image: #imageLiteral(resourceName: "ic_add_white")) { item in
            print("Action Float button")
            OBJCOM.animateButton(button: actionButton)
            let storyboard = UIStoryboard(name: "CRM", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "idAddContactVC")
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: false, completion: nil)
        }
        actionButton.display(inViewController: self)
        
        txtSearch.leftViewMode = UITextFieldViewMode.always
        txtSearch.layer.cornerRadius = txtSearch.frame.size.height/2
        txtSearch.layer.borderColor = APPGRAYCOLOR.cgColor
        txtSearch.layer.borderWidth = 1.0
        txtSearch.clipsToBounds = true
        let uiView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let imageView = UIImageView(frame: CGRect(x: 5, y: 5, width: 20, height: 20))
        let image = #imageLiteral(resourceName: "icons8-search")
        
        imageView.image = image
        uiView.addSubview(imageView)
        txtSearch.leftView = uiView
        self.txtSearch.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if OBJCOM.isConnectedToNetwork(){
            //DispatchQueue.main.sync {
                OBJCOM.setLoader()
                getContactData()
           // }
        }else{
            OBJCOM.NoInternetConnectionCall()
        }
    }

    func getContactData(){
        let dictParam = ["userId": userID,
                         "platform":"3",
                         "crmFlag":"1"]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: dictParam, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        let dictParamTemp = ["param":jsonString];
        
        typealias JSONDictionary = [String:Any]
        OBJCOM.modalAPICall(Action: "getListCrm", param:dictParamTemp as [String : AnyObject],  vcObject: self){
            JsonDict, staus in
            let success:String = JsonDict!["IsSuccess"] as! String
            if success == "true"{
                self.arrContactData = JsonDict!["result"] as! [AnyObject]
                if self.arrContactData.count > 0 {
                    self.arrFirstName = self.arrContactData.compactMap { $0["contact_fname"] as? String }
                    self.arrMiddleName = self.arrContactData.compactMap { $0["contact_middle"] as? String }
                    self.arrLastName = self.arrContactData.compactMap { $0["contact_lname"] as? String }
                    self.arrEmail = self.arrContactData.compactMap { $0["contact_email"] as? String }
                    self.arrPhone = self.arrContactData.compactMap { $0["contact_phone"] as? String }
                    self.arrContactId = self.arrContactData.compactMap { $0["contact_id"] as? String }
                    self.arrCategory = self.arrContactData.compactMap { $0["contact_category"] as? String }
                }
                if self.arrFirstName.count > 0 {
                    self.noRecView.isHidden = true
                }
                self.tblContactList.expandableTableViewDataSource = self
                self.tblContactList.expandableTableViewDelegate = self
                self.tblContactList.reloadData()
                OBJCOM.hideLoader()
            }else{
                self.noRecView.isHidden = false
                self.tblContactList.expandableTableViewDataSource = self
                self.tblContactList.expandableTableViewDelegate = self
                self.tblContactList.reloadData()
                print("result:",JsonDict ?? "")
                OBJCOM.hideLoader()
            }
        };
    }
    
    @IBAction func actionSelectAll(_ sender: UIButton) {
        OBJCOM.animateButton(button: sender)
        var arrId = [String]()
        if isFilter {
            arrId = arrContactIdSearch
        }else{
            arrId = arrContactId
        }
        if !sender.isSelected{
            self.arrSelectedContact.removeAll()
            for id in arrId {
                self.arrSelectedContact.append(id)
            }
            sender.isSelected = true
            selectAllRecords = true
        }else{
            self.arrSelectedContact.removeAll()
            sender.isSelected = false
            selectAllRecords = false
        }
        self.tblContactList.reloadData()
        showHideMoveDeleteButtons()
        print("Selected id >> ",self.arrSelectedContact)
    }
    
    @IBAction func actionSelectRecord(_ sender: UIButton) {
        OBJCOM.animateButton(button: sender)
        selectAllRecords = false
        view.layoutIfNeeded()
        var arrId = [String]()
        if isFilter {
            arrId = arrContactIdSearch
        }else{
            arrId = arrContactId
        }
        if self.arrSelectedContact.contains(arrId[sender.tag]){
            if let index = self.arrSelectedContact.index(of: arrId[sender.tag]) {
                self.arrSelectedContact.remove(at: index)
            }
        }else{
            self.arrSelectedContact.append(arrId[sender.tag])
        }
        print("Selected id >> ",self.arrSelectedContact)
        self.tblContactList.reloadData()
        showHideMoveDeleteButtons()
    }
    
    func showHideMoveDeleteButtons(){
        if self.arrSelectedContact.count > 0{
            self.actionViewHeight.constant = 40.0
        }else{
            self.actionViewHeight.constant = 0.0
        }
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func actionMoveRecord(_ sender: UIButton) {
        //OBJCOM.animateButton(button: sender)
        if arrSelectedContact.count > 0 {
            let selected = arrSelectedContact.joined(separator: ",")
            self.selectOptionsForMoveContacts(ContactId: selected)
        }
        
    }
    @IBAction func actionDeleteMultipleRecord(_ sender: UIButton) {
        //OBJCOM.animateButton(button: sender)
        if self.arrSelectedContact.count>0{
            let strSelectedID = self.arrSelectedContact.joined(separator: ",")
            var msg = ""
            if self.selectAllRecords == true {
                msg = "Do you want to delete all contacts."
            }else{
                msg = "Do you want to delete selected contacts."
            }
            let alertController = UIAlertController(title: "", message: msg, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default) {
                UIAlertAction in
                
                if self.selectAllRecords == true {
                    if OBJCOM.isConnectedToNetwork(){
                        OBJCOM.setLoader()
                        self.deleteAllRecords()
                    }else{
                        OBJCOM.NoInternetConnectionCall()
                    }
                }else{
                    if OBJCOM.isConnectedToNetwork(){
                        OBJCOM.setLoader()
                        self.deleteContact(ContactId: strSelectedID)
                    }else{
                        OBJCOM.NoInternetConnectionCall()
                    }
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
                UIAlertAction in }
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }else{
            OBJCOM.setAlert(_title: "", message: "Please select atleast one or more Contact(s) to delete.")
        }
    }
    
    @IBAction func actionEditRecord(_ sender: UIButton) {
        //OBJCOM.animateButton(button: sender)
        self.arrSelectedContact.removeAll()
        var arrId = [String]()
        if isFilter {
            arrId = arrContactIdSearch
        }else{
            arrId = arrContactId
        }
        let selectedID = arrId[sender.tag]
        print("SelectedID >> ",selectedID)
        self.editContact(ContactId: selectedID, view: sender)
    }
    @IBAction func actionDeleteRecord(_ sender: UIButton) {
        //OBJCOM.animateButton(button: sender)
        self.arrSelectedContact.removeAll()
        var arrId = [String]()
        if isFilter {
            arrId = arrContactIdSearch
        }else{
            arrId = arrContactId
        }
        let selectedID = arrId[sender.tag]
        let alertController = UIAlertController(title: "", message: "Do you want to delete this Contact", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default) {
            UIAlertAction in
            if OBJCOM.isConnectedToNetwork(){
                OBJCOM.setLoader()
                self.deleteContact(ContactId: selectedID)
            }else{
                OBJCOM.NoInternetConnectionCall()
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
            UIAlertAction in }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
        print("SelectedID >> ",selectedID)
    }
    @IBAction func actionAssignCampaign(_ sender: UIButton) {
        self.arrSelectedContact.removeAll()
        var arrId = [String]()
        if isFilter {
            arrId = arrContactIdSearch
        }else{
            arrId = arrContactId
        }
        let storyboard = UIStoryboard(name: "CRM", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "idPopUpAssignCampaign") as! PopUpAssignCampaign
        vc.contactId = arrId[sender.tag]
        vc.isGroup = false
        vc.modalPresentationStyle = .custom
        vc.modalTransitionStyle = .crossDissolve
        vc.view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
        self.present(vc, animated: false, completion: nil)
    }
    @IBAction func actionSetTag(_ sender: UIButton) {
        var arrId : [String] = []
        if isFilter {
            arrId = arrContactIdSearch
        }else{
            arrId = arrContactId
        }
        
        let contact_id = arrId[sender.tag]
        setTagCrm(contact_id:contact_id)
    }
    @IBAction func actionBtnMore(_ sender: Any) {
        self.selectOptions()
    }
}

// MARK: - LUExpandableTableViewDataSource
extension MyContactVC: LUExpandableTableViewDataSource {
    func numberOfSections(in expandableTableView: LUExpandableTableView) -> Int {
        if isFilter {
            return self.arrFirstNameSearch.count
        }else { return self.arrFirstName.count }
    }
    
    func expandableTableView(_ expandableTableView: LUExpandableTableView, numberOfRowsInSection section: Int) -> Int { return 1 }
    
    func expandableTableView(_ expandableTableView: LUExpandableTableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tblContactList.dequeueReusableCell(withIdentifier: "CrmCell") as? MyCrmCell else {
            assertionFailure("Cell shouldn't be nil")
            return UITableViewCell()
        }
        var category = ""
        if isFilter {
            cell.selectionStyle = .none
            cell.lblEmail.text = "Email : \(self.arrEmailSearch[indexPath.section])";
            cell.lblPhone.text = "Phone : \(self.arrPhoneSearch[indexPath.section])";
            cell.lblTag.text = "Tag : ";
            category = self.arrCategorySearch[indexPath.section]
            
            if self.arrEmailSearch[indexPath.section] == "" {
                cell.btnAssignCampaign.isHidden = true
            }else{
                cell.btnAssignCampaign.isHidden = false
            }
        }else{
            cell.selectionStyle = .none
            cell.lblEmail.text = "Email : \(self.arrEmail[indexPath.section])";
            cell.lblPhone.text = "Phone : \(self.arrPhone[indexPath.section])";
            cell.lblTag.text = "Tag : ";
            category = self.arrCategory[indexPath.section]
            
            if self.arrEmail[indexPath.section] == "" {
                cell.btnAssignCampaign.isHidden = true
            }else{
                cell.btnAssignCampaign.isHidden = false
            }
        }
        
        if category != "" {
            cell.btnTag.setTitle(category, for: .normal)
            if category == "Green Apple"{
                cell.btnTag.setImage(#imageLiteral(resourceName: "greenApple"), for: .normal)
                cell.btnTag.setTitleColor(colorGreenApple, for: .normal)
                cell.btnTag.layer.borderColor = colorGreenApple.cgColor
            }else if category == "Red Apple"{
                cell.btnTag.setImage(#imageLiteral(resourceName: "redApple"), for: .normal)
                cell.btnTag.setTitleColor(colorRedApple, for: .normal)
                cell.btnTag.layer.borderColor = colorRedApple.cgColor
            }else if category == "Brown Apple"{
                cell.btnTag.setImage(#imageLiteral(resourceName: "brownApple"), for: .normal)
                cell.btnTag.setTitleColor(colorBrownApple, for: .normal)
                cell.btnTag.layer.borderColor = colorBrownApple.cgColor
            }else if category == "Rotten Apple"{
                cell.btnTag.setImage(#imageLiteral(resourceName: "rottenApple"), for: .normal)
                cell.btnTag.setTitleColor(colorRottenApple, for: .normal)
                cell.btnTag.layer.borderColor = colorRottenApple.cgColor
            }
        }else{
            cell.btnTag.setTitle(" Add Tag ", for: .normal)
            cell.btnTag.setTitleColor(UIColor.black, for: .normal)
            cell.btnTag.setImage(#imageLiteral(resourceName: "40x40_ios"), for: .normal)
            cell.btnTag.layer.borderColor = APPGRAYCOLOR.cgColor
        }
        
        cell.btnEdit.setImage(#imageLiteral(resourceName: "edit_black"), for: .normal)
        cell.btnDelete.setImage(#imageLiteral(resourceName: "delete_black"), for: .normal)
        cell.btnAssignCampaign.setImage(#imageLiteral(resourceName: "campain_black"), for: .normal)
        
        cell.btnTag.tag = indexPath.section
        cell.btnEdit.tag = indexPath.section
        cell.btnDelete.tag = indexPath.section
        cell.btnAssignCampaign.tag = indexPath.section
        
        cell.btnTag.addTarget(self, action: #selector(actionSetTag), for: .touchUpInside)
        cell.btnEdit.addTarget(self, action: #selector(actionEditRecord), for: .touchUpInside)
        cell.btnDelete.addTarget(self, action: #selector(actionDeleteRecord), for: .touchUpInside)
        cell.btnAssignCampaign.addTarget(self, action: #selector(actionAssignCampaign), for: .touchUpInside)
        return cell
    }
    
    func expandableTableView(_ expandableTableView: LUExpandableTableView, sectionHeaderOfSection section: Int) -> LUExpandableTableViewSectionHeader {
        guard let sectionHeader = tblContactList.dequeueReusableHeaderFooterView(withIdentifier: "MyCrmHeader") as? CrmHeaderCell else {
            assertionFailure("Section header shouldn't be nil")
            return LUExpandableTableViewSectionHeader()
        }
        var fname = ""
        var lname = ""
        if isFilter {
            fname = self.arrFirstNameSearch[section]
            lname = self.arrLastNameSearch[section]
            if self.arrSelectedContact.contains(self.arrContactIdSearch[section]){
                sectionHeader.selectRecordButton.isSelected = true
            }else{
                sectionHeader.selectRecordButton.isSelected = false
            }
        }else{
            fname = self.arrFirstName[section]
            lname = self.arrLastName[section]
            if self.arrSelectedContact.contains(self.arrContactId[section]){
                sectionHeader.selectRecordButton.isSelected = true
            }else{
                sectionHeader.selectRecordButton.isSelected = false
            }
        }
        sectionHeader.label.text = "\(fname) \(lname)"
        
        sectionHeader.selectRecordButton.tag = section
        sectionHeader.selectRecordButton.setImage(#imageLiteral(resourceName: "uncheck"), for: .normal)
        sectionHeader.selectRecordButton.setImage(#imageLiteral(resourceName: "checkbox_ic"), for: .selected)
        sectionHeader.selectRecordButton.addTarget(self, action: #selector(actionSelectRecord), for: .touchUpInside)
        return sectionHeader
    }
}

// MARK: - LUExpandableTableViewDelegate
extension MyContactVC: LUExpandableTableViewDelegate {
    func expandableTableView(_ expandableTableView: LUExpandableTableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 130 }
    
    func expandableTableView(_ expandableTableView: LUExpandableTableView, heightForHeaderInSection section: Int) -> CGFloat { return 44.0 }
    
    // MARK: - Optional
    
    func expandableTableView(_ expandableTableView: LUExpandableTableView, didSelectRowAt indexPath: IndexPath) {
        print("Did select cell at section \(indexPath.section) row \(indexPath.row)")
    }
    
    func expandableTableView(_ expandableTableView: LUExpandableTableView, didSelectSectionHeader sectionHeader: LUExpandableTableViewSectionHeader, atSection section: Int) {
        var arrId : [String] = []
        if isFilter {
            arrId = arrContactIdSearch
        }else{
            arrId = arrContactId
        }
        print("Did select section header at section \(section)")
        let storyboard = UIStoryboard(name: "CRM", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "idViewAndEditContactVC") as! ViewAndEditContactVC
        vc.contactID = arrId[section]
        vc.isEditable = false
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: false, completion: nil)
    }
    
    func expandableTableView(_ expandableTableView: LUExpandableTableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        print("Will display cell at section \(indexPath.section) row \(indexPath.row)")
        
        // self.arrSelectedRecords.removeAll()
    }
    
    func expandableTableView(_ expandableTableView: LUExpandableTableView, willDisplaySectionHeader sectionHeader: LUExpandableTableViewSectionHeader, forSection section: Int) {
        print("Will display section header for section \(section)")
    }
}

//------

extension MyContactVC {
    
    func selectOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actionImportDevContact = UIAlertAction(title: "Import phone contact(s)", style: .default)
        { UIAlertAction in
            SwiftMultiSelect.Show(to: self)
        }
        actionImportDevContact.setValue(UIColor.black, forKey: "titleTextColor")
        
        let actionImportDevice = UIAlertAction(title: "Import new phone contact(s)", style: .default)
        { UIAlertAction in
            let storyboard = UIStoryboard(name: "CRM", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "idNewContactListVC") as! NewContactListVC
            vc.contact_flag = "1"
            vc.modalTransitionStyle = .crossDissolve
            vc.view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
            self.present(vc, animated: false, completion: nil)
        }
        actionImportDevice.setValue(UIColor.black, forKey: "titleTextColor")
        
        let actionImportGoogleContact = UIAlertAction(title: "Import Google Contact(s)", style: .default)
        { UIAlertAction in
            self.getGoogleContacts()
        }
        actionImportGoogleContact.setValue(UIColor.black, forKey: "titleTextColor")
    
        let actionImport = UIAlertAction(title: "Import Contact(s) CSV", style: .default)
        { UIAlertAction in
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.apple.iwork.pages.pages", "com.apple.iwork.numbers.numbers", "com.apple.iwork.keynote.key","public.image", "com.apple.application", "public.item","public.data", "public.content", "public.audiovisual-content", "public.movie", "public.audiovisual-content", "public.video", "public.audio", "public.text", "public.data", "public.zip-archive", "com.pkware.zip-archive", "public.composite-content", "public.text"], in: .import)
            
            documentPicker.delegate = self
            self.present(documentPicker, animated: true, completion: nil)
        }
        actionImport.setValue(UIColor.black, forKey: "titleTextColor")
        
        let actionExport = UIAlertAction(title: "Export Contact(s)", style: .default)
        { UIAlertAction in
            self.contactCsvArray = []
            for obj in self.arrContactData {
                self.contactCsvArray.append(obj as! Dictionary<String, AnyObject>)
            }
            //print(self.contactCsvArray)
            self.createCSV(from: self.contactCsvArray, crmFlag: "1")
        }
        actionExport.setValue(UIColor.black, forKey: "titleTextColor")
        
        let actionDuplicateContacts = UIAlertAction(title: "Remove duplicate  contact(s)", style: .default)
        { UIAlertAction in
            
            if OBJCOM.isConnectedToNetwork(){
                OBJCOM.setLoader()
                self.removeDuplicateContacts()
            }else{
                OBJCOM.NoInternetConnectionCall()
            }
           
        }
        actionDuplicateContacts.setValue(UIColor.black, forKey: "titleTextColor")
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel)
        { UIAlertAction in }
        actionCancel.setValue(UIColor.red, forKey: "titleTextColor")
        
        alert.addAction(actionImportDevice)
        alert.addAction(actionImportDevContact)
        alert.addAction(actionImportGoogleContact)
        alert.addAction(actionImport)
        alert.addAction(actionExport)
        alert.addAction(actionDuplicateContacts)
        alert.addAction(actionCancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    func selectOptionsForMoveContacts(ContactId: String) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let actionImport = UIAlertAction(title: "My Prospects", style: .default)
        {
            UIAlertAction in
            self.moveContact(ContactId: ContactId, crmFlag:  "3")
        }
        actionImport.setValue(UIColor.black, forKey: "titleTextColor")
        let actionExport = UIAlertAction(title: "My Customers", style: .default)
        {
            UIAlertAction in
            self.moveContact(ContactId: ContactId, crmFlag:  "2")
        }
        actionExport.setValue(UIColor.black, forKey: "titleTextColor")
        let actionRecruit = UIAlertAction(title: "My Recruits", style: .default)
        {
            UIAlertAction in
            self.moveContact(ContactId: ContactId, crmFlag:  "4")
        }
        actionRecruit.setValue(UIColor.black, forKey: "titleTextColor")
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel)
        {
            UIAlertAction in
        }
        actionCancel.setValue(UIColor.red, forKey: "titleTextColor")
        
        alert.addAction(actionImport)
        alert.addAction(actionExport)
        alert.addAction(actionRecruit)
        alert.addAction(actionCancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    func editContact(ContactId: String, view:UIButton){
        OBJCOM.animateButton(button: view)
        let storyboard = UIStoryboard(name: "CRM", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "idViewAndEditContactVC") as! ViewAndEditContactVC
        vc.modalTransitionStyle = .crossDissolve
        vc.isEditable = true
        vc.contactID = ContactId
        self.present(vc, animated: false, completion: nil)
    }
    
    func deleteContact(ContactId: String){
        
        let dictParam = ["userId": userID,
                         "platform":"3",
                         "contactIds":ContactId]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: dictParam, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        let dictParamTemp = ["param":jsonString];
        
        typealias JSONDictionary = [String:Any]
        OBJCOM.modalAPICall(Action: "deleteMultipleRowCrm", param:dictParamTemp as [String : AnyObject],  vcObject: self){
            JsonDict, staus in
            let success:String = JsonDict!["IsSuccess"] as! String
            if success == "true"{
                let result = JsonDict!["result"] as AnyObject
                OBJCOM.hideLoader()
                OBJCOM.setAlert(_title: "", message: result as! String)
                
            }else{
                print("result:",JsonDict ?? "")
                OBJCOM.hideLoader()
            }
            if OBJCOM.isConnectedToNetwork(){
                OBJCOM.setLoader()
                self.getContactData()
            }else{
                OBJCOM.NoInternetConnectionCall()
            }
        };
    }
    
    func deleteAllRecords(){
        
        let dictParam = ["userId": userID,
                         "platform":"3",
                         "contact_flag":"1"]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: dictParam, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        let dictParamTemp = ["param":jsonString];
        
        typealias JSONDictionary = [String:Any]
        OBJCOM.modalAPICall(Action: "deleteAllCrm", param:dictParamTemp as [String : AnyObject],  vcObject: self){
            JsonDict, staus in
            let success:String = JsonDict!["IsSuccess"] as! String
            if success == "true"{
                let result = JsonDict!["result"] as AnyObject
                OBJCOM.hideLoader()
                OBJCOM.setAlert(_title: "", message: result as! String)
                self.showHideMoveDeleteButtons()
                self.selectAllRecords = false
            }else{
                print("result:",JsonDict ?? "")
                OBJCOM.hideLoader()
            }
            if OBJCOM.isConnectedToNetwork(){
                OBJCOM.setLoader()
                self.getContactData()
            }else{
                OBJCOM.NoInternetConnectionCall()
            }
        };
    }
    
   
    func moveContact(ContactId: String, crmFlag: String){
        
        let dictParam = ["userId": userID,
                         "platform":"3",
                         "contactId":ContactId,
                         "newCrmFlag" : crmFlag]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: dictParam, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        let dictParamTemp = ["param":jsonString];
        
        typealias JSONDictionary = [String:Any]
        OBJCOM.modalAPICall(Action: "moveRowCrm", param:dictParamTemp as [String : AnyObject],  vcObject: self){
            JsonDict, staus in
            let success:String = JsonDict!["IsSuccess"] as! String
            if success == "true"{
                let result = JsonDict!["result"] as AnyObject
                OBJCOM.hideLoader()
                OBJCOM.setAlert(_title: "", message: result as! String)
                
            }else{
                print("result:",JsonDict ?? "")
                OBJCOM.hideLoader()
            }
            if OBJCOM.isConnectedToNetwork(){
                OBJCOM.setLoader()
                self.getContactData()
            }else{
                OBJCOM.NoInternetConnectionCall()
            }
        };
    }
}

extension MyContactVC {
    //Search code
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.txtSearch.addTarget(self, action: #selector(self.searchRecordsAsPerText(_ :)), for: .editingChanged)
        isFilter = true
        return isFilter
    }
    
    @objc func searchRecordsAsPerText(_ textfield:UITextField) {
        
        arrFirstNameSearch.removeAll()
        arrLastNameSearch.removeAll()
        arrMiddleNameSearch.removeAll()
        arrEmailSearch.removeAll()
        arrPhoneSearch.removeAll()
        arrCategorySearch.removeAll()
        arrContactIdSearch.removeAll()
        
        if textfield.text?.count != 0 {
            for i in 0 ..< arrContactData.count {
                let strfName = arrFirstName[i].lowercased().range(of: textfield.text!, options: .caseInsensitive, range: nil,   locale: nil)
                let strmName = arrMiddleName[i].lowercased().range(of: textfield.text!, options: .caseInsensitive, range: nil,   locale: nil)
                let strlName = arrLastName[i].lowercased().range(of: textfield.text!, options: .caseInsensitive, range: nil,   locale: nil)
                let strEmail = arrEmail[i].lowercased().range(of: textfield.text!, options: .caseInsensitive, range: nil,   locale: nil)
                let strPhone = arrPhone[i].lowercased().range(of: textfield.text!, options: .caseInsensitive, range: nil,   locale: nil)
                let strCat = arrCategory[i].lowercased().range(of: textfield.text!, options: .caseInsensitive, range: nil,   locale: nil)
                
                if strfName != nil || strmName != nil || strlName != nil || strEmail != nil || strPhone != nil || strCat != nil{
                    arrFirstNameSearch.append(arrFirstName[i])
                    arrMiddleNameSearch.append(arrMiddleName[i])
                    arrLastNameSearch.append(arrLastName[i])
                    arrEmailSearch.append(arrEmail[i])
                    arrPhoneSearch.append(arrPhone[i])
                    arrCategorySearch.append(arrCategory[i])
                    arrContactIdSearch.append(arrContactId[i])
                }
            }
        } else {
            isFilter = false
        }
        tblContactList.reloadData()
    }
}

extension MyContactVC {
    func setTagCrm(contact_id:String) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actionGreenApple = UIAlertAction(title: "Green Apple", style: .default)
        {
            UIAlertAction in
            self.apiCallForUpdateTag(tag: "Green Apple", contact_id: contact_id)
        }
        actionGreenApple.setValue(colorGreenApple, forKey: "titleTextColor")
        actionGreenApple.setValue(arrAppleImages[2], forKey: "image")
        
        let actionRedApple = UIAlertAction(title: "Red Apple", style: .default)
        {
            UIAlertAction in
            self.apiCallForUpdateTag(tag: "Red Apple", contact_id: contact_id)
        }
        actionRedApple.setValue(colorRedApple, forKey: "titleTextColor")
        actionRedApple.setValue(arrAppleImages[1], forKey: "image")
        
        let actionBrownApple = UIAlertAction(title: "Brown Apple", style: .default)
        {
            UIAlertAction in
            self.apiCallForUpdateTag(tag: "Brown Apple", contact_id: contact_id)
        }
        actionBrownApple.setValue(colorBrownApple, forKey: "titleTextColor")
        actionBrownApple.setValue(arrAppleImages[3], forKey: "image")
        
        let actionRottenApple = UIAlertAction(title: "Rotten Apple", style: .default)
        {
            UIAlertAction in
            self.apiCallForUpdateTag(tag: "Rotten Apple", contact_id: contact_id)
        }
        actionRottenApple.setValue(colorRottenApple, forKey: "titleTextColor")
        actionRottenApple.setValue(arrAppleImages[4], forKey: "image")
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel)
        {
            UIAlertAction in
        }
        actionCancel.setValue(UIColor.black, forKey: "titleTextColor")
        
        alert.addAction(actionGreenApple)
        alert.addAction(actionRedApple)
        alert.addAction(actionBrownApple)
        alert.addAction(actionRottenApple)
        alert.addAction(actionCancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    func apiCallForUpdateTag(tag:String, contact_id:String){
        let dictParam = ["contact_id": contact_id,
                         "contact_category":tag]
        
        typealias JSONDictionary = [String:Any]
        OBJCOM.modalAPICall(Action: "updateTag", param:dictParam as [String : AnyObject],  vcObject: self){
            JsonDict, staus in
            let success:String = JsonDict!["IsSuccess"] as! String
            if success == "true"{
                let result = JsonDict!["result"] as AnyObject
                OBJCOM.hideLoader()
                OBJCOM.setAlert(_title: "", message: result as! String)
                if OBJCOM.isConnectedToNetwork(){
                    OBJCOM.setLoader()
                    self.getContactData()
                }else{
                    OBJCOM.NoInternetConnectionCall()
                }
            }else{
                print("result:",JsonDict ?? "")
                OBJCOM.hideLoader()
            }
        };
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print(url)
        
        print(url.lastPathComponent)
        print(url.pathExtension)
        
        if controller.documentPickerMode == .import {
            arrImpFname = [];
            //   arrImpMiddle = [];
            arrImpLname = [];
            arrImpEmail = [];
            arrImpPhone = [];
            
            let content = try? String(contentsOf: url, encoding: .ascii)
            var rows = content?.components(separatedBy: "\n")
            
            var columnsTitle = rows![0].components(separatedBy: ",")
            if columnsTitle.count >= 4 {
                var fn = columnsTitle[0]
                // let mn = columnsTitle[1]
                var ln = columnsTitle[1]
                var em = columnsTitle[2]
                var ph = columnsTitle[3]
                
                fn = fn.replacingOccurrences(of: "\r", with: "")
                ln = ln.replacingOccurrences(of: "\r", with: "")
                em = em.replacingOccurrences(of: "\r", with: "")
                ph = ph.replacingOccurrences(of: "\r", with: "")
                
                if fn == "fname" && ln == "lname" && em == "email" && ph == "phone"{
                    for i in 1..<(rows?.count)!-1 {
                        var columns = rows![i].components(separatedBy: ",")
                        if columns.count > 0{
                            arrImpFname.append(columns[0])
                            // arrImpMiddle.append(columns[1])
                            arrImpLname.append(columns[1])
                            arrImpEmail.append(columns[2])
                            arrImpPhone.append(columns[3])
                        }
                    }
                    var importArray = [AnyObject]()
                    for i in 0..<arrImpFname.count {
                        let tempDict = ["fname": arrImpFname[i],
                                        "lname": arrImpLname[i],
                                        "email": arrImpEmail[i],
                                        "phone": arrImpPhone[i]]
                        importArray.append(tempDict as AnyObject)
                    }
                    if importArray.count > 0 {
                        self.importCSVAPIContacts(impArray: importArray, crmFlag: "1")
                    }
                }else{
                    OBJCOM.setAlert(_title: "", message: "Selected file format is invalid.")
                }
            }else{
                OBJCOM.setAlert(_title: "", message: "Selected file format is invalid.")
            }
        }
    }
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        
    }
}

extension MyContactVC : SwiftMultiSelectDelegate, SwiftMultiSelectDataSource {
    
    
    func getGoogleContacts() {
        
        let storyboard = UIStoryboard(name: "CRM", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "idGmailContactVC") as! GmailContactVC
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: false, completion: nil)
    
//        let storyBoard = UIStoryboard(name:"CRM", bundle:nil)
//        let controllerName = (storyBoard.instantiateViewController(withIdentifier: "idGmailContactVC"))
//        controllerName.hidesBottomBarWhenPushed = true
//        self.delegate?.pushTo(viewController: controllerName)
    }
    
    
    //MARK: - SwiftMultiSelectDelegate
    func userDidSearch(searchString: String) {
        if searchString == ""{
            selectedItems = items
        }else{
            selectedItems = items.filter({$0.title.lowercased().contains(searchString.lowercased()) || ($0.description != nil && $0.description!.lowercased().contains(searchString.lowercased())) })
        }
    }
    
    func numberOfItemsInSwiftMultiSelect() -> Int {
        return selectedItems.count
    }
    
    func swiftMultiSelect(didUnselectItem item: SwiftMultiSelectItem) {
        if self.selectedItems.containsReference(obj: item as AnyObject){
            let index = find(itemFind: item)
            self.selectedItems.remove(at: index!)
        }
    }
    
    func swiftMultiSelect(didSelectItem item: SwiftMultiSelectItem) {
        
        if self.selectedItems.containsReference(obj: item as AnyObject){
            //let index = find(itemFind: item)
            self.selectedItems.append(item)
        }
    }
    
    func didCloseSwiftMultiSelect() {
    }
    
    func swiftMultiSelect(itemAtRow row: Int) -> SwiftMultiSelectItem {
        print(selectedItems[row])
        return selectedItems[row]
    }
    
    func find(itemFind: SwiftMultiSelectItem) -> Int? {
        for i in 0...self.selectedItems.count {
            if self.selectedItems[i] == itemFind {
                return i
            }
        }
        return nil
    }
    
    func swiftMultiSelect(didSelectItems items: [SwiftMultiSelectItem]) {
        
        initialValues   = items
        print("you have been selected: \(items.count) items!")
        if items.count > 0{
            //OBJCOM.setLoader()
            self.extractDeviceContacts(items:items)
        }else{
            OBJCOM.setAlert(_title: "", message: "Please select atleast one contact to import in success entellus.")
        }
    }
    
    func extractDeviceContacts(items:[SwiftMultiSelectItem]){
        //print(items)
        var arrForImport = [AnyObject]()
        for item in items {
            print(item.userInfo as Any)
            //item.userInfo?["contact_users_id"] = userID
            arrForImport.append(item.userInfo as AnyObject)
        }
       // print(arrForImport[0])
        if arrForImport.count > 0 {
            print("----------------------------------")
            let dictParam = ["userId": userID,
                             "platform":"3",
                             "contact_details":arrForImport] as [String : Any]
            
            let jsonData = try? JSONSerialization.data(withJSONObject: dictParam, options: [])
            let jsonString = String(data: jsonData!, encoding: .utf8)
            let dictParamTemp = ["param":jsonString];
            
            typealias JSONDictionary = [String:Any] //importCrmWithoutValidation
            OBJCOM.modalAPICall(Action: "importCrmDevice", param:dictParamTemp as [String : AnyObject],  vcObject: self){
                JsonDict, staus in
                let success:String = JsonDict!["IsSuccess"] as! String
                if success == "true"{
                    let result = JsonDict!["result"] as? String ?? ""
                    OBJCOM.hideLoader()
                   // OBJCOM.setAlert(_title: "", message: result as! String)
                    let alertController = UIAlertController(title: "", message: result, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Remove duplicate contact(s)", style: UIAlertActionStyle.default) {
                        UIAlertAction in
                        if OBJCOM.isConnectedToNetwork(){
                            OBJCOM.setLoader()
                            self.removeDuplicateContacts()
                        }else{
                            OBJCOM.NoInternetConnectionCall()
                        }
                    }
                    okAction.setValue(UIColor.red, forKey: "titleTextColor")
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)


                    if OBJCOM.isConnectedToNetwork(){
                        OBJCOM.setLoader()
                        self.getContactData()
                    }else{
                        OBJCOM.NoInternetConnectionCall()
                    }
                }else{
                    print("result:",JsonDict ?? "")
                    OBJCOM.hideLoader()
                }
            };
        }
    }
    
    func removeDuplicateContacts(){
        
        let dictParam = ["userId": userID,
                         "platform":"3",
                         "crmFlag":"1"]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: dictParam, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        let dictParamTemp = ["param":jsonString];
        
        typealias JSONDictionary = [String:Any]
        OBJCOM.modalAPICall(Action: "deleteDuplicateCrm", param:dictParamTemp as [String : AnyObject],  vcObject: self){
            JsonDict, staus in
            let success:String = JsonDict!["IsSuccess"] as! String
            if success == "true"{
                let result = JsonDict!["result"] as AnyObject
                OBJCOM.hideLoader()
                OBJCOM.setAlert(_title: "", message: result as! String)
                if OBJCOM.isConnectedToNetwork(){
                    OBJCOM.setLoader()
                    self.getContactData()
                }else{
                    OBJCOM.NoInternetConnectionCall()
                }
            }else{
                print("result:",JsonDict ?? "")
                let result = JsonDict!["result"] as AnyObject
                OBJCOM.setAlert(_title: "", message: result as! String)
                OBJCOM.hideLoader()
            }
        };
    }
    
    func importCSVAPIContacts(impArray : [AnyObject], crmFlag : String){
        let dictParam = ["userId":userID,
                         "platform":"3",
                         "crmFlag":"1",
                         "csvDetails": impArray] as [String : Any]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: dictParam, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        let dictParamTemp = ["param":jsonString];
        
        typealias JSONDictionary = [String:Any]
        OBJCOM.modalAPICall(Action: "importCsvCrm", param:dictParamTemp as [String : AnyObject],  vcObject: self) {
            JsonDict, staus in
            
            let success:String = JsonDict!["IsSuccess"] as! String
            if success == "true"{
                OBJCOM.hideLoader()
                let result = JsonDict!["result"] as! String
                print(result)
                let alertController = UIAlertController(title: "", message: result, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                    UIAlertAction in
                   // DispatchQueue.main.sync {
                        if OBJCOM.isConnectedToNetwork(){
                            OBJCOM.setLoader()
                            self.getContactData()
                        }else{
                            OBJCOM.NoInternetConnectionCall()
                        }
                        self.dismiss(animated: true, completion: nil)
                   // }
                    
                }
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                
            }else{
                print("result:",JsonDict ?? "")
                OBJCOM.hideLoader()
            }
        };
    }
}

extension Array {
    func containsReference(obj: AnyObject) -> Bool {
        for ownedItem in self {
            if let ownedObject: AnyObject = ownedItem as AnyObject {
                if (ownedObject === obj) {
                    return true
                }
            }
        }
        
        return false
    }
}