import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:quiver/core.dart';

export 'share.dart';

class ContactsService {
  static const MethodChannel _channel = MethodChannel('github.com/clovisnicolas/flutter_contacts');

  /// Fetches all contacts, or when specified, the contacts with a name
  /// matching [query]
  static Future<Iterable<Contact>> getContacts(
      {String query,
      bool withThumbnails = true,
      bool photoHighResolution = true,
      bool orderByGivenName = true,
      bool iOSLocalizedLabels = true}) async {
    Iterable contacts = await _channel.invokeMethod('getContacts', <String, dynamic>{
      'query': query,
      'withThumbnails': withThumbnails,
      'photoHighResolution': photoHighResolution,
      'orderByGivenName': orderByGivenName,
      'iOSLocalizedLabels': iOSLocalizedLabels,
    });
    return contacts.map((m) => Contact.fromMap(m));
  }

  /// Fetches all contacts with names fields for list screen, or when specified, the contacts with a name
  /// matching [query]
  static Future<Iterable<Contact>> getContactsSummary(
      {String query,
      bool withThumbnails = true,
      bool photoHighResolution = false,
      bool orderByGivenName = true,
      bool iOSLocalizedLabels = true}) async {
    Iterable contacts = await _channel.invokeMethod('getContactsSummary', <String, dynamic>{
      'query': query,
      'withThumbnails': withThumbnails,
      'photoHighResolution': photoHighResolution,
      'orderByGivenName': orderByGivenName,
      'iOSLocalizedLabels': iOSLocalizedLabels,
    });
    return contacts.map((m) => Contact.fromSummaryMap(m));
  }

  /// Fetches all contacts identifiers, or when specified, the contacts with a name
  /// matching [query]
  static Future<Iterable<String>> getIdentifiers(
      {String query,
      bool withThumbnails = false,
      bool photoHighResolution = false,
      bool orderByGivenName = true,
      bool iOSLocalizedLabels = true}) async {
    Iterable contacts = await _channel.invokeMethod('getIdentifiers', <String, dynamic>{
      'query': query,
      'withThumbnails': withThumbnails,
      'photoHighResolution': photoHighResolution,
      'orderByGivenName': orderByGivenName,
      'iOSLocalizedLabels': iOSLocalizedLabels,
    });
    if (contacts != null && contacts.length > 0) {
      var first = contacts.first;
      return (first['identifiers'] as List)?.map((item) => item as String)?.toList();
    }
    return List<String>();
  }

  /// Fetches all contacts with specified identifiers for list screen, or when specified, the contacts with a name
  /// matching [query]
  static Future<Iterable<Contact>> getContactsByIdentifiers(
      {List<String> identifiers,
      bool withThumbnails = true,
      bool photoHighResolution = false,
      bool orderByGivenName = true,
      bool iOSLocalizedLabels = true}) async {
    Iterable contacts = await _channel.invokeMethod('getContactsByIdentifiers', <String, dynamic>{
      'identifiers': identifiers.join('|'),
      'withThumbnails': withThumbnails,
      'photoHighResolution': photoHighResolution,
      'orderByGivenName': orderByGivenName,
      'iOSLocalizedLabels': iOSLocalizedLabels,
    });
    return contacts.map((m) => Contact.fromMap(m));
  }

  /// Fetches all contacts, or when specified, the contacts with the phone
  /// matching [phone]
  static Future<Iterable<Contact>> getContactsForPhone(String phone,
      {bool withThumbnails = true, bool photoHighResolution = true, bool orderByGivenName = true, bool iOSLocalizedLabels = true}) async {
    if (phone == null || phone.isEmpty) return Iterable.empty();

    Iterable contacts = await _channel.invokeMethod('getContactsForPhone', <String, dynamic>{
      'phone': phone,
      'withThumbnails': withThumbnails,
      'photoHighResolution': photoHighResolution,
      'orderByGivenName': orderByGivenName,
      'iOSLocalizedLabels': iOSLocalizedLabels,
    });
    return contacts.map((m) => Contact.fromMap(m));
  }

