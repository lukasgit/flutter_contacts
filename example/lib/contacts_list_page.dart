import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:contacts_service_example/main.dart';

import 'package:contacts_service/contacts_service.dart';
import 'package:intl/intl.dart';

class ContactListPage extends StatefulWidget {
  @override
  _ContactListPageState createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  List<Contact> _contacts;

  @override
  void initState() {
    super.initState();
    refreshContacts();
  }

  Future<void> refreshContacts() async {
    // Load without thumbnails initially.
//    var ids = (await ContactsService.getIdentifiers());
//    var contacts = (await ContactsService.getContactsByIdentifiers(identifiers: ids)).toList();
//    var contacts = (await ContactsService.getContactsSummary()).toList();
    var contacts = (await ContactsService.getContacts()).toList();

    setState(() {
      _contacts = contacts;
    });

    // Lazy load thumbnails after rendering initial contacts.
    for (final contact in contacts) {
      if (contact.avatar == null) {
        ContactsService.getAvatar(contact).then((avatar) {
          if (avatar == null) return; // Don't redraw if no change.
          setState(() => contact.avatar = avatar);
        }).catchError((error) {
          print(error.toString());
        });
      } else {
        setState(() => contact.avatar);
      }
    }
  }

  void updateContact() async {
    Contact ninja = _contacts.toList().firstWhere((contact) => contact.familyName.startsWith("Ninja"));
    ninja.avatar = null;
    ninja =
    await ContactsService.updateContact(ninja);

    refreshContacts();
  }

  _openContactForm() async {
    try {
      await ContactsService.openContactForm(iOSLocalizedLabels: iOSLocalizedLabels);
      refreshContacts();
    } on FormOperationException catch (e) {
      switch (e.errorCode) {
        case FormOperationErrorCode.FORM_OPERATION_CANCELED:
        case FormOperationErrorCode.FORM_COULD_NOT_BE_OPEN:
        case FormOperationErrorCode.FORM_OPERATION_UNKNOWN_ERROR:
        default:
          print(e.errorCode);
      }
    }
  }

  void contactOnDeviceHasBeenUpdated(Contact contact) {
    this.setState(() {
      var id = _contacts.indexWhere((c) => c.identifier == contact.identifier);
      _contacts[id] = contact;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contacts Plugin Example',
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.create),
            onPressed: _openContactForm,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed("/add").then((_) {
            refreshContacts();
          });
        },
      ),
      body: SafeArea(
        child: _contacts != null
            ? ListView.builder(
                itemCount: _contacts?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {

                  Contact c = _contacts?.elementAt(index);
                  return ListTile(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => ContactDetailsPage(
                                c,
                                onContactDeviceSave: contactOnDeviceHasBeenUpdated,
                              )));
                    },
                    leading: (c.avatar != null && c.avatar.length > 0)
                        ? CircleAvatar(backgroundImage: MemoryImage(c.avatar))
                        : CircleAvatar(child: Text(c.initials())),
                    title: Text(c.displayName ?? ""),
                  );
                },
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}

class ContactDetailsPage extends StatelessWidget {
  ContactDetailsPage(this._contact, {this.onContactDeviceSave});

  final Contact _contact;
  final Function(Contact) onContactDeviceSave;

