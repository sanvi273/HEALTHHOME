import json
import os

INPUT = "localization_output/en.json"
OUTPUT_DIR = "localization_output"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# HINDI TRANSLATIONS
# ============================================================

HI = {
    "inProgress": "प्रगति में",
    "collectorIsOnTheWay": "कलेक्टर रास्ते में है",
    "errorE": "त्रुटि: $e",
    "collectorName": "कलेक्टर का नाम",
    "testNameIsRequired": "टेस्ट का नाम आवश्यक है",
    "enterAValidPrice": "मान्य कीमत दर्ज करें",
    "labIdNotFound": "लैब आईडी नहीं मिली",
    "testName": "टेस्ट का नाम *",
    "price": "कीमत *",
    "sampleType": "सैंपल का प्रकार",
    "reportTime": "रिपोर्ट का समय",
    "deleteLabTest": "लैब टेस्ट हटाएँ",
    "labTestDeletedSuccessfully": "लैब टेस्ट सफलतापूर्वक हटा दिया गया",
    "labProfileSaved": "लैब प्रोफ़ाइल सहेजी गई",
    "addressType": "पते का प्रकार",
    "addDeliveryPartner": "डिलीवरी पार्टनर जोड़ें",
    "partnerName": "पार्टनर का नाम",
    "phoneNumber": "फ़ोन नंबर",
    "deliveryPartnerRemoved": "डिलीवरी पार्टनर हटा दिया गया।",
    "thisDeliveryPartnerAlreadyExists": "यह डिलीवरी पार्टनर पहले से मौजूद है।",
    "deliveryPartnerAdded": "डिलीवरी पार्टनर जोड़ा गया।",
    "orderIdNotFound": "ऑर्डर आईडी नहीं मिली।",
    "selectDeliveryPartner": "डिलीवरी पार्टनर चुनें",
    "addPartner": "पार्टनर जोड़ें",
    "editPartner": "पार्टनर संपादित करें",
    "shopType": "दुकान का प्रकार",
    "appointmentDetails": "अपॉइंटमेंट विवरण",
    "paymentCancelled": "भुगतान रद्द कर दिया गया",
    "searchTests": "टेस्ट खोजें...",
    "testDetailsNotAvailable": "टेस्ट का विवरण उपलब्ध नहीं है।",
    "homeCollection": "होम कलेक्शन",
    "visitLaboratory": "लैबोरेटरी पर जाएँ",
    "searchDoctor": "डॉक्टर खोजें",
    "searchDoctors": "डॉक्टर खोजें...",
    "labTests": "लैब टेस्ट",
    "doctorProfile": "डॉक्टर प्रोफ़ाइल",
    "22Jun2024": "22 जून 2024",
    "labExecutive": "लैब एग्जीक्यूटिव",
    "unableToLoadLaboratoriesE": "लैबोरेटरी लोड नहीं हो सकीं: $e",
    "selectedLabTests": "चयनित लैब टेस्ट",
    "selectLaboratory": "लैबोरेटरी चुनें",
    "collectionMethod": "कलेक्शन का तरीका",
    "collectionAddress": "कलेक्शन का पता",
    "additionalNotes": "अतिरिक्त नोट्स",
    "optionalNotes": "वैकल्पिक नोट्स",
    "unableToLoadLabOrdersE": "लैब ऑर्डर लोड नहीं हो सके: $e",
    "labOrderIdNotFound": "लैब ऑर्डर आईडी नहीं मिली।",
    "unableToLoadLabOrderE": "लैब ऑर्डर लोड नहीं हो सका: $e",
    "unableToLoadMedicinesE": "दवाइयाँ लोड नहीं हो सकीं: $e",
    "viewCart": "कार्ट देखें",
    "unableToLoadOrderE": "ऑर्डर लोड नहीं हो सका: $e",
    "medicineDelivery": "दवा की डिलीवरी",
    "orderMedicines": "दवाइयाँ ऑर्डर करें",
    "uploadPrescription": "प्रिस्क्रिप्शन अपलोड करें",
    "uploadRx": "Rx अपलोड करें",
    "a": "A+",
    "b": "B+",
    "o": "O+",
    "ab": "AB+",
    "unableToOpenPdfE": "PDF नहीं खुल सकी: $e"
}


# ============================================================
# GUJARATI TRANSLATIONS
# ============================================================

