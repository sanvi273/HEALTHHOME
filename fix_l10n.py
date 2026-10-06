import json
from pathlib import Path

base = Path("lib/l10n")

translations = {
    "en": {
        "welcome": "Welcome!",
        "chooseYourRole": "Choose your role",
        "patient": "Patient",
        "doctorsAndMedicines": "Doctors & medicines",
        "doctor": "Doctor",
        "managePatients": "Manage patients",
        "laboratory": "Laboratory",
        "uploadReports": "Upload reports",
        "pharmacy": "Pharmacy",
        "medicineOrders": "Medicine orders",

        "doctorConsultation": "Doctor Consultation",
        "medicineDelivery": "Medicine Delivery",
        "homeLabTests": "Home Lab Tests",
        "fastDeliveryTitle": "Fast & Reliable Healthcare",
        "fastDeliverySubtitle": "Get medicines, lab tests and doctor consultations easily.",
        "quickAccess": "Quick Access",
        "myAppointments": "My Appointments",
        "myPrescriptions": "My Prescriptions",
        "labReports": "Lab Reports",
        "myMedicineOrders": "My Medicine Orders",
        "myLabOrders": "My Lab Orders",
        "goodMorning": "Good Morning",
        "goodAfternoon": "Good Afternoon",
        "goodEvening": "Good Evening"
    },

    "hi": {
        "welcome": "स्वागत है!",
        "chooseYourRole": "अपनी भूमिका चुनें",
        "patient": "मरीज़",
        "doctorsAndMedicines": "डॉक्टर और दवाइयाँ",
        "doctor": "डॉक्टर",
        "managePatients": "मरीज़ों का प्रबंधन करें",
        "laboratory": "प्रयोगशाला",
        "uploadReports": "रिपोर्ट अपलोड करें",
        "pharmacy": "फार्मेसी",
        "medicineOrders": "दवा के ऑर्डर",

        "doctorConsultation": "डॉक्टर से परामर्श",
        "medicineDelivery": "दवा की डिलीवरी",
        "homeLabTests": "घर पर लैब टेस्ट",
        "fastDeliveryTitle": "तेज़ और विश्वसनीय स्वास्थ्य सेवा",
        "fastDeliverySubtitle": "दवाइयाँ, लैब टेस्ट और डॉक्टर से परामर्श आसानी से प्राप्त करें।",
        "quickAccess": "त्वरित पहुँच",
        "myAppointments": "मेरी अपॉइंटमेंट्स",
        "myPrescriptions": "मेरे प्रिस्क्रिप्शन",
        "labReports": "लैब रिपोर्ट्स",
        "myMedicineOrders": "मेरे दवा के ऑर्डर",
        "myLabOrders": "मेरे लैब ऑर्डर",
        "goodMorning": "सुप्रभात",
        "goodAfternoon": "शुभ दोपहर",
        "goodEvening": "शुभ संध्या"
    },

    "gu": {
        "welcome": "સ્વાગત છે!",
        "chooseYourRole": "તમારી ભૂમિકા પસંદ કરો",
        "patient": "દર્દી",
        "doctorsAndMedicines": "ડૉક્ટર અને દવાઓ",
        "doctor": "ડૉક્ટર",
        "managePatients": "દર્દીઓનું સંચાલન કરો",
        "laboratory": "પ્રયોગશાળા",
        "uploadReports": "રિપોર્ટ અપલોડ કરો",
        "pharmacy": "ફાર્મસી",
        "medicineOrders": "દવાઓના ઓર્ડર",

        "doctorConsultation": "ડૉક્ટરની સલાહ",
        "medicineDelivery": "દવાની ડિલિવરી",
        "homeLabTests": "ઘરે લેબ ટેસ્ટ",
        "fastDeliveryTitle": "ઝડપી અને વિશ્વસનીય આરોગ્ય સેવા",
        "fastDeliverySubtitle": "દવાઓ, લેબ ટેસ્ટ અને ડૉક્ટરની સલાહ સરળતાથી મેળવો.",
        "quickAccess": "ઝડપી ઍક્સેસ",
        "myAppointments": "મારી એપોઇન્ટમેન્ટ્સ",
        "myPrescriptions": "મારા પ્રિસ્ક્રિપ્શન",
        "labReports": "લેબ રિપોર્ટ્સ",
        "myMedicineOrders": "મારા દવાના ઓર્ડર",
        "myLabOrders": "મારા લેબ ઓર્ડર",
        "goodMorning": "સુપ્રભાત",
        "goodAfternoon": "શુભ બપોર",
        "goodEvening": "શુભ સાંજ"
    }
}

for lang, values in translations.items():
    file = base / f"{lang}.json"

    with open(file, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Keep all existing translations and add/update these keys
    data.update(values)

    with open(file, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Updated {file}: {len(data)} keys")

print("Localization fixed successfully!")