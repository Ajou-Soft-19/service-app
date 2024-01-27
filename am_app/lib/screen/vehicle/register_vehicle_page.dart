import 'package:am_app/model/api/vehicle_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
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
        labelText: '국가 코드',
        prefixIcon: Icon(Icons.flag),
      ),
      items: const [
        DropdownMenuItem(
          value: 'ko-KR',
          child: Text('한국'),
        ),
        DropdownMenuItem(
          value: 'en-US',
          child: Text('미국'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _countryCode = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return '국가 코드를 선택해주세요.';
        }
        return null;
      },
    );
  }

  DropdownButtonFormField<String> buildVehicleTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _vehicleType,
      decoration: const InputDecoration(
        labelText: '차량 유형',
        prefixIcon: Icon(Icons.directions_car),
      ),
      items: const [
        DropdownMenuItem(
          value: 'LIGHTWEIGHT_CAR',
          child: Text('경차'),
        ),
        DropdownMenuItem(
          value: 'SMALL_CAR',
          child: Text('소형 차'),
        ),
        DropdownMenuItem(
          value: 'MEDIUM_CAR',
          child: Text('중형 차'),
        ),
        DropdownMenuItem(
          value: 'LARGE_CAR',
          child: Text('대형 차'),
        ),
        DropdownMenuItem(
          value: 'LARGE_TRUCK',
          child: Text('대형 트럭'),
        ),
        DropdownMenuItem(
          value: 'SPECIAL_TRUCK',
          child: Text('특수 트럭'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _vehicleType = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return '차량 유형을 선택해주세요.';
        }
        return null;
      },
    );
  }

  TextFormField buildLicenseNumberField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: '차량 번호',
        prefixIcon: Icon(Icons.format_list_numbered),
      ),
      onChanged: (value) {
        _licenseNumber = value;
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '차량 번호를 입력해주세요.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    double paddingSize = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('차량 정보 등록'),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: paddingSize, left: 16.0, right: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.directions_car,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                ),
                child: const Text(
                  '차량 등록',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
