## [0.3.0] - August 5th, 2019

* @budo385 closed image streams and cursors on Android

## [0.2.9] - July 19th, 2019

* File cleanup and removed .iml references. Use "flutter clean" to clear build files and re-build

## [0.2.8] - June 24th, 2019

* Android add avatar image - was not working.
* Android and iOS - update avatar image.
* Android custom phone label - adding label other then predefined ones sets the label to specified value.
* Android and iOS - on getContacts get the higher resolution image (photoHighResolution). Only when withThumbnails is true. photoHighResolution set to default when getting contact. Default is photoHighResolution = true because if you update the contact after getting, it will update the original size picture.
* Android and iOS - getContactsForPhone(String phone, {bool withThumbnails = true, bool photoHighResolution = true}) - gets the contacts with phone filter.

## [0.2.7] - May 24th, 2019

* Removed path_provider

## [0.2.6] - May 9th, 2019

* Removed share_extend
* Updated example app
* Bug fixes

## [0.2.5] - April 20th, 2019

* Added Notes support, and updateContact for Android fix
* Added Note support for iOS
* Added public method to convert contact to map using the static _toMap
* Updated tests
* Updated example app
* Bug fixes

## [0.2.4] - March 12th, 2019

* Added support for more phone labels
* Bug fixes

## [0.2.3] - March 2nd, 2019

* Added permission handling to example app
* Fixed build errors for Android & iOS

## [0.2.2] - March 1st, 2019

* **Feature:** Update Contact for iOS & Android
* Added updateContact method to contacts_service.dart
* Added updateContact method to SwiftContactsServicePlugin.swift
* Added unit testing for the updateContact method
* Fixed formatting discrepancies in the example app (making code easier to read)
* Fixed formatting discrepancies in contacts_service.dart (making code easier to read)
* AndroidX compatibility fix for example app
* Updated example app to show updateContacts method
* Fixed example app bugs
* Updated PostalAddress.java and Contact.java (wasn't working properly)
* Added updateContact method to ContactsServicePlugin.java

## [0.2.1] - February 21st, 2019

* **Breaking:** Updated dependencies

## [0.2.0] - February 19th, 2019

* **Breaking:** Updated to support AndroidX

## [0.1.1] - January 11th, 2019

* Added Ability to Share VCF Card (@AppleEducate)

## [0.1.0] - January 4th, 2019

* Update pubspec version and maintainer info for Dart Pub
* Add withThumbnails and update example (@trinqk)

## [0.0.9] - October 10th, 2018

* Fix an issue when fetching contacts on Android

## [0.0.8] - August 16th, 2018

* Fix an issue with phones being added to emails on Android
* Update plugin for dart 2

## [0.0.7] - July 10th, 2018

* Fix PlatformException on iOS
* Add a refresh to the contacts list in the sample app when you add a contact
* Return more meaningful errors when addContact() fails on iOS
* Code tidy up

## [0.0.6] - April 13th, 2018

* Add contact thumbnails

## [0.0.5] - April 5th, 2018

* Fix with dart2 compatibility

## [0.0.4] - February 1st, 2018

* Implement deleteContact(Contact c) for Android and iOS

## [0.0.3] - January 31st, 2018

* Implement addContact(Contact c) for Android and iOS

## [0.0.2] - January 30th, 2018

* Now retrieving contacts' prefixes and suffixes

## [0.0.1] - January 30th, 2018

* All contacts can be retrieved
* Contacts matching a string can be retrieved
