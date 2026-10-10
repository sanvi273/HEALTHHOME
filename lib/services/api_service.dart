import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl =
      "https://healthhome-backend.onrender.com";

  // ============================================================
  // AUTH
  // ============================================================

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,

    required String label,
    required String fullAddress,
    String landmark = "",
    required String city,
    required String state,
    required String pincode,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/register"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "phone": phone,
          "role": role,
          "label": label,
          "fullAddress": fullAddress,
          "landmark": landmark,
          "city": city,
          "state": state,
          "pincode": pincode,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      debugPrint("================================");
      debugPrint("REGISTER USER");
      debugPrint("STATUS = ${response.statusCode}");
      debugPrint("BODY = ${response.body}");
      debugPrint("================================");

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      debugPrint("REGISTER USER ERROR = $e");

      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phone": phone,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  static Future<Map<String, dynamic>> sendOTP({
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/send-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "phone": phone,
        }),
      );

      debugPrint("================================");
      debugPrint("SEND OTP");
      debugPrint("STATUS = ${response.statusCode}");
      debugPrint("BODY = ${response.body}");
      debugPrint("================================");

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      debugPrint("SEND OTP ERROR = $e");

      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  static Future<Map<String, dynamic>> verifyOTP({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/verify-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "phone": phone,
          "otp": otp,
        }),
      );

      debugPrint("================================");
      debugPrint("VERIFY OTP");
      debugPrint("STATUS = ${response.statusCode}");
      debugPrint("BODY = ${response.body}");
      debugPrint("================================");

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      debugPrint("VERIFY OTP ERROR = $e");

      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  // ============================================================
  // PROFESSIONAL VERIFICATION
  // ============================================================

  static Future<Map<String, dynamic>> submitVerification({
    required String token,
    required String role,
    required String licenseNumber,
    required String licenseType,
    required String documentUrl,
    String businessName = "",
    String registrationNumber = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/verification/submit"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "role": role,
          "licenseNumber": licenseNumber,
          "licenseType": licenseType,
          "documentUrl": documentUrl,
          "businessName": businessName,
          "registrationNumber": registrationNumber,
        }),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getMyVerification({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/verification/my"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getVerificationStatus({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/verification/my"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  // ============================================================
  // DOCTORS
  // ============================================================

  static Future<List<dynamic>> getDoctors() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/doctors/all"),
    );

    final data = jsonDecode(response.body);

    return data["doctors"] ?? [];
  }

  static Future<Map<String, dynamic>> getDoctorProfile(
    String phone,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/doctors/profile/${Uri.encodeComponent(phone)}",
      ),
    );

    return jsonDecode(response.body);
  }

  
static Future<Map<String, dynamic>> updateDoctorAvailability({
  required String doctorId,
  required bool isAvailable,
}) async {
  final response = await http.put(
    Uri.parse('$baseUrl/api/doctors/availability/$doctorId'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'isAvailable': isAvailable}),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return Map<String, dynamic>.from(data);
  }

  throw Exception(
    data['message'] ?? 'Failed to update doctor availability',
  );
}

