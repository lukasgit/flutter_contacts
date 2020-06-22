package flutter.plugins.contactsservice.contactsservice;

import android.annotation.TargetApi;
import android.content.ContentProviderOperation;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.provider.BaseColumns;
import android.provider.ContactsContract;
import android.text.TextUtils;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static android.app.Activity.RESULT_CANCELED;
import static android.provider.ContactsContract.CommonDataKinds;
import static android.provider.ContactsContract.CommonDataKinds.Email;
import static android.provider.ContactsContract.CommonDataKinds.Organization;
import static android.provider.ContactsContract.CommonDataKinds.Phone;
import static android.provider.ContactsContract.CommonDataKinds.StructuredName;
import static android.provider.ContactsContract.CommonDataKinds.StructuredPostal;

@TargetApi(Build.VERSION_CODES.ECLAIR)
public class ContactsServicePlugin implements MethodCallHandler, FlutterPlugin, ActivityAware {

    private static final int FORM_OPERATION_CANCELED = 1;
    private static final int FORM_COULD_NOT_BE_OPEN = 2;

    private static final String LOG_TAG = "flutter_contacts";
    private ContentResolver contentResolver;
    private MethodChannel methodChannel;
    private BaseContactsServiceDelegate delegate;

    private final ExecutorService executor =
            new ThreadPoolExecutor(0, 10, 60, TimeUnit.SECONDS, new ArrayBlockingQueue<Runnable>(1000));

    private void initDelegateWithRegister(Registrar registrar) {
        this.delegate = new ContactServiceDelegateOld(registrar);
    }

    public static void registerWith(Registrar registrar) {
        ContactsServicePlugin instance = new ContactsServicePlugin();
        instance.initInstance(registrar.messenger(), registrar.context());
        instance.initDelegateWithRegister(registrar);
    }