  /// Fetches all contacts, or when specified, the contacts with the email
  /// matching [email]
  /// Works only on iOS
  static Future<Iterable<Contact>> getContactsForEmail(String email,
      {bool withThumbnails = true, bool photoHighResolution = true, bool orderByGivenName = true, bool iOSLocalizedLabels = true}) async {
    Iterable contacts = await _channel.invokeMethod('getContactsForEmail', <String, dynamic>{
      'email': email,
      'withThumbnails': withThumbnails,
      'photoHighResolution': photoHighResolution,
      'orderByGivenName': orderByGivenName,
      'iOSLocalizedLabels': iOSLocalizedLabels,
    });
    return contacts.map((m) => Contact.fromMap(m));
  }

  /// Loads the avatar for the given contact and returns it. If the user does
  /// not have an avatar, then `null` is returned in that slot. Only implemented
  /// on Android.
  static Future<Uint8List> getAvatar(final Contact contact, {final bool photoHighRes = true}) => _channel.invokeMethod('getAvatar', <String, dynamic>{
        'contact': Contact._toMap(contact),
        'photoHighResolution': photoHighRes,
      });

  /// Adds the [contact] to the device contact list
  static Future addContact(Contact contact) => _channel.invokeMethod('addContact', Contact._toMap(contact));

  /// Deletes the [contact] if it has a valid identifier
  static Future deleteContact(Contact contact) => _channel.invokeMethod('deleteContact', Contact._toMap(contact));

  /// Deletes the contacts with specified identifiers if they have valid identifiers
  static Future deleteContactsByIdentifiers(List<String> identifiers) =>
      _channel.invokeMethod('deleteContactsByIdentifiers', <String, dynamic>{'identifiers': identifiers.join('|')});

  /// Updates the [contact] if it has a valid identifier
  static Future updateContact(Contact contact) => _channel.invokeMethod('updateContact', Contact._toMap(contact));

  static Future<Contact> openContactForm({bool iOSLocalizedLabels = true}) async {
    dynamic result = await _channel.invokeMethod('openContactForm', <String, dynamic>{
      'iOSLocalizedLabels': iOSLocalizedLabels,
    });
    return _handleFormOperation(result);
  }

  static Future<Contact> openExistingContact(Contact contact, {bool iOSLocalizedLabels = true}) async {
    dynamic result = await _channel.invokeMethod(
      'openExistingContact',
      <String, dynamic>{
        'contact': Contact._toMap(contact),
        'iOSLocalizedLabels': iOSLocalizedLabels,
      },
    );
    return _handleFormOperation(result);
  }

  // Displays the device/native contact picker dialog and returns the contact selected by the user
  static Future<Contact> openDeviceContactPicker({bool iOSLocalizedLabels = true}) async {
    dynamic result = await _channel.invokeMethod('openDeviceContactPicker', <String, dynamic>{
      'iOSLocalizedLabels': iOSLocalizedLabels,
    });
    // result contains either :
    // - an Iterable of contacts containing 0 or 1 contact
    // - a FormOperationErrorCode value
    if (result is Iterable) {
      if (result.isEmpty) {
        return null;
      }
      result = result.first;
    }
    return _handleFormOperation(result);
  }

  static Contact _handleFormOperation(dynamic result) {
    if (result is int) {
      switch (result) {
        case 1:
          throw FormOperationException(errorCode: FormOperationErrorCode.FORM_OPERATION_CANCELED);
        case 2:
          throw FormOperationException(errorCode: FormOperationErrorCode.FORM_COULD_NOT_BE_OPEN);
        default:
          throw FormOperationException(errorCode: FormOperationErrorCode.FORM_OPERATION_UNKNOWN_ERROR);
      }
    } else if (result is Map) {
      return Contact.fromMap(result);
    } else {
      throw FormOperationException(errorCode: FormOperationErrorCode.FORM_OPERATION_UNKNOWN_ERROR);
    }
  }
}

class FormOperationException implements Exception {
  final FormOperationErrorCode errorCode;

  const FormOperationException({this.errorCode});

  String toString() => 'FormOperationException: $errorCode';
}

enum FormOperationErrorCode { FORM_OPERATION_CANCELED, FORM_COULD_NOT_BE_OPEN, FORM_OPERATION_UNKNOWN_ERROR }

class Contact {
  Contact(
      {this.identifier,
      this.displayName,
      this.givenName,
      this.middleName,
      this.prefix,
      this.suffix,
      this.familyName,
      this.company,
      this.jobTitle,
      this.emails,
      this.phones,
      this.postalAddresses,
      this.avatar,
      this.birthday,
      this.androidAccountType,
      this.androidAccountTypeRaw,
      this.androidAccountName,
      this.note,
      this.sip,
      this.phoneticGivenName,
      this.phoneticMiddleName,
      this.phoneticFamilyName,
      this.phoneticName,
      this.nickname,
      this.department,
      this.dates,
      this.instantMessageAddresses,
      this.relations,
      this.websites,
      this.socialProfiles,
      this.labels,
      this.birthDayString});

