import UIKit
import Flutter
import GoogleMaps
import CoreLocation

@UIApplicationMain
class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("MY_APIKEY")
        GeneratedPluginRegistrant.register(with: self)

        // CLLocationManager의 위임자로 AppDelegate를 설정
        locationManager.delegate = self

        // 권한 상태에 따른 처리를 수행
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            // 권한 상태가 결정되지 않은 경우, 권한 요청
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // 권한이 제한되거나 거부된 경우, 사용자에게 알리거나 다른 조치를 취함
            break
        case .authorizedWhenInUse, .authorizedAlways:
            // 권한이 허용된 경우, 필요한 작업을 수행
            break
        @unknown default:
            break
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // 위치 서비스 접근 권한 상태가 변경되었을 때 호출되는 메소드
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined, .restricted, .denied:
            // 권한이 결정되지 않았거나 제한되거나 거부된 경우
            break
        case .authorizedAlways, .authorizedWhenInUse:
            // 권한이 허용된 경우
            break
        @unknown default:
            break
        }
    }
}
