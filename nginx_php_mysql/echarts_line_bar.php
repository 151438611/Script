<!--
1、为hadoop hive bbase作业可视化而写，流程：此页面从mysql中获取数据，并用echarts可视化出来 
2、软件依赖: nginx mysql php7.3 php7.3-json php7.3-mysql
3、echarts.js文件下载：https://github.com/apache/echarts/releases
-->

<html>
<head>
    <title>Echarts Line Bar Demo</title>
    <meta charset="utf-8">
</head>
     
<body>
    
    <?php
        $db_username = "root";
        $db_password = "root";
        $db_host = "192.168.200.233";
        $db_name = "echarts";
        $tab_name = "stu";
        // mysqli_connect(host,username,password,dbname,port,socket);
        $conn_sql = mysqli_connect($db_host, $db_username, $db_password) or  
            die('<script> alert("数据库连接失败 : '. mysqli_connect_error() .'"); </script>');   
        
        mysqli_set_charset($conn_sql, 'utf8');
        mysqli_query($conn_sql, "set names utf8");
        
        $select = "SELECT * FROM $db_name.$tab_name";
        $result = mysqli_query($conn_sql, $select) or
            die('<script> alert("数据库查询失败 : '. mysqli_error($conn_sql) .'"); </script>');
    
        $data_array= array();
        class getData{        // 此处定义查询的列；若需要多个列，自行添加
            public $row1;
            public $row2;
        }
        while($row = mysqli_fetch_assoc($result)) {
            $gd=new getData();
            // 此处通过Mysql查询的数据传入class赋值
            $gd->name = $row['name'];
            $gd->age = $row['age'];
            $data_array[] = $gd;
        }
    
        $data_json = json_encode($data_array);       // 将php数组转换成json格式
        //echo $all_arr;
        mysqli_free_result($result);
        mysqli_close($conn_sql);
    ?>
    
    <div id="echarts_js" style="height: 100%"></div>
    <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js"></script>       <!-- 需要在线连接echarts库 -->
    <!-- <script type="text/javascript" src="echarts.min.js"></script>             <!-- 离线使用echarts,将echarts.min.js文件放入代码当前目录中 -->
    <script type="text/javascript">
        var jsrow1 = new Array(), jsrow2 = new Array();
        var jsdata = <?php echo $data_json?>;
        jsdata.forEach(function(js_i){
            console.log(js_i.name + '---' + js_i.age)
            jsrow1.push(js_i.name);
            jsrow2.push(js_i.age);
        })
        console.log(jsdata)
        // 以上代码作用从php_sql中的数组转换
        var dom = document.getElementById("echarts_js");
        var myChart = echarts.init(dom);
        var option;
    
        option = {
            title: {
                text: '可视化标题',
                subtext: '子标题',
                left: 'left'
            },
            legend: {
                data: ['sql_name1','sql_name2',]
            },
            grid: {
                left: '5%',
                right: '5%',
                bottom: '5%',
                containLabel: true
            },
            xAxis: [{
                type: 'category',
                gridIndex: 0,
                data: jsrow1
            }],
            yAxis: [
                {type: 'value'}
            ],
            series: [
                {
                name: 'sql_name1',
                type: 'line',            // type:line折线图 bar柱状图 pie圆饼图
                data: jsrow2
                },
                {
                name: 'sql_name2',
                type: 'bar', 
                data: jsrow2,
                showBackground: true,
                backgroundStyle: { color: 'rgba(180, 180, 180, 0.3)'}
                }
            ]
        };
    
        if (option && typeof option === 'object') {
            myChart.setOption(option);
        }
    
    </script>

</body>
</html>