static Future<Map<String, dynamic>> updateDoctorSchedule({
  required String doctorId,
  required List<String> workingDays,
  required String startTime,
  required String endTime,
  required String breakStart,
  required String breakEnd,
  required int slotDurationMinutes,
  required int maxAppointmentsPerDay,
}) async {
  final response = await http.put(
    Uri.parse('$baseUrl/api/doctors/schedule/$doctorId'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'workingDays': workingDays,
      'startTime': startTime,
      'endTime': endTime,
      'breakStart': breakStart,
      'breakEnd': breakEnd,
      'slotDurationMinutes': slotDurationMinutes,
      'maxAppointmentsPerDay': maxAppointmentsPerDay,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return Map<String, dynamic>.from(data);
  }

  throw Exception(
    data['message'] ?? 'Failed to update doctor schedule',
  );
}


  static Future<Map<String, dynamic>> addDoctor({
    required String name,
    required String phone,
    required String specialization,
    required String experience,
    required String fees,
    required String hospital,
    required String about,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/doctors/add"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "phone": phone,
        "specialization": specialization,
        "experience": experience,
        "fees": fees,
        "hospital": hospital,
        "about": about,
      }),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // LABS
  // ============================================================

  static Future<List<dynamic>> getLabs() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/labs/all"),
    );

    final data = jsonDecode(response.body);

    return data["labs"] ?? [];
  }

  static Future<Map<String, dynamic>> getLabProfile(
    String phone,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/labs/profile/${Uri.encodeComponent(phone)}",
      ),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addLab({
    required String name,
    required String labType,
    required String experience,
    required String address,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/labs/add"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "labType": labType,
        "experience": experience,
        "address": address,
        "phone": phone,
      }),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // PHARMACIES
  // ============================================================

  static Future<List<dynamic>> getPharmacies() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/pharmacies/all"),
    );

    final data = jsonDecode(response.body);

    return data["pharmacies"] ?? [];
  }

  static Future<Map<String, dynamic>> getPharmacyProfile(
    String phone,
  ) async {
    final url = Uri.parse(
      "$baseUrl/api/pharmacies/profile/${Uri.encodeComponent(phone)}",
    );

    final response = await http.get(url);

    if (response.body.isEmpty) {
      throw Exception(
        "Empty response from pharmacy profile API",
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>> addPharmacy({
    required String name,
    required String shopType,
    required String experience,
    required String address,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/pharmacies/add"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "shopType": shopType,
        "experience": experience,
        "address": address,
        "phone": phone,
      }),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // MEDICINES
  // ============================================================

  static Future<dynamic> addMedicine({
    required String pharmacyPhone,
    required String medicineName,
    required String category,
    required String description,
    required String price,
    required String stock,
    required String image,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/medicines/add"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "pharmacyPhone": pharmacyPhone,
        "medicineName": medicineName,
        "category": category,
        "description": description,
        "price": int.parse(price),
        "stock": int.parse(stock),
        "image": image,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getMedicines() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/medicines/all"),
    );

    final data = jsonDecode(response.body);

    return data["medicines"] ?? [];
  }

  static Future<List<dynamic>> findMedicinesByName(
    String medicineName,
  ) async {
    try {
      final allMedicines = await getMedicines();

      final searchName = medicineName
          .trim()
          .toLowerCase();

      if (searchName.isEmpty) {
        return [];
      }

      final matchedMedicines = allMedicines.where((item) {
        if (item is! Map) {
          return false;
        }

        final inventoryName =
            item["medicineName"]
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                "";

        final stock =
            int.tryParse(
              item["stock"]?.toString() ?? "0",
            ) ??
            0;

        final status =
            item["status"]
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                "";

        return inventoryName == searchName &&
            stock > 0 &&
            (status.isEmpty || status == "available");
      }).toList();

      return matchedMedicines;
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getInventoryStats() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/medicines/stats"),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateMedicine({
    required String id,
    required String medicineName,
    required String category,
    required String manufacturer,
    required String description,
    required String price,
    required String stock,
    required String image,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/medicines/$id"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "medicineName": medicineName,
        "category": category,
        "manufacturer": manufacturer,
        "description": description,
        "price": int.parse(price),
        "stock": int.parse(stock),
        "image": image,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteMedicine(
    String id,
  ) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/api/medicines/$id"),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // APPOINTMENTS
  // ============================================================

  static Future<Map<String, dynamic>> bookAppointment({
    required String patientName,
    required String patientPhone,
    required String doctorId,
    required String doctorName,
    required String specialization,
    required String hospital,
    required String fees,
    required String consultationType,
    required String appointmentDate,
    required String appointmentTime,
    required List<File> reports,
    String paymentStatus = "Pending",
    String razorpayOrderId = "",
    String paymentId = "",
  }) async {
    try {
      final dio = Dio();

      final formData = FormData.fromMap({
        "patientName": patientName,
        "patientPhone": patientPhone,
        "doctorId": doctorId,
        "doctorName": doctorName,
        "specialization": specialization,
        "hospital": hospital,
        "fees": fees,
        "consultationType": consultationType,
        "appointmentDate": appointmentDate,
        "appointmentTime": appointmentTime,
        "paymentStatus": paymentStatus,
        "razorpayOrderId": razorpayOrderId,
        "paymentId": paymentId,
      });

      for (final file in reports) {
        formData.files.add(
          MapEntry(
            "reports",
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      final response = await dio.post(
        "$baseUrl/api/appointments/book",
        data: formData,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Map<String, dynamic>.from(
          response.data,
        );
      }

      throw Exception(
        "Failed to book appointment: ${response.data}",
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableSlots({
    required String doctorId,
    required String date,
  }) async {
    try {
      if (doctorId.isEmpty) {
        throw Exception("Doctor ID is required");
      }

      if (date.isEmpty) {
        throw Exception("Appointment date is required");
      }

      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/appointments/available-slots/"
          "${Uri.encodeComponent(doctorId)}/"
          "${Uri.encodeComponent(date)}",
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to load available slots: "
          "${response.statusCode}",
        );
      }

      final data = jsonDecode(response.body);

      if (data is Map && data["slots"] is List) {
        return List<Map<String, dynamic>>.from(
          (data["slots"] as List).map(
            (slot) => Map<String, dynamic>.from(slot),
          ),
        );
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>> getPatientAppointments(
    String patientPhone,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/appointments/patient/"
          "${Uri.encodeComponent(patientPhone)}",
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      if (data is Map &&
          data["appointments"] is List) {
        return List<dynamic>.from(
          data["appointments"],
        );
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getDoctorAppointments(
    String doctorId,
  ) async {
    try {
      if (doctorId.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/appointments/doctor/"
          "${Uri.encodeComponent(doctorId)}",
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      if (data is Map &&
          data["appointments"] is List) {
        return List<dynamic>.from(
          data["appointments"],
        );
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAppointmentById(
    String id,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/appointments/$id"),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(
          data["appointment"] ?? {},
        );
      }

      throw Exception(
        data["message"] ?? "Failed to get appointment",
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required String id,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/appointments/status/$id",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "status": status,
      }),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>>
      updateAppointmentPaymentStatus({
    required String id,
    required String paymentStatus,
  }) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/appointments/payment/$id",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "paymentStatus": paymentStatus,
      }),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  // ============================================================
  // APPOINTMENT RESCHEDULING
  // ============================================================

  /// Doctor proposes a new date/time for an existing appointment.
  static Future<Map<String, dynamic>> proposeAppointmentReschedule({
    required String appointmentId,
    required String proposedAppointmentDate,
    required String proposedAppointmentTime,
    required String rescheduleReason,
  }) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/appointments/"
        "${Uri.encodeComponent(appointmentId)}/propose-reschedule",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "proposedAppointmentDate": proposedAppointmentDate,
        "proposedAppointmentTime": proposedAppointmentTime,
        "rescheduleReason": rescheduleReason,
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(
      decoded is Map
          ? (decoded["message"] ?? "Failed to propose rescheduling")
          : "Failed to propose rescheduling (${response.statusCode})",
    );
  }

  /// Patient responds to a doctor's reschedule proposal.
  /// Supported values depend on the backend schema: "Accepted"
  /// or "Requested Another Time".
  static Future<Map<String, dynamic>> respondToAppointmentReschedule({
    required String appointmentId,
    required String response,
  }) async {
    final result = await http.put(
      Uri.parse(
        "$baseUrl/api/appointments/"
        "${Uri.encodeComponent(appointmentId)}/respond-reschedule",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"response": response}),
    );

    final decoded = jsonDecode(result.body);
    if (result.statusCode >= 200 && result.statusCode < 300) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(
      decoded is Map
          ? (decoded["message"] ?? "Failed to respond to reschedule")
          : "Failed to respond to reschedule (${result.statusCode})",
    );
  }

  // ============================================================
  // AGORA VIDEO CONSULTATION
  // ============================================================

  static Future<Map<String, dynamic>> startConsultation(
    String appointmentId,
  ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/appointments/"
        "start-consultation/$appointmentId",
      ),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>> joinConsultation(
    String appointmentId,
  ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/appointments/"
        "join/$appointmentId",
      ),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>> generateAgoraToken({
    required String appointmentId,
    required int uid,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/api/appointments/agora-token",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "appointmentId": appointmentId,
          "uid": uid,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        data["message"] ??
            "Failed to generate Agora token",
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> completeConsultation(
    String appointmentId,
  ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/appointments/"
        "complete/$appointmentId",
      ),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>?>
      checkReadyConsultation(
    String patientPhone,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/appointments/ready/"
          "${Uri.encodeComponent(patientPhone)}",
        ),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      if (data["appointment"] == null) {
        return null;
      }

      return Map<String, dynamic>.from(
        data["appointment"],
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> saveProfile({
    required String userId,
    required String name,
    required String age,
    required String gender,
    required String bloodGroup,
    required String height,
    required String weight,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/profile/save"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": userId,
        "name": name,
        "age": age,
        "gender": gender,
        "bloodGroup": bloodGroup,
        "height": height,
        "weight": weight,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/profile/$userId"),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // PHARMACY ORDERS
  // ============================================================

  static Future<Map<String, dynamic>> getPharmacyOrders(
    String pharmacyId,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/orders/pharmacy/$pharmacyId",
      ),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          "$baseUrl/api/orders/status/$orderId",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "status": status,
        }),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  // ============================================================
  // ASSIGN DELIVERY PARTNER
  // ============================================================

  static Future<Map<String, dynamic>> assignDeliveryAgent({
    required String orderId,
    required String deliveryAgentName,
    required String deliveryAgentPhone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          "$baseUrl/api/orders/delivery-agent/$orderId",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "deliveryAgentName": deliveryAgentName,
          "deliveryAgentPhone": deliveryAgentPhone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      return {
        "success": false,
        "message": data["message"] ??
            "Failed to assign delivery partner.",
      };
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  // ============================================================
  // REMOVE DELIVERY PARTNER
  // ============================================================

  static Future<Map<String, dynamic>> removeDeliveryAgent({
    required String orderId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          "$baseUrl/api/orders/delivery-agent/"
          "remove/$orderId",
        ),
        headers: {
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      return {
        "success": false,
        "message": data["message"] ??
            "Failed to remove delivery partner.",
      };
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  // ============================================================
  // CART
  // ============================================================

  static Future<Map<String, dynamic>> addMedicineToCart({
    required String patientId,
    required String patientName,
    required String medicineId,
    required String medicine,
    required String dose,
    required String duration,
    required String food,
    required String instruction,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/cart/add"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "patientPhone": patientId,
        "patientName": patientName,
        "medicineId": medicineId,
        "medicine": medicine,
        "dose": dose,
        "duration": duration,
        "food": food,
        "instruction": instruction,
        "quantity": quantity,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getCartItems(
    String phone,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/cart/$phone"),
    );

    final data = jsonDecode(response.body);

    return data["items"] ?? [];
  }

  static Future<Map<String, dynamic>> deleteCartItem(
    String id,
  ) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/api/cart/$id"),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> increaseCartQuantity(
    String id,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/cart/increase/$id"),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> decreaseCartQuantity(
    String id,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/cart/decrease/$id"),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> clearCart(
    String patientPhone,
  ) async {
    final response = await http.delete(
      Uri.parse(
        "$baseUrl/api/cart/clear/$patientPhone",
      ),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // MEDICINE ORDERS
  // ============================================================

  static Future<Map<String, dynamic>> placeMedicineOrder({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String pharmacyId,
    required String pharmacyName,
    required String address,
    required String notes,
    required String prescriptionImage,
    required List<dynamic> medicines,
    required double totalAmount,
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/orders/place"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "patientId": patientId,
        "patientName": patientName,
        "patientPhone": patientPhone,
        "pharmacyId": pharmacyId,
        "pharmacyName": pharmacyName,
        "address": address,
        "notes": notes,
        "prescriptionImage": prescriptionImage,
        "medicines": medicines,
        "totalAmount": totalAmount,
        "paymentMethod": paymentMethod,
        "paymentStatus": paymentStatus,
        "status": "Pending",
      }),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // PRESCRIPTION ORDER
  // ============================================================

  static Future<Map<String, dynamic>> placePrescriptionOrder({
    required String patientName,
    required String patientPhone,
    required String pharmacyId,
    required String pharmacyName,
    required String address,
    required String notes,
    required String prescriptionImage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/orders/prescription"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "patientId": patientPhone,
          "patientName": patientName,
          "patientPhone": patientPhone,
          "pharmacyId": pharmacyId,
          "pharmacyName": pharmacyName,
          "address": address,
          "notes": notes,
          "prescriptionImage": prescriptionImage,
        }),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>>
      confirmPrescriptionOrder({
    required String orderId,
    required List<dynamic> medicines,
    double deliveryFee = 0,
    double discount = 0,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          "$baseUrl/api/orders/prescription/"
          "confirm/$orderId",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "medicines": medicines,
          "deliveryFee": deliveryFee,
          "discount": discount,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      return {
        "success": false,
        "message": data["message"] ??
            "Failed to confirm prescription order.",
      };
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<List<dynamic>> getPatientMedicineOrders(
    String phone,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/orders/patient/$phone",
      ),
    );

    final data = jsonDecode(response.body);

    return data["orders"] ?? [];
  }

  static Future<List<dynamic>> getAllMedicineOrders() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/orders/all"),
    );

    final data = jsonDecode(response.body);

    return data["orders"] ?? [];
  }

  // ============================================================
  // LAB ORDERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getLabOrders() async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/lab-orders/all",
        ),
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final data = jsonDecode(response.body);

        if (data is Map &&
            data["orders"] is List) {
          return List<Map<String, dynamic>>.from(
            (data["orders"] as List).map(
              (order) =>
                  Map<String, dynamic>.from(order),
            ),
          );
        }

        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map(
              (order) =>
                  Map<String, dynamic>.from(order),
            ),
          );
        }
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addSampleCollector({
    required String name,
    required String phone,
    required String address,
    required String labId,
    required String labName,
  }) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/api/sample-collectors/add",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "phone": phone,
        "address": address,
        "labId": labId,
        "labName": labName,
      }),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<List<Map<String, dynamic>>>
      getSampleCollectors(
    String labId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/sample-collectors/lab/$labId",
        ),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final data = jsonDecode(response.body);

        if (data is Map &&
            data["collectors"] is List) {
          return List<Map<String, dynamic>>.from(
            (data["collectors"] as List).map(
              (collector) =>
                  Map<String, dynamic>.from(collector),
            ),
          );
        }

        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map(
              (collector) =>
                  Map<String, dynamic>.from(collector),
            ),
          );
        }
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getLabOrderById(
    String orderId,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/lab-orders/$orderId",
      ),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>> placeLabOrder({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String labId,
    required String labName,
    required String address,
    required String notes,
    required String prescriptionImage,
    required List<String> tests,
    required String collectionMode,
    String bookingType = "TEST",
  }) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/api/lab-orders/add",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "patientId": patientId,
        "patientName": patientName,
        "patientPhone": patientPhone,
        "labId": labId,
        "labName": labName,
        "address": address,
        "notes": notes,
        "prescriptionImage": prescriptionImage,
        "tests": tests,
        "collectionMode": collectionMode,
        "bookingType": bookingType,
        "status": "Pending",
      }),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>> acceptLabOrder(
    String orderId,
  ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/lab-orders/accept/$orderId",
      ),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>> rejectLabOrder(
    String orderId,
  ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/lab-orders/reject/$orderId",
      ),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  
  // ============================================================
  // CANCEL LAB BOOKING
  // ============================================================

  static Future<Map<String, dynamic>> cancelLabOrder({
    required String orderId,
    required String patientId,
    String reason = "",
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/lab-orders/cancel/$orderId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "patientId": patientId,
        "cancelledBy": "Patient",
        "reason": reason,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["message"] ?? "Failed to cancel lab booking",
    );
  }

  // ============================================================
  // REQUEST LAB BOOKING RESCHEDULE
  // ============================================================

  static Future<Map<String, dynamic>> requestLabReschedule({
    required String orderId,
    required String patientId,
    required DateTime scheduledAt,
    String reason = "",
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/lab-orders/reschedule/$orderId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "patientId": patientId,
        "scheduledAt": scheduledAt.toIso8601String(),
        "reason": reason,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["message"] ?? "Failed to request rescheduling",
    );
  }

  // ============================================================
  // LAB APPROVES OR REJECTS RESCHEDULE REQUEST
  // ============================================================

  static Future<Map<String, dynamic>> decideLabReschedule({
    required String orderId,
    required String labId,
    required String decision,
  }) async {
    // The lab can confirm the patient's requested date or cancel
    // that reschedule request without cancelling the whole booking.
    if (!["Approved", "Cancelled", "Rejected"].contains(decision)) {
      throw ArgumentError(
        'Decision must be "Approved", "Cancelled", or "Rejected".',
      );
    }

    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/lab-orders/reschedule/$orderId/decision",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "labId": labId,
        "decision": decision,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["message"] ?? "Failed to process reschedule request",
    );
  }


  static Future<Map<String, dynamic>>
      assignSampleCollector({
    required String orderId,
    required String collectorId,
    required String collectorName,
    required String collectorPhone,
  }) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/lab-orders/assign-collector/$orderId",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "collectorId": collectorId,
        "collectorName": collectorName,
        "collectorPhone": collectorPhone,
      }),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>> collectorOnTheWay(
    String orderId,
  ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/lab-orders/"
        "collector-on-the-way/$orderId",
      ),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  // ============================================================
  // LAB COLLECTION OTP
  // ============================================================

  static Future<Map<String, dynamic>>
      generateCollectionOtp(
    String orderId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/api/lab-orders/"
          "generate-collection-otp/$orderId",
        ),
        headers: {
          "Content-Type": "application/json",
        },
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getCollectionOtp(
    String orderId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/lab-orders/"
          "collection-otp/$orderId",
        ),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>>
      verifyCollectionOtp({
    required String orderId,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/api/lab-orders/"
          "verify-collection-otp/$orderId",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "otp": otp,
        }),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>>
      markSampleCollected(
    String orderId,
  ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/lab-orders/"
        "sample-collected/$orderId",
      ),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>>
      markSampleReceived(
    String orderId,
  ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/lab-orders/"
        "sample-received/$orderId",
      ),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>>
      startLabTesting(
    String orderId,
  ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/lab-orders/"
        "start-testing/$orderId",
      ),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>>
      updateLabOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/lab-orders/status/$orderId",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "status": status,
      }),
    );

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<Map<String, dynamic>> uploadLabReport({
    required String orderId,
    required List<Map<String, dynamic>> reports,
  }) async {
    try {
      if (orderId.isEmpty) {
        throw Exception(
          "Lab order ID is required",
        );
      }

      if (reports.isEmpty) {
        throw Exception(
          "At least one report is required",
        );
      }

      final response = await http.put(
        Uri.parse(
          "$baseUrl/api/lab-orders/report/$orderId",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "reports": reports,
        }),
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
      }

      final data = jsonDecode(response.body);

      throw Exception(
        data["message"] ??
            "Failed to upload lab report",
      );
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // ONESIGNAL
  // ============================================================

  static Future<void> updateOneSignalId({
    required String phone,
    required String oneSignalId,
  }) async {
    await http.put(
      Uri.parse(
        "$baseUrl/api/auth/update-onesignal",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phone": phone,
        "oneSignalId": oneSignalId,
      }),
    );
  }

  // ============================================================
  // PRESCRIPTIONS
  // ============================================================

  static Future<Map<String, dynamic>> savePrescription({
    required Map<String, dynamic> prescription,
  }) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/api/prescriptions/save",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(prescription),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getPatientPrescriptions(
    String patientId,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/prescriptions/patient/$patientId",
      ),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendPrescription(
    String prescriptionId,
  ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/prescriptions/send/$prescriptionId",
      ),
      headers: {
        "Content-Type": "application/json",
      },
    );

    return jsonDecode(response.body);
  }

  static Future<void> downloadPrescription(
    String prescriptionId,
  ) async {
    try {
      final dir =
          await getApplicationDocumentsDirectory();

      final filePath =
          "${dir.path}/Prescription_$prescriptionId.pdf";

      await Dio().download(
        "$baseUrl/api/prescriptions/pdf/$prescriptionId",
        filePath,
      );

      await OpenFilex.open(filePath);
    } catch (e) {
      throw Exception(
        "Failed to download PDF: $e",
      );
    }
  }

// ============================================================
// PAYMENTS
// NORMAL RAZORPAY CHECKOUT
// ============================================================

static Future<Map<String, dynamic>> createPaymentOrder({
  required String userId,
  required String userName,
  required String userPhone,
  required String serviceType,
  required String serviceId,
}) async {
  try {
    debugPrint("================================");
    debugPrint("CREATE RAZORPAY ORDER");
    debugPrint("SERVICE TYPE = $serviceType");
    debugPrint("SERVICE ID = $serviceId");
    debugPrint("================================");

    final response = await http.post(
      Uri.parse(
        "$baseUrl/api/payment/create-order",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": userId,
        "userName": userName,
        "userPhone": userPhone,
        "serviceType": serviceType,
        "serviceId": serviceId,
      }),
    );

    debugPrint(
      "CREATE RAZORPAY ORDER STATUS = ${response.statusCode}",
    );

    debugPrint(
      "CREATE RAZORPAY ORDER BODY = ${response.body}",
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["message"] ??
          "Failed to create Razorpay order.",
    );
  } catch (e) {
    debugPrint(
      "CREATE RAZORPAY ORDER ERROR = $e",
    );

    rethrow;
  }
}


