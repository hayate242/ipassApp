//#include "application.h"
//#include <Time.h>
/*
 * Copyright (c) 2016 RedBear
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
 * to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 * and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
 * IN THE SOFTWARE.
 */
 
/*
 * Download RedBear "BLE Controller" APP from APP store(IOS)/Play Store(Android) to play with this sketch
 */
 
/******************************************************
 *                      Macros
 ******************************************************/
#if defined(ARDUINO) 
SYSTEM_MODE(SEMI_AUTOMATIC); 
//SYSTEM_MODE(MANUAL);
#endif

/* 
 * BLE peripheral preferred connection parameters:
 *     - Minimum connection interval = MIN_CONN_INTERVAL * 1.25 ms, where MIN_CONN_INTERVAL ranges from 0x0006 to 0x0C80
 *     - Maximum connection interval = MAX_CONN_INTERVAL * 1.25 ms,  where MAX_CONN_INTERVAL ranges from 0x0006 to 0x0C80
 *     - The SLAVE_LATENCY ranges from 0x0000 to 0x03E8
 *     - Connection supervision timeout = CONN_SUPERVISION_TIMEOUT * 10 ms, where CONN_SUPERVISION_TIMEOUT ranges from 0x000A to 0x0C80
 */
#define MIN_CONN_INTERVAL          0x0028 // 50ms.
#define MAX_CONN_INTERVAL          0x0190 // 500ms.
#define SLAVE_LATENCY              0x0000 // No slave latency.
#define CONN_SUPERVISION_TIMEOUT   0x03E8 // 10s.

// Learn about appearance: http://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.gap.appearance.xml
#define BLE_PERIPHERAL_APPEARANCE  BLE_APPEARANCE_UNKNOWN

#define BLE_DEVICE_NAME            "iPass-Door123456"

#define CHARACTERISTIC1_MAX_LEN    15
#define CHARACTERISTIC2_MAX_LEN    15
#define TXRX_BUF_LEN               15

/******************************************************
 *              BLE Variable Definitions
 ******************************************************/
static uint8_t service1_uuid[16]    = { 0x71,0x3d,0x00,0x00,0x50,0x3e,0x4c,0x75,0xba,0x94,0x31,0x48,0xf1,0x8d,0x94,0x1e };
static uint8_t service1_tx_uuid[16] = { 0x71,0x3d,0x00,0x03,0x50,0x3e,0x4c,0x75,0xba,0x94,0x31,0x48,0xf1,0x8d,0x94,0x1e };
static uint8_t service1_rx_uuid[16] = { 0x71,0x3d,0x00,0x02,0x50,0x3e,0x4c,0x75,0xba,0x94,0x31,0x48,0xf1,0x8d,0x94,0x1e };

// GAP and GATT characteristics value
static uint8_t  appearance[2] = { 
  LOW_BYTE(BLE_PERIPHERAL_APPEARANCE), 
  HIGH_BYTE(BLE_PERIPHERAL_APPEARANCE) 
};

static uint8_t  change[4] = {
  0x00, 0x00, 0xFF, 0xFF
};

static uint8_t  conn_param[8] = {
  LOW_BYTE(MIN_CONN_INTERVAL), HIGH_BYTE(MIN_CONN_INTERVAL), 
  LOW_BYTE(MAX_CONN_INTERVAL), HIGH_BYTE(MAX_CONN_INTERVAL), 
  LOW_BYTE(SLAVE_LATENCY), HIGH_BYTE(SLAVE_LATENCY), 
  LOW_BYTE(CONN_SUPERVISION_TIMEOUT), HIGH_BYTE(CONN_SUPERVISION_TIMEOUT)
};

