import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'package:healthhome/pages/add_address_page.dart'
    as add_address;

class MyAddressesPage extends StatefulWidget {
  final String userId;

  const MyAddressesPage({
    super.key,
    required this.userId,
  });

  @override
  State<MyAddressesPage> createState() =>
      _MyAddressesPageState();
}

class _MyAddressesPageState
    extends State<MyAddressesPage> {
  // ============================================================
  // COLORS
  // ============================================================

  final Color primaryColor =
      const Color(0xff00C2CB);

  // ============================================================
  // VARIABLES
  // ============================================================

  List<Map<String, dynamic>> addresses = [];

  bool isLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  // ============================================================
  // LOAD ADDRESSES
  // ============================================================

  Future<void> _loadAddresses() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response =
          await ApiService.getAddresses(
        widget.userId,
      );

      if (!mounted) return;

      if (response["success"] == true) {
        final dynamic data =
            response["addresses"];

        if (data is List) {
          addresses = data
              .whereType<Map>()
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();
        } else {
          addresses = [];
        }

        setState(() {});
      } else {
        _showMessage(
          response["message"] ??
              "Unable to load addresses.",
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          "Unable to load addresses.",
        );
      }

      debugPrint(
        "LOAD ADDRESSES ERROR: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // ADD ADDRESS
  // ============================================================

  Future<void> _addAddress() async {
    final result =
        await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            add_address.AddAddressPage(
          userId: widget.userId,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadAddresses();
    }
  }

  // ============================================================
  // EDIT ADDRESS
  // ============================================================

  Future<void> _editAddress(
    Map<String, dynamic> address,
  ) async {
    final result =
        await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            add_address.AddAddressPage(
          userId: widget.userId,
          existingAddress: address,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadAddresses();
    }
  }

  // ============================================================
  // SET DEFAULT ADDRESS
  // ============================================================

  Future<void> _setDefaultAddress(
    Map<String, dynamic> address,
  ) async {
    final String? addressId =
        address["_id"]?.toString();

    if (addressId == null ||
        addressId.isEmpty) {
      _showMessage(
        "Address ID not found.",
      );
      return;
    }

    try {
      final response =
          await ApiService.setDefaultAddress(
        userId: widget.userId,
        addressId: addressId,
      );

      if (!mounted) return;

      if (response["success"] == true) {
        await _loadAddresses();

        if (mounted) {
          _showMessage(
            "Default address updated.",
          );
        }
      } else {
        _showMessage(
          response["message"] ??
              "Unable to update default address.",
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          "Unable to update default address.",
        );
      }

      debugPrint(
        "SET DEFAULT ADDRESS ERROR: $e",
      );
    }
  }

  // ============================================================
  // DELETE ADDRESS
  // ============================================================

  Future<void> _deleteAddress(
    Map<String, dynamic> address,
  ) async {
    final String? addressId =
        address["_id"]?.toString();

    if (addressId == null ||
        addressId.isEmpty) {
      _showMessage(
        "Address ID not found.",
      );
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Text(
            "Delete Address?",
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this saved address?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                "Delete",
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final response =
          await ApiService.deleteAddress(
        userId: widget.userId,
        addressId: addressId,
      );

      if (!mounted) return;

      if (response["success"] == true) {
        await _loadAddresses();

        if (mounted) {
          _showMessage(
            "Address deleted successfully.",
          );
        }
      } else {
        _showMessage(
          response["message"] ??
              "Unable to delete address.",
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          "Unable to delete address.",
        );
      }

      debugPrint(
        "DELETE ADDRESS ERROR: $e",
      );
    }
  }

  // ============================================================
  // ADDRESS ICON
  // ============================================================

  IconData _getAddressIcon(
    String label,
  ) {
    switch (label.toLowerCase()) {
      case "home":
        return Icons.home_rounded;

      case "work":
        return Icons.work_rounded;

      case "college":
        return Icons.school_rounded;

      default:
        return Icons.location_on_rounded;
    }
  }

  // ============================================================
  // ADDRESS CARD
  // ============================================================

  Widget _buildAddressCard(
    Map<String, dynamic> address,
  ) {
    final String label =
        address["label"]?.toString() ??
            "Other";

    final String fullAddress =
        address["fullAddress"]?.toString() ??
            "";

    final String landmark =
        address["landmark"]?.toString() ??
            "";

    final String city =
        address["city"]?.toString() ??
            "";

    final String state =
        address["state"]?.toString() ??
            "";

    final String pincode =
        address["pincode"]?.toString() ??
            "";

    final bool isDefault =
        address["isDefault"] == true;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: isDefault
              ? primaryColor
              : Colors.grey.shade200,
          width:
              isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.04),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                      BoxDecoration(
                    color: primaryColor
                        .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    _getAddressIcon(
                      label,
                    ),
                    color:
                        primaryColor,
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ),

                          if (isDefault) ...[
                            const SizedBox(
                              width: 8,
                            ),
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    primaryColor
                                        .withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child: Text(
                                "DEFAULT",
                                style:
                                    TextStyle(
                                  color:
                                      primaryColor,
                                  fontSize:
                                      10,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        fullAddress,
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade700,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ==================================================
            // LANDMARK
            // ==================================================

            if (landmark.isNotEmpty) ...[
              const SizedBox(
                height: 12,
              ),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      "Landmark: $landmark",
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ==================================================
            // CITY / STATE / PINCODE
            // ==================================================

            if (city.isNotEmpty ||
                state.isNotEmpty ||
                pincode.isNotEmpty) ...[
              const SizedBox(
                height: 8,
              ),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Icon(
                    Icons
                        .location_city_outlined,
                    size: 18,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      [
                        if (city.isNotEmpty)
                          city,
                        if (state.isNotEmpty)
                          state,
                        if (pincode.isNotEmpty)
                          pincode,
                      ].join(", "),
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(
              height: 15,
            ),

            Divider(
              height: 1,
              color:
                  Colors.grey.shade200,
            ),

            const SizedBox(
              height: 5,
            ),

            // ==================================================
            // ACTIONS
            // ==================================================

            Row(
              children: [
                if (!isDefault)
                  TextButton.icon(
                    onPressed: () =>
                        _setDefaultAddress(
                      address,
                    ),
                    icon: Icon(
                      Icons.star_border_rounded,
                      size: 19,
                      color:
                          primaryColor,
                    ),
                    label: Text(
                      "Set Default",
                      style: TextStyle(
                        color:
                            primaryColor,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .check_circle_rounded,
                          size: 18,
                          color:
                              Colors.green,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          "Default",
                          style: TextStyle(
                            color:
                                Colors.green
                                    .shade700,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                IconButton(
                  tooltip: "Edit",
                  onPressed: () =>
                      _editAddress(
                    address,
                  ),
                  icon: Icon(
                    Icons.edit_outlined,
                    color:
                        Colors.grey.shade700,
                  ),
                ),

                IconButton(
                  tooltip: "Delete",
                  onPressed: () =>
                      _deleteAddress(
                    address,
                  ),
                  icon: const Icon(
                    Icons
                        .delete_outline_rounded,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration:
                  BoxDecoration(
                color: primaryColor
                    .withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .location_on_outlined,
                size: 45,
                color:
                    primaryColor,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              "No saved addresses",
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              "Add your Home, Work, College or other address for faster orders and lab bookings.",
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            ElevatedButton.icon(
              onPressed:
                  _addAddress,
              icon: const Icon(
                Icons
                    .add_location_alt_outlined,
              ),
              label: const Text(
                "Add Address",
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryColor,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF7F9FA),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,
        elevation: 0,
        title: const Text(
          "My Addresses",
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                _addAddress,
            tooltip:
                "Add Address",
            icon: Icon(
              Icons
                  .add_location_alt_outlined,
              color:
                  primaryColor,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: primaryColor,
        onRefresh:
            _loadAddresses,
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : addresses.isEmpty
                ? ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height:
                            MediaQuery.of(
                          context,
                        ).size.height *
                            0.25,
                      ),
                      _buildEmptyState(),
                    ],
                  )
                : ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      100,
                    ),
                    children: [
                      // ==================================================
                      // INFO CARD
                      // ==================================================

                      Container(
                        padding:
                            const EdgeInsets
                                .all(17),
                        decoration:
                            BoxDecoration(
                          color: primaryColor
                              .withValues(
                            alpha: 0.08,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .local_shipping_outlined,
                              color:
                                  primaryColor,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Text(
                                "Choose an address for medicine delivery and lab bookings.",
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade800,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      Text(
                        "${addresses.length} Saved Address${addresses.length == 1 ? '' : 'es'}",
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      ...addresses.map(
                        (address) =>
                            _buildAddressCard(
                          address,
                        ),
                      ),
                    ],
                  ),
      ),

      // ============================================================
      // ADD ADDRESS BUTTON
      // ============================================================

      floatingActionButton:
          addresses.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed:
                      _addAddress,
                  backgroundColor:
                      primaryColor,
                  foregroundColor:
                      Colors.white,
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text(
                    "Add Address",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                )
              : null,
    );
  }
}