  _openExistingContactOnDevice(BuildContext context) async {
    try {
      var contact = await ContactsService.openExistingContact(_contact, iOSLocalizedLabels: iOSLocalizedLabels);
      if (onContactDeviceSave != null) {
        onContactDeviceSave(contact);
      }
      Navigator.of(context).pop();
    } on FormOperationException catch (e) {
      switch (e.errorCode) {
        case FormOperationErrorCode.FORM_OPERATION_CANCELED:
        case FormOperationErrorCode.FORM_COULD_NOT_BE_OPEN:
        case FormOperationErrorCode.FORM_OPERATION_UNKNOWN_ERROR:
        default:
          print(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_contact.displayName ?? ""),
        actions: <Widget>[
//          IconButton(
//            icon: Icon(Icons.share),
//            onPressed: () => shareVCFCard(context, contact: _contact),
//          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => ContactsService.deleteContact(_contact),
          ),
          IconButton(
            icon: Icon(Icons.update),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UpdateContactsPage(
                  contact: _contact,
                ),
              ),
            ),
          ),
          IconButton(icon: Icon(Icons.edit), onPressed: () => _openExistingContactOnDevice(context)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text("Identifier"),
              subtitle: Text(_contact.identifier ?? ""),
            ),
            ListTile(
              title: Text("Name"),
              trailing: Text(_contact.givenName ?? ""),
            ),
            ListTile(
              title: Text("Middle name"),
              trailing: Text(_contact.middleName ?? ""),
            ),
            ListTile(
              title: Text("Family name"),
              trailing: Text(_contact.familyName ?? ""),
            ),
            ListTile(
              title: Text("Prefix"),
              trailing: Text(_contact.prefix ?? ""),
            ),
            ListTile(
              title: Text("Suffix"),
              trailing: Text(_contact.suffix ?? ""),
            ),
            ListTile(
              title: Text("Phonetic name"),
              trailing: Text(_contact.phoneticGivenName ?? ""),
            ),
            ListTile(
              title: Text("Phonetic middle name"),
              trailing: Text(_contact.phoneticMiddleName ?? ""),
            ),
            ListTile(
              title: Text("Phonetic family name"),
              trailing: Text(_contact.phoneticFamilyName ?? ""),
            ),
            ListTile(
              title: Text("Birthday"),
              trailing: Text(_contact.birthday != null ? DateFormat('dd-MM-yyyy').format(_contact.birthday) : ""),
            ),
            ListTile(
              title: Text("Company"),
              trailing: Text(_contact.company ?? ""),
            ),
            ListTile(
              title: Text("Job"),
              trailing: Text(_contact.jobTitle ?? ""),
            ),
            ListTile(
              title: Text("Department"),
              trailing: Text(_contact.department ?? ""),
            ),
            ListTile(
              title: Text("Nickname"),
              trailing: Text(_contact.nickname ?? ""),
            ),
            ListTile(
              title: Text("Sip"),
              trailing: Text(_contact.sip ?? ""),
            ),
            ListTile(
              title: Text("Note"),
              trailing: Text(_contact.note ?? ""),
            ),
            ListTile(
              title: Text("Account Type"),
              trailing: Text((_contact.androidAccountType != null) ? _contact.androidAccountType.toString() : ""),
            ),
            ListTile(title: Text("Labels"), trailing: Text(_contact.labels != null ? _contact.labels.join(", ") : "")),
            AddressesTile(_contact.postalAddresses),
            ItemsTile("Phones", _contact.phones),
            ItemsTile("Emails", _contact.emails),
            ItemsTile("Dates", _contact.dates),
            ItemsTile("Instant message addresses", _contact.instantMessageAddresses),
            ItemsTile("Relations", _contact.relations),
            ItemsTile("Websites", _contact.websites),
          ],
        ),
      ),
    );
  }
}

class AddressesTile extends StatelessWidget {
  AddressesTile(this._addresses);

