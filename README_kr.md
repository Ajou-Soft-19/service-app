# EPAS APP

- [EPAS APP](#epas-app)
  - [테스트 계정](#테스트-계정)
  - [Initial Page](#initial-page)
  - [1. Sign Up](#1-sign-up)
  - [2. Sign In](#2-sign-in)
  - [3. User Info](#3-user-info)
    - [3.1 General User](#31-general-user)
    - [3.2 Emergency Auth User](#32-emergency-auth-user)
    - [3.3 Admin](#33-admin)
      - [3.3.1 Admin Role Request Page](#331-admin-role-request-page)
      - [3.3.2 Monitoring Page](#332-monitoring-page)
  - [4. Map Page](#4-map-page)
  - [5. EPAS](#5-epas)

## 테스트 계정

| 권한 | 이메일 | 비밀번호 |
|------|-------|----------|
| `Emergency, Admin` | `adminepas@ajou.ac.kr` | `adminepas1234!?` |
| `Emergency` | `epas@ajou.ac.kr` | `1q2w3e4r!` |

이 계정을 통해 응급 차량 등록과 어드민 페이지를 테스트할 수 있습니다. 자세한 내용은 아래를 참고해주세요.

## Initial page

| 위치권한 화면 | 초기 화면                         | 유저 인포 화면 |
|-------------|---------------------------------|------------------------------------|
| ![위치권한 화면](/img/initial1.jpeg) | ![초기화면](/img/initial2.jpeg) | ![유저 인포 화면](/img/initial3.jpeg) |
|위치 권한 설정을 해야 앱을 실행할 수 있습니다.|일반 사용자의 맵 페이지로, 설정버튼을 누르면 계정 정보 페이지로 넘어갑니다. |로그인하거나 회원가입할 수 있습니다.|

## 1. Sign up

| 계정 생성 초기 화면 | 계정 생성 폼                         | 계정 생성 성공   |
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

| 차량 선택 | 차량 등록 | 차량 등록 성공 |
|-------------|-----------------|---|
| ![차량선택](img/selectVehicle1.jpeg) | ![차량등록](img/selectVehicle2.jpeg) | ![차량 등록 성공](img/selectVehicle3.jpeg) |

### 3.3 Admin

| 어드민 페이지 |  
|-------------|
| <img src="img/adminUser.jpeg" width = "200"> |

#### 3.3.1 Admin Role Request Page

| 권한 관리 페이지 |  
|-------------|
| <img src="img/adminRoleRequestListPage.jpeg" width = "500"> |

#### 3.3.2 Monitoring Page

| 초기화면 |  
|-------------|
| <img src="img/monitoringPage1.jpeg" width = "500"> |

| 차량 정보 |  
|-------------|
| <img src="img/monitoringPage2.jpeg" width = "500"> |
> 화면 위에 작은 점들은 차량으로, 점을 누르면 차량 정보가 모달 창이 뜹니다.

| Dots | Explanation |
|------|-------------|
|<img src = "./am_app/assets/circle_red.png" width = "20">|Emergency Vehicles|
|<img src = "./am_app/assets/circle_blue.png" width = "20">|Not-Alerted Vehicles|
|<img src = "./am_app/assets/circle_black.png" width = "20">|Alerted Vehicles|

| 긴급차량 별 확인 |  
|-------------|
| <img src="img/monitoringPage3.jpeg" width = "500"> |
> 응급차 별로 경로와 알림 경계를 볼 수 있습니다.  

- `Unselect` 버튼으로 차량 선택 버튼을 취소할 수 있습니다.  
- `Filter` 버튼으로 화면에 표시되는 영역의 범위를 정합니다.  
- `Pin` 버튼으로 선택한 차량을 중심으로 화면을 고정합니다.

## 4. Map Page

> 일반적인 네비게이션 사용법과 동일합니다.

| 초기화면 | 위치 검색 리스트 | 경로 탐색 | 가이드 시작 |네비게이션 종료|
|---|---|---|---|---|
|![초기화면](/img/mapPage1.jpeg)|![위치 검색 리스트](/img/mapPage2.jpeg)|![경로 탐색](/img/mapPage3.jpeg)|![가이드 시작](/img/mapPage4.jpeg)|![네비게이션 종료](/img/mapPage5.jpeg)|
||원하는 목적지를 선택할 수 있습니다.|ETA(Estimated Time of Arrival), Distance 값이 나옵니다. ||뒤로가기 버튼이나 목적지 30m 부근에 도착하면 가이드를 종료합니다.|

## 5. EPAS

> 일반 차량일 경우, 응급 상황의 알림을 받습니다.

| 첫 알림 확인 | 응급 차량 위치 반영 | 여러 응급 상황 등록 |
| --- | --- | --- |
| ![첫 알림 확인](/img/alerted1.jpeg) | ![응급 차량 위치 반영](/img/alerted2.jpeg) | ![여러 응급 상황 등록](/img/alerted3.jpeg) |
|미디어 소리를 켜놓으면 비프음과 응급 차량의 현 위치를 말해줍니다.| 응급차의 현 위치를 반영합니다. | 여러 응급 차량도 반영됩니다. |

> 응급 차량일 경우, 응급 상황의 알림을 발송할 수 있습니다.

| 초기 화면 | 네비게이션 시작 후 |
| --- | - |
| <img src="img/alerting1.jpeg" width = "200">|<img src="img/alerting2.jpeg" width = "200">|
