import 'dart:typed_data';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('github.com/clovisnicolas/flutter_contacts');
  final List<MethodCall> log = <MethodCall>[];
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    log.add(methodCall);
    if (methodCall.method == 'getContacts') {
      return [
        {'identifier': 'id', 'givenName': 'givenName1'},
        {
          'identifier': 'id',
          'givenName': 'givenName2',
          'postalAddresses': [
            {'identifier': 'id', 'label': 'label'}
          ],
          'emails': [
            {'identifier': 'id', 'label': 'label'}
          ],
          'dates' : [
            {'identifier': 'id', 'label': 'label'}
          ],
          'relations' : [
            {'identifier': 'id', 'label': 'label'}
          ],
          'instantMessageAddresses' : [
            {'identifier': 'id', 'label': 'label'}
          ],
          'socialProfiles' : [
            {'identifier': 'id', 'label': 'label'}
          ],
          'websites' : [
            {'identifier': 'id', 'label': 'label'}
          ],
          'labels' : [
            ''
          ],
          'birthday': '1994-02-01'
        },
      ];
    } else if (methodCall.method == 'getAvatar') {
      return Uint8List.fromList([0, 1, 2, 3]);
    }
    return null;
  });

  tearDown(() {
    log.clear();
  });

  test('should get contacts', () async {
    final contacts = await ContactsService.getContacts();
    expect(contacts.length, 2);
    expect(contacts, everyElement(isInstanceOf<Contact>()));
    expect(contacts.toList()[0].givenName, 'givenName1');
    expect(contacts.toList()[1].postalAddresses.toList()[0].label, 'label');
    expect(contacts.toList()[1].emails.toList()[0].label, 'label');
    expect(contacts.toList()[1].dates.toList()[0].label, 'label');
    expect(contacts.toList()[1].socialProfiles.toList()[0].label, 'label');
    expect(contacts.toList()[1].relations.toList()[0].label, 'label');
    expect(contacts.toList()[1].websites.toList()[0].label, 'label');
    expect(contacts.toList()[1].labels.toList()[0], '');
    expect(contacts.toList()[1].birthday, DateTime(1994, 2, 1));
  });

  test('should get avatar for contact identifiers', () async {
    final contact = Contact(givenName: 'givenName');

    final avatar = await ContactsService.getAvatar(contact);

    expect(log, <Matcher>[
      isMethodCall('getAvatar', arguments: <String, dynamic>{
        'contact': contact.toMap(),
        'photoHighResolution': true,
      })
    ]);

    expect(avatar, Uint8List.fromList([0, 1, 2, 3]));
  });

  test('should get low-res avatar for contact identifiers', () async {
    final contact = Contact(givenName: 'givenName');

    await ContactsService.getAvatar(contact, photoHighRes: false);

    expect(log, <Matcher>[
      isMethodCall('getAvatar', arguments: <String, dynamic>{
        'contact': contact.toMap(),
        'photoHighResolution': false,
      })
    ]);
  });

  test('should add contact', () async {
    await ContactsService.addContact(Contact(
      givenName: 'givenName',
      emails: [Item(label: 'label')],
      phones: [Item(label: 'label')],
      postalAddresses: [PostalAddress(label: 'label')],
    ));
    expectMethodCall(log, 'addContact');
  });

  test('should delete contact', () async {
    await ContactsService.deleteContact(Contact(
      givenName: 'givenName',
      emails: [Item(label: 'label')],
      phones: [Item(label: 'label')],
      postalAddresses: [PostalAddress(label: 'label')],
    ));
    expectMethodCall(log, 'deleteContact');
  });

  test('should provide initials for contact', () {
    Contact contact1 = Contact(
        givenName: "givenName", familyName: "familyName");
    Contact contact2 = Contact(givenName: "givenName");
    Contact contact3 = Contact(familyName: "familyName");
    Contact contact4 = Contact();

    expect(contact1.initials(), "GF");
    expect(contact2.initials(), "G");
    expect(contact3.initials(), "F");
    expect(contact4.initials(), "");
  });

  test('should update contact', () async {
    await ContactsService.updateContact(Contact(
      givenName: 'givenName',
      emails: [Item(label: 'label')],
      phones: [Item(label: 'label')],
      postalAddresses: [PostalAddress(label: 'label')],
    ));
    expectMethodCall(log, 'updateContact');
  });


  test('should show contacts are equal', () {
    Contact contact1 =
        Contact(givenName: "givenName", familyName: "familyName", emails: [
      Item(label: "Home", value: "example@example.com"),
      Item(label: "Work", value: "example2@example.com"),
    ]);
    Contact contact2 =
        Contact(givenName: "givenName", familyName: "familyName", emails: [
      Item(label: "Work", value: "example2@example.com"),
      Item(label: "Home", value: "example@example.com"),
    ]);
    expect(contact1 == contact2, true);
    expect(contact1.hashCode, contact2.hashCode);
  });

  test('should produce a valid merged contact', () {
    Contact contact1 =
        Contact(givenName: "givenName", familyName: "familyName", emails: [
      Item(label: "Home", value: "home@example.com"),
      Item(label: "Work", value: "work@example.com"),
    ], phones: [], postalAddresses: []);
    Contact contact2 = Contact(familyName: "familyName", phones: [
      Item(label: "Mobile", value: "111-222-3344")
    ], emails: [
      Item(label: "Mobile", value: "mobile@example.com"),
    ], postalAddresses: [
      PostalAddress(
          label: 'Home',
          street: "1234 Middle-of Rd",
          city: "Nowhere",
          postcode: "12345",
          region: null,
          country: null)
    ]);
    Contact mergedContact =
        Contact(givenName: "givenName", familyName: "familyName", emails: [
      Item(label: "Home", value: "home@example.com"),
      Item(label: "Mobile", value: "mobile@example.com"),
      Item(label: "Work", value: "work@example.com"),
    ], phones: [
      Item(label: "Mobile", value: "111-222-3344")
    ], postalAddresses: [
      PostalAddress(
          label: 'Home',
          street: "1234 Middle-of Rd",
          city: "Nowhere",
          postcode: "12345",
          region: null,
          country: null)
    ]);

    expect(contact1 + contact2, mergedContact);
  });

  test('should provide a valid merged contact, with no extra info', (){
    Contact contact1 = Contact(familyName: "familyName");
    Contact contact2 = Contact();
    expect(contact1 + contact2, contact1);
  });

  test('should provide a map of the contact', () {
    Contact contact = Contact(givenName: "givenName", familyName: "familyName");
    expect(contact.toMap(), {
      "displayName": null,
      "givenName": "givenName",
      "middleName": null,
      "familyName": "familyName",
      "prefix": null,
      "suffix": null,
      "company": null,
      "jobTitle": null,
      "androidAccountType": null,
      "androidAccountName": null,
      "emails": [],
      "phones": [],
      "postalAddresses": [],
      "avatar": null,
    "birthday": null,
    "note": null,
    "sip": null,
    "phoneticGivenName": null,
    "phoneticMiddleName": null,
    "phoneticFamilyName": null,
    "phoneticName": null,
    "nickname": null,
    "dates": [],
    "department": null,
    "instantMessageAddresses": [],
    "relations": [],
    "websites": [],
    "socialProfiles": [],
    "labels": null,
    });
  });
}

void expectMethodCall(List<MethodCall> log, String methodName) {
}
