import 'package:flutter/material.dart';

class PrescriptionPage extends StatelessWidget {
  const PrescriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Prescription",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.cloud_upload_outlined,
              color: Color(0xff00C2CB),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // Doctor Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Row(
                children: [

                  const CircleAvatar(
                    radius: 35,
                    child: Icon(
                      Icons.person,
                      size: 35,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: const [

                        Text(
                          "Dr. Amit Patel",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          "Cardiologist",
                        ),

                        SizedBox(height: 4),

                        Text(
                          "12 Years Experience",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tabs
            Row(
              children: [

                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xffEAFBFA),
                      borderRadius:
                          BorderRadius.circular(
                              12),
                    ),
                    child: const Center(
                      child: Text(
                        "Medicines (4)",
                        style: TextStyle(
                          color:
                              Color(0xff00C2CB),
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                              12),
                    ),
                    child: const Center(
                      child: Text(
                        "Lab Tests (3)",
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Medicines
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Prescribed Medicines",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  medicineTile(
                    "Tab. Ecosprin 75",
                    "10 Days",
                  ),

                  medicineTile(
                    "Tab. Atorvast 10",
                    "30 Days",
                  ),

                  medicineTile(
                    "Cap. Pantodac 40",
                    "15 Days",
                  ),

                  medicineTile(
                    "Tab. Chelwin D3",
                    "28 Days",
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                                0xff00C2CB),
                      ),

                      onPressed: () {},

                      child: const Text(
                        "Add Selected To Cart",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Lab Tests
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Prescribed Lab Tests",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  labTile(
                    "Lipid Profile",
                    "₹599",
                  ),

                  labTile(
                    "HbA1c",
                    "₹350",
                  ),

                  labTile(
                    "Vitamin D",
                    "₹700",
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.purple,
                      ),

                      onPressed: () {},

                      child: const Text(
                        "Book Selected Tests",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.medical_services,
                    size: 45,
                    color: Color(0xff00C2CB),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      "Browse medicines and lab tests directly",
                    ),
                  ),

                  OutlinedButton(
                    onPressed: () {},

                    child: const Text(
                      "Browse Store",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget medicineTile(
      String name,
      String days,
      ) {
    return ListTile(
      leading: const Icon(
        Icons.medication,
        color: Color(0xff00C2CB),
      ),
      title: Text(name),
      subtitle: Text(days),
      trailing: Checkbox(
        value: true,
        onChanged: (_) {},
      ),
    );
  }

  Widget labTile(
      String name,
      String price,
      ) {
    return ListTile(
      leading: const Icon(
        Icons.science,
        color: Colors.purple,
      ),
      title: Text(name),
      trailing: Text(
        price,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}