GU = {
    "inProgress": "પ્રગતિમાં",
    "collectorIsOnTheWay": "કલેક્શન કરનાર રસ્તામાં છે",
    "errorE": "ભૂલ: $e",
    "collectorName": "કલેક્શન કરનારનું નામ",
    "testNameIsRequired": "ટેસ્ટનું નામ જરૂરી છે",
    "enterAValidPrice": "માન્ય કિંમત દાખલ કરો",
    "labIdNotFound": "લેબ ID મળી નથી",
    "testName": "ટેસ્ટનું નામ *",
    "price": "કિંમત *",
    "sampleType": "સેમ્પલનો પ્રકાર",
    "reportTime": "રિપોર્ટનો સમય",
    "deleteLabTest": "લેબ ટેસ્ટ કાઢી નાખો",
    "labTestDeletedSuccessfully": "લેબ ટેસ્ટ સફળતાપૂર્વક કાઢી નાખવામાં આવ્યો",
    "labProfileSaved": "લેબ પ્રોફાઇલ સેવ થઈ",
    "addressType": "સરનામાનો પ્રકાર",
    "addDeliveryPartner": "ડિલિવરી પાર્ટનર ઉમેરો",
    "partnerName": "પાર્ટનરનું નામ",
    "phoneNumber": "ફોન નંબર",
    "deliveryPartnerRemoved": "ડિલિવરી પાર્ટનર દૂર કરવામાં આવ્યો.",
    "thisDeliveryPartnerAlreadyExists": "આ ડિલિવરી પાર્ટનર પહેલેથી જ અસ્તિત્વમાં છે.",
    "deliveryPartnerAdded": "ડિલિવરી પાર્ટનર ઉમેરવામાં આવ્યો.",
    "orderIdNotFound": "ઓર્ડર ID મળી નથી.",
    "selectDeliveryPartner": "ડિલિવરી પાર્ટનર પસંદ કરો",
    "addPartner": "પાર્ટનર ઉમેરો",
    "editPartner": "પાર્ટનર સંપાદિત કરો",
    "shopType": "દુકાનનો પ્રકાર",
    "appointmentDetails": "એપોઇન્ટમેન્ટની વિગતો",
    "paymentCancelled": "ચુકવણી રદ કરવામાં આવી",
    "searchTests": "ટેસ્ટ શોધો...",
    "testDetailsNotAvailable": "ટેસ્ટની વિગતો ઉપલબ્ધ નથી.",
    "homeCollection": "હોમ કલેક્શન",
    "visitLaboratory": "લેબોરેટરીની મુલાકાત લો",
    "searchDoctor": "ડૉક્ટર શોધો",
    "searchDoctors": "ડૉક્ટર શોધો...",
    "labTests": "લેબ ટેસ્ટ",
    "doctorProfile": "ડૉક્ટર પ્રોફાઇલ",
    "22Jun2024": "22 જૂન 2024",
    "labExecutive": "લેબ એક્ઝિક્યુટિવ",
    "unableToLoadLaboratoriesE": "લેબોરેટરી લોડ કરી શકાઈ નથી: $e",
    "selectedLabTests": "પસંદ કરેલા લેબ ટેસ્ટ",
    "selectLaboratory": "લેબોરેટરી પસંદ કરો",
    "collectionMethod": "કલેક્શનની રીત",
    "collectionAddress": "કલેક્શનનું સરનામું",
    "additionalNotes": "વધારાની નોંધ",
    "optionalNotes": "વૈકલ્પિક નોંધ",
    "unableToLoadLabOrdersE": "લેબ ઓર્ડર લોડ કરી શકાયા નથી: $e",
    "labOrderIdNotFound": "લેબ ઓર્ડર ID મળી નથી.",
    "unableToLoadLabOrderE": "લેબ ઓર્ડર લોડ કરી શકાયો નથી: $e",
    "unableToLoadMedicinesE": "દવાઓ લોડ કરી શકાઈ નથી: $e",
    "viewCart": "કાર્ટ જુઓ",
    "unableToLoadOrderE": "ઓર્ડર લોડ કરી શકાયો નથી: $e",
    "medicineDelivery": "દવાની ડિલિવરી",
    "orderMedicines": "દવાઓ ઓર્ડર કરો",
    "uploadPrescription": "પ્રિસ્ક્રિપ્શન અપલોડ કરો",
    "uploadRx": "Rx અપલોડ કરો",
    "a": "A+",
    "b": "B+",
    "o": "O+",
    "ab": "AB+",
    "unableToOpenPdfE": "PDF ખોલી શકાતી નથી: $e"
}


# ============================================================
# LOAD ENGLISH
# ============================================================

with open(INPUT, "r", encoding="utf-8") as f:
    EN = json.load(f)


# ============================================================
# CHECK ALL KEYS EXIST
# ============================================================

for key in EN:

    if key not in HI:
        HI[key] = EN[key]

    if key not in GU:
        GU[key] = EN[key]


# ============================================================
# SAVE FILES
# ============================================================

files = {
    "en.json": EN,
    "hi.json": HI,
    "gu.json": GU,
}

for filename, data in files.items():

    path = os.path.join(
        OUTPUT_DIR,
        filename
    )

    with open(
        path,
        "w",
        encoding="utf-8"
    ) as f:

        json.dump(
            data,
            f,
            ensure_ascii=False,
            indent=2
        )

    print(f"Created: {path}")


print()
print("=" * 60)
print(" LOCALIZATION FILES GENERATED SUCCESSFULLY")
print("=" * 60)
print()
print(f"English strings : {len(EN)}")
print(f"Hindi strings   : {len(HI)}")
print(f"Gujarati strings: {len(GU)}")
print()