/* 
 * BLE peripheral advertising parameters:
 *     - advertising_interval_min: [0x0020, 0x4000], default: 0x0800, unit: 0.625 msec
 *     - advertising_interval_max: [0x0020, 0x4000], default: 0x0800, unit: 0.625 msec
 *     - advertising_type: 
 *           BLE_GAP_ADV_TYPE_ADV_IND 
 *           BLE_GAP_ADV_TYPE_ADV_DIRECT_IND 
 *           BLE_GAP_ADV_TYPE_ADV_SCAN_IND 
 *           BLE_GAP_ADV_TYPE_ADV_NONCONN_IND
 *     - own_address_type: 
 *           BLE_GAP_ADDR_TYPE_PUBLIC 
 *           BLE_GAP_ADDR_TYPE_RANDOM
 *     - advertising_channel_map: 
 *           BLE_GAP_ADV_CHANNEL_MAP_37 
 *           BLE_GAP_ADV_CHANNEL_MAP_38 
 *           BLE_GAP_ADV_CHANNEL_MAP_39 
 *           BLE_GAP_ADV_CHANNEL_MAP_ALL
 *     - filter policies: 
 *           BLE_GAP_ADV_FP_ANY 
 *           BLE_GAP_ADV_FP_FILTER_SCANREQ 
 *           BLE_GAP_ADV_FP_FILTER_CONNREQ 
 *           BLE_GAP_ADV_FP_FILTER_BOTH
 *     
 * Note:  If the advertising_type is set to BLE_GAP_ADV_TYPE_ADV_SCAN_IND or BLE_GAP_ADV_TYPE_ADV_NONCONN_IND, 
 *        the advertising_interval_min and advertising_interval_max should not be set to less than 0x00A0.
 */
static advParams_t adv_params = {
  .adv_int_min   = 0x0030,
  .adv_int_max   = 0x0030,
  .adv_type      = BLE_GAP_ADV_TYPE_ADV_IND,
  .dir_addr_type = BLE_GAP_ADDR_TYPE_PUBLIC,
  .dir_addr      = {0,0,0,0,0,0},
  .channel_map   = BLE_GAP_ADV_CHANNEL_MAP_ALL,
  .filter_policy = BLE_GAP_ADV_FP_ANY
};

static uint8_t adv_data[] = {
  0x02,
  BLE_GAP_AD_TYPE_FLAGS,
  BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE,
  
  0x08,
  BLE_GAP_AD_TYPE_SHORT_LOCAL_NAME,
  'i','P','a','s','s','-','d',       //iPass-d(I'm a door)
  
  0x11,
  BLE_GAP_AD_TYPE_128BIT_SERVICE_UUID_COMPLETE,
  0x1e,0x94,0x8d,0xf1,0x48,0x31,0x94,0xba,0x75,0x4c,0x3e,0x50,0x00,0x00,0x3d,0x71
};

static uint16_t character1_handle = 0x0000;
static uint16_t character2_handle = 0x0000;
static uint16_t character3_handle = 0x0000;

static uint8_t characteristic1_data[CHARACTERISTIC1_MAX_LEN] = { 0x01 };
static uint8_t characteristic2_data[CHARACTERISTIC2_MAX_LEN] = { 0x00 };

static btstack_timer_source_t characteristic2;

char rx_buf[TXRX_BUF_LEN];
static uint8_t rx_buf_num;
static uint8_t rx_state = 0;

//BLEで受信したデータ
static String tempWatchID = "";
static String BLEData = "";
static String BLEString = "";
static String BLEWatchID = "";
static String BLEorder = "";


//モノの名前（phpで送信用）
#define MyMonoID            "Door123456"

//許可するwatchID
static String watchIDs[1000];
static int cntWatchIDs = 0;

//今の自分の状態
bool myStatus = false;
//bool sendStatusFlag = true;

//disconnectされるときに使う
bool disconnectedFlag = false;

/* 接続していいwatchIDかどうか判断 */
//受け取ったvalue_handleを保存
//uint16_t myValue_Handle;
bool checkWIDflag = false;
bool WIDcheckedflag = true;

//時間外かどうか保存
bool outOfTime = false;

//wifiFunction
//void httpRequestToWriteHistory(String,bool);
/******************************************************
 *               BLE Function Definitions
 ******************************************************/
//電子錠制御用
//outputPin
int startPin = 1;
int blue = 0;
int brown = 2;
//inputPin
int keyOpen = 3;
int keyClose = 4;
int doorStatus = 5;

//ドアの開閉状況
int valueKeyOpen = 0;
int valueKeyClose = 0;
int valueDoorStatus = 0;

//ドアを開閉する処理
void openDoor(); 
void closeDoor();

 
void deviceConnectedCallback(BLEStatus_t status, uint16_t handle) {
  switch (status) {
    case BLE_STATUS_OK:
      Serial.println("Device connected!");
      break;
    default: break;
  }

}
void deviceDisconnectedCallback(uint16_t handle){
  //BLEのタイマーをリセット
  ble.setTimer(&characteristic2, 200);
  ble.addTimer(&characteristic2);
  Serial.println("reset timer");
  //接続が切れた時にOFFにする
  disconnectedFlag = true;
  Serial.println("Disconnected.");
}


