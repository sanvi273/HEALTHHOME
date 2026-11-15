import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'services/api_service.dart';

class UploadLabReportPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const UploadLabReportPage({
    super.key,
    required this.order,
  });

  @override
  State<UploadLabReportPage> createState() =>
      _UploadLabReportPageState();
}

class _UploadLabReportPageState
    extends State<UploadLabReportPage> {

  // ============================================================
  // CLOUDINARY
  // ============================================================

  final CloudinaryPublic cloudinary =
      CloudinaryPublic(
    'dvjvp5bu7',
    'healthhome_prescriptions',
    cache: false,
  );

  // ============================================================
  // STATE
  // ============================================================

  final List<PlatformFile> selectedFiles = [];

  // User-entered name for every uploaded report.
  // Example: CBC Report, Blood Pressure Report, Blood Sugar Report.
  final List<String> reportNames = [];

  bool isUploading = false;

  // ============================================================
  // PICK MULTIPLE PHOTO REPORTS
  // ============================================================

  Future<void> pickReports() async {
    try {
      final FilePickerResult? result =
          await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: kIsWeb,
      );

      if (result == null) {
        return;
      }

      final files = result.files.where((pickedFile) {
        final extension = pickedFile.extension?.toLowerCase() ?? '';
        final isSupportedPhoto =
            const {'jpg', 'jpeg', 'png'}.contains(extension);
        final hasReadableData = kIsWeb
            ? pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty
            : pickedFile.path != null ||
                (pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty);
        return isSupportedPhoto && hasReadableData;
      }).toList();

      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Select readable JPG, JPEG, or PNG photo files.",
              ),
            ),
          );
        }
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        // Keep the most recently selected photos at the top and preserve
        // that order when the reports are uploaded.
        selectedFiles.insertAll(0, files.reversed);

        // Every file gets its own editable report name.
        reportNames.insertAll(0, List<String>.filled(files.length, ""));
      });

      debugPrint(
        "================================",
      );

      debugPrint(
        "REPORT FILES SELECTED",
      );

      debugPrint(
        "TOTAL FILES = ${selectedFiles.length}",
      );

      for (int i = 0;
          i < selectedFiles.length;
          i++) {
        debugPrint(
          "PAGE ${i + 1} = "
          "${selectedFiles[i].name}",
        );
      }

      debugPrint(
        "================================",
      );
    } catch (e) {
      debugPrint(
        "PICK REPORT ERROR = $e",
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Unable to select reports: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // REMOVE ONE FILE
  // ============================================================

  void removeFile(int index) {
    if (isUploading) {
      return;
    }

    setState(() {
      selectedFiles.removeAt(index);

      if (index < reportNames.length) {
        reportNames.removeAt(index);
      }
    });
  }

  // ============================================================
  // CLEAR ALL FILES
  // ============================================================

  void clearAllFiles() {
    if (isUploading) {
      return;
    }

    setState(() {
      selectedFiles.clear();
      reportNames.clear();
    });
  }

  // ============================================================
  // FILE NAME
  // ============================================================

  String getFileName(PlatformFile file) {
    return file.name;
  }

  // ============================================================
  // ============================================================
  // UPLOAD REPORT
  // ============================================================

  Future<void> uploadReport() async {

    // ----------------------------------------------------------
    // VALIDATE FILES
    // ----------------------------------------------------------

    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select at least one report.",
          ),
        ),
      );

      return;
    }

    // Require a proper name for every report.
    for (int i = 0; i < selectedFiles.length; i++) {
      final name = i < reportNames.length
          ? reportNames[i].trim()
          : "";

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Please enter a report name for Report ${i + 1}.",
            ),
          ),
        );
        return;
      }
    }

    // ----------------------------------------------------------
    // GET ORDER ID
    // ----------------------------------------------------------

    final String orderId =
        widget.order["_id"]?.toString() ?? "";

    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Lab order ID not found.",
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // START UPLOADING
    // ----------------------------------------------------------

    setState(() {
      isUploading = true;
    });

    try {

      final List<Map<String, dynamic>> reports = [];

      // ========================================================
      // UPLOAD EVERY FILE TO CLOUDINARY
      // ========================================================

      for (int i = 0;
          i < selectedFiles.length;
          i++) {

        final PlatformFile file = selectedFiles[i];

        final String fileName =
            getFileName(file);

        debugPrint(
          "================================",
        );

        debugPrint(
          "UPLOADING REPORT ${i + 1}",
        );

        debugPrint(
          "FILE NAME = $fileName",
        );

        debugPrint(
          "FILE TYPE = IMAGE",
        );

        debugPrint(
          "================================",
        );

        // ------------------------------------------------------
        // CLOUDINARY RESOURCE TYPE
        // ------------------------------------------------------

        const CloudinaryResourceType resourceType =
            CloudinaryResourceType.Image;

        // ------------------------------------------------------
        // UPLOAD
        // ------------------------------------------------------

        final CloudinaryFile cloudinaryFile;
        if (file.bytes != null && file.bytes!.isNotEmpty) {
          cloudinaryFile = CloudinaryFile.fromBytesData(
            file.bytes!,
            identifier: fileName,
            resourceType: resourceType,
          );
        } else if (!kIsWeb && file.path != null) {
          cloudinaryFile = CloudinaryFile.fromFile(
            file.path!,
            identifier: fileName,
            resourceType: resourceType,
          );
        } else {
          throw Exception(
            "File data is unavailable for $fileName. Please select the file again.",
          );
        }

        final CloudinaryResponse response = await cloudinary.uploadFile(
          cloudinaryFile,
        );

        final String fileUrl =
            response.secureUrl;

        debugPrint(
          "UPLOADED URL = $fileUrl",
        );

        // ------------------------------------------------------
        // DETERMINE FILE TYPE
        // ------------------------------------------------------

        final String lowerName = fileName.toLowerCase();
        final String fileType = lowerName.endsWith(".png")
            ? "image/png"
            : "image/jpeg";

        // ------------------------------------------------------
        // ADD TO REPORT LIST
        // ------------------------------------------------------

        reports.add({
          // IMPORTANT:
          // This is the human-readable name that must also be shown
          // in the Patient module.
          "reportName": reportNames[i].trim(),

          // Keep the original filename for the actual file.
          "fileName": fileName,
          "fileUrl": fileUrl,
          "fileType": fileType,

          // Keep pageNumber for backward compatibility.
          "pageNumber": i + 1,
        });
      }

      // ========================================================
      // SEND ALL REPORTS TO BACKEND
      // ========================================================

      debugPrint(
        "================================",
      );

      debugPrint(
        "SENDING REPORTS TO BACKEND",
      );

      debugPrint(
        "ORDER ID = $orderId",
      );

      debugPrint(
        "TOTAL REPORTS = ${reports.length}",
      );

      debugPrint(
        "================================",
      );

      await ApiService.uploadLabReport(
        orderId: orderId,
        reports: reports,
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Lab report uploaded successfully.",
          ),
        ),
      );

      // Return true to Lab Dashboard
      Navigator.pop(
        context,
        true,
      );

    } catch (e) {

      debugPrint(
        "================================",
      );

      debugPrint(
        "UPLOAD REPORT ERROR",
      );

      debugPrint(
        "$e",
      );

      debugPrint(
        "================================",
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to upload report: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {

    final String patientName =
        widget.order["patientName"]
                ?.toString() ??
            "Patient";

    final List<dynamic> tests =
        widget.order["tests"] is List
            ? widget.order["tests"]
            : [];

    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FA),

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black,

        elevation: 0,

        title: const Text(
          "Upload Lab Report",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // PATIENT INFORMATION
            // ==================================================

            _buildPatientCard(
              patientName,
            ),

            const SizedBox(
              height: 22,
            ),

            // ==================================================
            // TESTS
            // ==================================================

            if (tests.isNotEmpty) ...[
              const Text(
                "Tests",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Wrap(
                spacing: 8,
                runSpacing: 8,

                children:
                    tests.map(
                  (test) {

                    return Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xffE8FAF8,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),

                      child: Text(
                        test.toString(),
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xff0F766E,
                          ),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),

              const SizedBox(
                height: 25,
              ),
            ],

            // ==================================================
            // REPORT SECTION
            // ==================================================

            const Text(
              "Lab Report",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              "Upload completed reports and give each file a meaningful name.",
              style: TextStyle(
                color:
                    Colors.black54,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // SELECT FILES
            // ==================================================

            GestureDetector(
              onTap:
                  isUploading
                      ? null
                      : pickReports,

              child: Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),

                  border:
                      Border.all(
                    color:
                        const Color(
                      0xff14B8A6,
                    ),

                    width: 1.5,
                  ),
                ),

                child: const Column(
                  children: [

                    Icon(
                      Icons
                          .cloud_upload_outlined,
                      size: 50,
                      color:
                          Color(
                        0xff14B8A6,
                      ),
                    ),

                    SizedBox(
                      height: 12,
                    ),

                    Text(
                      "Add Report Files",
                      style:
                          TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(
                      height: 6,
                    ),

                    Text(
                      "Select one or more report photos",
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color:
                            Colors.black54,
                      ),
                    ),

                    SizedBox(
                      height: 6,
                    ),

                    Text(
                      "JPG • JPEG • PNG photos only",
                      style:
                          TextStyle(
                        color:
                            Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // SELECTED FILES
            // ==================================================

            if (selectedFiles.isNotEmpty) ...[

              const SizedBox(
                height: 25,
              ),

              Row(
                children: [

                  const Expanded(
                    child: Text(
                      "Selected Files",
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed:
                        isUploading
                            ? null
                            : clearAllFiles,

                    child:
                        const Text(
                      "Clear All",
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),

                itemCount:
                    selectedFiles.length,

                itemBuilder:
                    (context, index) {

                  final PlatformFile file =
                      selectedFiles[index];

                  return Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 14,
                    ),

                    padding:
                        const EdgeInsets.all(14),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      boxShadow: const [
                        BoxShadow(
                          color:
                              Colors.black12,
                          blurRadius:
                              6,
                          offset:
                              Offset(0, 2),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        // FILE INFORMATION
                        Row(
                          children: [

                            Container(
                              width: 48,
                              height: 48,

                              decoration:
                                  BoxDecoration(
                                color: const Color(0xffE8FAF8),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),

                              child: const Icon(
                                Icons.image_outlined,
                                color: Color(0xff14B8A6),
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    "Report ${index + 1}",
                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    getFileName(file),
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              onPressed:
                                  isUploading
                                      ? null
                                      : () =>
                                          removeFile(
                                            index,
                                          ),
                              icon:
                                  const Icon(
                                Icons
                                    .delete_outline,
                                color:
                                    Colors.red,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // REPORT NAME
                        TextField(
                          enabled:
                              !isUploading,
                          onChanged: (value) {
                            if (index <
                                reportNames.length) {
                              reportNames[index] =
                                  value;
                            }
                          },
                          decoration:
                              InputDecoration(
                            labelText:
                                "Report Name",
                            hintText:
                                "e.g. CBC Report",
                            prefixIcon:
                                const Icon(
                              Icons
                                  .description_outlined,
                              color:
                                  Color(
                                0xff14B8A6,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                const Color(
                              0xffF8FAFC,
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  BorderSide.none,
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  BorderSide(
                                color:
                                    Colors.grey
                                        .shade300,
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    Color(
                                  0xff14B8A6,
                                ),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // UPLOAD BUTTON
            // ==================================================

            SizedBox(
              width:
                  double.infinity,

              height:
                  55,

              child:
                  ElevatedButton.icon(

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xff14B8A6,
                  ),

                  foregroundColor:
                      Colors.white,

                  disabledBackgroundColor:
                      Colors.grey.shade400,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                ),

                onPressed:
                    isUploading ||
                            selectedFiles.isEmpty
                        ? null
                        : uploadReport,

                icon:
                    isUploading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth:
                                  2.5,
                            ),
                          )
                        : const Icon(
                            Icons
                                .cloud_upload,
                          ),

                label:
                    Text(
                  isUploading
                      ? "Uploading..."
                      : "Upload Report",
                ),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // INFORMATION
            // ==================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                15,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xffEAF7FF,
                ),

                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),

              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Icon(
                    Icons.info_outline,
                    color:
                        Colors.blue,
                  ),

                  SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      "After uploading, the booking will be "
                      "marked as Completed and the patient "
                      "will be able to view the complete report.",

                      style:
                          TextStyle(
                        color:
                            Colors.black87,
                        height:
                            1.4,
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

  // ============================================================
  // PATIENT CARD
  // ============================================================

  Widget _buildPatientCard(
    String patientName,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Colors.black12,
            blurRadius:
                8,
            offset:
                Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [

          Container(
            width: 52,
            height: 52,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xffE8FAF8,
              ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),

            child:
                const Icon(
              Icons.person,
              color:
                  Color(
                0xff14B8A6,
              ),
              size: 30,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Text(
                  "Patient",
                  style:
                      TextStyle(
                    color:
                        Colors.black54,
                    fontSize:
                        12,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  patientName,
                  style:
                      const TextStyle(
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
