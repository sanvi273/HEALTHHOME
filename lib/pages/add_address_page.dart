import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';

class AddAddressPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? existingAddress;

  const AddAddressPage({
    super.key,
    required this.userId,
    this.existingAddress,
  });

  @override
  State<AddAddressPage> createState() =>
      _AddAddressPageState();
}

class _AddAddressPageState
    extends State<AddAddressPage> {
  final Geocoding geocoding = Geocoding();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController landmarkController =
      TextEditingController();

  final TextEditingController cityController =
      TextEditingController();

  final TextEditingController stateController =
      TextEditingController();

  final TextEditingController pincodeController =
      TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  final Color primaryColor =
      const Color(0xff00C2CB);

  String selectedLabel = "Home";

  bool isDefault = false;
  bool isLoadingLocation = false;
  bool isSaving = false;

  double? latitude;
  double? longitude;

  // ============================================================
  // EDIT MODE
  // ============================================================

  bool get isEditing =>
      widget.existingAddress != null;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadExistingAddress();
  }

  // ============================================================
  // LOAD EXISTING ADDRESS
  // ============================================================

  void _loadExistingAddress() {
    final address =
        widget.existingAddress;

    if (address == null) {
      return;
    }

    selectedLabel =
        address["label"]?.toString() ??
            "Home";

    addressController.text =
        address["fullAddress"]?.toString() ??
            "";

    landmarkController.text =
        address["landmark"]?.toString() ??
            "";

    cityController.text =
        address["city"]?.toString() ??
            "";

    stateController.text =
        address["state"]?.toString() ??
            "";

    pincodeController.text =
        address["pincode"]?.toString() ??
            "";

    isDefault =
        address["isDefault"] == true;

    if (address["latitude"] != null) {
      latitude = double.tryParse(
        address["latitude"].toString(),
      );
    }

    if (address["longitude"] != null) {
      longitude = double.tryParse(
        address["longitude"].toString(),
      );
    }
  }

  // ============================================================
  // LOCATION PERMISSION
  // ============================================================

  Future<bool>
      _checkLocationPermission() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              "Location is turned off",
            ),
            content: const Text(
              "Please enable location services and try again.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  await Geolocator
                      .openLocationSettings();
                },
                child:
                    const Text("Settings"),
              ),
            ],
          );
        },
      );

      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();

      if (permission ==
          LocationPermission.denied) {
        if (mounted) {
          _showMessage(
            "Location permission denied.",
          );
        }

        return false;
      }
    }

    if (permission ==
        LocationPermission.deniedForever) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              "Location Permission Required",
            ),
            content: const Text(
              "Location permission is permanently denied. "
              "Please enable it from app settings.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child:
                    const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  await Geolocator
                      .openAppSettings();
                },
                child: const Text(
                  "Open Settings",
                ),
              ),
            ],
          );
        },
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void>
      _useCurrentLocation() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isLoadingLocation = true;
    });

    try {
      final permission =
          await _checkLocationPermission();

      if (!permission) {
        return;
      }

      final Position position =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      latitude =
          position.latitude;

      longitude =
          position.longitude;

      // Convert coordinates
      // into readable address.
      final List<Placemark> places =
    await geocoding.placemarkFromCoordinates(
  position.latitude,
  position.longitude,
);

      if (places.isEmpty) {
        _showMessage(
          "Unable to find address for this location.",
        );

        return;
      }

      final Placemark place =
          places.first;

      final List<String>
          addressParts = [];

      if (place.name != null &&
          place.name!
              .trim()
              .isNotEmpty) {
        addressParts.add(
          place.name!.trim(),
        );
      }

      if (place.street != null &&
          place.street!
              .trim()
              .isNotEmpty &&
          place.street!
              .trim() !=
              place.name?.trim()) {
        addressParts.add(
          place.street!.trim(),
        );
      }

      if (place.subLocality != null &&
          place.subLocality!
              .trim()
              .isNotEmpty) {
        addressParts.add(
          place.subLocality!.trim(),
        );
      }

      addressController.text =
          addressParts.join(", ");

      cityController.text =
          place.locality?.trim() ??
              "";

      if (cityController
          .text
          .isEmpty) {
        cityController.text =
            place.subAdministrativeArea
                    ?.trim() ??
                "";
      }

      stateController.text =
          place.administrativeArea
                  ?.trim() ??
              "";

      pincodeController.text =
          place.postalCode?.trim() ??
              "";

      if (mounted) {
        _showMessage(
          "Location detected. You can edit the address before saving.",
        );
      }
    } catch (e) {
      debugPrint(
        "CURRENT LOCATION ERROR: $e",
      );

      if (mounted) {
        _showMessage(
          "Unable to get current location.",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE ADDRESS
  // ============================================================

  Future<void> _saveAddress() async {
    FocusScope.of(context).unfocus();

    final fullAddress =
        addressController.text.trim();

    final landmark =
        landmarkController.text.trim();

    final city =
        cityController.text.trim();

    final state =
        stateController.text.trim();

    final pincode =
        pincodeController.text.trim();

    if (fullAddress.isEmpty) {
      _showMessage(
        "Please enter your full address.",
      );
      return;
    }

    if (city.isEmpty) {
      _showMessage(
        "Please enter your city.",
      );
      return;
    }

    if (state.isEmpty) {
      _showMessage(
        "Please enter your state.",
      );
      return;
    }

    if (pincode.isEmpty) {
      _showMessage(
        "Please enter your pincode.",
      );
      return;
    }

    if (!RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(pincode)) {
      _showMessage(
        "Please enter a valid 6-digit pincode.",
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      Map<String, dynamic>
          response;

      // ========================================================
      // UPDATE
      // ========================================================

      if (isEditing) {
        final addressId =
            widget.existingAddress?["_id"]
                ?.toString();

        if (addressId == null ||
            addressId.isEmpty) {
          _showMessage(
            "Address ID not found.",
          );

          return;
        }

        response =
            await ApiService.updateAddress(
          userId: widget.userId,
          addressId: addressId,
          label: selectedLabel,
          fullAddress: fullAddress,
          landmark: landmark,
          city: city,
          state: state,
          pincode: pincode,
          latitude: latitude,
          longitude: longitude,
          isDefault: isDefault,
        );
      }

      // ========================================================
      // ADD
      // ========================================================

      else {
        response =
            await ApiService.addAddress(
          userId: widget.userId,
          label: selectedLabel,
          fullAddress: fullAddress,
          landmark: landmark,
          city: city,
          state: state,
          pincode: pincode,
          latitude: latitude,
          longitude: longitude,
          isDefault: isDefault,
        );
      }

      if (!mounted) return;

      if (response["success"] == true) {
        _showMessage(
          isEditing
              ? "Address updated successfully."
              : "Address added successfully.",
        );

        Navigator.pop(
          context,
          response["address"] ??
              response["addresses"],
        );
      } else {
        _showMessage(
          response["message"] ??
              "Unable to save address.",
        );
      }
    } catch (e) {
      debugPrint(
        "SAVE ADDRESS ERROR: $e",
      );

      if (mounted) {
        _showMessage(
          "Something went wrong while saving the address.",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
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
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // LABEL ICON
  // ============================================================

  IconData _getLabelIcon(
    String label,
  ) {
    switch (label) {
      case "Home":
        return Icons.home_rounded;

      case "Work":
        return Icons.work_rounded;

      case "College":
        return Icons.school_rounded;

      case "Other":
        return Icons.location_on_rounded;

      default:
        return Icons.location_on_rounded;
    }
  }

  // ============================================================
  // LABEL BUTTON
  // ============================================================

  Widget _buildLabelButton(
    String label,
  ) {
    final selected =
        selectedLabel == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLabel = label;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? primaryColor.withValues(
                  alpha: 0.10,
                )
              : Colors.white,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade300,
            width:
                selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              _getLabelIcon(label),
              size: 19,
              color: selected
                  ? primaryColor
                  : Colors.grey.shade700,
            ),
            const SizedBox(
              width: 7,
            ),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? primaryColor
                    : Colors.grey.shade800,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            keyboardType,
        maxLines: maxLines,
        decoration:
            InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: primaryColor,
          ),
          filled: true,
          fillColor:
              Colors.white,
          contentPadding:
              const EdgeInsets
                  .symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide: BorderSide(
              color:
                  Colors.grey.shade300,
            ),
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide: BorderSide(
              color:
                  Colors.grey.shade300,
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide: BorderSide(
              color: primaryColor,
              width: 1.5,
            ),
          ),
        ),
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
        title: Text(
          isEditing
              ? "Edit Address"
              : "Add New Address",
          style: const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // LOCATION CARD
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 12,
                      offset:
                          const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      "Where should we deliver?",
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      "Use your current location or enter your address manually.",
                      style:
                          TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          OutlinedButton
                              .icon(
                        onPressed:
                            isLoadingLocation
                                ? null
                                : _useCurrentLocation,
                        icon:
                            isLoadingLocation
                                ? const SizedBox(
                                    width:
                                        18,
                                    height:
                                        18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : Icon(
                                    Icons
                                        .my_location,
                                    color:
                                        primaryColor,
                                  ),
                        label:
                            Text(
                          isLoadingLocation
                              ? "Detecting location..."
                              : "Use Current Location",
                          style:
                              TextStyle(
                            color:
                                primaryColor,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                        style:
                            OutlinedButton
                                .styleFrom(
                          side:
                              BorderSide(
                            color:
                                primaryColor,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical:
                                14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              // ==================================================
              // LABEL
              // ==================================================

              const Text(
                "Save address as",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildLabelButton(
                    "Home",
                  ),
                  _buildLabelButton(
                    "Work",
                  ),
                  _buildLabelButton(
                    "College",
                  ),
                  _buildLabelButton(
                    "Other",
                  ),
                ],
              ),

              const SizedBox(
                height: 22,
              ),

              // ==================================================
              // FULL ADDRESS
              // ==================================================

              _buildTextField(
                controller:
                    addressController,
                label:
                    "Full Address",
                hint:
                    "House / Flat / Building / Street",
                icon: Icons
                    .location_on_outlined,
                maxLines: 3,
              ),

              // ==================================================
              // LANDMARK
              // ==================================================

              _buildTextField(
                controller:
                    landmarkController,
                label:
                    "Landmark",
                hint:
                    "Nearby landmark (optional)",
                icon:
                    Icons.place_outlined,
              ),

              // ==================================================
              // CITY
              // ==================================================

              _buildTextField(
                controller:
                    cityController,
                label: "City",
                hint:
                    "Enter city",
                icon: Icons
                    .location_city_outlined,
              ),

              // ==================================================
              // STATE
              // ==================================================

              _buildTextField(
                controller:
                    stateController,
                label: "State",
                hint:
                    "Enter state",
                icon:
                    Icons.map_outlined,
              ),

              // ==================================================
              // PINCODE
              // ==================================================

              _buildTextField(
                controller:
                    pincodeController,
                label:
                    "Pincode",
                hint:
                    "6-digit pincode",
                icon: Icons
                    .markunread_mailbox_outlined,
                keyboardType:
                    TextInputType.number,
              ),

              // ==================================================
              // DEFAULT
              // ==================================================

              Container(
                margin:
                    const EdgeInsets
                        .only(
                  bottom: 20,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color: Colors
                        .grey
                        .shade300,
                  ),
                ),
                child:
                    SwitchListTile(
                  value:
                      isDefault,
                  activeThumbColor:
                      primaryColor,
                  onChanged:
                      (value) {
                    setState(() {
                      isDefault =
                          value;
                    });
                  },
                  title:
                      const Text(
                    "Make this my default address",
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                  subtitle:
                      const Text(
                    "Use automatically for orders and lab bookings.",
                  ),
                  secondary:
                      Icon(
                    Icons
                        .star_rounded,
                    color: isDefault
                        ? primaryColor
                        : Colors.grey,
                  ),
                ),
              ),

              // ==================================================
              // SAVE
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 54,
                child:
                    ElevatedButton(
                  onPressed:
                      isSaving
                          ? null
                          : _saveAddress,
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        primaryColor,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                  ),
                  child:
                      isSaving
                          ? const SizedBox(
                              width:
                                  22,
                              height:
                                  22,
                              child:
                                  CircularProgressIndicator(
                                color: Colors
                                    .white,
                                strokeWidth:
                                    2.5,
                              ),
                            )
                          : Text(
                              isEditing
                                  ? "Update Address"
                                  : "Save Address",
                              style:
                                  const TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    addressController.dispose();
    landmarkController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();

    super.dispose();
  }
}