// ============================================================
// VERIFY NORMAL RAZORPAY CHECKOUT PAYMENT
// ============================================================

static Future<Map<String, dynamic>> verifyPayment({
  required String razorpayOrderId,
  required String razorpayPaymentId,
  required String razorpaySignature,
  required String serviceType,
  required String serviceId,
}) async {
  try {
    debugPrint("================================");
    debugPrint("VERIFY RAZORPAY PAYMENT");
    debugPrint(
      "ORDER ID = $razorpayOrderId",
    );
    debugPrint(
      "PAYMENT ID = $razorpayPaymentId",
    );
    debugPrint(
      "SERVICE TYPE = $serviceType",
    );
    debugPrint(
      "SERVICE ID = $serviceId",
    );
    debugPrint("================================");

    final response = await http.post(
      Uri.parse(
        "$baseUrl/api/payment/verify-payment",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "razorpayOrderId": razorpayOrderId,
        "razorpayPaymentId": razorpayPaymentId,
        "razorpaySignature": razorpaySignature,
        "serviceType": serviceType,
        "serviceId": serviceId,
      }),
    );

    debugPrint(
      "VERIFY PAYMENT STATUS = ${response.statusCode}",
    );

    debugPrint(
      "VERIFY PAYMENT BODY = ${response.body}",
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["message"] ??
          "Payment verification failed.",
    );
  } catch (e) {
    debugPrint(
      "VERIFY RAZORPAY PAYMENT ERROR = $e",
    );

    rethrow;
  }
} 

  // ============================================================
  // GET UPI QR PAYMENT STATUS
  //
  // GET /api/payment/qr-status/:paymentRecordId
  //
  // Flutter can call this after the patient scans the QR.
  // Backend checks Razorpay and returns paid=true only after
  // a captured UPI payment for the exact expected amount exists.
  // ============================================================

  static Future<Map<String, dynamic>>
      getQrPaymentStatus({
    required String paymentRecordId,
  }) async {
    try {
      if (paymentRecordId.trim().isEmpty) {
        throw Exception(
          "Payment record ID is required.",
        );
      }

      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/payment/qr-status/"
          "${Uri.encodeComponent(paymentRecordId)}",
        ),
      );

      debugPrint("================================");
      debugPrint("GET QR PAYMENT STATUS");
      debugPrint(
        "PAYMENT RECORD ID = $paymentRecordId",
      );
      debugPrint(
        "STATUS = ${response.statusCode}",
      );
      debugPrint(
        "BODY = ${response.body}",
      );
      debugPrint("================================");

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        data["message"] ??
            "Failed to get QR payment status.",
      );
    } catch (e) {
      debugPrint(
        "GET QR PAYMENT STATUS ERROR = $e",
      );
      rethrow;
    }
  }

  // ============================================================
  // CLOSE UPI QR
  //
  // POST /api/payment/close-qr
  //
  // Used when the patient cancels/leaves the payment screen.
  // A successful payment is protected by the backend and cannot
  // be closed as an unpaid QR.
  // ============================================================

  static Future<Map<String, dynamic>>
      closeQrPayment({
    required String paymentRecordId,
  }) async {
    try {
      if (paymentRecordId.trim().isEmpty) {
        throw Exception(
          "Payment record ID is required.",
        );
      }

      final response = await http.post(
        Uri.parse(
          "$baseUrl/api/payment/close-qr",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "paymentRecordId": paymentRecordId,
        }),
      );

      debugPrint("================================");
      debugPrint("CLOSE QR PAYMENT");
      debugPrint(
        "PAYMENT RECORD ID = $paymentRecordId",
      );
      debugPrint(
        "STATUS = ${response.statusCode}",
      );
      debugPrint(
        "BODY = ${response.body}",
      );
      debugPrint("================================");

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        data["message"] ??
            "Failed to close QR payment.",
      );
    } catch (e) {
      debugPrint("CLOSE QR PAYMENT ERROR = $e");
      rethrow;
    }
  }

  // Short alias if the payment screen wants to call closeQr().
  static Future<Map<String, dynamic>> closeQr({
    required String paymentRecordId,
  }) async {
    return closeQrPayment(
      paymentRecordId: paymentRecordId,
    );
  }

  // ============================================================
  // COLLECT COD PAYMENT
  //
  // PUT /api/orders/cod/collect/:id
  //
  // Used when delivery partner actually
  // receives cash from patient.
  // ============================================================

  static Future<Map<String, dynamic>>
      collectCODPayment({
    required String orderId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          "$baseUrl/api/orders/cod/collect/$orderId",
        ),
        headers: {
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        data["message"] ??
            "Failed to collect COD payment.",
      );
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // ADDRESS APIs
  // ============================================================

  static Future<Map<String, dynamic>> addAddress({
    required String userId,
    required String label,
    required String fullAddress,
    String landmark = "",
    required String city,
    required String state,
    required String pincode,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/addresses/add"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userId": userId,
          "label": label,
          "fullAddress": fullAddress,
          "landmark": landmark,
          "city": city,
          "state": state,
          "pincode": pincode,
          "latitude": latitude,
          "longitude": longitude,
          "isDefault": isDefault,
        }),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getAddresses(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/addresses/"
          "${Uri.encodeComponent(userId)}",
        ),
        headers: {
          "Content-Type": "application/json",
        },
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
        "addresses": [],
      };
    }
  }

  static Future<Map<String, dynamic>> updateAddress({
    required String userId,
    required String addressId,
    String? label,
    String? fullAddress,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final Map<String, dynamic> body = {};

      if (label != null) {
        body["label"] = label;
      }

      if (fullAddress != null) {
        body["fullAddress"] = fullAddress;
      }

      if (landmark != null) {
        body["landmark"] = landmark;
      }

      if (city != null) {
        body["city"] = city;
      }

      if (state != null) {
        body["state"] = state;
      }

      if (pincode != null) {
        body["pincode"] = pincode;
      }

      if (latitude != null) {
        body["latitude"] = latitude;
      }

      if (longitude != null) {
        body["longitude"] = longitude;
      }

      if (isDefault != null) {
        body["isDefault"] = isDefault;
      }

      final response = await http.put(
        Uri.parse(
          "$baseUrl/api/addresses/"
          "${Uri.encodeComponent(userId)}/"
          "${Uri.encodeComponent(addressId)}",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> deleteAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(
          "$baseUrl/api/addresses/"
          "${Uri.encodeComponent(userId)}/"
          "${Uri.encodeComponent(addressId)}",
        ),
        headers: {
          "Content-Type": "application/json",
        },
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>>
      setDefaultAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          "$baseUrl/api/addresses/"
          "${Uri.encodeComponent(userId)}/"
          "default/"
          "${Uri.encodeComponent(addressId)}",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userId": userId,
        }),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  // ============================================================
  // LAB TEST MANAGEMENT
  // ============================================================

  static Future<Map<String, dynamic>> addLabTest({
    required String labId,
    required String labName,
    required String labPhone,
    required String testName,
    required String category,
    required double price,
    required String sampleType,
    required String reportTime,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/labs/tests/add"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "labId": labId,
          "labName": labName,
          "labPhone": labPhone,
          "testName": testName,
          "category": category,
          "price": price,
          "sampleType": sampleType,
          "reportTime": reportTime,
          "description": description,
          "isActive": true,
        }),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<List<Map<String, dynamic>>>
      getLabTests() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/labs/tests/all"),
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final data = jsonDecode(response.body);

        if (data is Map &&
            data["tests"] is List) {
          return List<Map<String, dynamic>>.from(
            (data["tests"] as List).map(
              (test) =>
                  Map<String, dynamic>.from(test),
            ),
          );
        }

        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map(
              (test) =>
                  Map<String, dynamic>.from(test),
            ),
          );
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>>
      getLabTestsByLab(
    String labId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/labs/tests/lab/"
          "${Uri.encodeComponent(labId)}",
        ),
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final data = jsonDecode(response.body);

        if (data is Map &&
            data["tests"] is List) {
          return List<Map<String, dynamic>>.from(
            (data["tests"] as List).map(
              (test) =>
                  Map<String, dynamic>.from(test),
            ),
          );
        }

        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map(
              (test) =>
                  Map<String, dynamic>.from(test),
            ),
          );
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateLabTest({
    required String id,
    required String testName,
    required String category,
    required double price,
    required String sampleType,
    required String reportTime,
    required String description,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/labs/tests/$id"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "testName": testName,
          "category": category,
          "price": price,
          "sampleType": sampleType,
          "reportTime": reportTime,
          "description": description,
        }),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> deleteLabTest(
    String id,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/labs/tests/$id"),
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> toggleLabTest(
    String id,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          "$baseUrl/api/labs/tests/toggle/$id",
        ),
        headers: {
          "Content-Type": "application/json",
        },
      );

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  // ============================================================
  // PHARMACY DELIVERY OTP
  //
  // GET /api/orders/delivery-otp/:id
  //
  // Patient side:
  // Gets the OTP generated for the medicine order.
  // ============================================================

  static Future<Map<String, dynamic>>
      getDeliveryOtp({
    required String orderId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/orders/delivery-otp/$orderId",
        ),
      );

      debugPrint("================================");
      debugPrint("GET DELIVERY OTP");
      debugPrint("ORDER ID = $orderId");
      debugPrint(
        "STATUS = ${response.statusCode}",
      );
      debugPrint(
        "BODY = ${response.body}",
      );
      debugPrint("================================");

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  // ============================================================
  // VERIFY PHARMACY DELIVERY OTP
  //
  // PUT /api/orders/delivery-otp/:id
  //
  // Delivery partner enters patient's OTP.
  // ============================================================

  static Future<Map<String, dynamic>>
      verifyDeliveryOtp({
    required String orderId,
    required String otp,
  }) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/api/orders/delivery-otp/$orderId",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "otp": otp,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data["message"] ??
          "Failed to verify delivery OTP",
    );
  }

  // ============================================================
  // PHARMACY DELIVERY PARTNERS
  // ============================================================

  static Future<Map<String, dynamic>>
      getDeliveryPartners(
    String pharmacyPhone,
  ) async {
    try {
      final encodedPhone =
          Uri.encodeComponent(pharmacyPhone);

      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/pharmacies/"
          "$encodedPhone/delivery-partners",
        ),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      return {
        "success": false,
        "message": data["message"] ??
            "Failed to load delivery partners.",
        "deliveryPartners": [],
      };
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
        "deliveryPartners": [],
      };
    }
  }

  static Future<Map<String, dynamic>>
      addDeliveryPartner({
    required String pharmacyPhone,
    required String name,
    required String phone,
  }) async {
    try {
      final encodedPhone =
          Uri.encodeComponent(pharmacyPhone);

      final response = await http.post(
        Uri.parse(
          "$baseUrl/api/pharmacies/"
          "$encodedPhone/delivery-partners",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "phone": phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      return {
        "success": false,
        "message": data["message"] ??
            "Failed to add delivery partner.",
      };
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>>
      deleteDeliveryPartner({
    required String pharmacyPhone,
    required String partnerId,
  }) async {
    try {
      final encodedPhone =
          Uri.encodeComponent(pharmacyPhone);

      final encodedPartnerId =
          Uri.encodeComponent(partnerId);

      final response = await http.delete(
        Uri.parse(
          "$baseUrl/api/pharmacies/"
          "$encodedPhone/delivery-partners/"
          "$encodedPartnerId",
        ),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      return {
        "success": false,
        "message": data["message"] ??
            "Failed to delete delivery partner.",
      };
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

static Future<Map<String, dynamic>> createDoctorPaymentOrder({
  required String patientName,
  required String patientPhone,
  required String doctorId,
  required String doctorName,
  required String specialization,
  required String hospital,
  required String consultationType,
  required String appointmentDate,
  required String appointmentTime,
  required List<File> reports,
}) async {
  try {
    // Create Dio instance
    final dio = Dio();

    final formData = FormData.fromMap({
      "patientName": patientName,
      "patientPhone": patientPhone,
      "doctorId": doctorId,
      "doctorName": doctorName,
      "specialization": specialization,
      "hospital": hospital,
      "consultationType": consultationType,
      "appointmentDate": appointmentDate,
      "appointmentTime": appointmentTime,
    });

    // Attach reports
    for (final file in reports) {
      formData.files.add(
        MapEntry(
          "reports",
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split(RegExp(r'[\\/]')).last,
          ),
        ),
      );
    }

    print("========================================");
    print("CREATE DOCTOR PAYMENT REQUEST");
    print("PATIENT: $patientName");
    print("PHONE: $patientPhone");
    print("DOCTOR ID: $doctorId");
    print("DOCTOR: $doctorName");
    print("DATE: $appointmentDate");
    print("TIME: $appointmentTime");
    print("REPORTS: ${reports.length}");
    print("========================================");

    final response = await dio.post(
      "$baseUrl/api/payment/create-doctor-order",
      data: formData,
    );

    print("========================================");
    print("CREATE DOCTOR PAYMENT STATUS");
    print(response.statusCode);
    print("CREATE DOCTOR PAYMENT BODY");
    print(response.data);
    print("========================================");

    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    print("========================================");
    print("DOCTOR PAYMENT DIO ERROR");
    print("STATUS: ${e.response?.statusCode}");
    print("DATA: ${e.response?.data}");
    print("MESSAGE: ${e.message}");
    print("URL: ${e.requestOptions.uri}");
    print("========================================");

    final data = e.response?.data;

    if (data is Map) {
      throw Exception(
        data["message"] ??
            data["error"] ??
            "Server returned ${e.response?.statusCode}",
      );
    }

    throw Exception(
      "Server returned ${e.response?.statusCode}: "
      "${e.message ?? "Unknown error"}",
    );
  } catch (e) {
    print("CREATE DOCTOR PAYMENT ERROR: $e");
    rethrow;
  }
}



/// Verifies Razorpay payment on the BACKEND.
///
/// The backend checks:
/// 1. Razorpay signature
/// 2. Razorpay order
/// 3. Payment ID
/// 4. Amount
/// 5. Currency
/// 6. Payment status = captured
/// 7. UPI method
/// 8. Exact appointment/order mapping
///
/// Only after successful verification is the appointment marked Paid.
static Future<Map<String, dynamic>> verifyDoctorPayment({
  required String appointmentId,
  required String razorpayOrderId,
  required String razorpayPaymentId,
  required String razorpaySignature,
  required String patientPhone,
}) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/api/payment/verify-doctor-payment"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "appointmentId": appointmentId,
        "razorpayOrderId": razorpayOrderId,
        "razorpayPaymentId": razorpayPaymentId,
        "razorpaySignature": razorpaySignature,
        "userPhone": patientPhone,
      }),
    );

    print("VERIFY DOCTOR PAYMENT STATUS: ${response.statusCode}");
    print("VERIFY DOCTOR PAYMENT BODY: ${response.body}");

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(
      decoded["message"] ??
          decoded["error"] ??
          "Doctor payment verification failed",
    );
  } catch (e) {
    print("VERIFY DOCTOR PAYMENT ERROR: $e");
    rethrow;
  }
}


/// Cancels the pending doctor appointment/payment reservation
/// when the user closes Razorpay or payment fails.
///
/// This prevents an unpaid appointment from unnecessarily blocking
/// the doctor's time slot.
static Future<Map<String, dynamic>> cancelDoctorPayment({
  required String appointmentId,
  required String razorpayOrderId,
  required String patientPhone,
}) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/api/payment/cancel-doctor-order"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "appointmentId": appointmentId,
        "razorpayOrderId": razorpayOrderId,
        "userPhone": patientPhone,
      }),
    );

    print("CANCEL DOCTOR PAYMENT STATUS: ${response.statusCode}");
    print("CANCEL DOCTOR PAYMENT BODY: ${response.body}");

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(
      decoded["message"] ??
          decoded["error"] ??
          "Failed to cancel doctor payment",
    );
  } catch (e) {
    print("CANCEL DOCTOR PAYMENT ERROR: $e");
    rethrow;
  }
}

