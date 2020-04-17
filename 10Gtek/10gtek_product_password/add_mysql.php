<!DOCTYPE html> 
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>10Gtek Product_Compatibility</title>
</head>
<style>
    body { background:#F8F8F8; }
    fieldset {
        width: 50%;
        margin:5px;
        text-align: center;
        position:relative;
        left:300px;
    }
</style>
<body>
    <div>
		<p>Transceiver Module Group (TMG) Compatibility Matrix</p>
		
		<form id="frontForm" name="frontForm" action="" method="get">
			<input class="inputKeywords" name="inputKeywords" type="text" maxlength="25" placeholder=" Input more than 5 keywords of Product_Name / Item_Number " value="">
			
			<button class="button" type="submit">清空</button>
<!--	    <button class="button" type="button" onmouseenter="this.innerHTML=Date()" onmouseleave="this.innerHTML='时间'">时间</button> 
-->
		</form>
	</div>  
<?php
/**
* date 20190901
* @author Jun | e-mail:jun@qq.com
*/
$host = "localhost";
$username = "root";
$password = "root";
$dbName = "product";
$tabName = "product_compatibility";
// 连接数据库格式 ：mysqli_connect(host,username,password,dbname,port,socket);
$conn = mysqli_connect($host, $username, $password);
if (!$conn) { 
    die('<script> alert("数据库连接失败 : '. mysqli_connect_error() .'"); </script>');   
} 
else { 
    echo '<script> alert("数据库连接成功"); </script>'; 
}
mysqli_set_charset($conn, 'utf8');      //设置字符集,防止中文乱码
mysqli_query($conn, "set names utf8");
mysqli_select_db($conn, $dbName)；      //选择使用指定数据库
//mysqli_select_db(mysqliLink, database)；
$select = "SELECT * FROM $db_name.$tab_name WHERE $row_select like '%$inputKeywords%'";
$result = mysqli_query($conn_sql, $select);

if (!$result) { 
    die('<script> alert("数据库查询失败 : '. mysqli_error($conn_sql) .'"); </script>');
} //elseif (count(mysqli_fetch_array($result)) < 1) { die('<script> alert("数据库无法找到相关记录"); </script>'); }


echo '<fieldset>';

echo '<table>';
echo '<tr>
</tr>';
echo '<tr>
</tr>';
echo '<tr>
</tr>';
echo '</table>';
echo '</fieldset>';
?>
</body> 
</html>