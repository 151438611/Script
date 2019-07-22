#!/bin/bash
# 叶工需求：查找所有文件夹中的某些同名文件(目标文件$2), 并替换为指定文件(源文件$1)
# 备注：$1源文件需要唯一; $2目标文件(被替换文件)至少1个以上; 将目标文件和源文件压缩为zip格式后上传入Linux服务器中
# 使用格式： bash xx.sh 源文件名 被替换文件名

cd `dirname $0`  ;  clear
echo "----------------------------------"
echo "使用方法： sh $0 源文件名 目标文件名"
echo -e "----------------------------------\n"
sleep 1

if [ "$1" -a "$2" ]; then
	echo ""
else
	echo "请输入替换的源文件名和目标文件名,用空格隔开！"
	exit
fi
newName=$1
oldName=$2

delDir(){
	extractDir=$(find ./ -maxdepth 1 -type d -cmin -1 | grep -v ^./$)
	rm -rf $extractDir
}

input_zip=$(ls -t *.zip | head -n1)
ls | grep -qi "wo" && find . -type d -iname "WO*" -exec rm -rf {} \; 2> /dev/null
[ -z "$input_zip" ] && echo -e "\nzip文件不存在，请重新检查！！！\n" && exit
unzip -oq "$input_zip" || exit

newReplaced=$(find ./ -type f -name $newName)
if [ $(echo "$newReplaced" | grep -c $newName) -ne 1 ]; then
	echo "请检查源文件，并确保只有一个源文件！！" 
	delDir
	exit
fi

oldAllReplaced=$(find ./ -type f -name $oldName)
oldAllNum=$(echo "$oldAllReplaced" | grep -c $oldName)
if [ "$oldAllNum" -eq 0 ]; then
	echo "没有找到被替换的目标文件，请检查目标文件名是否输入正确"
	delDir
	exit
fi

for oldNum in $(seq $oldAllNum)
do
	oldReplaced=$(echo "$oldAllReplaced" | awk 'NR=="'$oldNum'"{print $0}')
	rm -f $oldReplaced
	cp -f $newReplaced ${oldReplaced%/*}
done

replacedDir=$(find ./ -maxdepth 1 -type d -cmin -1 | grep -v ^./$)
dir_name="$(date +%Y%m%d-%H%M%S).tar"
tar --remove-files -cf $dir_name $replacedDir && echo -e "\n----------替换文件 $dir_name 完成!----------\n"
mv -f $input_zip old.zip &> /dev/null