  String identifier, displayName, givenName, middleName, prefix, suffix, familyName, company, jobTitle;
  String note, sip, phoneticGivenName, phoneticMiddleName, phoneticFamilyName, phoneticName, nickname, department;
  String androidAccountTypeRaw, androidAccountName;
  AndroidAccountType androidAccountType;
  Iterable<Item> emails = [];
  Iterable<Item> phones = [];
  Iterable<PostalAddress> postalAddresses = [];
  Iterable<Item> dates = [];
  Iterable<Item> instantMessageAddresses = [];
  Iterable<Item> relations = [];
  Iterable<Item> websites = [];
  Iterable<Item> socialProfiles = [];
  Iterable<String> labels = [];

  Uint8List avatar;
  DateTime birthday;
  String birthDayString;

  String initials() {
    return ((this.givenName?.isNotEmpty == true ? this.givenName[0] : "") + (this.familyName?.isNotEmpty == true ? this.familyName[0] : ""))
        .toUpperCase();
  }

  Contact.fromSummaryMap(Map m) {
    identifier = m["identifier"];
    displayName = m["displayName"];
    givenName = m["givenName"];
    middleName = m["middleName"];
    familyName = m["familyName"];
    prefix = m["prefix"];
    suffix = m["suffix"];
    try {
      avatar = m["avatar"];
    } catch (e) {
      avatar = Uint8List(0);
    }
  }

  Contact.fromIdentifierMap(Map m) {
    identifier = m["identifier"];
  }

  Contact.fromMap(Map m) {
    identifier = m["identifier"];
    displayName = m["displayName"];
    givenName = m["givenName"];
    middleName = m["middleName"];
    familyName = m["familyName"];
    prefix = m["prefix"];
    suffix = m["suffix"];
    company = m["company"];
    jobTitle = m["jobTitle"];
    androidAccountTypeRaw = m["androidAccountType"];
    androidAccountType = accountTypeFromString(androidAccountTypeRaw);
    androidAccountName = m["androidAccountName"];
    note = m["note"];
    sip = m["sip"];
    phoneticGivenName = m["phoneticGivenName"];
    phoneticMiddleName = m["phoneticMiddleName"];
    phoneticFamilyName = m["phoneticFamilyName"];
    phoneticName = m["phoneticName"];
    nickname = m["nickname"];
    department = m["department"];
    emails = (m["emails"] as Iterable)?.map((m) => Item.fromMap(m));
    phones = (m["phones"] as Iterable)?.map((m) => Item.fromMap(m));
    postalAddresses = (m["postalAddresses"] as Iterable)?.map((m) => PostalAddress.fromMap(m));
    dates = (m["dates"] as Iterable)?.map((m) => Item.fromMap(m));
    instantMessageAddresses = (m["instantMessageAddresses"] as Iterable)?.map((m) => Item.fromMap(m));
    relations = (m["relations"] as Iterable)?.map((m) => Item.fromMap(m));
    websites = (m["websites"] as Iterable)?.map((m) => Item.fromMap(m));
    socialProfiles = (m["socialProfiles"] as Iterable)?.map((m) => Item.fromMap(m));
    labels = m["labels"]?.cast<String>();
    try {
      avatar = m["avatar"];
    } catch (e) {
      avatar = Uint8List(0);
    }
    try {
      birthday = DateTime.parse(m["birthday"]);
    } catch (e) {
      birthday = null;
    }
    birthDayString = m["birthday"];
  }

