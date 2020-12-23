package flutter.plugins.contactsservice.contactsservice;

import android.content.res.Resources;
import android.database.Cursor;

import static android.provider.ContactsContract.CommonDataKinds;

import java.util.HashMap;

/***
 * Represents an object which has a label and a value
 * such as an email or a phone
 ***/
public class Item {

    public String label, value;
    int type;

    public Item(String label, String value, int type) {
        this.label = label;
        this.value = value;
        this.type = type;
    }

    HashMap<String, String> toMap() {
        HashMap<String, String> result = new HashMap<>();
        result.put("label", label);
        result.put("value", value);
        result.put("type", String.valueOf(type));
        return result;
    }

    public static Item fromMap(HashMap<String, String> map) {
        String label = map.get("label");
        String value = map.get("value");
        String type = map.get("type");
        return new Item(label, value, type != null ? Integer.parseInt(type) : -1);
    }

    public static String getPhoneLabel(Resources resources, int type, Cursor cursor, boolean localizedLabels) {
        if (localizedLabels) {
            CharSequence localizedLabel = CommonDataKinds.Phone.getTypeLabel(resources, type, "");
            return localizedLabel.toString().toLowerCase();
        } else {
            switch (type) {
                case CommonDataKinds.Phone.TYPE_HOME:
                    return "home";
                case CommonDataKinds.Phone.TYPE_WORK:
                    return "work";
                case CommonDataKinds.Phone.TYPE_MOBILE:
                    return "mobile";
                case CommonDataKinds.Phone.TYPE_FAX_WORK:
                    return "fax work";
                case CommonDataKinds.Phone.TYPE_FAX_HOME:
                    return "fax home";
                case CommonDataKinds.Phone.TYPE_MAIN:
                    return "main";
                case CommonDataKinds.Phone.TYPE_COMPANY_MAIN:
                    return "company";
                case CommonDataKinds.Phone.TYPE_PAGER:
                    return "pager";
                case CommonDataKinds.Phone.TYPE_CUSTOM:
                    if (cursor.getString(cursor.getColumnIndex(CommonDataKinds.Phone.LABEL)) != null) {
                        return cursor.getString(cursor.getColumnIndex(CommonDataKinds.Phone.LABEL)).toLowerCase();
                    } else return "";
                default:
                    return "other";
            }
        }
    }

    public static String getEmailLabel(Resources resources, int type, Cursor cursor, boolean localizedLabels) {
        if (localizedLabels) {
            CharSequence localizedLabel = CommonDataKinds.Email.getTypeLabel(resources, type, "");
            return localizedLabel.toString().toLowerCase();
        } else {
            switch (type) {
                case CommonDataKinds.Email.TYPE_HOME:
                    return "home";
                case CommonDataKinds.Email.TYPE_WORK:
                    return "work";
                case CommonDataKinds.Email.TYPE_MOBILE:
                    return "mobile";
                case CommonDataKinds.Email.TYPE_CUSTOM:
                    if (cursor.getString(cursor.getColumnIndex(CommonDataKinds.Email.LABEL)) != null) {
                        return cursor.getString(cursor.getColumnIndex(CommonDataKinds.Email.LABEL)).toLowerCase();
                    } else return "";
                default:
                    return "other";
            }
        }
    }
}