// Add this method inside ApiService in api_service.dart.
// It uses the existing baseUrl, http, and jsonEncode members.

static Future<Map<String, dynamic>> proposeLabReschedule({
  required String orderId,
  required String labId,
  required DateTime scheduledAt,
  required String reason,
}) async {
  final response = await http.put(
    Uri.parse(
      "$baseUrl/api/lab-orders/reschedule/$orderId/propose",
    ),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "labId": labId,
      "scheduledAt": scheduledAt.toUtc().toIso8601String(),
      "reason": reason,
    }),
  );

  final dynamic decoded = jsonDecode(response.body);
  final data = decoded is Map
      ? Map<String, dynamic>.from(decoded)
      : <String, dynamic>{};

  if (response.statusCode >= 200 &&
      response.statusCode < 300 &&
      data["success"] != false) {
    return data;
  }

  throw Exception(
    data["message"]?.toString() ??
        "Failed to propose a new date/time",
  );
}

/// Patient responds to a date/time proposed by the laboratory.
///
/// Endpoint: PUT /api/lab-orders/reschedule/:id/respond
/// decision: "Accepted", "Declined", or "Requested Another Time".
/// Requesting another time keeps the original booking unchanged and asks
/// the laboratory to send a different proposal.
static Future<Map<String, dynamic>> respondToLabReschedule({
  required String orderId,
  required String patientId,
  required String decision,
  String reason = "",
}) async {
  if (orderId.trim().isEmpty) {
    throw ArgumentError("Lab order ID is required.");
  }
  if (patientId.trim().isEmpty) {
    throw ArgumentError("Patient ID is required.");
  }
  const allowedDecisions = [
    "Accepted",
    "Declined",
    "Requested Another Time",
  ];
  if (!allowedDecisions.contains(decision)) {
    throw ArgumentError(
      'Decision must be "Accepted", "Declined", or "Requested Another Time".',
    );
  }

  final response = await http.put(
    Uri.parse(
      "$baseUrl/api/lab-orders/reschedule/"
      "${Uri.encodeComponent(orderId)}/respond",
    ),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "patientId": patientId,
      "decision": decision,
      "reason": reason,
    }),
  );

  final dynamic decoded = jsonDecode(response.body);
  final data = decoded is Map
      ? Map<String, dynamic>.from(decoded)
      : <String, dynamic>{};

  if (response.statusCode >= 200 &&
      response.statusCode < 300 &&
      data["success"] != false) {
    return data;
  }

  throw Exception(
    data["message"]?.toString() ??
        "Failed to respond to lab reschedule proposal "
            "(${response.statusCode})",
  );
}

/// Fetches the latest lab booking details after a reschedule action.
static Future<Map<String, dynamic>> refreshLabOrder(
  String orderId,
) async {
  if (orderId.trim().isEmpty) {
    throw ArgumentError("Lab order ID is required.");
  }

  final response = await http.get(
    Uri.parse(
      "$baseUrl/api/lab-orders/"
      "${Uri.encodeComponent(orderId)}",
    ),
  );

  final dynamic decoded = jsonDecode(response.body);
  final data = decoded is Map
      ? Map<String, dynamic>.from(decoded)
      : <String, dynamic>{};

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    return data;
  }

  throw Exception(
    data["message"]?.toString() ??
        "Failed to refresh lab booking (${response.statusCode})",
  );
}




}
