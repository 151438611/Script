<!DOCTYPE html> 
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta http-equiv="Content-TYPE" content="text/html; charset=UTF-8" />
    <title>10Gtek Product Compatibility</title>
    <link href="index.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript" language="javascript">
		function disRecord(record){ 
		    alert(record); 
		}
	</script>
	
</head>
<body>
<!--
	<a href="https://wx2.qq.com/" target="_self"><img border="0" src="./weixin.jpg" /></a>
	<a href="http://192.168.200.21/phpmyadmin" target="_blank"><img border="0" src="./mariadb.jpg" /></a>
	<a href="https://192.168.200.21" target="_self"><img border="0" src="./kodexplorer.jpg" /></a>
	<a href="https://github.com/151438611/Script/" target="_blank"><img border="0" src="./github.jpg" /></a>
	<a href="https://mirrors.aliyun.com/apache/hadoop/common/" target="_blank"><img border="0" src="./hadoop.jpg" /></a>
	<a href="https://mirrors.aliyun.com/apache/hbase/" target="_blank"><img border="0" src="./hbase.jpg" /></a>
	<a href="https://mirrors.aliyun.com/apache/hive/" target="_blank"><img border="0" src="./hive.jpg" /></a>
	<a href="https://mirrors.aliyun.com/apache/spark/" target="_blank"><img border="0" src="./spark.jpg" /></a>
	<a href="https://naotu.baidu.com/" target="_blank"><img border="0" src="./baidu_naotu.jpg" /></a>
	<a href="https://www.right.com.cn/forum/forum-158-1.html" target="_blank"><img border="0" src="./right_ensan.jpg" /></a>
	<a href="http://192.168.200.201:81" target="_blank"><img border="0" src="./zabbix.jpg" /></a>
	<a href="https://192.168.200.221/ui/" target="_blank"><img border="0" src="./vmware.jpg" /></a>
	<a href="https://yadi.sk/d/_rQgn_FosYuW0g" target="_blank"><img border="0" src="./armbian.jpg" /></a>
	<a href="https://play.google.com/store/apps" target="_blank"><img border="0" src="./google_play.jpg" /></a>
	<a href="https://www.google.com.hk/" target="_self"><img border="0" src="./google.jpg" /></a>
	<br>
	<a href="https://tmgmatrix.cisco.com/home" target="_blank"><img border="0" src="./cisco_optics_compatibility_matrix.jpg" /></a>
	<a href="https://www.vmware.com/resources/compatibility/search.php?deviceCategory=io" target="_blank"><img border="0" src="./vmware_compatibility_guide.jpg" /></a>
	<a href="https://partsurfer.hpe.com/search.aspx" target="_blank"><img border="0" src="./hpe_partsurfer.jpg" /></a>
	<a href="https://www.synology.com/zh-cn/compatibility" target="_blank"><img border="0" src="./synology_compatibility.jpg" /></a>
	<a href="https://downloadcenter.intel.com/en/" target="_blank"><img border="0" src="./intel_driver.jpg" /></a>
	<a href="https://ark.intel.com/content/www/us/en/ark.html" target="_blank"><img border="0" src="./intel_ark.jpg" /></a>
	<br>
	<a href="http://10.5.5.75" target="_blank"><img border="0" src="./router_jh_75.jpg" /></a>
	<a href="http://10.5.5.76" target="_blank"><img border="0" src="./router_jh_76.jpg" /></a>
	<a href="http://10.5.5.11" target="_blank"><img border="0" src="./router_jh_11.jpg" /></a>
	<a href="http://10.5.5.11:81" target="_blank"><img border="0" src="./filebrowser.jpg" /></a>
	<a href="http://10.5.5.05" target="_blank"><img border="0" src="./router_gx_05.jpg" /></a>
	<a href="http://10.5.5.57" target="_blank"><img border="0" src="./router_gx_57.jpg" /></a>
	<a href="http://10.5.5.18:5000" target="_blank"><img border="0" src="./dsm_jh.jpg" /></a>
	<a href="http://10.5.5.28:5000" target="_blank"><img border="0" src="./dsm_sz.jpg" /></a>
	<a href="http://192.168.200.250:5000" target="_blank"><img border="0" src="./dsm_wzt.jpg" /></a>