  static Map _toMap(Contact contact) {
    var emails = [];
    for (Item email in contact.emails ?? []) {
      emails.add(Item._toMap(email));
    }
    var phones = [];
    for (Item phone in contact.phones ?? []) {
      phones.add(Item._toMap(phone));
    }
    var postalAddresses = [];
    for (PostalAddress address in contact.postalAddresses ?? []) {
      postalAddresses.add(PostalAddress._toMap(address));
    }
    var dates = [];
    for (Item date in contact.dates ?? []) {
      dates.add(Item._toMap(date));
    }
    var instantMessageAddresses = [];
    for (Item im in contact.instantMessageAddresses ?? []) {
      instantMessageAddresses.add(Item._toMap(im));
    }
    var relations = [];
    for (Item relation in contact.relations ?? []) {
      relations.add(Item._toMap(relation));
    }
    var websites = [];
    for (Item website in contact.websites ?? []) {
      websites.add(Item._toMap(website));
    }
    var socialProfiles = [];
    for (Item socialProfile in contact.socialProfiles ?? []) {
      socialProfiles.add(Item._toMap(socialProfile));
    }

    final birthday =
        contact.birthday == null ? null : "--${contact.birthday.month.toString().padLeft(2, '0')}-${contact.birthday.day.toString().padLeft(2, '0')}";

    if (contact.identifier == null) {
      final map = {
        "displayName": contact.displayName,
        "givenName": contact.givenName,
        "middleName": contact.middleName,
        "familyName": contact.familyName,
        "prefix": contact.prefix,
        "suffix": contact.suffix,
        "company": contact.company,
        "jobTitle": contact.jobTitle,
        "androidAccountType": contact.androidAccountTypeRaw,
        "androidAccountName": contact.androidAccountName,
        "emails": emails,
        "phones": phones,
        "postalAddresses": postalAddresses,
        "avatar": contact.avatar,
        "birthday": birthday,
        "note": contact.note,
        "sip": contact.sip,
        "phoneticGivenName": contact.phoneticGivenName,
        "phoneticMiddleName": contact.phoneticMiddleName,
        "phoneticFamilyName": contact.phoneticFamilyName,
        "phoneticName": contact.phoneticName,
        "nickname": contact.nickname,
        "dates": dates,
        "department": contact.department,
        "instantMessageAddresses": instantMessageAddresses,
        "relations": relations,
        "websites": websites,
        "socialProfiles": socialProfiles,
        "labels": contact.labels,
      };

      return map;
    } else {
      final map = {
        "identifier": contact.identifier,
        "displayName": contact.displayName,
        "givenName": contact.givenName,
        "middleName": contact.middleName,
        "familyName": contact.familyName,
        "prefix": contact.prefix,
        "suffix": contact.suffix,
        "company": contact.company,
        "jobTitle": contact.jobTitle,
        "androidAccountType": contact.androidAccountTypeRaw,
        "androidAccountName": contact.androidAccountName,
        "emails": emails,
        "phones": phones,
        "postalAddresses": postalAddresses,
        "avatar": contact.avatar,
        "birthday": birthday,
        "note": contact.note,
        "sip": contact.sip,
        "phoneticGivenName": contact.phoneticGivenName,
        "phoneticMiddleName": contact.phoneticMiddleName,
        "phoneticFamilyName": contact.phoneticFamilyName,
        "phoneticName": contact.phoneticName,
        "nickname": contact.nickname,
        "dates": dates,
        "department": contact.department,
        "instantMessageAddresses": instantMessageAddresses,
        "relations": relations,
        "socialProfiles": socialProfiles,
        "websites": websites,
        "labels": contact.labels,
      };
      return map;
    }
  }

  Map toMap() {
    return Contact._toMap(this);
  }

