import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../role_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState
    extends State<OnboardingScreen> {

  final PageController _controller =
      PageController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [

            // Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 16,
              ),

              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.end,

                children: [

                  GestureDetector(
                    onTap: () {

                      Navigator.pushReplacement(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                          const RoleSelectionScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      "Skip",

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _controller,

                children: [

                  // Page 1
                  buildPage(
                    image:
                    "assets/images/doctor.png",

                    title:
                    "Complete\nHealthcare\nat Your Doorstep",

                    subtitle:
                    "Consult doctors, order medicines,\nbook lab tests & more.",
                  ),

                  // Page 2
                  buildPage(
                    image:
                    "assets/images/consult.png",

                    title:
                    "Online Doctor\nConsultation",

                    subtitle:
                    "Connect with experienced doctors\nanytime anywhere.",
                  ),

                  // Page 3
                  buildPage(
                    image:
                    "assets/images/medicine.png",

                    title:
                    "Medicine &\nLab Services",

                    subtitle:
                    "Fast medicine delivery and\naccurate lab tests.",
                  ),
                ],
              ),
            ),

            // Indicator
            SmoothPageIndicator(
              controller: _controller,
              count: 3,

              effect: const ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
                activeDotColor:
                Color(0xff00C2CB),

                dotColor: Color(0xffD1D5DB),
              ),
            ),

            const SizedBox(height: 35),

            // Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),

              child: SizedBox(
                width: double.infinity,
                height: 60,

                child: ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xff00C2CB),

                    elevation: 0,

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                  ),

                  onPressed: () {

                    Navigator.pushReplacement(
                      context,

                      MaterialPageRoute(
                        builder: (_) =>
                        const RoleSelectionScreen(),
                      ),
                    );
                  },

                  child: const Text(
                    "Get Started",

                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget buildPage({
    required String image,
    required String title,
    required String subtitle,
  }) {

    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 24),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          const SizedBox(height: 10),

          // Title
          Text(
            title,

            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
              height: 1.2,
            ),
          ),

          const SizedBox(height: 18),

          // Subtitle
          Text(
            subtitle,

            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 35),

          // Image Container
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,

                padding:
                const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xffE8FAFB),
                      Color(0xffF4FFFF),
                    ],

                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius:
                  BorderRadius.circular(35),
                ),

                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}