-->
    <div>
		<p>Windows and Linux Question Query</p>
		
		<form id="frontForm" name="frontForm" action="" method="get">
			<input class="inputKeywords" name="inputKeywords1" type="text" maxlength="10" placeholder=" OS " value="">
			<input class="inputKeywords" name="inputKeywords2" type="text" maxlength="10" placeholder=" Type " value="">
			<input class="inputKeywords" name="inputKeywords3" type="text" maxlength="25" placeholder=" Ask " value="">
			<input class="inputKeywords" name="inputKeywords4" type="text" maxlength="25" placeholder=" Question " value="">
			<button class="button" type="submit">清空</button>

		</form>
	</div>   
<?php 
/**
* date 20210202
* @author Jun | e-mail:jun@qq.com
*/

$inputKeywords1 = $_GET["inputKeywords1"];
$inputKeywords2 = $_GET["inputKeywords2"];
$inputKeywords3 = $_GET["inputKeywords3"];
$inputKeywords4 = $_GET["inputKeywords4"];

if (empty($inputKeywords1.$inputKeywords2.$inputKeywords3.$inputKeywords4)) { 
    die(""); 
} 
//else { $inputKeywords = str_replace(" ","",$inputKeywords); } //去除空格
/**
if (preg_match("/[\/-]/",$inputKeywords)) {
    $Product_Name=true;
} else { $Item_Number = true; }
*/
if (!empty($inputKeywords1)) { $row_select = "OS" ; $inputKeywords=$inputKeywords1 ; }
elseif (!empty($inputKeywords2)) { $row_select = "Type" ; $inputKeywords=$inputKeywords2 ; }
elseif (!empty($inputKeywords3)) { $row_select = "Ask" ; $inputKeywords=$inputKeywords3 ; }
elseif (!empty($inputKeywords4)) { $row_select = "Question" ; $inputKeywords=$inputKeywords4 ; }
else { die('<script> alert("无法识别输入的字符"); </script>'); }

$db_username = "product";
$db_password = "product";
$db_host = "192.168.200.200";
$db_name = "os";
$tab_name = "Record";
// mysqli_connect(host,username,password,dbname,port,socket);
$conn_sql = mysqli_connect($db_host, $db_username, $db_password);
if (!$conn_sql) { 
    die('<script> alert("数据库连接失败 : '. mysqli_connect_error() .'"); </script>');   
}

mysqli_set_charset($conn_sql, 'utf8');
mysqli_query($conn_sql, "set names utf8");

//mysqli_select_db(mysqliLink, database)；
$select = "SELECT * FROM $db_name.$tab_name WHERE $row_select like '%$inputKeywords%'";
$result = mysqli_query($conn_sql, $select);

if (!$result) { 
    die('<script> alert("数据库查询失败 : '. mysqli_error($conn_sql) .'"); </script>');
} //elseif (count(mysqli_fetch_array($result)) < 1) { die('<script> alert("数据库无法找到相关记录"); </script>'); }

// 下面常量对应数据库的字段，请勿更改数据库字段
define("OS", "OS");
define("TYPE", "Type");
define("ASK", "Ask");
define("QUESTION", "Question");

function tagColor($receive, $swRecord) {
    if (empty($receive)) {
        return "<td></td>";
    }
    else { 
        if (preg_match("/down|error|unsupported|异常|无法读取/i", $receive)) {
        return "<td class=unsupport onclick=disRecord(\"".$swRecord."\")>".$receive."</td>"; 
         } 
        else { return "<td class=support>".$receive."</td>"; }
        }
}

echo "<fieldset>";
echo "<table class=outputData border=1 cellspacing=0 cellpadding=3 align=center>";
echo "<tr class=row1>
        <th>".OS."</th> <th>".TYPE."</th> <th>".ASK."</th> <th>".QUESTION."</th>
        </tr>";

while($row = mysqli_fetch_array($result, MYSQLI_ASSOC)) { 
    echo "<tr class=row2>      
            <td>".$row[OS]."</td> <td>".$row[TYPE]."</td> <td>".$row[ASK]."</td> <td>".$row[QUESTION]."</td>
            </tr>";
}

echo "</table>";
echo "</fieldset>";

mysqli_free_result($result);
mysqli_close($conn_sql);

?>

</body> 
</html>