  /// The [+] operator fills in this contact's empty fields with the fields from [other]
  operator +(Contact other) => Contact(
      givenName: this.givenName ?? other.givenName,
      middleName: this.middleName ?? other.middleName,
      prefix: this.prefix ?? other.prefix,
      suffix: this.suffix ?? other.suffix,
      familyName: this.familyName ?? other.familyName,
      company: this.company ?? other.company,
      jobTitle: this.jobTitle ?? other.jobTitle,
      androidAccountType: this.androidAccountType ?? other.androidAccountType,
      androidAccountName: this.androidAccountName ?? other.androidAccountName,
      emails: this.emails == null ? other.emails : this.emails.toSet().union(other.emails?.toSet() ?? Set()).toList(),
      phones: this.phones == null ? other.phones : this.phones.toSet().union(other.phones?.toSet() ?? Set()).toList(),
      postalAddresses:
          this.postalAddresses == null ? other.postalAddresses : this.postalAddresses.toSet().union(other.postalAddresses?.toSet() ?? Set()).toList(),
      avatar: this.avatar ?? other.avatar,
      birthday: this.birthday ?? other.birthday,
      note: this.note ?? other.note,
      sip: this.sip ?? other.sip,
      phoneticGivenName: this.phoneticGivenName ?? other.phoneticGivenName,
      phoneticMiddleName: this.phoneticMiddleName ?? other.phoneticMiddleName,
      phoneticFamilyName: this.phoneticFamilyName ?? other.phoneticFamilyName,
      phoneticName: this.phoneticName ?? other.phoneticName,
      nickname: this.nickname ?? other.nickname,
      department: this.department ?? other.department,
      dates: this.dates == null ? other.dates : this.dates.toSet().union(other.dates?.toSet() ?? Set()).toList(),
      instantMessageAddresses: this.instantMessageAddresses == null
          ? other.instantMessageAddresses
          : this.instantMessageAddresses.toSet().union(other.instantMessageAddresses?.toSet() ?? Set()).toList(),
      relations: this.relations == null ? other.relations : this.relations.toSet().union(other.relations?.toSet() ?? Set()).toList(),
      websites: this.websites == null ? other.websites : this.websites.toSet().union(other.websites?.toSet() ?? Set()).toList(),
      socialProfiles:
          this.socialProfiles == null ? other.socialProfiles : this.socialProfiles.toSet().union(other.socialProfiles?.toSet() ?? Set()).toList(),
      labels: this.labels == null ? other.labels : this.labels.toSet().union(other.labels?.toSet() ?? Set()).toList(),
      birthDayString: this.birthDayString ?? other.birthDayString);

  /// Returns true if all items in this contact are identical.
  @override
  bool operator ==(Object other) {
    return other is Contact &&
        this.avatar == other.avatar &&
        this.company == other.company &&
        this.displayName == other.displayName &&
        this.givenName == other.givenName &&
        this.familyName == other.familyName &&
        this.identifier == other.identifier &&
        this.jobTitle == other.jobTitle &&
        this.androidAccountType == other.androidAccountType &&
        this.androidAccountName == other.androidAccountName &&
        this.middleName == other.middleName &&
        this.prefix == other.prefix &&
        this.suffix == other.suffix &&
        this.birthday == other.birthday &&
        this.note == other.note &&
        this.sip == other.sip &&
        this.phoneticGivenName == other.phoneticGivenName &&
        this.phoneticMiddleName == other.phoneticMiddleName &&
        this.phoneticFamilyName == other.phoneticFamilyName &&
        this.phoneticName == other.phoneticName &&
        this.nickname == other.nickname &&
        this.department == other.department &&
        DeepCollectionEquality.unordered().equals(this.phones, other.phones) &&
        DeepCollectionEquality.unordered().equals(this.emails, other.emails) &&
        DeepCollectionEquality.unordered().equals(this.postalAddresses, other.postalAddresses) &&
        DeepCollectionEquality.unordered().equals(this.dates, other.dates) &&
        DeepCollectionEquality.unordered().equals(this.postalAddresses, other.postalAddresses) &&
        DeepCollectionEquality.unordered().equals(this.instantMessageAddresses, other.instantMessageAddresses) &&
        DeepCollectionEquality.unordered().equals(this.relations, other.relations) &&
        DeepCollectionEquality.unordered().equals(this.websites, other.websites) &&
        DeepCollectionEquality.unordered().equals(this.socialProfiles, other.socialProfiles) &&
        DeepCollectionEquality.unordered().equals(this.labels, other.labels) &&
        this.birthDayString == other.birthDayString;
  }

  @override
  int get hashCode {
    return hashObjects([
      this.identifier,
      this.company,
      this.displayName,
      this.familyName,
      this.givenName,
      this.identifier,
      this.jobTitle,
      this.androidAccountType,
      this.androidAccountName,
      this.middleName,
      this.prefix,
      this.suffix,
      this.birthday,
      this.note,
      this.sip,
      this.nickname,
      this.phoneticGivenName,
      this.phoneticMiddleName,
      this.phoneticFamilyName,
      this.phoneticName,
      this.department,
    ].where((s) => s != null));
  }

  AndroidAccountType accountTypeFromString(String androidAccountType) {
    if (androidAccountType == null) {
      return null;
    }
    if (androidAccountType.startsWith("com.google")) {
      return AndroidAccountType.google;
    } else if (androidAccountType.startsWith("com.whatsapp")) {
      return AndroidAccountType.whatsapp;
    } else if (androidAccountType.startsWith("com.facebook")) {
      return AndroidAccountType.facebook;
    }

    /// Other account types are not supported on Android
    /// such as Samsung, htc etc...
    return AndroidAccountType.other;
  }
}

