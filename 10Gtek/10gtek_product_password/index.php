<!DOCTYPE html> 
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>10Gtek Product_Compatibility</title>
    <link href="index.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript" language="javascript">
		function disRecord(record){ 
		    alert(record); 
		}
	</script>
	
</head>
<body>
	<a href="https://wx2.qq.com/" target="_self"><img border="0" src="./weixin.jpg" /></a>
	<a href="http://192.168.200.21/phpmyadmin" target="_blank"><img border="0" src="./mariadb.jpg" /></a>
	<a href="https://192.168.200.21" target="_self"><img border="0" src="./kodexplorer.jpg" /></a>
	<a href="http://10.5.5.11:81" target="_blank"><img border="0" src="./filebrowser.jpg" /></a>
	<a href="https://github.com/151438611/Script" target="_blank"><img border="0" src="./github.jpg" /></a>
	<a href="https://naotu.baidu.com/" target="_blank"><img border="0" src="./baidu_naotu.jpg" /></a>
	<a href="https://www.right.com.cn/forum/forum-158-1.html" target="_blank"><img border="0" src="./right_ensan.jpg" /></a>
	<a href="http://192.168.200.201:81" target="_blank"><img border="0" src="./zabbix.jpg" /></a>
	<a href="http://192.168.200.250:5000" target="_blank"><img border="0" src="./synology_dsm.jpg" /></a>
	<a href="https://192.168.200.221/ui/" target="_blank"><img border="0" src="./vmware.jpg" /></a>
	<a href="https://yadi.sk/d/_rQgn_FosYuW0g" target="_blank"><img border="0" src="./armbian.jpg" /></a>
	<!-- armbian : https://yadi.sk/d/pHxaRAs-tZiei https://yadi.sk/d/_rQgn_FosYuW0g-->
	<a href="https://play.google.com/store/apps" target="_blank"><img border="0" src="./google_play.jpg" /></a>
	<a href="https://www.google.com.hk/" target="_self"><img border="0" src="./google.jpg" /></a>
	<br>
	<a href="https://tmgmatrix.cisco.com/home" target="_blank"><img border="0" src="./cisco_optics_compatibility_matrix.jpg" /></a>
	<a href="https://www.vmware.com/resources/compatibility/search.php?deviceCategory=io" target="_blank"><img border="0" src="./vmware_compatibility_guide.jpg" /></a>
	<a href="https://partsurfer.hpe.com/search.aspx" target="_blank"><img border="0" src="./hpe_partsurfer.jpg" /></a>
	<a href="https://www.synology.com/zh-cn/compatibility" target="_blank"><img border="0" src="./synology_compatibility.jpg" /></a>
	<a href="https://downloadcenter.intel.com/en/" target="_blank"><img border="0" src="./intel_driver.jpg" /></a>
	<a href="https://ark.intel.com/content/www/us/en/ark.html" target="_blank"><img border="0" src="./intel_ark.jpg" /></a>
	
    <div>
		<p>Transceiver Module Group Compatibility Matrix</p>
		
		<form id="frontForm" name="frontForm" action="" method="get">
			<input class="inputKeywords" name="inputKeywords" type="text" maxlength="25" placeholder=" Least 5 keywords of Product_Name or Item_Number " value="">
			<button class="button" type="submit">清空</button>
<!--	    <button class="button" type="button" onmouseenter="this.innerHTML=Date()" onmouseleave="this.innerHTML='时间'">时间</button> 
-->
		</form>
	</div>   
<?php 
/**
* date 20190501
* @author Jun | e-mail:jun@qq.com
*/

$inputKeywords = $_GET["inputKeywords"];

if (empty($inputKeywords) or strlen($inputKeywords) < 5) { 
    die(""); 
} 
//else { $inputKeywords = str_replace(" ","",$inputKeywords); } //去除空格

if (preg_match("/[\/-]/",$inputKeywords)) {
    $Product_Name=true;
} else { $Item_Number = true; }

if ($Product_Name) { $row_select = "Product_Name" ; }
elseif ($Item_Number) { $row_select = "Item_Number" ; }
else { die('<script> alert("无法分辨是物料编号或产品名称 : '. $inputKeywords .'"); </script>'); }

$db_username = "product";
$db_password = "product";
$db_host = "192.168.200.201";
$db_name = "product";
$tab_name = "product_compatibility";
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

