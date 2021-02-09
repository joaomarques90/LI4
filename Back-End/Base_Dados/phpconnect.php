<?php
   $utime = sprintf('%.4f', microtime(TRUE));
   $raw_time = DateTime::createFromFormat('U.u', $utime);
   $timezone = new DateTimeZone('Europe/Lisbon');
   $raw_time->setTimezone($timezone);
   $mysqltime = $raw_time->format('Y-m-d H:i:s.u');

    // $phptime = time();
    // $mysqltime = date ("Y-m-d H:i:s.u", $phptime);
    // $mysqltime = $today;
    error_reporting(E_ALL & ~E_NOTICE);
    
    $con = mysqli_init();
    
    if (!$con) {
      echo "FAIL [ mysqli_init failed ]";
      die("mysqli_init failed");
    }
    else { 
        mysqli_ssl_set($con,NULL,NULL, "BaltimoreCyberTrustRoot.crt.pem", NULL, NULL) ; 

        // expired passwords
        if (!mysqli_real_connect($con, "iqueue.mysql.database.azure.com", "guestSMS@iqueue", "uminho2020_SMS", "iqueue", 3306, MYSQLI_CLIENT_SSL)) {
          echo "FAIL [ Connect Error: " . mysqli_connect_error() . " ]";
          die("Connect Error: " . mysqli_connect_error());
        }
        else { 
            // FAIL MINIMUM REQUIREMENTS (todos os parâmetros)
            if(!isset($_GET['MsgId']) || !isset($_GET['status']) || !isset($_GET['status_name']) || !isset($_GET['idx']) || !isset($_GET['to']) || !isset($_GET['donedate']) || !isset($_GET['username']) || !isset($_GET['mcc']) || !isset($_GET['mnc']) || !isset($_GET['from']) || !isset($_GET['points'])) {
                
                $key   = array();
                $valor = array();
                
                // GET ALL HTML_HEADERS FOR LOG
                foreach (getallheaders() as $name => $value) {
                    array_push($key,$name);
                    array_push($valor,$value);
                }

                foreach($_GET as $name => $value) {
                    array_push($key,$name);
                    array_push($valor,$value);
                }

                foreach($_POST as $name => $value) {
                    array_push($key,$name);
                    array_push($valor,$value);
                }

                $querycontent = "INSERT INTO SMS_SERVER_FailedWebRequest(data) VALUES('$mysqltime')";
                // $res = mysqli_query($con, $querycontent);
                // echo "res = ".$res;

                $insert2 = true;

                if(mysqli_query($con, $querycontent) && mysqli_affected_rows($con)) {
                    foreach ($key as $index => $key) {
                            // echo "FAIL [ NOT RECOGNIZED ARGS ]";
                            // echo " [ ". $key . " ],[ " . $valor[$index] . " ] ## ";
                            if($insert2) {
                                $querycontent = "INSERT INTO FailedWebRequest(chave, valor, data) VALUES('".mysqli_real_escape_string($con, $key)."', '".mysqli_real_escape_string($con, $valor[$index])."', '".mysqli_real_escape_string($con, $mysqltime)."' )";
        
                                mysqli_query($con, $querycontent);
                                $insert2 = mysqli_affected_rows($con);

                            }
                    }
                    if($insert2) echo "FAIL [ INVALID ARGS ]  (LOG OK)";
                    else { echo "FAIL [ INVALID ARGS ] - FAIL SQL FailedWebRequest (PARTIAL LOG)"; }
                }
                else { echo "FAIL [ INVALID ARGS ] - FAIL SQL SMS_SERVER_FailedWebRequest (PARTIAL LOG)"; }
            }
            // OK MINIMUM REQUIREMENTS (MsgId, status, idx)
            else {
                $arIds        = explode(',',$_GET['MsgId']);
                $arStatus     = explode(',',$_GET['status']);
                // $arIdx        = explode(',',$_GET['idx']);
                $arTo         = explode(',',$_GET['to']);
                $arDate       = explode(',',$_GET['donedate']);
                $arUName      = explode(',',$_GET['username']);
                $arMCC        = explode(',',$_GET['mcc']);
                $arMNC        = explode(',',$_GET['mnc']);
                $arFrom       = explode(',',$_GET['from']); 
                $arPoints     = explode(',',$_GET['points']);
                $arStatusName = explode(',',$_GET['status_name']);

                $failed  = false;
                $insert  = true;
                $insert2 = true;

                // TRY UPDATE
                foreach($arIds as $k => $v) {
                    
                    $raw_time_2 = DateTime::createFromFormat('U.u', $arDate[$k]);
                    $timezone_2 = new DateTimeZone('Europe/Lisbon');
                    $raw_time_2->setTimezone($timezone_2);
                    $donedatefinal = $raw_time_2->format('Y-m-d H:i:s.u');
                    
                    if($failed == false) {
                        $querycontent = "UPDATE SMS SET 
                            sms_id ='".mysqli_real_escape_string($con, $v)."',
                            sms_status = '".mysqli_real_escape_string($con, $arStatus[$k])."', 
                            sms_status_name = '".mysqli_real_escape_string($con, $arStatusName[$k])."', 
                            sms_points = '".mysqli_real_escape_string($con, $arPoints[$k])."', 
                            sms_mcc = '".mysqli_real_escape_string($con, $arMCC[$k])."', 
                            sms_mnc = '".mysqli_real_escape_string($con, $arMNC[$k])."', 
                            sms_username = '".mysqli_real_escape_string($con, $arUName[$k])."', 
                            sms_donedate = '".mysqli_real_escape_string($con, $donedatefinal)."', 
                            last_update = '".mysqli_real_escape_string($con, $mysqltime)."'

                            WHERE 
                                
                                sms_from = '".mysqli_real_escape_string($con, $arFrom[$k])."' AND
                                sms_to = '".mysqli_real_escape_string($con, $arTo[$k])."' 
                            
                            ORDER BY sms_idx DESC 
                            LIMIT 1";
                        
                        // WHERE sms_id ='".mysqli_real_escape_string($con, $v)."' AND     
                        //       sms_idx = '".mysqli_real_escape_string($con, $arIdx[$k])."' AND 

                        $failed = mysqli_query($con, $querycontent);
                        // echo "affected_rows" . mysqli_affected_rows($con);
                        if($failed) $failed = (mysqli_affected_rows($con) <= 0);
                    }
                    else $failed = true;
                }
                
                // UPDATE FAILED
                if($failed == true) {

                    $key   = array();
                    $valor = array();
                    
                    // GET ALL HTML_HEADERS FOR LOG
                    foreach (getallheaders() as $name => $value) {
                        array_push($key,$name);
                        array_push($valor,$value);
                    }
                    foreach($_GET as $name => $value) {
                        array_push($key,$name);
                        array_push($valor,$value);
                    }

                    foreach($_POST as $name => $value) {
                        array_push($key,$name);
                        array_push($valor,$value);
                    }

                    // code here
                    // echo "FAIL [ query: ". $arIds ." " . $arIdx . " ". $arStatus . " ]"; 
                    // echo " ". $_GET['MsgId'] ." " . $_GET['status'] . " ". $_GET['idx'] . " ]"; 

                    $querycontent = "INSERT INTO SMS_SERVER_FailedWebRequest(data) VALUES('$mysqltime')";
                    $insert = mysqli_query($con, $querycontent);
                    if($insert) $insert = (mysqli_affected_rows($con) > 0);

                    // OK INSERT SMS_SERVER_FailedWebRequest
                    if($insert == true) {
                        mysqli_query($con, $querycontent);
                        foreach ($key as $index => $key) {
                                // echo "FAIL [ NOT RECOGNIZED ARGS ]";
                                // echo " [ ". $key . " ],[ " . $valor[$index] . " ] ## ";

                                // IF OK INSERT FailedWebRequest => KEEP INSERTING
                                if($insert2) {
                                    $querycontent = "INSERT INTO FailedWebRequest(chave, valor, data) VALUES('$key', '$valor[$index]', '$mysqltime')";
                                    $insert2 = mysqli_query($con, $querycontent);
                                    if($insert2) $insert2 = (mysqli_affected_rows($con) > 0);
                                }
                        }
                    }
                    // FAIL INSERT SMS_SERVER_FailedWebRequest
                    else echo "FAIL SQL SMS_SERVER_FailedWebRequest (PARTIAL LOG)";
                }

                if($failed == false) echo "OK"; // EVERYTHING PERFECT
                else if($insert == true && $insert2 == true) echo "FAIL (LOG OK)"; // OK LOG 
                else if($insert == true && $insert2 == false) echo "FAIL SQL FailedWebRequest (PARTIAL LOG)"; // FAIL LOG (TOTAL/PARTIAL)
            }
            mysqli_close($con);
        }
    }

?>

