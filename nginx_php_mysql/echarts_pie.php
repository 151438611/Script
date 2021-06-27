<!--
1、为hadoop hive bbase作业可视化而写，流程：此页面从mysql中获取数据，并用echarts可视化出来 
2、软件依赖: nginx mysql php7.3 php7.3-json php7.3-mysql
3、echarts.js文件下载：https://github.com/apache/echarts/releases
-->

<html>
<head>
    <title>Echarts Pie Demo</title>
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
            public $name;
            public $value;
        }
        while($row = mysqli_fetch_assoc($result)) {
            $gd=new getData();
            // 此处通过Mysql查询的数据传入class赋值
            $gd->name = $row['name'];
            $gd->value = $row['age'];
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
        var jsdata = <?php echo $data_json?>;
        console.log(jsdata)
        // 以上代码作用从php_sql中的数组转换
        var dom = document.getElementById("echarts_js");
        var myChart = echarts.init(dom);
        var option;
    
        option = {
            title: {
                text: '圆饼可视化标题',
                subtext: '子标题',
                left: 'center'
            },
            tooltip: {trigger: 'item'},
            legend: {orient: 'vertical', left: 'left'}, 
            series: [
                {
                name: 'pie_demo',
                type: 'pie',
                radius: '50%',      // 表示饼图的大小比例
                data: jsdata,
            /*    data: [           // 圆饼图data类型为数组对象，则格式必须为 {name: 'xx',value: xx},
                    {name: '搜索引擎',value: 1048},
                    {value: 735, name: '直接访问'},
                    {value: 580, name: '邮件营销'},
                    {value: 484, name: '联盟广告'},
                    {value: 300, name: '视频广告'}
                    ],    */
                emphasis: {
                itemStyle: {
                    shadowBlur: 20,
                    shadowOffsetX: 0,
                    shadowColor: 'rgba(0, 0, 0, 0.5)'
                }
                }
            }
            ]
        };
    
        if (option && typeof option === 'object') {
            myChart.setOption(option);
        }
    
    </script>

</body>
</html>
