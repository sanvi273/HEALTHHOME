import 'package:flutter/material.dart';

class LabBookingDetailsPage
    extends StatelessWidget {

  const LabBookingDetailsPage(
      {super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "Lab Booking Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            Container(
              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                        20),
              ),

              child: Column(
                children: [

                  Row(
                    children: [

                      const CircleAvatar(
                        radius: 35,
                        backgroundColor:
                            Color(
                                0xffEAFBFA),

                        child: Icon(
                          Icons.science,
                          size: 35,
                          color:
                              Color(
                                  0xff00C2CB),
                        ),
                      ),

                      const SizedBox(
                          width: 15),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [

                            Text(
                              "Lipid Profile",
                              style:
                                  TextStyle(
                                fontSize:
                                    22,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            SizedBox(
                                height:
                                    5),

                            Text(
                              "Booked",
                              style:
                                  TextStyle(
                                color:
                                    Colors
                                        .green,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Text(
                        "₹599",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 20),

                  const Divider(),

                  const ListTile(
                    leading:
                        Icon(Icons.date_range),
                    title: Text(
                        "Booking Date"),
                    subtitle:
                        Text("22 Jun 2024"),
                  ),

                  const ListTile(
                    leading:
                        Icon(Icons.access_time),
                    title: Text(
                        "Time Slot"),
                    subtitle: Text(
                        "08:00 AM - 10:00 AM"),
                  ),

                  const ListTile(
                    leading:
                        Icon(Icons.home),
                    title: Text(
                        "Collection Type"),
                    subtitle: Text(
                        "Home Sample Collection"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                        20),
              ),

              child: const Column(
                children: [

                  ListTile(
                    leading:
                        Icon(Icons.person),
                    title: Text(
                        "Rahul Singh"),
                    subtitle:
                        Text("Lab Executive"),
                  ),

                  Divider(),

                  ListTile(
                    leading:
                        Icon(Icons.call),
                    title: Text(
                        "Call Executive"),
                  ),

                  ListTile(
                    leading:
                        Icon(Icons.message),
                    title: Text(
                        "Message Executive"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                        20),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.support_agent,
                    color:
                        Color(0xff00C2CB),
                    size: 40,
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Text(
                      "Need Help?",
                    ),
                  ),

                  ElevatedButton(
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                              0xff00C2CB),
                    ),

                    onPressed: () {},

                    child: const Text(
                      "Contact",
                      style: TextStyle(
                        color:
                            Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}