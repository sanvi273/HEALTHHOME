import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/api_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List reports = [];
  bool isLoading = true;

  // ============================================================
  // LOAD REPORTS
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final String currentPhone =
          prefs.getString("userPhone") ?? "";

      final orders =
          await ApiService.getLabOrders();

      debugPrint("================================");
      debugPrint("LOADING PATIENT LAB REPORTS");
      debugPrint("USER PHONE = $currentPhone");
      debugPrint("ALL ORDERS = $orders");
      debugPrint("================================");

      final filteredReports =
          orders.where((e) {
        final String patientPhone =
            e["patientPhone"]?.toString() ?? "";

        final String status =
            e["status"]?.toString() ?? "";

        final List<dynamic> reportFiles =
            e["reports"] is List
                ? e["reports"]
                : [];

        return patientPhone == currentPhone &&
            status == "Completed" &&
            reportFiles.isNotEmpty;
      }).toList();

      debugPrint(
        "FILTERED REPORTS = $filteredReports",
      );

      // Verify that the backend response contains the human-readable
      // reportName for every uploaded report page.
      for (final order in filteredReports) {
        final dynamic raw = order["reports"];
        if (raw is List) {
          for (final report in raw) {
            if (report is Map) {
              debugPrint(
                "PATIENT REPORT NAME = ${report["reportName"]} | "
                "FILE = ${report["fileName"]}",
              );
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        reports = filteredReports;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        "LOAD REPORTS ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // GET REPORT FILES
  // ============================================================

  List<Map<String, dynamic>> getReportFiles(
    Map item,
  ) {
    final dynamic rawReports =
        item["reports"];

    if (rawReports is! List) {
      return [];
    }

    final List<Map<String, dynamic>> result =
        [];

    for (final report in rawReports) {
      if (report is Map) {
        result.add(
          Map<String, dynamic>.from(report),
        );
      }
    }

    result.sort(
      (a, b) {
        final int pageA =
            int.tryParse(
                  a["pageNumber"]?.toString() ??
                      "",
                ) ??
                0;

        final int pageB =
            int.tryParse(
                  b["pageNumber"]?.toString() ??
                      "",
                ) ??
                0;

        return pageA.compareTo(pageB);
      },
    );

    return result;
  }

  // ============================================================
  // REPORT NAME
  // ============================================================

  String getReportName(
    Map<String, dynamic> report,
    int index,
  ) {
    final String name =
        report["reportName"]?.toString().trim() ?? "";

    // Backward compatibility for old reports that do not have
    // reportName saved yet.
    if (name.isNotEmpty) {
      return name;
    }

    // Do NOT show the uploaded Cloudinary/file-system filename
    // in the Patient UI. If reportName is missing (old data),
    // use a clean generic label instead.
    return "${"report".tr()} ${index + 1}";
  }

  // ============================================================
  // CHECK PDF
  // ============================================================

  bool isPdf(
    Map<String, dynamic> report,
  ) {
    final String type =
        report["fileType"]
                ?.toString()
                .toLowerCase() ??
            "";

    final String fileName =
        report["fileName"]
                ?.toString()
                .toLowerCase() ??
            "";

    return type.contains("pdf") ||
        fileName.endsWith(".pdf");
  }

  // ============================================================
  // DOWNLOAD FILE
  // ============================================================

  Future<File?> downloadFile(
    String url,
    String fileName,
  ) async {
    try {
      final Directory dir =
          await getApplicationDocumentsDirectory();

      String safeFileName =
          fileName.trim();

      if (safeFileName.isEmpty) {
        safeFileName =
            "lab_report_${DateTime.now().millisecondsSinceEpoch}";
      }

      final String filePath =
          "${dir.path}/$safeFileName";

      debugPrint(
        "DOWNLOADING REPORT",
      );

      debugPrint(
        "URL = $url",
      );

      debugPrint(
        "PATH = $filePath",
      );

      await Dio().download(
        url,
        filePath,
      );

      return File(filePath);
    } catch (e) {
      debugPrint(
        "DOWNLOAD ERROR = $e",
      );

      return null;
    }
  }

  // ============================================================
  // DOWNLOAD ALL REPORT FILES
  // ============================================================

  Future<void> downloadAllReports(
    List<Map<String, dynamic>> files,
  ) async {
    try {
      if (files.isEmpty) return;

      int successCount = 0;

      for (final report in files) {
        final String url =
            report["fileUrl"]?.toString() ??
                "";

        final String fileName =
            report["fileName"]?.toString() ??
                "";

        if (url.isEmpty) continue;

        final File? file =
            await downloadFile(
          url,
          fileName,
        );

        if (file != null) {
          successCount++;
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$successCount report file(s) downloaded successfully",
          ),
          backgroundColor:
              Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${"downloadFailed".tr()} $e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // SHARE REPORT
  // ============================================================

  Future<void> shareReport(
    Map<String, dynamic> report,
  ) async {
    try {
      final String url =
          report["fileUrl"]?.toString() ??
              "";

      if (url.isEmpty) {
        return;
      }

      await Share.share(
        url,
        subject:
            report["reportName"]?.toString().trim().isNotEmpty == true
                ? report["reportName"].toString()
                : "labReport".tr(),
      );
    } catch (e) {
      debugPrint(
        "SHARE ERROR = $e",
      );
    }
  }

  // ============================================================
  // OPEN PDF
  // ============================================================

  Future<void> openPdf(
    Map<String, dynamic> report,
  ) async {
    final String url =
        report["fileUrl"]?.toString() ??
            "";

    final String fileName =
        report["fileName"]?.toString() ??
            "labReportPdf".tr();

    if (url.isEmpty) {
      return;
    }

    try {
      final File? file =
          await downloadFile(
        url,
        fileName,
      );

      if (file == null) {
        throw Exception(
          "unableToDownloadPdf".tr(),
        );
      }

      await OpenFilex.open(
        file.path,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${"unableToOpenPdf".tr()} $e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // VIEW REPORT
  // ============================================================

  void viewReport(
    List<Map<String, dynamic>> files,
  ) {
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "noReportFilesAvailable".tr(),
          ),
        ),
      );

      return;
    }

    // If the report is a single PDF
    if (files.length == 1 &&
        isPdf(files.first)) {
      openPdf(files.first);
      return;
    }

    // Otherwise open image/page viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReportViewerPage(
          reports: files,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  String translateReportStatus(String status) {
    switch (status.toLowerCase()) {
      case "completed":
        return "completed".tr();
      case "pending":
        return "pending".tr();
      case "in progress":
        return "inProgress".tr();
      case "rejected":
        return "rejected".tr();
      case "accepted":
        return "accepted".tr();
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FA),

      appBar: AppBar(
        title: Text(
          "myLabReports".tr(),
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ?  Center(
              child:
                  CircularProgressIndicator(),
            )
          : reports.isEmpty
              ?  Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons
                            .description_outlined,
                        size: 60,
                        color:
                            Colors.grey,
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Text(
                        "noReportsFound".tr(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh:
                      loadReports,

                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),

                    itemCount:
                        reports.length,

                    itemBuilder:
                        (context, index) {
                      final Map item =
                          reports[index];

                      final List<
                              Map<String,
                                  dynamic>>
                          files =
                          getReportFiles(
                        item,
                      );

                      final String labName =
                          item["labName"]
                                  ?.toString() ??
                              "laboratory".tr();

                      final String status =
                          item["status"]
                                  ?.toString() ??
                              "Completed";

                      final String date =
                          item["updatedAt"]
                                  ?.toString() ??
                              "";

                      return _buildReportCard(
                        item,
                        files,
                        labName,
                        status,
                        date,
                      );
                    },
                  ),
                ),
    );
  }

  // ============================================================
  // REPORT CARD
  // ============================================================

  Widget _buildReportCard(
    Map item,
    List<Map<String, dynamic>> files,
    String labName,
    String status,
    String date,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),

      elevation: 2,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // --------------------------------------------------
            // LAB NAME
            // --------------------------------------------------

            Row(
              children: [

                Container(
                  width: 48,
                  height: 48,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xffE8FAF8,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),

                  child: const Icon(
                    Icons
                        .medical_services_outlined,
                    color:
                        Color(
                      0xff14B8A6,
                    ),
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
                        labName,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        status,
                        style:
                            const TextStyle(
                          color:
                              Colors.green,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            // --------------------------------------------------
            // DATE
            // --------------------------------------------------

            if (date.isNotEmpty)
              Row(
                children: [

                  const Icon(
                    Icons
                        .calendar_today_outlined,
                    size: 17,
                    color:
                        Colors.grey,
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Expanded(
                    child: Text(
                      date,
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(
              height: 12,
            ),

            // --------------------------------------------------
            // NAMED REPORTS
            // --------------------------------------------------

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                14,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xffF4F9F9,
                ),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(
                    children: [

                      const Icon(
                        Icons
                            .description_outlined,
                        color:
                            Color(
                          0xff14B8A6,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Text(
                        files.length == 1
                            ? "1 Report"
                            : "${files.length} Reports",
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  ...List.generate(
                    files.length,
                    (reportIndex) {

                      final report =
                          files[reportIndex];

                      final String name =
                          getReportName(
                        report,
                        reportIndex,
                      );

                      final bool pdf =
                          isPdf(report);

                      return Container(
                        margin:
                            EdgeInsets.only(
                          bottom:
                              reportIndex ==
                                      files.length - 1
                                  ? 0
                                  : 8,
                        ),

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),

                        child: Row(
                          children: [

                            Icon(
                              pdf
                                  ? Icons
                                      .picture_as_pdf
                                  : Icons
                                      .insert_drive_file_outlined,
                              size: 20,
                              color: pdf
                                  ? Colors.red
                                  : const Color(
                                      0xff14B8A6,
                                    ),
                            ),

                            const SizedBox(
                              width: 9,
                            ),

                            Expanded(
                              child: Text(
                                name,
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // --------------------------------------------------
            // BUTTONS
            // --------------------------------------------------

            Row(
              children: [

                Expanded(
                  child:
                      ElevatedButton.icon(
                    icon: const Icon(
                      Icons.visibility,
                    ),

                    label:
                        Text(
                      "view".tr(),
                    ),

                    onPressed:
                        files.isEmpty
                            ? null
                            : () =>
                                viewReport(
                                  files,
                                ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child:
                      ElevatedButton.icon(
                    icon: const Icon(
                      Icons.download,
                    ),

                    label:
                        Text(
                      "download".tr(),
                    ),

                    onPressed:
                        files.isEmpty
                            ? null
                            : () =>
                                downloadAllReports(
                                  files,
                                ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child:
                      ElevatedButton.icon(
                    icon: const Icon(
                      Icons.share,
                    ),

                    label:
                        Text(
                      "share".tr(),
                    ),

                    onPressed:
                        files.isEmpty
                            ? null
                            : () =>
                                shareReport(
                                  files.first,
                                ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// REPORT VIEWER
// ============================================================================

class ReportViewerPage
    extends StatefulWidget {
  final List<
      Map<String, dynamic>> reports;

  const ReportViewerPage({
    super.key,
    required this.reports,
  });

  @override
  State<ReportViewerPage> createState() =>
      _ReportViewerPageState();
}

class _ReportViewerPageState
    extends State<ReportViewerPage> {

  late final PageController
      pageController;

  int currentPage = 0;

  @override
  void initState() {
    super.initState();

    pageController =
        PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  bool isPdf(
    Map<String, dynamic> report,
  ) {
    final String type =
        report["fileType"]
                ?.toString()
                .toLowerCase() ??
            "";

    final String fileName =
        report["fileName"]
                ?.toString()
                .toLowerCase() ??
            "";

    return type.contains("pdf") ||
        fileName.endsWith(".pdf");
  }

  Future<void> openPdf(
    Map<String, dynamic> report,
  ) async {
    final String url =
        report["fileUrl"]?.toString() ??
            "";

    final String fileName =
        report["fileName"]?.toString() ??
            "labReportPdf".tr();

    if (url.isEmpty) return;

    try {
      final Directory dir =
          await getApplicationDocumentsDirectory();

      final String path =
          "${dir.path}/$fileName";

      await Dio().download(
        url,
        path,
      );

      await OpenFilex.open(
        path,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text("${"unableToOpenPdf".tr()} $e"),
        ),
      );
    }
  }

  String getReportName(
    Map<String, dynamic> report,
    int index,
  ) {
    final String name =
        report["reportName"]?.toString().trim() ?? "";

    if (name.isNotEmpty) {
      return name;
    }

    // Do NOT show the uploaded Cloudinary/file-system filename
    // in the Patient UI. If reportName is missing (old data),
    // use a clean generic label instead.
    return "${"report".tr()} ${index + 1}";
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.black,

      appBar: AppBar(
        backgroundColor:
            Colors.black,

        foregroundColor:
            Colors.white,

        title: Text(
          "${getReportName(widget.reports[currentPage], currentPage)} "
          "(${currentPage + 1} / ${widget.reports.length})",
        ),
      ),

      body: PageView.builder(
        controller:
            pageController,

        itemCount:
            widget.reports.length,

        onPageChanged:
            (index) {
          setState(() {
            currentPage = index;
          });
        },

        itemBuilder:
            (context, index) {

          final report =
              widget.reports[index];

          final String url =
              report["fileUrl"]
                      ?.toString() ??
                  "";

          final String fileName =
              report["fileName"]
                      ?.toString() ??
                  "report".tr();

          final String reportName =
              getReportName(
            report,
            index,
          );

          // ----------------------------------------------------
          // PDF
          // ----------------------------------------------------

          if (isPdf(report)) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const Icon(
                    Icons
                        .picture_as_pdf,
                    color:
                        Colors.white,
                    size: 90,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 30,
                    ),
                    child: Column(
                      children: [
                        Text(
                          reportName,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                19,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),


                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  ElevatedButton.icon(
                    onPressed:
                        () =>
                            openPdf(
                              report,
                            ),

                    icon:
                        const Icon(
                      Icons.open_in_new,
                    ),

                    label:
                        Text(
                      "openPdf".tr(),
                    ),
                  ),
                ],
              ),
            );
          }

          // ----------------------------------------------------
          // IMAGE
          // ----------------------------------------------------

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,

            child:
                Center(
              child:
                  Image.network(
                url,

                fit:
                    BoxFit.contain,

                loadingBuilder:
                    (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress ==
                      null) {
                    return child;
                  }

                  return  Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          Colors.white,
                    ),
                  );
                },

                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return  Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [

                        Icon(
                          Icons
                              .broken_image_outlined,
                          color:
                              Colors.white,
                          size: 60,
                        ),

                        SizedBox(
                          height: 10,
                        ),

                        Text(
                          "failedToLoadReport".tr(),
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),

      // ========================================================
      // PAGE INDICATOR
      // ========================================================

      bottomNavigationBar:
          widget.reports.length > 1
              ? Container(
                  color:
                      Colors.black,

                  padding:
                      const EdgeInsets
                          .only(
                    bottom: 20,
                    top: 10,
                  ),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: List.generate(
                      widget.reports.length,
                      (index) {
                        return Container(
                          margin:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 4,
                          ),

                          width:
                              currentPage ==
                                      index
                                  ? 22
                                  : 8,

                          height: 8,

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : null,
    );
  }
}