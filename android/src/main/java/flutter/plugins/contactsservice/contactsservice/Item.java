package flutter.plugins.contactsservice.contactsservice;

import android.database.Cursor;

import static android.provider.ContactsContract.CommonDataKinds;

import java.util.HashMap;

/***
 * Represents an object which has a label and a value
 * such as an email or a phone
 ***/
public class Item {

    public String identifier, label, value;

    public Item(String identifier, String label, String value) {
        this.identifier = identifier;
        this.label = label;
        this.value = value;
    }

    HashMap<String, String> toMap() {
        HashMap<String, String> result = new HashMap<>();
        result.put("identifier", identifier);
        result.put("label", label);
        result.put("value", value);
        return result;
    }

    public static Item fromMap(HashMap<String, String> map) {
        return new Item(map.get("identifier"), map.get("label"), map.get("value"));
    }

    public static String getPhoneLabel(int type, Cursor cursor) {
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
                } else {
                    return "";
                }
            default:
                return "other";
        }
    }

    public static String getEmailLabel(int type, Cursor cursor) {
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
                } else {
                    return "";
                }
            default:
                return "other";
        }
    }

    public static String getDatesLabel(int type, Cursor cursor) {
        switch (type) {
            case CommonDataKinds.Event.TYPE_ANNIVERSARY:
                return "anniversary";
            case CommonDataKinds.Event.TYPE_BIRTHDAY:
                return "birthday";
            case CommonDataKinds.Event.TYPE_CUSTOM:
                if (cursor.getString(cursor.getColumnIndex(CommonDataKinds.Event.LABEL)) != null) {
                    return cursor.getString(cursor.getColumnIndex(CommonDataKinds.Event.LABEL)).toLowerCase();
                } else {
                    return "";
                }
            default:
                return "other";
        }
    }

    public static String getRelationLabel(int type, Cursor cursor) {
        switch (type) {
            case CommonDataKinds.Relation.TYPE_ASSISTANT:
                return "assistant";
            case CommonDataKinds.Relation.TYPE_BROTHER:
                return "brother";
            case CommonDataKinds.Relation.TYPE_CHILD:
                return "child";
            case CommonDataKinds.Relation.TYPE_DOMESTIC_PARTNER:
                return "domestic partner";
            case CommonDataKinds.Relation.TYPE_FATHER:
                return "father";
            case CommonDataKinds.Relation.TYPE_FRIEND:
                return "friend";
            case CommonDataKinds.Relation.TYPE_MANAGER:
                return "manager";
            case CommonDataKinds.Relation.TYPE_MOTHER:
                return "mother";
            case CommonDataKinds.Relation.TYPE_PARENT:
                return "parent";
            case CommonDataKinds.Relation.TYPE_PARTNER:
                return "partner";
            case CommonDataKinds.Relation.TYPE_REFERRED_BY:
                return "referred by";
            case CommonDataKinds.Relation.TYPE_SISTER:
                return "sister";
            case CommonDataKinds.Relation.TYPE_SPOUSE:
                return "spouse";
            case CommonDataKinds.Relation.TYPE_CUSTOM:
                if (cursor.getString(cursor.getColumnIndex(CommonDataKinds.Relation.LABEL)) != null) {
                    return cursor.getString(cursor.getColumnIndex(CommonDataKinds.Relation.LABEL)).toLowerCase();
                } else {
                    return "";
                }
            default:
                return "other";
        }
    }

    public static String getInstantMessageAddressLabel(int protocol, Cursor cursor) {
        switch (protocol) {
            case CommonDataKinds.Im.PROTOCOL_AIM:
                return "AIM";
            case CommonDataKinds.Im.PROTOCOL_MSN:
                return "Windows Live";
            case CommonDataKinds.Im.PROTOCOL_YAHOO:
                return "Yahoo";
            case CommonDataKinds.Im.PROTOCOL_SKYPE:
                return "Skype";
            case CommonDataKinds.Im.PROTOCOL_QQ:
                return "QQ";
            case CommonDataKinds.Im.PROTOCOL_GOOGLE_TALK:
                return "Hangouts";
            case CommonDataKinds.Im.PROTOCOL_ICQ:
                return "ICQ";
            case CommonDataKinds.Im.PROTOCOL_JABBER:
                return "Jabber";
            case CommonDataKinds.Im.PROTOCOL_NETMEETING:
                return "Net Meeting";
            case CommonDataKinds.Im.PROTOCOL_CUSTOM:
                if (cursor.getString(cursor.getColumnIndex(CommonDataKinds.Im.CUSTOM_PROTOCOL)) != null) {
                    return cursor.getString(cursor.getColumnIndex(CommonDataKinds.Im.CUSTOM_PROTOCOL));
                } else {
                    return "";
                }
            default:
                return "other";
        }
    }

    public static String getWebsiteLabel(int type, Cursor cursor) {
        switch (type) {
            case CommonDataKinds.Website.TYPE_HOMEPAGE:
                return "home page";
            case CommonDataKinds.Website.TYPE_BLOG:
                return "blog";
            case CommonDataKinds.Website.TYPE_PROFILE:
                return "profile";
            case CommonDataKinds.Website.TYPE_HOME:
                return "home";
            case CommonDataKinds.Website.TYPE_WORK:
                return "work";
            case CommonDataKinds.Website.TYPE_FTP:
                return "ftp";
            case CommonDataKinds.Website.TYPE_CUSTOM:
                if (cursor.getString(cursor.getColumnIndex(CommonDataKinds.Website.LABEL)) != null) {
                    return cursor.getString(cursor.getColumnIndex(CommonDataKinds.Website.LABEL));
                } else {
                    return "";
                }
            default:
                return "other";
        }
    }

    public static int stringToPhoneType(String label) {
        if (label != null) {
            switch (label.toLowerCase()) {
                case "home":
                    return CommonDataKinds.Phone.TYPE_HOME;
                case "work":
                    return CommonDataKinds.Phone.TYPE_WORK;
                case "mobile":
                    return CommonDataKinds.Phone.TYPE_MOBILE;
                case "fax work":
                    return CommonDataKinds.Phone.TYPE_FAX_WORK;
                case "fax home":
                    return CommonDataKinds.Phone.TYPE_FAX_HOME;
                case "main":
                    return CommonDataKinds.Phone.TYPE_MAIN;
                case "company":
                    return CommonDataKinds.Phone.TYPE_COMPANY_MAIN;
                case "pager":
                    return CommonDataKinds.Phone.TYPE_PAGER;
                case "other":
                    return CommonDataKinds.Phone.TYPE_OTHER;
                default:
                    return CommonDataKinds.Phone.TYPE_CUSTOM;
            }
        }
        return CommonDataKinds.Phone.TYPE_OTHER;
    }

    public static int stringToEmailType(String label) {
        if (label != null) {
            switch (label.toLowerCase()) {
                case "home":
                    return CommonDataKinds.Email.TYPE_HOME;
                case "work":
                    return CommonDataKinds.Email.TYPE_WORK;
                case "mobile":
                    return CommonDataKinds.Email.TYPE_MOBILE;
                default:
                    return CommonDataKinds.Email.TYPE_CUSTOM;
            }
        }
        return CommonDataKinds.Email.TYPE_OTHER;
    }

    public static int stringToDatesType(String label) {
        if (label != null) {
            switch (label.toLowerCase()) {
                case "anniversary":
                    return CommonDataKinds.Event.TYPE_ANNIVERSARY;
                case "birthday":
                    return CommonDataKinds.Event.TYPE_BIRTHDAY;
                default:
                    return CommonDataKinds.Event.TYPE_CUSTOM;
            }
        }
        return CommonDataKinds.Email.TYPE_OTHER;
    }

    public static int stringToRelationType(String label) {
        if (label != null) {
            switch (label.toLowerCase()) {
                case "assistant":
                    return CommonDataKinds.Relation.TYPE_ASSISTANT;
                case "brother":
                    return CommonDataKinds.Relation.TYPE_BROTHER;
                case "child":
                    return CommonDataKinds.Relation.TYPE_CHILD;
                case "domestic partner":
                    return CommonDataKinds.Relation.TYPE_DOMESTIC_PARTNER;
                case "father":
                    return CommonDataKinds.Relation.TYPE_FATHER;
                case "friend":
                    return CommonDataKinds.Relation.TYPE_FRIEND;
                case "manager":
                    return CommonDataKinds.Relation.TYPE_MANAGER;
                case "mother":
                    return CommonDataKinds.Relation.TYPE_MOTHER;
                case "parent":
                    return CommonDataKinds.Relation.TYPE_PARENT;
                case "partner":
                    return CommonDataKinds.Relation.TYPE_PARTNER;
                case "referred by":
                    return CommonDataKinds.Relation.TYPE_REFERRED_BY;
                case "sister":
                    return CommonDataKinds.Relation.TYPE_SISTER;
                case "spouse":
                    return CommonDataKinds.Relation.TYPE_SPOUSE;
                default:
                    return CommonDataKinds.Event.TYPE_CUSTOM;
            }
        }
        return CommonDataKinds.Email.TYPE_OTHER;
    }

    public static int stringToInstantMessageAddressProtocol(String label) {
        if (label != null) {
            switch (label.toLowerCase()) {
                case "aim":
                    return CommonDataKinds.Im.PROTOCOL_AIM;
                case "windows live":
                    return CommonDataKinds.Im.PROTOCOL_MSN;
                case "yahoo":
                    return CommonDataKinds.Im.PROTOCOL_YAHOO;
                case "skype":
                    return CommonDataKinds.Im.PROTOCOL_SKYPE;
                case "qq":
                    return CommonDataKinds.Im.PROTOCOL_QQ;
                case "hangouts":
                    return CommonDataKinds.Im.PROTOCOL_GOOGLE_TALK;
                case "icq":
                    return CommonDataKinds.Im.PROTOCOL_ICQ;
                case "jabber":
                    return CommonDataKinds.Im.PROTOCOL_JABBER;
                case "net meeting":
                    return CommonDataKinds.Im.PROTOCOL_NETMEETING;
                default:
                    return CommonDataKinds.Im.PROTOCOL_CUSTOM;
            }
        }
        return CommonDataKinds.Im.PROTOCOL_CUSTOM;
    }

    public static int stringToWebsiteType(String label) {
        if (label != null) {
            switch (label.toLowerCase()) {
                case "home page":
                    return CommonDataKinds.Website.TYPE_HOMEPAGE;
                case "blog":
                    return CommonDataKinds.Website.TYPE_BLOG;
                case "profile":
                    return CommonDataKinds.Website.TYPE_PROFILE;
                case "home":
                    return CommonDataKinds.Website.TYPE_HOME;
                case "work":
                    return CommonDataKinds.Website.TYPE_WORK;
                case "ftp":
                    return CommonDataKinds.Website.TYPE_FTP;
                case "other":
                    return CommonDataKinds.Website.TYPE_OTHER;
                default:
                    return CommonDataKinds.Website.TYPE_CUSTOM;
            }
        }
        return CommonDataKinds.Website.TYPE_OTHER;
    }

}