    private void initInstance(BinaryMessenger messenger, Context context) {
        methodChannel = new MethodChannel(messenger, "github.com/clovisnicolas/flutter_contacts");
        methodChannel.setMethodCallHandler(this);
        this.contentResolver = context.getContentResolver();
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        initInstance(binding.getBinaryMessenger(), binding.getApplicationContext());
        this.delegate = new ContactServiceDelegate(binding.getApplicationContext());
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
        contentResolver = null;
        this.delegate = null;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "getContacts": {
                this.getContacts(call.method, (String) call.argument("query"), (boolean) call.argument("withThumbnails"), (boolean) call.argument("photoHighResolution"), (boolean) call.argument("orderByGivenName"), result);
                break;
            }
            case "getContactsForPhone": {
                this.getContactsForPhone(call.method, (String) call.argument("phone"), (boolean) call.argument("withThumbnails"), (boolean) call.argument("photoHighResolution"), (boolean) call.argument("orderByGivenName"), result);
                break;
            }
            case "getAvatar": {
                final Contact contact = Contact.fromMap((HashMap) call.argument("contact"));
                this.getAvatar(contact, (boolean) call.argument("photoHighResolution"), result);
                break;
            }
            case "addContact": {
                final Contact contact = Contact.fromMap((HashMap) call.arguments);
                if (this.addContact(contact)) {
                    result.success(null);
                } else {
                    result.error(null, "Failed to add the contact", null);
                }
                break;
            }
            case "deleteContact": {
                final Contact contact = Contact.fromMap((HashMap) call.arguments);
                if (this.deleteContact(contact)) {
                    result.success(null);
                } else {
                    result.error(null, "Failed to delete the contact, make sure it has a valid identifier", null);
                }
                break;
            }
            case "updateContact": {
                final Contact contact = Contact.fromMap((HashMap) call.arguments);
                if (this.updateContact(contact)) {
                    result.success(null);
                } else {
                    result.error(null, "Failed to update the contact, make sure it has a valid identifier", null);
                }
                break;
            }
            case "openExistingContact": {
                final Contact contact = Contact.fromMap((HashMap) call.argument("contact"));
                if (delegate != null) {
                    delegate.setResult(result);
                    delegate.openExistingContact(contact);
                } else {
                    result.success(FORM_COULD_NOT_BE_OPEN);
                }
                break;
            }
            case "openContactForm": {
                if (delegate != null) {
                    delegate.setResult(result);
                    delegate.openContactForm();
                } else {
                    result.success(FORM_COULD_NOT_BE_OPEN);
                }
                break;
            }
            case "openDeviceContactPicker": {
                openDeviceContactPicker(result);
                break;
            }
            default: {
                result.notImplemented();
                break;
            }
        }
    }

    private static final String[] PROJECTION = {
            ContactsContract.Data.CONTACT_ID,
            ContactsContract.Profile.DISPLAY_NAME,
            ContactsContract.Contacts.Data.MIMETYPE,
            ContactsContract.RawContacts.ACCOUNT_TYPE,
            ContactsContract.RawContacts.ACCOUNT_NAME,
            StructuredName.DISPLAY_NAME,
            StructuredName.GIVEN_NAME,
            StructuredName.MIDDLE_NAME,
            StructuredName.FAMILY_NAME,
            StructuredName.PREFIX,
            StructuredName.SUFFIX,
            StructuredName.PHONETIC_GIVEN_NAME,
            StructuredName.PHONETIC_MIDDLE_NAME,
            StructuredName.PHONETIC_FAMILY_NAME,
            StructuredName.PHONETIC_NAME,
            CommonDataKinds.Note.NOTE,
            CommonDataKinds.Nickname.NAME,
            BaseColumns._ID,
            Phone.NUMBER,
            Phone.TYPE,
            Phone.LABEL,
            Email.DATA,
            Email.ADDRESS,
            Email.TYPE,
            Email.LABEL,
            Organization.COMPANY,
            Organization.TITLE,
            Organization.DEPARTMENT,
            StructuredPostal.FORMATTED_ADDRESS,
            StructuredPostal.TYPE,
            StructuredPostal.LABEL,
            StructuredPostal.STREET,
            StructuredPostal.POBOX,
            StructuredPostal.NEIGHBORHOOD,
            StructuredPostal.CITY,
            StructuredPostal.REGION,
            StructuredPostal.POSTCODE,
            StructuredPostal.COUNTRY,
            CommonDataKinds.Im.DATA,
            CommonDataKinds.Im.LABEL,
            CommonDataKinds.Im.TYPE,
            CommonDataKinds.Im.PROTOCOL,
            CommonDataKinds.Im.CUSTOM_PROTOCOL,
            CommonDataKinds.Relation.NAME,
            CommonDataKinds.Relation.LABEL,
            CommonDataKinds.Relation.TYPE,
            CommonDataKinds.Event.START_DATE,
            CommonDataKinds.Event.LABEL,
            CommonDataKinds.Event.TYPE,
            CommonDataKinds.Website.URL,
            ContactsContract.Data.DATA1,
    };


    @TargetApi(Build.VERSION_CODES.ECLAIR)
    private void getContacts(String callMethod, String query, boolean withThumbnails, boolean photoHighResolution, boolean orderByGivenName, Result result) {
        new GetContactsTask(callMethod, result, withThumbnails, photoHighResolution, orderByGivenName).executeOnExecutor(executor, query, false);
    }

    private void getContactsForPhone(String callMethod, String phone, boolean withThumbnails, boolean photoHighResolution, boolean orderByGivenName, Result result) {
        new GetContactsTask(callMethod, result, withThumbnails, photoHighResolution, orderByGivenName).executeOnExecutor(executor, phone, true);
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        if (delegate instanceof ContactServiceDelegate) {
            ((ContactServiceDelegate) delegate).bindToActivity(binding);
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        if (delegate instanceof ContactServiceDelegate) {
            ((ContactServiceDelegate) delegate).unbindActivity();
        }
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        if (delegate instanceof ContactServiceDelegate) {
            ((ContactServiceDelegate) delegate).bindToActivity(binding);
        }
    }

    @Override
    public void onDetachedFromActivity() {
        if (delegate instanceof ContactServiceDelegate) {
            ((ContactServiceDelegate) delegate).unbindActivity();
        }
    }

    private class BaseContactsServiceDelegate implements PluginRegistry.ActivityResultListener {
        private static final int REQUEST_OPEN_CONTACT_FORM = 52941;
        private static final int REQUEST_OPEN_EXISTING_CONTACT = 52942;
        private static final int REQUEST_OPEN_CONTACT_PICKER = 52943;
        private Result result;

        void setResult(Result result) {
            this.result = result;
        }

        void finishWithResult(Object result) {
            if (this.result != null) {
                this.result.success(result);
                this.result = null;
            }
        }

        @Override
        public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
            if (requestCode == REQUEST_OPEN_EXISTING_CONTACT || requestCode == REQUEST_OPEN_CONTACT_FORM) {
                try {
                    Uri ur = intent.getData();
                    finishWithResult(getContactByIdentifier(ur.getLastPathSegment()));
                } catch (NullPointerException e) {
                    finishWithResult(FORM_OPERATION_CANCELED);
                }
                return true;
            }

            if (requestCode == REQUEST_OPEN_CONTACT_PICKER) {
                if (resultCode == RESULT_CANCELED) {
                    finishWithResult(FORM_OPERATION_CANCELED);
                    return true;
                }
                Uri contactUri = intent.getData();
                Cursor cursor = contentResolver.query(contactUri, null, null, null, null);
                if (cursor.moveToFirst()) {
                    String id = contactUri.getLastPathSegment();
                    getContacts("openDeviceContactPicker", id, false, false, false, this.result);
                } else {
                    Log.e(LOG_TAG, "onActivityResult - cursor.moveToFirst() returns false");
                    finishWithResult(FORM_OPERATION_CANCELED);
                }
                cursor.close();
                return true;
            }

            finishWithResult(FORM_COULD_NOT_BE_OPEN);
            return false;
        }

        void openExistingContact(Contact contact) {
            String identifier = contact.identifier;
            try {
                HashMap contactMapFromDevice = getContactByIdentifier(identifier);
                // Contact existence check
                if (contactMapFromDevice != null) {
                    Uri uri = Uri.withAppendedPath(ContactsContract.Contacts.CONTENT_URI, identifier);
                    Intent intent = new Intent(Intent.ACTION_EDIT);
                    intent.setDataAndType(uri, ContactsContract.Contacts.CONTENT_ITEM_TYPE);
                    intent.putExtra("finishActivityOnSaveCompleted", true);
                    startIntent(intent, REQUEST_OPEN_EXISTING_CONTACT);
                } else {
                    finishWithResult(FORM_COULD_NOT_BE_OPEN);
                }
            } catch (Exception e) {
                finishWithResult(FORM_COULD_NOT_BE_OPEN);
            }
        }

        void openContactForm() {
            try {
                Intent intent = new Intent(Intent.ACTION_INSERT, ContactsContract.Contacts.CONTENT_URI);
                intent.putExtra("finishActivityOnSaveCompleted", true);
                startIntent(intent, REQUEST_OPEN_CONTACT_FORM);
            } catch (Exception e) {
            }
        }

        void openContactPicker() {
            Intent intent = new Intent(Intent.ACTION_PICK);
            intent.setType(ContactsContract.Contacts.CONTENT_TYPE);
            startIntent(intent, REQUEST_OPEN_CONTACT_PICKER);
        }

        void startIntent(Intent intent, int request) {
        }

        HashMap getContactByIdentifier(String identifier) {
            ArrayList<Contact> matchingContacts;
            {
                Cursor cursor = contentResolver.query(
                        ContactsContract.Data.CONTENT_URI, PROJECTION,
                        ContactsContract.RawContacts.CONTACT_ID + " = ?",
                        new String[]{identifier},
                        null
                );
                try {
                    matchingContacts = getContactsFrom(cursor);
                } finally {
                    if (cursor != null) {
                        cursor.close();
                    }
                }
            }
            if (matchingContacts.size() > 0) {
                return matchingContacts.iterator().next().toMap();
            }
            return null;
        }
    }

    private void openDeviceContactPicker(Result result) {
        if (delegate != null) {
            delegate.setResult(result);
            delegate.openContactPicker();
        } else {
            result.success(FORM_COULD_NOT_BE_OPEN);
        }
    }

    private class ContactServiceDelegateOld extends BaseContactsServiceDelegate {
        private final PluginRegistry.Registrar registrar;

        ContactServiceDelegateOld(PluginRegistry.Registrar registrar) {
            this.registrar = registrar;
            registrar.addActivityResultListener(this);
        }

        @Override
        void startIntent(Intent intent, int request) {
            if (registrar.activity() != null) {
                registrar.activity().startActivityForResult(intent, request);
            } else {
                registrar.context().startActivity(intent);
            }
        }
    }

    private class ContactServiceDelegate extends BaseContactsServiceDelegate {
        private final Context context;
        private ActivityPluginBinding activityPluginBinding;

        ContactServiceDelegate(Context context) {
            this.context = context;
        }

        void bindToActivity(ActivityPluginBinding activityPluginBinding) {
            this.activityPluginBinding = activityPluginBinding;
            this.activityPluginBinding.addActivityResultListener(this);
        }

        void unbindActivity() {
            this.activityPluginBinding.removeActivityResultListener(this);
            this.activityPluginBinding = null;
        }

        @Override
        void startIntent(Intent intent, int request) {
            if (this.activityPluginBinding != null) {
                if (intent.resolveActivity(context.getPackageManager()) != null) {
                    activityPluginBinding.getActivity().startActivityForResult(intent, request);
                } else {
                    finishWithResult(FORM_COULD_NOT_BE_OPEN);
                }
            } else {
                context.startActivity(intent);
            }
        }
    }

    @TargetApi(Build.VERSION_CODES.CUPCAKE)
    private class GetContactsTask extends AsyncTask<Object, Void, ArrayList<HashMap>> {

        private String callMethod;
        private Result getContactResult;
        private boolean withThumbnails;
        private boolean photoHighResolution;
        private boolean orderByGivenName;

        public GetContactsTask(String callMethod, MethodChannel.Result result, boolean withThumbnails, boolean photoHighResolution, boolean orderByGivenName) {
            this.callMethod = callMethod;
            this.getContactResult = result;
            this.withThumbnails = withThumbnails;
            this.photoHighResolution = photoHighResolution;
            this.orderByGivenName = orderByGivenName;
        }

        @TargetApi(Build.VERSION_CODES.ECLAIR)
        protected ArrayList<HashMap> doInBackground(Object... params) {
            ArrayList<Contact> contacts;
            switch (callMethod) {
                case "openDeviceContactPicker":
                    contacts = getContactsFrom(getCursor(null, (String) params[0]));
                    break;
                case "getContacts":
                    contacts = getContactsFrom(getCursor((String) params[0], null));
                    break;
                case "getContactsForPhone":
                    contacts = getContactsFrom(getCursorForPhone(((String) params[0])));
                    break;
                default:
                    return null;
            }

            if (withThumbnails) {
                for (Contact c : contacts) {
                    final byte[] avatar = loadContactPhotoHighRes(
                            c.identifier, photoHighResolution, contentResolver);
                    if (avatar != null) {
                        c.avatar = avatar;
                    } else {
                        // To stay backwards-compatible, return an empty byte array rather than `null`.
                        c.avatar = new byte[0];
                    }
//          if ((Boolean) params[3])
//              loadContactPhotoHighRes(c.identifier, (Boolean) params[3]);
//          else
//              setAvatarDataForContactIfAvailable(c);
                }
            }

            if (orderByGivenName) {
                Comparator<Contact> compareByGivenName = new Comparator<Contact>() {
                    @Override
                    public int compare(Contact contactA, Contact contactB) {
                        return contactA.compareTo(contactB);
                    }
                };
                Collections.sort(contacts, compareByGivenName);
            }

            //Transform the list of contacts to a list of Map
            ArrayList<HashMap> contactMaps = new ArrayList<>();
            for (Contact c : contacts) {
                contactMaps.add(c.toMap());
            }

            return contactMaps;
        }

        protected void onPostExecute(ArrayList<HashMap> result) {
            if (result == null) {
                getContactResult.notImplemented();
            } else {
                getContactResult.success(result);
            }
        }
    }


    private Cursor getCursor(String query, String rawContactId) {
        String selection = ContactsContract.Data.MIMETYPE + " IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ";
        ArrayList<String> selectionArgs = new ArrayList<>(Arrays.asList(CommonDataKinds.Nickname.CONTENT_ITEM_TYPE,
                CommonDataKinds.Note.CONTENT_ITEM_TYPE, Email.CONTENT_ITEM_TYPE,
                Phone.CONTENT_ITEM_TYPE, StructuredName.CONTENT_ITEM_TYPE, Organization.CONTENT_ITEM_TYPE,
                StructuredPostal.CONTENT_ITEM_TYPE, CommonDataKinds.Event.CONTENT_ITEM_TYPE, CommonDataKinds.Im.CONTENT_ITEM_TYPE,
                CommonDataKinds.Relation.CONTENT_ITEM_TYPE, CommonDataKinds.Website.CONTENT_ITEM_TYPE, CommonDataKinds.SipAddress.CONTENT_ITEM_TYPE,
                CommonDataKinds.GroupMembership.CONTENT_ITEM_TYPE));

        if (query != null) {
            selectionArgs = new ArrayList<>();
            selectionArgs.add(query + "%");
            selection = ContactsContract.Contacts.DISPLAY_NAME_PRIMARY + " LIKE ?";
        }
        if (rawContactId != null) {
            selection += " AND " + ContactsContract.Data.CONTACT_ID + " = ?";
            selectionArgs.add(rawContactId);
        }
        return contentResolver.query(ContactsContract.Data.CONTENT_URI, PROJECTION, selection,
                selectionArgs.toArray(new String[selectionArgs.size()]), null);
    }

    private Cursor getCursorForPhone(String phone) {
        if (phone.isEmpty()) {
            return null;
        }

        Uri uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phone));
        String[] projection = new String[]{BaseColumns._ID};

        ArrayList<String> contactIds = new ArrayList<>();
        Cursor phoneCursor = contentResolver.query(uri, projection, null, null, null);
        while (phoneCursor != null && phoneCursor.moveToNext()) {
            contactIds.add(phoneCursor.getString(phoneCursor.getColumnIndex(BaseColumns._ID)));
        }
        if (phoneCursor != null) {
            phoneCursor.close();
        }

        if (!contactIds.isEmpty()) {
            String contactIdsListString = contactIds.toString().replace("[", "(").replace("]", ")");
            String contactSelection = ContactsContract.Data.CONTACT_ID + " IN " + contactIdsListString;
            return contentResolver.query(ContactsContract.Data.CONTENT_URI, PROJECTION, contactSelection, null, null);
        }

        return null;
    }

    /**
     * Builds the list of contacts from the cursor
     *
     * @param cursor
     * @return the list of contacts
     */
    private ArrayList<Contact> getContactsFrom(Cursor cursor) {
        HashMap<String, Contact> map = new LinkedHashMap<>();

        while (cursor != null && cursor.moveToNext()) {
            int columnIndex = cursor.getColumnIndex(ContactsContract.Data.CONTACT_ID);
            String contactId = cursor.getString(columnIndex);

            if (!map.containsKey(contactId)) {
                map.put(contactId, new Contact(contactId));
            }
            Contact contact = map.get(contactId);

            String mimeType = cursor.getString(cursor.getColumnIndex(ContactsContract.Data.MIMETYPE));
            contact.identifier = contactId;
            contact.displayName = cursor.getString(cursor.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME));
            contact.androidAccountType = cursor.getString(cursor.getColumnIndex(ContactsContract.RawContacts.ACCOUNT_TYPE));
            contact.androidAccountName = cursor.getString(cursor.getColumnIndex(ContactsContract.RawContacts.ACCOUNT_NAME));

            //NAMES
            if (mimeType.equals(CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)) {
                contact.givenName = cursor.getString(cursor.getColumnIndex(StructuredName.GIVEN_NAME));
                contact.middleName = cursor.getString(cursor.getColumnIndex(StructuredName.MIDDLE_NAME));
                contact.familyName = cursor.getString(cursor.getColumnIndex(StructuredName.FAMILY_NAME));
                contact.prefix = cursor.getString(cursor.getColumnIndex(StructuredName.PREFIX));
                contact.suffix = cursor.getString(cursor.getColumnIndex(StructuredName.SUFFIX));
                contact.phoneticGivenName = cursor.getString(cursor.getColumnIndex(StructuredName.PHONETIC_GIVEN_NAME));
                contact.phoneticMiddleName = cursor.getString(cursor.getColumnIndex(StructuredName.PHONETIC_MIDDLE_NAME));
                contact.phoneticFamilyName = cursor.getString(cursor.getColumnIndex(StructuredName.PHONETIC_FAMILY_NAME));
                contact.phoneticName = cursor.getString(cursor.getColumnIndex(StructuredName.PHONETIC_NAME));
            }
            //NICK NAME
            else if (mimeType.equals(CommonDataKinds.Nickname.CONTENT_ITEM_TYPE)) {
                contact.nickname = cursor.getString(cursor.getColumnIndex(CommonDataKinds.Nickname.NAME));
            }
            // SIP
            else if (mimeType.equals(CommonDataKinds.SipAddress.CONTENT_ITEM_TYPE)) {
                contact.sip = cursor.getString(cursor.getColumnIndex(CommonDataKinds.SipAddress.SIP_ADDRESS));
            }
            // NOTE
            else if (mimeType.equals(CommonDataKinds.Note.CONTENT_ITEM_TYPE)) {
                contact.note = cursor.getString(cursor.getColumnIndex(CommonDataKinds.Note.NOTE));
            }
            //PHONES
            else if (mimeType.equals(CommonDataKinds.Phone.CONTENT_ITEM_TYPE)) {
                String phoneNumber = cursor.getString(cursor.getColumnIndex(Phone.NUMBER));
                if (!TextUtils.isEmpty(phoneNumber)) {
                    int type = cursor.getInt(cursor.getColumnIndex(Phone.TYPE));
                    String label = Item.getPhoneLabel(type, cursor);
                    contact.phones.add(new Item(cursor.getString(cursor.getColumnIndex(BaseColumns._ID)), label, phoneNumber));
                }
            }
            //MAILS
            else if (mimeType.equals(CommonDataKinds.Email.CONTENT_ITEM_TYPE)) {
                String email = cursor.getString(cursor.getColumnIndex(Email.ADDRESS));
                int type = cursor.getInt(cursor.getColumnIndex(Email.TYPE));
                if (!TextUtils.isEmpty(email)) {
                    contact.emails.add(new Item(cursor.getString(cursor.getColumnIndex(BaseColumns._ID)), Item.getEmailLabel(type, cursor), email));
                }
            }
            //ORG
            else if (mimeType.equals(CommonDataKinds.Organization.CONTENT_ITEM_TYPE)) {
                contact.company = cursor.getString(cursor.getColumnIndex(Organization.COMPANY));
                contact.jobTitle = cursor.getString(cursor.getColumnIndex(Organization.TITLE));
                contact.department = cursor.getString(cursor.getColumnIndex(Organization.DEPARTMENT));
            }
            //ADDRESSES
            else if (mimeType.equals(CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)) {
                contact.postalAddresses.add(new PostalAddress(cursor));
            }
            // BIRTHDAY/EVENTS(DATES)
            else if (mimeType.equals(CommonDataKinds.Event.CONTENT_ITEM_TYPE)) {
                String date = cursor.getString(cursor.getColumnIndex(CommonDataKinds.Event.START_DATE));
                int eventType = cursor.getInt(cursor.getColumnIndex(CommonDataKinds.Event.TYPE));
                if (eventType == CommonDataKinds.Event.TYPE_BIRTHDAY) {
                    contact.birthday = date;
                } else {
                    contact.dates.add(new Item(cursor.getString(cursor.getColumnIndex(BaseColumns._ID)), Item.getDatesLabel(eventType, cursor),
                            date));
                }
            }
            //INSTANT MESSAGE ADDRESSES / Im
            else if (mimeType.equals(CommonDataKinds.Im.CONTENT_ITEM_TYPE)) {
                String im = cursor.getString(cursor.getColumnIndex(CommonDataKinds.Im.DATA));
                int protocol = cursor.getInt(cursor.getColumnIndex(CommonDataKinds.Im.PROTOCOL));
                if (!TextUtils.isEmpty(im)) {
                    contact.instantMessageAddresses.add(new Item(cursor.getString(cursor.getColumnIndex(BaseColumns._ID)),
                            Item.getInstantMessageAddressLabel(protocol, cursor), im));
                }
            }
            //RELATIONS
            else if (mimeType.equals(CommonDataKinds.Relation.CONTENT_ITEM_TYPE)) {
                String relation = cursor.getString(cursor.getColumnIndex(CommonDataKinds.Relation.NAME));
                int type = cursor.getInt(cursor.getColumnIndex(CommonDataKinds.Relation.TYPE));
                if (!TextUtils.isEmpty(relation)) {
                    contact.relations.add(new Item(cursor.getString(cursor.getColumnIndex(BaseColumns._ID)), Item.getRelationLabel(type,
                            cursor), relation));
                }
            }
            //WEBSITES
            else if (mimeType.equals(CommonDataKinds.Website.CONTENT_ITEM_TYPE)) {
                String url = cursor.getString(cursor.getColumnIndex(CommonDataKinds.Website.URL));
                int type = cursor.getInt(cursor.getColumnIndex(CommonDataKinds.Website.TYPE));
                if (!TextUtils.isEmpty(url)) {
                    contact.websites.add(new Item(cursor.getString(cursor.getColumnIndex(BaseColumns._ID)), Item.getWebsiteLabel(type,
                            cursor), url));
                }
            }
            //LABELS
            else if (mimeType.equals(CommonDataKinds.GroupMembership.CONTENT_ITEM_TYPE)) {
                String groupId = cursor.getString(cursor.getColumnIndex(CommonDataKinds.GroupMembership.DATA1));
                if (!TextUtils.isEmpty(groupId)) {
                    Uri uriGroup = ContactsContract.Groups.CONTENT_URI;
                    String groupParam[] = new String[]{ContactsContract.Groups.TITLE};
                    String query = BaseColumns._ID + " = " + groupId;
                    Cursor cursorGroupTitle = contentResolver.query(uriGroup, groupParam, query, null, null);
                    if (cursorGroupTitle != null && cursorGroupTitle.getCount() > 0) {
                        while (cursorGroupTitle.moveToNext()) {
                            contact.labels.add(cursorGroupTitle.getString(0));
                        }
                    }
                    if (cursorGroupTitle != null) {
                        cursorGroupTitle.close();
                    }
                }
            }
        }

        if (cursor != null) {
            cursor.close();
        }

        return new ArrayList<>(map.values());
    }

    private void setAvatarDataForContactIfAvailable(Contact contact) {
        Uri contactUri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, Integer.parseInt(contact.identifier));
        Uri photoUri = Uri.withAppendedPath(contactUri, ContactsContract.Contacts.Photo.CONTENT_DIRECTORY);
        Cursor avatarCursor = contentResolver.query(photoUri,
                new String[]{ContactsContract.Contacts.Photo.PHOTO}, null, null, null);
        if (avatarCursor != null && avatarCursor.moveToFirst()) {
            byte[] avatar = avatarCursor.getBlob(0);
            contact.avatar = avatar;
        }
        if (avatarCursor != null) {
            avatarCursor.close();
        }
    }

    private void getAvatar(final Contact contact, final boolean highRes,
                           final Result result) {
        new GetAvatarsTask(contact, highRes, contentResolver, result).executeOnExecutor(this.executor);
    }

    private static class GetAvatarsTask extends AsyncTask<Void, Void, byte[]> {
        final Contact contact;
        final boolean highRes;
        final ContentResolver contentResolver;
        final Result result;

        GetAvatarsTask(final Contact contact, final boolean highRes,
                       final ContentResolver contentResolver, final Result result) {
            this.contact = contact;
            this.highRes = highRes;
            this.contentResolver = contentResolver;
            this.result = result;
        }

        @Override
        protected byte[] doInBackground(final Void... params) {
            // Load avatar for each contact identifier.
            return loadContactPhotoHighRes(contact.identifier, highRes, contentResolver);
        }

        @Override
        protected void onPostExecute(final byte[] avatar) {
            result.success(avatar);
        }

    }

    private static byte[] loadContactPhotoHighRes(final String identifier,
                                                  final boolean photoHighResolution, final ContentResolver contentResolver) {
        try {
            final Uri uri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, Long.parseLong(identifier));
            final InputStream input = ContactsContract.Contacts.openContactPhotoInputStream(contentResolver, uri, photoHighResolution);

            if (input == null) return null;

            final Bitmap bitmap = BitmapFactory.decodeStream(input);
            input.close();

            final ByteArrayOutputStream stream = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
            final byte[] bytes = stream.toByteArray();
            stream.close();
            return bytes;
        } catch (final IOException ex) {
            Log.e(LOG_TAG, ex.getMessage());
            return null;
        }
    }

    private boolean addContact(Contact contact) {

        ArrayList<ContentProviderOperation> ops = new ArrayList<>();

        ContentProviderOperation.Builder op = ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
                .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null);
        ops.add(op.build());

        // Names
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                .withValue(StructuredName.GIVEN_NAME, contact.givenName)
                .withValue(StructuredName.MIDDLE_NAME, contact.middleName)
                .withValue(StructuredName.FAMILY_NAME, contact.familyName)
                .withValue(StructuredName.PREFIX, contact.prefix)
                .withValue(StructuredName.SUFFIX, contact.suffix)
                .withValue(StructuredName.PHONETIC_GIVEN_NAME, contact.phoneticGivenName)
                .withValue(StructuredName.PHONETIC_MIDDLE_NAME, contact.phoneticMiddleName)
                .withValue(StructuredName.PHONETIC_FAMILY_NAME, contact.phoneticFamilyName);

        ops.add(op.build());

        // Note
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Note.CONTENT_ITEM_TYPE)
                .withValue(CommonDataKinds.Note.NOTE, contact.note);
        ops.add(op.build());

        // Sip
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.SipAddress.CONTENT_ITEM_TYPE)
                .withValue(CommonDataKinds.SipAddress.SIP_ADDRESS, contact.sip);
        ops.add(op.build());

        // Nickname
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Nickname.CONTENT_ITEM_TYPE)
                .withValue(CommonDataKinds.Nickname.NAME, contact.nickname);
        ops.add(op.build());

        // Organisation
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Organization.CONTENT_ITEM_TYPE)
                .withValue(Organization.COMPANY, contact.company)
                .withValue(Organization.TITLE, contact.jobTitle)
                .withValue(Organization.DEPARTMENT, contact.department);
        ops.add(op.build());

        //Photo
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.IS_SUPER_PRIMARY, 1)
                .withValue(ContactsContract.CommonDataKinds.Photo.PHOTO, contact.avatar)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Photo.CONTENT_ITEM_TYPE);
        ops.add(op.build());

        op.withYieldAllowed(true);

        //Phones
        for (Item phone : contact.phones) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone.value);

            if (Item.stringToPhoneType(phone.label) == ContactsContract.CommonDataKinds.Phone.TYPE_CUSTOM) {
                op.withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.BaseTypes.TYPE_CUSTOM);
                op.withValue(ContactsContract.CommonDataKinds.Phone.LABEL, phone.label);
            } else {
                op.withValue(ContactsContract.CommonDataKinds.Phone.TYPE, Item.stringToPhoneType(phone.label));
            }

            ops.add(op.build());
        }

        //Emails
        for (Item email : contact.emails) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                    .withValue(CommonDataKinds.Email.ADDRESS, email.value)
                    .withValue(CommonDataKinds.Email.TYPE, Item.stringToEmailType(email.label));
            ops.add(op.build());
        }
        //Postal addresses
        for (PostalAddress address : contact.postalAddresses) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
                    .withValue(CommonDataKinds.StructuredPostal.TYPE, PostalAddress.stringToPostalAddressType(address.label))
                    .withValue(CommonDataKinds.StructuredPostal.LABEL, address.label)
                    .withValue(CommonDataKinds.StructuredPostal.STREET, address.street)
                    .withValue(CommonDataKinds.StructuredPostal.CITY, address.city)
                    .withValue(CommonDataKinds.StructuredPostal.REGION, address.region)
                    .withValue(CommonDataKinds.StructuredPostal.POSTCODE, address.postcode)
                    .withValue(CommonDataKinds.StructuredPostal.COUNTRY, address.country);
            ops.add(op.build());
        }

        // Birthday
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Event.CONTENT_ITEM_TYPE)
                .withValue(CommonDataKinds.Event.TYPE, CommonDataKinds.Event.TYPE_BIRTHDAY)
                .withValue(CommonDataKinds.Event.START_DATE, contact.birthday);
        ops.add(op.build());

        // Other dates/events
        for (Item date : contact.dates) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Event.CONTENT_ITEM_TYPE)
                    .withValue(CommonDataKinds.Event.LABEL, date.label)
                    .withValue(CommonDataKinds.Event.TYPE, Item.stringToDatesType(date.label))
                    .withValue(CommonDataKinds.Event.START_DATE, date.value);
            ops.add(op.build());
        }

        // Website
        for (Item website : contact.websites) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Website.CONTENT_ITEM_TYPE)
                    .withValue(CommonDataKinds.Website.LABEL, website.label)
                    .withValue(CommonDataKinds.Website.TYPE, Item.stringToWebsiteType(website.label))
                    .withValue(CommonDataKinds.Website.URL, website.value);
            ops.add(op.build());
        }

        // Instant message address
        for (Item im : contact.instantMessageAddresses) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Im.CONTENT_ITEM_TYPE)
                    .withValue(CommonDataKinds.Im.PROTOCOL, Item.stringToInstantMessageAddressProtocol(im.label))
                    .withValue(CommonDataKinds.Im.DATA, im.value);
            ops.add(op.build());
        }
        // Relations
        for (Item relation : contact.relations) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Relation.CONTENT_ITEM_TYPE)
                    .withValue(CommonDataKinds.Relation.LABEL, relation.label)
                    .withValue(CommonDataKinds.Relation.TYPE, Item.stringToRelationType(relation.label))
                    .withValue(CommonDataKinds.Relation.NAME, relation.value);
            ops.add(op.build());
        }

        //TODO. Labels if any

        try {
            contentResolver.applyBatch(ContactsContract.AUTHORITY, ops);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private boolean deleteContact(Contact contact) {
        ArrayList<ContentProviderOperation> ops = new ArrayList<>();
        ops.add(ContentProviderOperation.newDelete(ContactsContract.RawContacts.CONTENT_URI)
                .withSelection(ContactsContract.RawContacts.CONTACT_ID + "=?", new String[]{String.valueOf(contact.identifier)})
                .build());
        try {
            contentResolver.applyBatch(ContactsContract.AUTHORITY, ops);
            return true;
        } catch (Exception e) {
            return false;

        }
    }

    private boolean updateContact(Contact contact) {
        ArrayList<ContentProviderOperation> ops = new ArrayList<>();
        ContentProviderOperation.Builder op;

        // Drop all details about contact except names

        // Organisation
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Nickname
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.Nickname.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Sip
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.SipAddress.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Note
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Phone
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Email
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Postal address
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Dates
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Instant message address
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.Im.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Relation
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.Relation.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Website
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        //Photo
        op = ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.Photo.CONTENT_ITEM_TYPE});
        ops.add(op.build());

        // Update data (name)
        op = ContentProviderOperation.newUpdate(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        new String[]{String.valueOf(contact.identifier), ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE})
                .withValue(StructuredName.GIVEN_NAME, contact.givenName)
                .withValue(StructuredName.MIDDLE_NAME, contact.middleName)
                .withValue(StructuredName.FAMILY_NAME, contact.familyName)
                .withValue(StructuredName.PREFIX, contact.prefix)
                .withValue(StructuredName.SUFFIX, contact.suffix)
                .withValue(StructuredName.PHONETIC_GIVEN_NAME, contact.phoneticGivenName)
                .withValue(StructuredName.PHONETIC_MIDDLE_NAME, contact.phoneticMiddleName)
                .withValue(StructuredName.PHONETIC_FAMILY_NAME, contact.phoneticFamilyName);
        ops.add(op.build());

        // Insert data back into contact
        // Organisation
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                .withValue(Organization.TYPE, Organization.TYPE_WORK)
                .withValue(Organization.COMPANY, contact.company)
                .withValue(Organization.DEPARTMENT, contact.department)
                .withValue(Organization.TITLE, contact.jobTitle);
        ops.add(op.build());

        // Note
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                .withValue(CommonDataKinds.Note.NOTE, contact.note);
        ops.add(op.build());

        // Sip
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                .withValue(CommonDataKinds.SipAddress.SIP_ADDRESS, contact.sip);
        ops.add(op.build());

        // Nick name
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                .withValue(CommonDataKinds.Nickname.NAME, contact.nickname);
        ops.add(op.build());

        //Photo
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                .withValue(ContactsContract.Data.IS_SUPER_PRIMARY, 1)
                .withValue(ContactsContract.CommonDataKinds.Photo.PHOTO, contact.avatar)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Photo.CONTENT_ITEM_TYPE);
        ops.add(op.build());


        // Phone
        for (Item phone : contact.phones) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                    .withValue(Phone.NUMBER, phone.value);

            if (Item.stringToPhoneType(phone.label) == ContactsContract.CommonDataKinds.Phone.TYPE_CUSTOM) {
                op.withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.BaseTypes.TYPE_CUSTOM);
                op.withValue(ContactsContract.CommonDataKinds.Phone.LABEL, phone.label);
            } else {
                op.withValue(ContactsContract.CommonDataKinds.Phone.TYPE, Item.stringToPhoneType(phone.label));
            }

            ops.add(op.build());
        }

        // Email
        for (Item email : contact.emails) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                    .withValue(CommonDataKinds.Email.ADDRESS, email.value)
                    .withValue(CommonDataKinds.Email.TYPE, Item.stringToEmailType(email.label));
            ops.add(op.build());
        }

        // Postal address
        for (PostalAddress address : contact.postalAddresses) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                    .withValue(CommonDataKinds.StructuredPostal.TYPE, PostalAddress.stringToPostalAddressType(address.label))
                    .withValue(CommonDataKinds.StructuredPostal.STREET, address.street)
                    .withValue(CommonDataKinds.StructuredPostal.CITY, address.city)
                    .withValue(CommonDataKinds.StructuredPostal.REGION, address.region)
                    .withValue(CommonDataKinds.StructuredPostal.POSTCODE, address.postcode)
                    .withValue(CommonDataKinds.StructuredPostal.COUNTRY, address.country);
            ops.add(op.build());
        }

        // Website
        for (Item website : contact.websites) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Website.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                    .withValue(CommonDataKinds.Website.URL, website.value)
                    .withValue(CommonDataKinds.Website.TYPE, Item.stringToWebsiteType(website.label));
            ops.add(op.build());
        }

        // Date
        op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Event.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                .withValue(CommonDataKinds.Event.START_DATE, contact.birthday)
                .withValue(CommonDataKinds.Event.TYPE, Item.stringToDatesType("birthday"));
        ops.add(op.build());
        for (Item date : contact.dates) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Event.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                    .withValue(CommonDataKinds.Event.START_DATE, date.value)
                    .withValue(CommonDataKinds.Event.TYPE, Item.stringToDatesType(date.label));
            ops.add(op.build());
        }

        // Instant message address
        for (Item im : contact.instantMessageAddresses) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Im.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                    .withValue(CommonDataKinds.Im.DATA, im.value)
                    .withValue(CommonDataKinds.Im.PROTOCOL, Item.stringToInstantMessageAddressProtocol(im.label));
            ops.add(op.build());
        }

        // Relation
        for (Item relation : contact.relations) {
            op = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Relation.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier)
                    .withValue(CommonDataKinds.Relation.NAME, relation.value)
                    .withValue(CommonDataKinds.Relation.TYPE, Item.stringToRelationType(relation.label));
            ops.add(op.build());
        }

        //TODO. Labels if any

        try {
            contentResolver.applyBatch(ContactsContract.AUTHORITY, ops);
            return true;
        } catch (Exception e) {
            // Log exception
            Log.e("TAG", "Exception encountered while inserting contact: ");
            e.printStackTrace();
            return false;
        }
    }

}