int gattWriteCallback(uint16_t value_handle, uint8_t *buffer, uint16_t size) {
  Serial.print("Write value handler: ");
  Serial.println(value_handle, HEX);
  //BLEString初期化
  BLEString = "";

  if (character1_handle == value_handle) {
    memcpy(characteristic1_data, buffer, min(size,CHARACTERISTIC1_MAX_LEN));
    Serial.print("Characteristic1 write value: ");
    for (uint8_t index = 0; index < min(size,CHARACTERISTIC1_MAX_LEN); index++) {
      Serial.print(characteristic1_data[index], HEX);
      BLEString += (char)characteristic1_data[index];
      Serial.print(" ");
    }
//    delay(1000);
    Serial.println(" ");
    Serial.println(BLEString);

    //主要データを保存
      BLEData = BLEString;
      BLEWatchID = BLEString.substring(0,7);
      BLEorder = BLEString.substring(7);
      tempWatchID = BLEWatchID;
    //表示
      Serial.print("BLEWatchID = ");
      Serial.println(BLEWatchID);
      Serial.print("BLEorder = ");
      Serial.println(BLEorder);
  }

  //iOSappに自分の状態を送る
//    if(BLEData == "tellMeSta") {
//      if(sendStatusFlag && on){
//        ble.sendNotify(character2_handle, (uint8_t*)"Door123456ON", CHARACTERISTIC2_MAX_LEN);
//        memset(rx_buf, 0x00, 20);
//      }
//      if(sendStatusFlag && off){
//        ble.sendNotify(character2_handle, (uint8_t*)"Door123456OFF", CHARACTERISTIC2_MAX_LEN);
//        memset(rx_buf, 0x00, 20);
//      }
//      BLEData = "";
//      sendStatusFlag = false;
//    }

    //iOSappに接続可能watchIDかどうかを送る Judge
    if(BLEorder == "J") {
//        myValue_Handle = value_handle; 
        Serial.println("Checked watchID");
        checkWIDflag = true;
        Serial.println(checkWIDflag);           
    }  

  //接続されたら返事を返す(何もcharacteristicがない時)
    //ここで通信相手に送る
//    if(BLEData == "" && BLEString == "" && BLEorder == ""){
//        ble.sendNotify(character2_handle, (uint8_t*)MyMonoID, CHARACTERISTIC2_MAX_LEN);
//        memset(rx_buf, 0x00, 20);
//    }
//    
  return 0;
}

/*void m_uart_rx_handle() {   //update characteristic data
  ble.sendNotify(character2_handle, rx_buf, CHARACTERISTIC2_MAX_LEN);
  memset(rx_buf, 0x00,20);
  rx_state = 0;
}*/

static void  characteristic2_notify(btstack_timer_source_t *ts) {   
//  if (Serial.available()) {
//    //read the serial command into a buffer
//    uint8_t rx_len = min(Serial.available(), CHARACTERISTIC2_MAX_LEN);
//    Serial.readBytes(rx_buf, rx_len);
//    //send the serial command to the server
//    Serial.print("Sent: ");
//    Serial.println(rx_buf);
//    rx_state = 1;
//  }
//  if (rx_state != 0) {
//    ble.sendNotify(character2_handle, (uint8_t*)rx_buf, CHARACTERISTIC2_MAX_LEN);
//    memset(rx_buf, 0x00, 20);
//    rx_state = 0;    
//  }
//  
  //sendStatus!!!!
//  if(sendStatusFlag && on){
//    Serial.println("Sent my st on (BLE)");
//    ble.sendNotify(character2_handle, (uint8_t*)"Door123456ON", CHARACTERISTIC2_MAX_LEN);
//    memset(rx_buf, 0x00, 20);
//  }
//  if(sendStatusFlag && off){
//    Serial.println("Sent my st off (BLE)");
//    ble.sendNotify(character2_handle, (uint8_t*)"Door123456OFF", CHARACTERISTIC2_MAX_LEN);
//    memset(rx_buf, 0x00, 20);
//  }
//  sendStatusFlag = false;

    //iOSappに接続できないwatchIDであることを送る 
  if(WIDcheckedflag == false){
      ble.sendNotify(character2_handle, (uint8_t*)"000", CHARACTERISTIC2_MAX_LEN);
//      memset("000", 0x00, 20);
      WIDcheckedflag = true;

      ble.setTimer(ts, 200);
      ble.addTimer(ts);
  }

  //時間外だったら送る
  //使用時間外の時の処理
        if(outOfTime){
          Serial.println("Send outOfTime");
          ble.sendNotify(character2_handle, (uint8_t*)"NIT", CHARACTERISTIC2_MAX_LEN);
//          memset("NIT", 0x00, 20);
          //初期化
          outOfTime = false;
          ble.setTimer(ts, 200);
          ble.addTimer(ts);
        }
  
  
  // reset
  ble.setTimer(ts, 200);
  ble.addTimer(ts);
}

