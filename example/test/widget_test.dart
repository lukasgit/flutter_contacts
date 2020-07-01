// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester utility that Flutter
// provides. For example, you can send tap and scroll gestures. You can also use WidgetTester to
// find child widgets in the widget tree, read text, and verify that the values of widget properties
// are correct.

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:contacts_service_example/contacts_list_page.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(ContactListPage());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

class TestData {
  static Contact getContactForSaving(String identifier) {
    Contact contact = Contact(identifier: identifier);

    contact.givenName = 'A';
    contact.middleName = 'B';
    contact.prefix = 'C';
    contact.suffix = 'D';
    contact.familyName = 'E';
    contact.company = 'F';
    contact.jobTitle = 'G';
    contact.note = 'note';
    contact.phoneticGivenName = 'H';
    contact.phoneticMiddleName = 'I';
    contact.phoneticFamilyName = 'j';
    contact.nickname = 'k';
    contact.department = 'l';

    List<Item> mails = List();
    mails.add(Item(label: 'work', value: 'j@kaps.com'));
    mails.add(Item(label: 'home', value: 'an@k.com'));
    contact.emails = mails;

    List<Item> phones = List();
    phones.add(Item(label: 'work', value: '+91 9538700000'));
    phones.add(Item(label: 'home', value: '+919538715743'));
    contact.phones = phones;

    List<PostalAddress> addresses = List();
    addresses.add(PostalAddress(label: 'home', street: '102, Park Royale', locality: 'Rahatani', city: 'Pune', postcode: '411027', region: 'Maharast'
        'ra',
        country: 'India'));
    addresses.add(PostalAddress(label: 'my address', street: '803\nrahatani', city: 'pune', postcode: '411017', region: 'MH',
        country: 'india'));
    contact.postalAddresses = addresses;

    List<Item> dates = List();
    dates.add(Item(label: 'anniversary', value: '2009-12-30'));
    dates.add(Item(label: 'my date', value: '2014-11-01'));
    contact.dates = dates;

    List<Item> ims = List();
    ims.add(Item(label: 'skype', value: 'jay04'));
    ims.add(Item(label: 'yahoo', value: 'jp'));
    ims.add(Item(label: 'gadu gadu', value: 'jayG'));
    contact.instantMessageAddresses = ims;

    List<Item> relations = List();
    relations.add(Item(label: 'father', value: 'jaypatel'));
    relations.add(Item(label: 'spouse', value: 'nim'));
    relations.add(Item(label: 'mother', value: 'sumi'));
    relations.add(Item(label: 'daughter', value: 'daina'));
    contact.relations = relations;

    List<Item> websites = List();
    websites.add(Item(label: 'home', value: 'http://k2m.com'));
    websites.add(Item(label: 'my page', value: 'www.jaypatel04.com'));
    contact.websites = websites;

    contact.birthday = DateTime(0, 1, 1);

    return contact;
  }

  static Contact getContactForInsert() {
    Contact contact = Contact();

    contact.givenName = 'Jay';
    contact.middleName = 'v';
    contact.prefix = 'Pre';
    contact.suffix = 'Suf';
    contact.familyName = 'Patel';
    contact.company = 'K2M';
    contact.jobTitle = 'Dev';
    contact.note = 'This is testing note';
    contact.phoneticGivenName = 'PhJ';
    contact.phoneticMiddleName = 'PhM';
    contact.phoneticFamilyName = 'PhF';
    contact.nickname = 'Nicks';
    contact.department = 'Mobile';

    List<Item> mails = List();
    mails.add(Item(label: 'HOme', value: 'jay@k2m.com'));
    mails.add(Item(label: 'work', value: 'j@k.com'));
    mails.add(Item(label: 'my mail', value: 'n@k.com'));
    contact.emails = mails;

    List<Item> phones = List();
    phones.add(Item(label: 'HOme', value: '+91 9538715744'));
    phones.add(Item(label: 'my phone', value: '+919538715743'));
    contact.phones = phones;

    List<PostalAddress> addresses = List();
    addresses.add(PostalAddress(label: 'work', street: '204', locality: 'rahatani', city: 'pune', postcode: '411017', region: 'MH',
        country: 'india'));
    addresses.add(PostalAddress(label: 'work', street: '204', locality: 'rahatani', city: 'pune', postcode: '411017', region: 'MH',
        country: 'india'));
    addresses.add(PostalAddress(label: 'my address', street: '803\nrahatani', city: 'pune', postcode: '411017', region: 'MH',
        country: 'india'));
    contact.postalAddresses = addresses;

    List<Item> dates = List();
    dates.add(Item(label: 'birthday', value: '1981-03-04'));
    dates.add(Item(label: 'anniversary', value: '2009-12-30'));
    dates.add(Item(label: 'my date', value: '2014-11-01'));
    contact.dates = dates;

    List<Item> ims = List();
    ims.add(Item(label: 'skype', value: 'jay04'));
    ims.add(Item(label: 'yahoo', value: 'jp'));
    ims.add(Item(label: 'gadu gadu', value: 'jayG'));
    contact.instantMessageAddresses = ims;

    List<Item> relations = List();
    relations.add(Item(label: 'brother', value: 'kaps'));
    relations.add(Item(label: 'spouse', value: 'nim'));
    relations.add(Item(label: 'other', value: 'dhams'));
    contact.relations = relations;

    List<Item> websites = List();
    websites.add(Item(label: 'homepage', value: 'http://jay.com'));
    websites.add(Item(label: 'other', value: 'http://known2me.com'));
    websites.add(Item(label: 'my page', value: 'www.jaypatel04.com'));
    contact.websites = websites;

    contact.birthday = DateTime(0, 1, 1);

    return contact;
  }
}
