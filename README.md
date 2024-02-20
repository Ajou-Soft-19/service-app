# service-app

## Initial page
| 위치권한 화면 | 초기 화면                         | 계정 생성 버튼 클릭   | 
|-------------|---------------------------------|------------------------------------|
| ![위치권한 화면](/img/initial1.jpeg) | ![초기화면](/img/initial2.jpeg) | ![계정 생성 버튼 클릭](/img/initial3.jpeg) |
|위치 권한 설정을 해야 앱을 실행할 수 있습니다.|일반 사용자의 맵 페이지로, 설정버튼을 누르면 계정 정보 페이지로 넘어갑니다. |로그인하거나 회원가입할 수 있습니다.|

## 1. Sign up
| 계정 생성 초기 화면 | 계정 생성 폼                         | 계정 생성 버튼 클릭   | 
|-------------|---------------------------------|------------------------------------|
| ![계정 생성 초기화면](/img/signup1.jpeg) | ![계정 생성 폼](/img/signup2.jpeg) | ![계정 생성 성공](/img/signup3.jpeg) |

## 2. Sign in
| 로그인 초기 화면 | 로그인 폼                         | 
|-------------|---------------------------------|
| <img src="img/signin1.jpeg" width = "200"> | <img src="img/signin2.jpeg" width = "200"> | 
## 3. User Info

### 3.1 General User
| 일반사용자 계정 | 응급차량 권한 등록 권한 요청 후      | 
|-------------|---------------------------------|
| <img src="img/generalUser1.jpeg" width = "200"> | <img src="img/generalUser2.jpeg" width = "200"> | 
> 관리자가 권한을 수락하면, Check Auth Request로 권한이 수정된 것을 확인할 수 있습니다.
### 3.2 Emergency Auth User
| 응급차량 계정 |  
|-------------|
| <img src="img/emergencyUser1.jpeg" width = "200"> | 
> 차량 선택 버튼을 통해 응급 상황으로 등록할 차량을 선택할 수 있다.

| 차량 선택 | 차량 등록      | 
|-------------|---------------------------------|
| <img src="img/SelectVehicle1.jpeg" width = "200"> | <img src="img/SelectVehicle2.jpeg" width = "200"> | 

### 3.3 Admin

| 어드민 페이지 |  
|-------------|
| <img src="img/emergencyUser1.jpeg" width = "200"> |

#### 3.3.1 Admin Role Request Page

| 어드민 페이지 |  
|-------------|
| <img src="img/adminRoleRequestListPage.jpeg" width = "200"> |


#### 3.3.2 Monitoring Page

| 어드민 계정 | 권한 관리 페이지   | 계정 생성 버튼 클릭 | 
|-------------|---------------------------------|------------------------------------|
| ![위치권한 화면](/img/initial1.jpeg) | ![초기화면](/img/initial2.jpeg) | ![계정 생성 버튼 클릭](/img/initial3.jpeg) |
| 위치 권한 설정을 해야 앱을 실행할 수 있습니다. | 일반 사용자의 맵 페이지로, 설정버튼을 누르면 계정 정보 페이지로 넘어갑니다. | 로그인하거나 회원가입할 수 있습니다. |

## Mappage

공통적인 부분 설명
> 정적인화면
  - 설정버튼, 검색, 내위치이동버튼
> 검색하고 경로찾기

  - 일반적인 네비게이션 사용법과 동일
  - 목적지 설정
  - startnavigation 하면 네비가이드 시작
  - 뒤로가기나 목적지도착30m 부근 가이드 종료

### Emergency User

응급권한이 있는 경우, 차량을 선택한뒤 알림발송서비스를 이용할 수 있다.