void setupBLE(){
  //ble.debugLogger(true);
  // Initialize ble_stack.
  ble.init();

  // Register BLE callback functions
  ble.onConnectedCallback(deviceConnectedCallback);
  ble.onDisconnectedCallback(deviceDisconnectedCallback);
  ble.onDataWriteCallback(gattWriteCallback);

  // Add GAP service and characteristics
  ble.addService(BLE_UUID_GAP);
  ble.addCharacteristic(BLE_UUID_GAP_CHARACTERISTIC_DEVICE_NAME, ATT_PROPERTY_READ|ATT_PROPERTY_WRITE, (uint8_t*)BLE_DEVICE_NAME, sizeof(BLE_DEVICE_NAME));
  ble.addCharacteristic(BLE_UUID_GAP_CHARACTERISTIC_APPEARANCE, ATT_PROPERTY_READ, appearance, sizeof(appearance));
  ble.addCharacteristic(BLE_UUID_GAP_CHARACTERISTIC_PPCP, ATT_PROPERTY_READ, conn_param, sizeof(conn_param));

  // Add GATT service and characteristics
  ble.addService(BLE_UUID_GATT);
  ble.addCharacteristic(BLE_UUID_GATT_CHARACTERISTIC_SERVICE_CHANGED, ATT_PROPERTY_INDICATE, change, sizeof(change));

  // Add user defined service and characteristics
  ble.addService(service1_uuid);
  character1_handle = ble.addCharacteristicDynamic(service1_tx_uuid, ATT_PROPERTY_NOTIFY|ATT_PROPERTY_WRITE|ATT_PROPERTY_WRITE_WITHOUT_RESPONSE, characteristic1_data, CHARACTERISTIC1_MAX_LEN);
  character2_handle = ble.addCharacteristicDynamic(service1_rx_uuid, ATT_PROPERTY_NOTIFY, characteristic2_data, CHARACTERISTIC2_MAX_LEN);

  // Set BLE advertising parameters
  ble.setAdvertisementParams(&adv_params);

  // // Set BLE advertising data
  ble.setAdvertisementData(sizeof(adv_data), adv_data);

  // BLE peripheral starts advertising now.
  ble.startAdvertising();
  Serial.println("BLE start advertising.");

  // set one-shot timer
  characteristic2.process = &characteristic2_notify;
  ble.setTimer(&characteristic2, 500);//100ms
  ble.addTimer(&characteristic2);
}

/******************************************************
 *              WiFi Variable Definitions
 ******************************************************/
