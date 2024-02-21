# EPAS APP

- [EPAS APP](#epas-app)
  - [Test Account](#test-account)
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

## Test Account

| Role | Email | Password |
|------|-------|----------|
| `Emergency, Admin` | `adminepas@ajou.ac.kr` | `adminepas1234!?` |
| `Emergency` | `epas@ajou.ac.kr` | `1q2w3e4r!` |

By this account, you can test the emergency vehicle registration and the admin page. For more information, please refer to the following.

## Initial Page

| Location Permission Screen | Initial Screen                         | User Info Screen |
|-------------|---------------------------------|------------------------------------|
| ![Location Permission Screen](/img/initial1.jpeg) | ![Initial Screen](/img/initial2.jpeg) | ![User Info Screen](/img/initial3.jpeg) |
|You need to set location permissions to run the app.|This is the map page for general users. By pressing the settings button, you will be taken to the account information page.|You can log in or sign up here.|

## 1. Sign Up

| Account Creation Initial Screen | Account Creation Form                         | Account Creation Success   |
|-------------|---------------------------------|------------------------------------|
| ![Account Creation Initial Screen](/img/signup1.jpeg) | ![Account Creation Form](/img/signup2.jpeg) | ![Account Creation Success](/img/signup3.jpeg) |

## 2. Sign In

| Login Initial Screen | Login Form                         |
|-------------|---------------------------------|
| <img src="img/signin1.jpeg" width = "200"> | <img src="img/signin2.jpeg" width = "200"> |

## 3. User Info

### 3.1 General User

| General User Account | After Requesting<br> Emergency Vehicle<br> Authorization      |
|-------------|---------------------------------|
| <img src="img/generalUser1.jpeg" width = "200"> | <img src="img/generalUser2.jpeg" width = "200"> |

> Once the administrator approves the authorization, you can check the updated authorization status at Check Auth Request.

### 3.2 Emergency Auth User

| Emergency Vehicle Account |  
|-------------|
| <img src="img/emergencyUser1.jpeg" width = "200"> |
> You can select the vehicle to register as an emergency situation through the Select Vehicle button.

| Vehicle Selection | Vehicle Registration | Vehicle Registration Success |
|-------------|-----------------|---|
| ![Vehicle Selection](img/selectVehicle1.jpeg) | ![Vehicle Registration](img/selectVehicle2.jpeg) | ![Vehicle Registration Success](img/selectVehicle3.jpeg) |

### 3.3 Admin

| Admin Page |  
|-------------|
| <img src="img/adminUser.jpeg" width = "200"> |

#### 3.3.1 Admin Role Request Page

| Role Management Page |  
|-------------|
| <img src="img/adminRoleRequestListPage.jpeg" width = "500"> |

#### 3.3.2 Monitoring Page

| Initial Screen |  
|-------------|
| <img src="img/monitoringPage1.jpeg" width = "500"> |

| Vehicle Information |  
|-------------|
| <img src="img/monitoringPage2.jpeg" width = "500"> |
> The small dots on the screen represent vehicles. When you click a dot, the vehicle information pops up in a modal window.

| Dots | Explanation |
|------|-------------|
|<img src = "./am_app/assets/circle_red.png" width = "20">|Emergency Vehicles|
|<img src = "./am_app/assets/circle_blue.png" width = "20">|Not-Alerted Vehicles|
|<img src = "./am_app/assets/circle_black.png" width = "20">|Alerted Vehicles|

| Emergency Vehicle Confirmation |  
|-------------|
| <img src="img/monitoringPage3.jpeg" width = "500"> |
> You can see the path and alert boundary for each emergency vehicle.

- You can cancel the vehicle selection with the `Unselect` button.
- You can define the range of the area displayed on the screen with the `Filter` button.
- You can pin the screen to the selected vehicle with the `Pin` button.

## 4. Map Page

> The usage is the same as common navigation.

| Initial Screen | Location Search List | Route Search | Guide Start |Navigation End|
|---|---|---|---|---|
|![Initial Screen](/img/mapPage1.jpeg)|![Location Search List](/img/mapPage2.jpeg)|![Route Search](/img/mapPage3.jpeg)|![Guide Start](/img/mapPage4.jpeg)|![Navigation End](/img/mapPage5.jpeg)|
||You can select your desired destination.|The ETA(Estimated Time of Arrival) and Distance values are displayed. ||The guide ends when you arrive within 30m of the destination or press the back button.|

## 5. EPAS

> For general vehicles, you receive emergency situation alerts.

| First Alert Confirmation | Reflecting Emergency Vehicle Location | Multiple Emergency Situation Registration |
| --- | --- | --- |
| ![First Alert Confirmation](/img/alerted1.jpeg) | ![Reflecting Emergency Vehicle Location](/img/alerted2.jpeg) | ![Multiple Emergency Situation Registration](/img/alerted3.jpeg) |
|If the media sound is on, you will hear a beep and the current location of the emergency vehicle.| The current location of the emergency vehicle is reflected. | Multiple emergency vehicles are also reflected. |

> For emergency vehicles, you can send emergency situation alerts.

| Initial Screen | After Starting Navigation |
| --- | - |
|<img src="img/alerting1.jpeg" width = "200">|<img src="img/alerting2.jpeg" width = "200">|
