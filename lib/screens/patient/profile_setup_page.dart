import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'patient_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() =>
      _ProfileSetupPageState();
}

class _ProfileSetupPageState
    extends State<ProfileSetupPage> {

  final nameController =
      TextEditingController();
       @override
  void initState() {
    super.initState();
    loadProfile();
  }

Future<void> loadProfile() async {
  final prefs = await SharedPreferences.getInstance();

  String userId = prefs.getString("userPhone") ?? "";

  if (userId.isEmpty) return;

  final response = await ApiService.getProfile(userId);

  if (response["success"] == true) {
    final profile = response["profile"];

    setState(() {
      nameController.text = profile["name"] ?? "";
      ageController.text = profile["age"] ?? "";
      gender = profile["gender"] ?? "Female";
      bloodGroup = profile["bloodGroup"] ?? "B+";
      heightController.text = profile["height"] ?? "";
      weightController.text = profile["weight"] ?? "";
    });
  } else {
    // New user
    nameController.text =
        prefs.getString("patientName") ?? "";
  }
}

  final ageController =
      TextEditingController();

  final heightController =
      TextEditingController();

  final weightController =
      TextEditingController();

  String gender = "Female";
  String bloodGroup = "B+";

  bool isLoading = false;

  Future<void> saveProfile() async {

    setState(() {
      isLoading = true;
    });

   try {
  final prefs = await SharedPreferences.getInstance();

  String userId = prefs.getString("userPhone") ?? "";

  print("USER ID = $userId");
print("NAME = ${nameController.text}");
print("AGE = ${ageController.text}");
print("GENDER = $gender");
print("BLOOD GROUP = $bloodGroup");
print("HEIGHT = ${heightController.text}");
print("WEIGHT = ${weightController.text}");

  final result = await ApiService.saveProfile(
    userId: userId,
    name: nameController.text,
    age: ageController.text,
    gender: gender,
    bloodGroup: bloodGroup,
    height: heightController.text,
    weight: weightController.text,
  );
print("SAVE PROFILE RESULT = $result");
if (result["success"] == true) {

  final phone =
      prefs.getString("userPhone") ?? "";

  final name =
      nameController.text.trim();

  // ==========================================
  // KEEP LOGIN SESSION
  // ==========================================

  await prefs.setBool(
    "isLoggedIn",
    true,
  );

  await prefs.setString(
    "userRole",
    "patient",
  );

  await prefs.setString(
    "userPhone",
    phone,
  );

  await prefs.setString(
    "userName",
    name,
  );

  // ==========================================
  // PATIENT DATA
  // ==========================================

  await prefs.setString(
    "patientPhone",
    phone,
  );

  await prefs.setString(
    "patientName",
    name,
  );

  await prefs.setBool(
    "profileCompleted_$phone",
    true,
  );

  debugPrint("================================");
  debugPrint("PATIENT PROFILE SAVED");
  debugPrint("PATIENT NAME  = $name");
  debugPrint("PATIENT PHONE = $phone");
  debugPrint("LOGIN SESSION = TRUE");
  debugPrint("================================");

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const PatientMain(),
    ),
    (route) => false,
  );
}
} catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString()),
    ),
  );
}

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xffF3FAFA),

      appBar: AppBar(

        backgroundColor:
        const Color(0xff14B8A6),

        title: const Text(

          "Profile Setup",

          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(20),

        child: Column(

          children: [

            const SizedBox(height: 20),

            const CircleAvatar(

              radius: 55,

              backgroundColor:
              Color(0xffE6FFFB),

              child: Icon(

                Icons.person,

                size: 60,

                color:
                Color(0xff14B8A6),
              ),
            ),

            const SizedBox(height: 25),

           TextField(
  controller: nameController,
  readOnly: true,
  decoration: inputDecoration(
    "Full Name",
  ),
),

            const SizedBox(height: 15),

            buildField(
              ageController,
              "Age",
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField(

              initialValue: gender,

              decoration:
              inputDecoration("Gender"),

              items: const [

                DropdownMenuItem(
                  value: "Male",
                  child: Text("Male"),
                ),

                DropdownMenuItem(
                  value: "Female",
                  child: Text("Female"),
                ),

                DropdownMenuItem(
                  value: "Other",
                  child: Text("Other"),
                ),
              ],

              onChanged: (value) {

                setState(() {

                  gender =
                  value.toString();
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField(

              initialValue: bloodGroup,

              decoration:
              inputDecoration(
                "Blood Group",
              ),

              items: const [

                DropdownMenuItem(
                  value: "A+",
                  child: Text("A+"),
                ),

                DropdownMenuItem(
                  value: "A-",
                  child: Text("A-"),
                ),

                DropdownMenuItem(
                  value: "B+",
                  child: Text("B+"),
                ),

                DropdownMenuItem(
                  value: "B-",
                  child: Text("B-"),
                ),

                DropdownMenuItem(
                  value: "O+",
                  child: Text("O+"),
                ),

                DropdownMenuItem(
                  value: "O-",
                  child: Text("O-"),
                ),

                DropdownMenuItem(
                  value: "AB+",
                  child: Text("AB+"),
                ),

                DropdownMenuItem(
                  value: "AB-",
                  child: Text("AB-"),
                ),
              ],

              onChanged: (value) {

                setState(() {

                  bloodGroup =
                  value.toString();
                });
              },
            ),

            const SizedBox(height: 15),

            buildField(
              heightController,
              "Height (cm)",
            ),

            const SizedBox(height: 15),

            buildField(
              weightController,
              "Weight (kg)",
            ),

            const SizedBox(height: 30),

            SizedBox(

              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                style:
                ElevatedButton.styleFrom(

                  backgroundColor:
                  const Color(
                    0xff14B8A6,
                  ),
                ),

                onPressed:
                isLoading
                    ? null
                    : saveProfile,

                child: isLoading

                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )

                    : const Text(

                        "Save Profile",

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(

    TextEditingController controller,
    String hint,

  ) {

    return TextField(

      controller: controller,

      decoration:
      inputDecoration(hint),
    );
  }

  InputDecoration inputDecoration(
      String hint) {

    return InputDecoration(

      hintText: hint,

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(

        borderRadius:
        BorderRadius.circular(16),

        borderSide: BorderSide.none,
      ),
    );
  }
}