//// your network name also called SSID
//char ssid[] = "L05E";
//// your network password
//char password[] = "hinahina";
//
//// if you don't want to use DNS (and reduce your sketch size)
//// use the numeric IP instead of the name for the server:
//IPAddress server(112,78,125,208);  //さくらサーバーIPaddress
//
//
//// Initialize the Ethernet client library
//// with the IP address and port of the server
//// that you want to connect to (port 80 is default for HTTP):
//TCPClient client;
//
//
////サーバーから受信結果
//static char charString[1000];
//static bool flagC = false;
//
//
//
////接続されたかどうか
//static bool firstWifiConnect = true;
//static bool monoInfoFlag = false;
//
///******************************************************
// *               Wifi Function Definitions
// ******************************************************/
//void httpRequest();
//void printWifiStatus();
//void getArrayValue();
//void httpRequestToGetTimetable();
//
////現在の時刻を取得
//String timeData = "";
//int hour;
//int minute;
//int second;
//int weekDay;
//void currentTime();
//void getTime(String);
//
////timerをセット
//Timer timer(1000, currentTime);
//
////このMonoの使用可能時間
//int timeTable[10];
//int startHour = 0;
//int startMin = 0;
//int endHour = 0;
//int endMin = 0;
//void getTimetable(String);
//bool checkTimeTable();
//
//void getArrayValue(String s){
//  
//  int cnt = 0;
//  if(s.indexOf(",") != -1 ){
//    do{
//      int indexNum = s.indexOf(",");
//      Serial.println(indexNum);
//      watchIDs[cnt] = s.substring(indexNum-8,indexNum-1);
//      cnt++;
//      s = s.substring(indexNum+1);
////      Serial.print("s=");
////      Serial.println(s);
//    }while(s.indexOf(",") != -1 );
//  }
//  //最後の一個を入れる
//  watchIDs[cnt] = s.substring(1,8);
////  Serial.println(s);
//}
//
////Timetableに値を格納
//void getTimetable(String s){
//  
//  int cnt = 0;
//  int indexNum = 0;
//  if(s.indexOf(",") != -1 ){
//    for(int i = 0; i < 8; i++){
//      indexNum = s.indexOf("\"");
//      timeTable[cnt] = (s.substring(indexNum+1,indexNum+2)).toInt();
//      cnt++;
//
//      //Serial.println(indexNum);
//      s = s.substring(indexNum+1);
//      indexNum = s.indexOf(",");
//      s = s.substring(indexNum+1);
////      Serial.print("s=");
////      Serial.println(s);
//    }
//  }
////  for(int i = 0; i < 8; i++){
////    Serial.print(timeTable[i]);
////  }
//  //start時間を入れる
//  indexNum = s.indexOf("\"");
//  startHour = s.substring(indexNum+1,indexNum+3).toInt();
//  indexNum = s.indexOf(":");
//  startMin = s.substring(indexNum+1,indexNum+3).toInt();
//  //Stringを短くする
//  indexNum = s.indexOf(",");
//  s = s.substring(indexNum+1);
////  Serial.print("s=");
////      Serial.println(s);
//      
//  //end時間を入れる
//  indexNum = s.indexOf("\"");
//  endHour = s.substring(indexNum+1,indexNum+3).toInt();
//  indexNum = s.indexOf(":");
////  Serial.println(indexNum);
//  endMin = s.substring(indexNum+1,indexNum+3).toInt();
//
////  Serial.println(startHour);
////  Serial.println(startMin);
////  Serial.println(endHour);
////  Serial.println(endMin);
//}
//
//// this method makes a HTTP connection to the server:
//void httpRequest() {
//  // close any connection before send a new request.
//  // This will free the socket on the WiFi shield
//  client.stop();
//
//  // if there's a successful connection:
//  if (client.connect(server, 80)) {
//    Serial.println("connecting...");
//    // send the HTTP PUT request:
//    client.print("GET http://tabuken.jp/ipass/nakayama/get_data1.php?MonoID=");
//    client.print(MyMonoID);
//    client.println(" HTTP/1.1");
//    client.println("Host: www.energia.nu");
//    client.println("User-Agent: Energia/1.1");
//    client.println("Connection: close");
//    client.println();
//
//  }
//  else {
//    // if you couldn't make a connection:
//    Serial.println("connection failed");
//    httpRequest();
//  }
//}
////使用履歴を更新する
////void httpRequestToWriteHistory(String watchID,bool state) {
////  // close any connection before send a new request.
////  // This will free the socket on the WiFi shield
////  client.stop();
////
////  // if there's a successful connection:
////  if (client.connect(server, 80)) {
////    Serial.println("connecting...");
////    // send the HTTP PUT request:
////    client.print("GET http://tabuken.jp/ipass/nakayama/write_history.php?watchID=");
////    client.print(watchID);
////    client.print("&MonoID=");
////    client.print(MyMonoID);
////    client.print("&status=");
////    client.print(state);
////    client.println(" HTTP/1.1");
////    client.println("Host: www.energia.nu");
////    client.println("User-Agent: Energia/1.1");
////    client.println("Connection: close");
////    client.println();
////
////    Serial.println("I sent a history!");
////
////  }
////  else {
////    // if you couldn't make a connection:
////    Serial.println("connection failed");
////  }
////}
//
////MonoのTimetableを取得する
//void httpRequestToGetTimetable() {
//  // close any connection before send a new request.
//  // This will free the socket on the WiFi shield
//  client.stop();
//
//  // if there's a successful connection:
//  if (client.connect(server, 80)) {
//    Serial.println("connecting...");
//    // send the HTTP PUT request:
//    client.print("GET http://tabuken.jp/ipass/nakayama/getMI.php?MonoID=");
//    client.print(MyMonoID);
//    client.println(" HTTP/1.1");
//    client.println("Host: www.energia.nu");
//    client.println("User-Agent: Energia/1.1");
//    client.println("Connection: close");
//    client.println();
//
//    Serial.println("I ordered my Timetable!");
//
//  }
//  else {
//    // if you couldn't make a connection:
//    Serial.println("connection failed");
////    httpRequestToGetTimetable();
//  }
//}
//
//void printWifiStatus() {
//  // print the SSID of the network you're attached to:
//  Serial.print("SSID: ");
//  Serial.println(WiFi.SSID());
//
//  // print your WiFi shield's IP address:
//  IPAddress ip = WiFi.localIP();
//  Serial.print("IP Address: ");
//  Serial.println(ip);
//
//  // print the received signal strength:
//  long rssi = WiFi.RSSI();
//  Serial.print("signal strength (RSSI):");
//  Serial.print(rssi);
//  Serial.println(" dBm");
//}