class PostalAddress {
  PostalAddress({this.identifier, this.label, this.street, this.locality, this.city, this.postcode, this.region, this.country});

  String identifier, label, street, locality, city, postcode, region, country;

  PostalAddress.fromMap(Map m) {
    identifier = m["identifier"];
    label = m["label"];
    street = m["street"];
    locality = m["locality"];
    city = m["city"];
    postcode = m["postcode"];
    region = m["region"];
    country = m["country"];
  }

  @override
  bool operator ==(Object other) {
    return other is PostalAddress &&
        this.identifier == other.identifier &&
        this.city == other.city &&
        this.country == other.country &&
        this.label == other.label &&
        this.postcode == other.postcode &&
        this.region == other.region &&
        this.street == other.street &&
        this.locality == other.locality;
  }

  @override
  int get hashCode {
    return hashObjects([
      this.identifier,
      this.label,
      this.street,
      this.locality,
      this.city,
      this.country,
      this.region,
      this.postcode,
    ].where((s) => s != null));
  }

  static Map _toMap(PostalAddress address) {
    if (address.identifier == null) {
      return {
        "label": address.label ?? "",
        "street": address.street ?? "",
        "locality": address.locality ?? "",
        "city": address.city ?? "",
        "postcode": address.postcode ?? "",
        "region": address.region ?? "",
        "country": address.country ?? ""
      };
    } else {
      return {
        "identifier": address.identifier,
        "label": address.label ?? "",
        "street": address.street ?? "",
        "locality": address.locality ?? "",
        "city": address.city ?? "",
        "postcode": address.postcode ?? "",
        "region": address.region ?? "",
        "country": address.country ?? ""
      };
    }
  }

  @override
  String toString() {
    String finalString = "";
    if (this.identifier != null) {
      finalString = this.identifier;
    }
    if (this.street != null) {
      if (finalString.isNotEmpty) {
        finalString += ", " + this.street;
      } else {
        finalString += this.street;
      }
    }
    if (this.locality != null) {
      if (finalString.isNotEmpty) {
        finalString += ", " + this.locality;
      } else {
        finalString += this.locality;
      }
    }
    if (this.city != null) {
      if (finalString.isNotEmpty) {
        finalString += ", " + this.city;
      } else {
        finalString += this.city;
      }
    }
    if (this.region != null) {
      if (finalString.isNotEmpty) {
        finalString += ", " + this.region;
      } else {
        finalString += this.region;
      }
    }
    if (this.postcode != null) {
      if (finalString.isNotEmpty) {
        finalString += " " + this.postcode;
      } else {
        finalString += this.postcode;
      }
    }
    if (this.country != null) {
      if (finalString.isNotEmpty) {
        finalString += ", " + this.country;
      } else {
        finalString += this.country;
      }
    }
    return finalString;
  }
}

/// Item class used for contact fields which only have a [label] and
/// a [value], such as emails and phone numbers
class Item {
  Item({this.identifier, this.label, this.value});

  String identifier, label, value;

  Item.fromMap(Map m) {
    identifier = m["identifier"];
    label = m["label"];
    value = m["value"];
  }

  @override
  bool operator ==(Object other) {
    return other is Item && this.identifier == other.identifier && this.label == other.label && this.value == other.value;
  }

  @override
  String toString() {
    String finalString = "";
    if (this.identifier != null) {
      finalString = this.identifier;
    }
    if (this.label != null) {
      if (finalString.isNotEmpty) {
        finalString += ", " + this.label;
      } else {
        finalString += this.label;
      }
    }
    if (this.value != null) {
      if (finalString.isNotEmpty) {
        finalString += ", " + this.value;
      } else {
        finalString += this.value;
      }
    }
    return finalString;
  }

  @override
  int get hashCode => hash3(identifier ?? "", label ?? "", value ?? "");

  static Map _toMap(Item i) {
    if (i.identifier == null) {
      return {"label": i.label ?? "", "value": i.value ?? ""};
    } else {
      return {"identifier": i.identifier, "label": i.label ?? "", "value": i.value ?? ""};
    }
  }
}

enum AndroidAccountType { facebook, google, whatsapp, other }