  final Iterable<PostalAddress> _addresses;

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(title: Text("Addresses")),
        Column(
          children: _addresses
              .map((a) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          title: Text("Identifier"),
                          subtitle: Text(a.identifier ?? ""),
                        ),
                        ListTile(
                          title: Text("Label"),
                          trailing: Text(a.label ?? ""),
                        ),
                        ListTile(
                          title: Text("Street"),
                          trailing: Text(a.street ?? ""),
                        ),
                        ListTile(
                          title: Text("Locality"),
                          trailing: Text(a.locality ?? ""),
                        ),
                        ListTile(
                          title: Text("Postcode"),
                          trailing: Text(a.postcode ?? ""),
                        ),
                        ListTile(
                          title: Text("City"),
                          trailing: Text(a.city ?? ""),
                        ),
                        ListTile(
                          title: Text("Region"),
                          trailing: Text(a.region ?? ""),
                        ),
                        ListTile(
                          title: Text("Country"),
                          trailing: Text(a.country ?? ""),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class ItemsTile extends StatelessWidget {
  ItemsTile(this._title, this._items);

  final Iterable<Item> _items;
  final String _title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(title: Text(_title)),
        Column(
          children: _items
              .map(
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    title: Text(i.label ?? ""),
                    subtitle: Text(i.identifier ?? ""),
                    trailing: Text(i.value ?? ""),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class AddContactPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  Contact contact = Contact();
  PostalAddress address = PostalAddress(label: "Home");
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add a contact"),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              _formKey.currentState.save();
              contact.postalAddresses = [address];
              contact = getContactForInsert();
              ContactsService.addContact(contact).then((value) {
                print(value.toString());
              }).catchError((error) {
                print(error.toString());
              });
              Navigator.of(context).pop();
            },
            child: Icon(Icons.save, color: Colors.white),
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'First name'),
                onSaved: (v) {
                  contact.givenName = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Middle name'),
                onSaved: (v) {
                  contact.middleName = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last name'),
                onSaved: (v) {
                  contact.familyName = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Prefix'),
                onSaved: (v) {
                  contact.prefix = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Suffix'),
                onSaved: (v) {
                  contact.suffix = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phonetic first name'),
                onSaved: (v) {
                  contact.phoneticGivenName = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phonetic middle name'),
                onSaved: (v) {
                  contact.phoneticMiddleName = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phonetic last name'),
                onSaved: (v) {
                  contact.phoneticFamilyName = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                onSaved: (v) {
                  contact.phones = [Item(label: "mobile", value: v)];
                },
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-mail'),
                onSaved: (v) {
                  contact.emails = [Item(label: "work", value: v)];
                },
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Company'),
                onSaved: (v) {
                  contact.company = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Job'),
                onSaved: (v) {
                  contact.jobTitle = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Department'),
                onSaved: (v) {
                  contact.department = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Street'),
                onSaved: (v) {
                  address.street = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Locality'),
                onSaved: (v) {
                  address.locality = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) {
                  address.city = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Region'),
                onSaved: (v) {
                  address.region = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Postal code'),
                onSaved: (v) {
                  address.postcode = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Country'),
                onSaved: (v) {
                  address.country = v;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Website'),
                onSaved: (v) {
                  contact.websites = [Item(label: "blog", value: v)];
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Im'),
                onSaved: (v) {
                  contact.instantMessageAddresses = [Item(label: "skype", value: v)];
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Relation'),
                onSaved: (v) {
                  contact.relations = [Item(label: "spouse", value: v)];
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Date(yyyy-MM-dd)'),
                onSaved: (v) {
                  contact.dates = [Item(label: "anniversary", value: v)];
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Label'),
                onSaved: (v) {
                  contact.labels = [v];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Contact getContactForInsert() {
    Contact contact = Contact();

    contact.givenName = 'TJay';
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

class UpdateContactsPage extends StatefulWidget {
  UpdateContactsPage({@required this.contact});

  final Contact contact;

  @override
  _UpdateContactsPageState createState() => _UpdateContactsPageState();
}

class _UpdateContactsPageState extends State<UpdateContactsPage> {
  Contact contact;
  PostalAddress address = PostalAddress(label: "Home");
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    contact = widget.contact;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Contact"),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.save,
              color: Colors.white,
            ),
            onPressed: () async {
              _formKey.currentState.save();
              contact.postalAddresses = [address];
              await ContactsService.updateContact(getContactForSaving('33BAFADB-1611-412E-910F-F9A1484FC7E1:ABPerson'));
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ContactListPage()));
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: contact.givenName ?? "",
                decoration: const InputDecoration(labelText: 'First name'),
                onSaved: (v) => contact.givenName = v,
              ),
              TextFormField(
                initialValue: contact.middleName ?? "",
                decoration: const InputDecoration(labelText: 'Middle name'),
                onSaved: (v) => contact.middleName = v,
              ),
              TextFormField(
                initialValue: contact.familyName ?? "",
                decoration: const InputDecoration(labelText: 'Last name'),
                onSaved: (v) => contact.familyName = v,
              ),
              TextFormField(
                initialValue: contact.prefix ?? "",
                decoration: const InputDecoration(labelText: 'Prefix'),
                onSaved: (v) => contact.prefix = v,
              ),
              TextFormField(
                initialValue: contact.suffix ?? "",
                decoration: const InputDecoration(labelText: 'Suffix'),
                onSaved: (v) => contact.suffix = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                onSaved: (v) => contact.phones = [Item(label: "mobile", value: v)],
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-mail'),
                onSaved: (v) => contact.emails = [Item(label: "work", value: v)],
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                initialValue: contact.company ?? "",
                decoration: const InputDecoration(labelText: 'Company'),
                onSaved: (v) => contact.company = v,
              ),
              TextFormField(
                initialValue: contact.jobTitle ?? "",
                decoration: const InputDecoration(labelText: 'Job'),
                onSaved: (v) => contact.jobTitle = v,
              ),
              TextFormField(
                initialValue: address.street ?? "",
                decoration: const InputDecoration(labelText: 'Street'),
                onSaved: (v) => address.street = v,
              ),
              TextFormField(
                initialValue: address.city ?? "",
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => address.city = v,
              ),
              TextFormField(
                initialValue: address.region ?? "",
                decoration: const InputDecoration(labelText: 'Region'),
                onSaved: (v) => address.region = v,
              ),
              TextFormField(
                initialValue: address.postcode ?? "",
                decoration: const InputDecoration(labelText: 'Postal code'),
                onSaved: (v) => address.postcode = v,
              ),
              TextFormField(
                initialValue: address.country ?? "",
                decoration: const InputDecoration(labelText: 'Country'),
                onSaved: (v) => address.country = v,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Contact getContactForSaving(String identifier) {
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


}