//ドアを開ける処理
void openDoor() {
  Serial.println("OPEN!");
  digitalWrite(blue,HIGH);
  digitalWrite(brown,LOW);
  digitalWrite(startPin,HIGH);
  while(digitalRead(keyOpen) == 0){}
  digitalWrite(blue,LOW);
  digitalWrite(startPin,LOW);
}
//ドアを閉める処理
void closeDoor() {
  Serial.println("CLOSE!");
  digitalWrite(blue,LOW);
  digitalWrite(brown,HIGH);
  digitalWrite(startPin,HIGH);
  while(digitalRead(keyClose) == 0){}
  digitalWrite(brown,LOW);
  digitalWrite(startPin,LOW);
  
}

void setup() {
  Serial.begin(115200);
  delay(5000);
  Serial.println(BLE_DEVICE_NAME);

  //output
  pinMode(startPin,OUTPUT);
  pinMode(blue,OUTPUT);
  pinMode(brown,OUTPUT);
  //input
  pinMode(keyOpen, INPUT);
  pinMode(keyClose, INPUT);
  pinMode(doorStatus, INPUT);
    
  //ble.debugLogger(true);
  // Initialize ble_stack.
  ble.init();

  // Register BLE callback functions
  ble.onConnectedCallback(deviceConnectedCallback);
  ble.onDisconnectedCallback(deviceDisconnectedCallback);
  ble.onDataWriteCallback(gattWriteCallback);

  // Add GAP service and characteristics
  ble.addService(BLE_UUID_GAP);
  ble.addCharacteristic(BLE_UUID_GAP_CHARACTERISTIC_DEVICE_NAME, ATT_PROPERTY_READ|ATT_PROPERTY_WRITE, (uint8_t*)BLE_DEVICE_NAME, sizeof(BLE_DEVICE_NAME));
  ble.addCharacteristic(BLE_UUID_GAP_CHARACTERISTIC_APPEARANCE, ATT_PROPERTY_READ, appearance, sizeof(appearance));
  ble.addCharacteristic(BLE_UUID_GAP_CHARACTERISTIC_PPCP, ATT_PROPERTY_READ, conn_param, sizeof(conn_param));

  // Add GATT service and characteristics
  ble.addService(BLE_UUID_GATT);
  ble.addCharacteristic(BLE_UUID_GATT_CHARACTERISTIC_SERVICE_CHANGED, ATT_PROPERTY_INDICATE, change, sizeof(change));

  // Add user defined service and characteristics
  ble.addService(service1_uuid);
  character1_handle = ble.addCharacteristicDynamic(service1_tx_uuid, ATT_PROPERTY_NOTIFY|ATT_PROPERTY_WRITE|ATT_PROPERTY_WRITE_WITHOUT_RESPONSE, characteristic1_data, CHARACTERISTIC1_MAX_LEN);
  character2_handle = ble.addCharacteristicDynamic(service1_rx_uuid, ATT_PROPERTY_NOTIFY, characteristic2_data, CHARACTERISTIC2_MAX_LEN);

  // Set BLE advertising parameters
  ble.setAdvertisementParams(&adv_params);

  // // Set BLE advertising data
  ble.setAdvertisementData(sizeof(adv_data), adv_data);

  // BLE peripheral starts advertising now.
  ble.startAdvertising();
  Serial.println("BLE start advertising.");

  // set one-shot timer
  characteristic2.process = &characteristic2_notify;
  ble.setTimer(&characteristic2, 500);//100ms
  ble.addTimer(&characteristic2);

//  //ここからwifi
//  
//  // attempt to connect to Wifi network:
//  Serial.print("Attempting to connect to Network named: ");
//  // print the network name (SSID);
//  Serial.println(ssid); 
//  
//  // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
//  WiFi.on();
//  WiFi.setCredentials(ssid,password);
//  WiFi.connect();
//  
//  while ( WiFi.connecting()) {
//    // print dots while we wait to connect
//    Serial.print(".");
//    delay(300);
//  }
//  
//  Serial.println("\nYou're connected to the network");
//  Serial.println("Waiting for an ip address");
//  
//  IPAddress localIP = WiFi.localIP();
//  while (localIP[0] == 0) {
//    localIP = WiFi.localIP();
//    Serial.println("waiting for an IP address");
//    delay(1000);
//  }
//
//  //checkmacAddress
//  byte mac[6];
//  WiFi.macAddress(mac);
//
//  for (int i=0; i<6; i++) {
//    if (i) Serial.print(":");
//    Serial.print(mac[i], HEX);
//  }
//  
//  Serial.println("\nIP Address obtained");
//  printWifiStatus();
//  httpRequest();

}

