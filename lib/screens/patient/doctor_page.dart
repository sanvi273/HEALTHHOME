import 'package:flutter/material.dart';
import 'patient_dashboard.dart';
import 'pharmacy_page.dart';

import 'profile_page.dart';
import 'lab_home_page.dart';

class DoctorPage extends StatelessWidget {
  const DoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Doctors",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Book appointment with trusted doctors",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search doctors...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "Browse by Specialty",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
  SpecialityCard("👨‍⚕️", "General Physician"),
  SpecialityCard("❤️", "Cardiology"),
  SpecialityCard("🧴", "Dermatology"),
  SpecialityCard("🧠", "Neurology"),
  SpecialityCard("🧠", "Neurosurgery"),
  SpecialityCard("🦴", "Orthopedics"),
  SpecialityCard("👶", "Pediatrics"),
  SpecialityCard("👩", "Gynecology"),
  SpecialityCard("🤰", "Obstetrics"),
  SpecialityCard("👂", "ENT"),
  SpecialityCard("👁️", "Ophthalmology"),
  SpecialityCard("🦷", "Dentistry"),
  SpecialityCard("🧠", "Psychiatry"),
  SpecialityCard("💭", "Psychology"),
  SpecialityCard("🫃", "Gastroenterology"),
  SpecialityCard("🫘", "Nephrology"),
  SpecialityCard("🚹", "Urology"),
  SpecialityCard("🫁", "Pulmonology"),
  SpecialityCard("🧬", "Endocrinology"),
  SpecialityCard("🎗️", "Oncology"),
  SpecialityCard("🩸", "Hematology"),
  SpecialityCard("🦠", "Infectious Disease"),
  SpecialityCard("🦋", "Rheumatology"),
  SpecialityCard("🚑", "Emergency Medicine"),
  SpecialityCard("👴", "Geriatrics"),
  SpecialityCard("🏃", "Sports Medicine"),
  SpecialityCard("🏥", "General Surgery"),
  SpecialityCard("🔪", "Plastic Surgery"),
  SpecialityCard("🫀", "Cardiothoracic Surgery"),
  SpecialityCard("🩺", "Vascular Surgery"),
  SpecialityCard("🥗", "Nutritionist"),
  SpecialityCard("🏃", "Physiotherapy"),
],
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "Top Doctors",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              doctorCard(
                "Dr. Neha Sharma",
                "General Physician",
                "8 Years",
                "₹500",
              ),
              doctorCard(
                "Dr. Amit Verma",
                "Cardiologist",
                "6 Years",
                "₹400",
              ),
              doctorCard(
                "Dr. Pooja Singh",
                "Dermatologist",
                "5 Years",
                "₹350",
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xff00C2CB),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PatientDashboard(),
              ),
            );
          }

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PharmacyPage(),
              ),
            );
          }

          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const LabHomePage(),
              ),
            );
          }
          if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfilePage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: "Doctors",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_pharmacy),
            label: "Pharmacy",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: "Lab Tests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget doctorCard(
    String name,
    String specialty,
    String experience,
    String fee,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(specialty),
                const SizedBox(height: 4),
                Text(
                  experience,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text("4.8"),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                fee,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00C2CB),
                ),
                onPressed: () {},
                child: const Text(
                  "Book Now",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SpecialityCard extends StatelessWidget {
  final String emoji;
  final String title;

  const SpecialityCard(
    this.emoji,
    this.title, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
