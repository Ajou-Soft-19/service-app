import 'package:am_app/model/api/vehicle_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/screen/asset/app_bar.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterVehiclePage extends StatefulWidget {
  const RegisterVehiclePage({super.key});

  @override
  _RegisterVehiclePageState createState() => _RegisterVehiclePageState();
}

class _RegisterVehiclePageState extends State<RegisterVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final vehicleApi = VehicleApi();

  String? _countryCode;
  String? _vehicleType;
  String _licenseNumber = '';

  DropdownButtonFormField<String> buildCountryCodeDropdown() {
    return DropdownButtonFormField<String>(
      value: _countryCode,
      decoration: const InputDecoration(
        labelText: 'National Code',
        prefixIcon: Icon(Icons.flag),
      ),
      items: const [
        DropdownMenuItem(
          value: 'ko-KR',
          child: Text('한국'),
        ),
        DropdownMenuItem(
          value: 'en-US',
          child: Text('United States'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _countryCode = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a country code.';
        }
        return null;
      },
    );
  }

  DropdownButtonFormField<String> buildVehicleTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _vehicleType,
      decoration: const InputDecoration(
        labelText: 'Vehicle Type',
        prefixIcon: Icon(Icons.directions_car),
      ),
      items: const [
        DropdownMenuItem(
          value: 'AMBULANCE',
          child: Text('AMBULANCE'),
        ),
        DropdownMenuItem(
          value: 'FIRE_TRUCK_MEDIUM',
          child: Text('FIRE_TRUCK_MEDIUM'),
        ),
        DropdownMenuItem(
          value: 'FIRE_TRUCK_LARGE',
          child: Text('FIRE_TRUCK_LARGE'),
        ),
        DropdownMenuItem(
          value: 'LIGHTWEIGHT_CAR',
          child: Text('LIGHTWEIGHT_CAR'),
        ),
        DropdownMenuItem(
          value: 'SMALL_CAR',
          child: Text('SMALL_CAR'),
        ),
        DropdownMenuItem(
          value: 'MEDIUM_CAR',
          child: Text('MEDIUM_CAR'),
        ),
        DropdownMenuItem(
          value: 'LARGE_CAR',
          child: Text('LARGE_CAR'),
        ),
        DropdownMenuItem(
          value: 'LARGE_TRUCK',
          child: Text('LARGE_TRUCK'),
        ),
        DropdownMenuItem(
          value: 'SPECIAL_TRUCK',
          child: Text('SPECIAL_TRUCK'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _vehicleType = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a vehicle type.';
        }
        return null;
      },
    );
  }

  TextFormField buildLicenseNumberField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'License Number',
        prefixIcon: Icon(Icons.format_list_numbered),
      ),
      onChanged: (value) {
        _licenseNumber = value;
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a license number.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Register',
        backButton: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                EdgeInsets.only(left: 16.0, right: 16.0, bottom: height * 0.1),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      getIconBasedOnVehicleType(),
                      size: 50,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    buildCountryCodeDropdown(),
                    const SizedBox(height: 10),
                    buildVehicleTypeDropdown(),
                    const SizedBox(height: 10),
                    buildLicenseNumberField(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            await vehicleApi.registerVehicle(_countryCode!,
                                _licenseNumber, _vehicleType!, userProvider);
                            Navigator.pop(context);
                          } catch (e) {
                            Assets().showErrorSnackBar(context, e.toString());
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 10),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// 차량 타입에 따른 아이콘 반환 함수
  IconData getIconBasedOnVehicleType() {
    switch (_vehicleType) {
      case "LIGHTWEIGHT_CAR":
      case "SMALL_CAR":
      case "MEDIUM_CAR":
      case "LARGE_CAR":
        return Icons.directions_car;
      case "LARGE_TRUCK":
      case "SPECIAL_TRUCK":
        return Icons.directions_bus;
      case "AMBULANCE":
        return Icons.local_hospital;
      case "FIRE_TRUCK_MEDIUM":
      case "FIRE_TRUCK_LARGE":
        return Icons.local_fire_department;
      default:
        return Icons.directions_car;
    }
  }
}