void loop() {

  //ドア開閉用
  valueKeyOpen = digitalRead(keyOpen);  // 入力ピンを読む
  valueKeyClose = digitalRead(keyClose);  // 入力ピンを読む
  valueDoorStatus = digitalRead(doorStatus);
  
//デバッグ用
//  Serial.print("valueDoorStatus : ");
//  Serial.print(valueDoorStatus);
//    Serial.print(" valueKeyOpen : ");
//  Serial.print(valueKeyOpen);
//    Serial.print(" valueKeyClose : ");
//  Serial.println(valueKeyClose);

  // if there are incoming bytes available
  // from the server, read them and print them:
//  int num = 0;
//  while (client.available()) {
//    //Serial.println("client receive data ");
//    char c = client.read();
//    if(c != '\n'){
//      timeData += c;
//    }
//    if(c == '['){
//      flagC = true;
//      delay(1000);
//    }
//    if(c != '[' && c != ']' && c != '\n' && flagC == true){
//      charString[num]= c;
//      num++;
//      //Serial.println("Hooo");
//    }
//    
//  }
//  num = 0;
//  flagC = false;
//  
//
//
//  // if the server's disconnected, stop the client:
//  if (!client.connected() && firstWifiConnect == true) {
//    //Serial.println();
//    Serial.println("disconnecting from server.");
//    client.stop();
//
//    Serial.println(timeData);
//    getTime(timeData);
//    
//    String tmpString(charString);
//     Serial.println(tmpString);
//      //WatchIDsに許可するwatchIDを入れる
//     getArrayValue(tmpString);
//
//     while(watchIDs[cntWatchIDs] != 0){
//        Serial.print("watchIDs[");
//         Serial.print(cntWatchIDs);
//         Serial.print("] = ");
//         Serial.println(watchIDs[cntWatchIDs]);
//         cntWatchIDs++;
//     }
//   
//    firstWifiConnect = false;
//    monoInfoFlag = true;
//    httpRequestToGetTimetable();
//  }
//
//  /*
//   * monoのTimetableを取得する
//   */
//    if (!client.connected() && monoInfoFlag == true) {
//      //Serial.println();
//      Serial.println("disconnecting from server.");
//      client.stop();
//      
//      Serial.println(charString);
//      String tmpString(charString);
//      getTimetable(tmpString);
//
//      monoInfoFlag = false;
//      //BLEをセットアップする
//      setupBLE();
//    }
//
//  //wifiここまで

//  watchIDs[0] = "CC12345";
   watchIDs[0] = "CC12345";
   cntWatchIDs = 1;

  
  //許可するwatchIDなら電流を流す
  for(int i = 0; i < cntWatchIDs ; i++){
     if(BLEWatchID == watchIDs[i]){
//        if(BLEorder == "O"){
//          Serial.println("order -> OPEN!");
//        }
        if((BLEorder == "O") && (valueDoorStatus == 1)&& (valueKeyOpen == 0) && (valueKeyClose == 1)){
          Serial.println("OPEN!");
          //ドアを開ける処理
//          if(checkTimeTable()){
            openDoor();
//          }
            
            //履歴を書き込む(状態が変わった時だけ)
//            if(myStatus == false){
//                httpRequestToWriteHistory(BLEWatchID,1);
//            }
//            delay(1000);
            
            //自分の状態を送る
            myStatus = true;
            //初期化
            BLEWatchID = "";
            BLEorder = "";
        }

        else if((BLEorder == "C") && (valueDoorStatus == 1) && (valueKeyOpen == 1) && (valueKeyClose == 0)){
          Serial.println("CLOSE!");
            //ドアを閉める処理
            closeDoor();
           //履歴を書き込む(状態が変わった時だけ)
//            if(myStatus == true){
//              Serial.println("");
//               httpRequestToWriteHistory(BLEWatchID,0);
//            }
//            delay(1000);
            
            //自分の状態を送る
           myStatus = false;
           //初期化
           BLEWatchID = "";
           BLEorder = "";
           
        }
//        //使用時間外の時の処理
//        if(BLEorder == "O" && checkTimeTable() == false){
//          Serial.println("Out of Time!");
//          outOfTime = true;
//          //初期化
//          BLEWatchID = "";
//          BLEorder = "";
//
//        }
     }
  }
  
    //適合するwatchIDかどうか調べる
    if(checkWIDflag) {
      checkWIDflag = false;
      Serial.println("checking");
      int i = 0;
      WIDcheckedflag = false;
      while(watchIDs[i] != 0){
        Serial.print("watchIDs[");
        Serial.print(i);
        Serial.print("] = ");
        Serial.print(watchIDs[i]);
        Serial.print(" == ");
        Serial.println(BLEWatchID);
      if(watchIDs[i] == BLEWatchID){
         WIDcheckedflag = true;
         Serial.println("TRUUU");
       }
       i++;
    }
    Serial.print("AllcheckedWID result = ");
    Serial.println(WIDcheckedflag);
    checkWIDflag = false;
  }
  
  if(disconnectedFlag){
    //履歴を書き込む(状態が変わった時だけ)
//    if(myStatus == true){
//       httpRequestToWriteHistory(BLEWatchID,0);
//    }

    delay(500);
    //ドアを閉める
    if((valueDoorStatus == 1) && (valueKeyOpen == 1) && (valueKeyClose == 0)){
      closeDoor();
    }
    myStatus = false;
//    delay(1000);
//    BLEWatchID = "";
    BLEorder = "";
    tempWatchID = "";
    disconnectedFlag = false;
    Serial.println("disconnectedFlag = "+(String)disconnectedFlag);
  }

 
  
}