define("itemNum", "Item_Number");
define("prodName", "Product_Name");
define("tpwd", "Transceiver Password");
define("ar7050", "Arista 7050");	define("ar7050_re", "Arista 7050 record");
define("cs2960", "Cisco 2960");	    define("cs2960_re", "Cisco 2960 record");
define("cs2960g", "Cisco 2960G");	define("cs2960g_re", "Cisco 2960G record");
define("cs3560", "Cisco 3560");	    define("cs3560_re", "Cisco 3560 record");
define("cs3064", "Cisco 3064");	    define("cs3064_re", "Cisco 3064 record");
define("cs5548", "Cisco 5548");	    define("cs5548_re", "Cisco 5548 record");
define("cs3232c", "Cisco 3232C");	define("cs3232c_re", "Cisco 3232C record");
define("cs92160", "Cisco 92160");	define("cs92160_re", "Cisco 92160 record");
define("de4810", "Dell S4810");    	define("de4810_re", "Dell S4810 record");
define("ed5712", "Edgecore 5712");	define("ed5712_re", "Edgecore 5712 record");
define("hc3100", "H3C S3100v2");	define("hc3100_re", "H3C S3100v2 record");
define("hc5120", "H3C S5120");    	define("hc5120_re", "H3C S5120 record");
define("hp2910", "HP 2910");    	define("hp2910_re", "HP 2910 record");
define("hp5900", "HP 5900");    	define("hp5900_re", "HP 5900 record");
define("hw3700", "Huawei S3700");	define("hw3700_re", "Huawei S3700 record");
define("hw5700", "Huawei S5700");	define("hw5700_re", "Huawei S5700 record");
define("ibm8264", "IBM G8264");	    define("ibm8264_re", "IBM G8264 record");
define("ju5100", "Juniper QFX5100");	define("ju5100_re", "Juniper QFX5100 record");
define("ju5200", "Juniper QFX5200");	define("ju5200_re", "Juniper QFX5200 record");
define("me7800", "Mellanox SB7800");	define("me7800_re", "Mellanox SB7800 record");
/*
$cols1 = array(
    "ar7050"=>"Arista 7050",        "ar7050_re"=>"Arista 7050 record",
    "cs2960"=>"Cisco 2960",         "cs2960_re"=>"Cisco 2960 record",
    "cs2960g"=>"Cisco 2960G",       "cs2960g_re"=>"Cisco 2960G record",
    "cs3560"=>"Cisco 3560",         "cs3560_re"=>"Cisco 3560 record",
    "cs3064"=>"Cisco 3064",         "cs3064_re"=>"Cisco 3064 record",
    "cs5548"=>"Cisco 5548",         "cs5548_re"=>"Cisco 5548 record",
    "cs3232c"=>"Cisco 3232C",       "cs3232c_re"=>"Cisco 3232C record",
    "cs92160"=>"Cisco 92160",       "cs92160_re"=>"Cisco 92160 record",
    "de4810"=>"Dell S4810",         "de4810_re"=>"Dell S4810 record",
    "ed5712"=>"Edgecore 5712",      "ed5712_re"=>"Edgecore 5712 record",
    "hc5120"=>"H3C S5120",          "hc5120_re"=>"H3C S5120 record",
    "hp2910"=>"HP 2910",            "hp2910_re"=>"HP 2910 record",
    "hp5900"=>"HP 5900",            "hp5900_re"=>"HP 5900 record",
    "hw3700"=>"Huawei S3700",       "hw3700_re"=>"Huawei S3700 record",
    "hw5700"=>"Huawei S5700",       "hw5700_re"=>"Huawei S5700 record",
    "ibm8264"=>"IBM G8264",         "ibm8264_re"=>"IBM G8264 record",
    "ju5100"=>"Juniper QFX5100",    "ju5100_re"=>"Juniper QFX5100 record",
    "ju5200"=>"Juniper QFX5200",    "ju5200_re"=>"Juniper QFX5200 record",
    "me7800"=>"Mellanox SB7800",    "me7800_re"=>"Mellanox SB7800 record"
    );
*/

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
//echo "<legend>结果</legend>";
echo "<table class=outputData border=1 cellspacing=0 cellpadding=0 align=center>";
echo "<tr class=row1>
        <th>".itemNum."</th> <th>".prodName."</th> <th>".tpwd."</th>
        </tr>";
/**
        <th>".ar7050."</th> <th>".cs2960."</th> <th>".cs2960g."</th> <th>".cs3560."</th>
	    <th>".cs3064."</th> <th>".cs5548."</th> <th>".cs3232c."</th> <th>".cs92160."</th>    
	    <th>".de4810."</th> <th>".ed5712."</th> <th>".hc3100."</th> <th>".hc5120."</th>    
	    <th>".hp2910."</th> <th>".hp5900."</th> <th>".hw3700."</th> <th>".hw5700."</th>    
	    <th>".ibm8264."</th> <th>".ju5100."</th> <th>".ju5200."</th> <th>".me7800."</th>
*/


while($row = mysqli_fetch_array($result, MYSQLI_ASSOC)) { 
//    echo "<pre>";    print_r($row);    echo "</pre>";
    echo "<tr class=row2>      
            <td>".$row[itemNum]."</td> <td>".$row[prodName]."</td> <td>".$row[tpwd]."</td>
            </tr>";
/**
            .tagColor($row[ar7050], $row[ar7050_re]). tagColor($row[cs2960], $row[cs2960_re]).
            tagColor($row[cs2960g], $row[cs2960g_re]).tagColor($row[cs3560], $$row[cs3560_re]).
            tagColor($row[cs3064], $row[cs3064_re]).tagColor($row[cs5548], $row[cs5548_re]).
            tagColor($row[cs3232c], $row[cs3232c_re]).tagColor($row[cs92160], $row[cs92160_re]). 
            tagColor($row[de4810], $row[de4810_re]).tagColor($row[ed5712], $row[ed5712_re]).
            tagColor($row[hc3100], $row[hc3100_re]).tagColor($row[hc5120], $row[hc5120_re]).
            tagColor($row[hp2910], $row[hp2910_re]).tagColor($row[hp5900], $row[hp5900_re]).
            tagColor($row[hw3700], $row[hw3700_re]).tagColor($row[hw5700], $row[hw5700_re]). 
            tagColor($row[ibm8264], $row[ibm8264_re]).tagColor($row[ju5100], $row[ju5100_re]).
            tagColor($row[ju5200], $row[ju5200_re]).tagColor($row[me7800], $row[me7800_re]).
*/
}

echo "</table>";
echo "</fieldset>";

mysqli_free_result($result);
mysqli_close($conn_sql);

?>

</body> 
</html>