//void getTime(String t){
//  String weeks[] = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
//  int a = t.indexOf("Date");
//  t = t.substring(a,a+32);
//  Serial.println(t);
//  String week = t.substring(6,9);
//  Serial.println(week);
//  for(int i = 0; i < 7; i++){
//    if(weeks[i] == week){
//      weekDay = i+1;
//    }
//  }
//  hour = t.substring(23,25).toInt();
//  hour +=9;
//  if(hour >= 24){
//    hour %= 24;
//    weekDay++;
//  }
//  Serial.println(weekDay);
//  Serial.println(hour);
//
//  minute = t.substring(26,28).toInt();
//  Serial.println(minute);
//  second = (t.substring(29,31).toInt())+3;
//  Serial.println(second);
//  //タイマーをstart
//  timer.start();
//}
//
//void currentTime() {
//  second++;
//  if(second >= 60){
//    second = second%60;
//    minute++;
//  }
//  
//  if( minute >= 60 ){
//    minute = minute%60;
//    hour++;
//  } 
//  
//  if(hour >= 24){
//    hour = hour%24;
//    weekDay++;
//  }
//
//  if(weekDay > 7){
//    weekDay = 1;
//  }
//  
////  Serial.print(weekDay);
////  
////  Serial.print("hour:");
////  Serial.print(hour);
////  Serial.print("minute:");
////  Serial.print(minute);
////  Serial.print("second:");
////  Serial.println(second);
//}

////使用可能時間かどうかを調べる
//bool checkTimeTable(){
// 
//  if(timeTable[0] == 0){
//    return true;
//  }else if(timeTable[weekDay] == 0){
//    return true;
//  }else if(timeTable[weekDay] == 1){
//    if(startHour < hour && endHour > hour){
//      return true;
//    }else if(endHour >= hour && endMin >= minute && startHour <= hour ){
//      return true;
//    }else if(endHour >= hour && startMin <= minute && startHour <= hour ){
//      return true;
//    }
//  }
//  
//  return false;
//}

