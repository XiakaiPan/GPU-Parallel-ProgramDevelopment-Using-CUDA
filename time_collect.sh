#!/bin/bash

# 检查是否提供了至少一个命令
if [ $# -lt 1 ]; then
    echo "用法: $0 '命令1' ['命令2' ...]"
    echo "示例: $0 './imflip h' './imflip v'"
    exit 1
fi

# 默认输入文件及相关信息
INPUT_FILE="../../dog.bmp"
ORIGINAL_BASENAME=$(basename "$INPUT_FILE" .bmp)  # 获取dog
RESULT_FILE="result.txt"
TIME_STATS_DIR=$(mktemp -d)  # 创建临时目录存储各命令的时间统计

# 清空结果文件
> "$RESULT_FILE"

# 处理单个命令的函数
process_command() {
    local cmd="$1"
    local cmd_idx="$2"  # 命令索引，用于唯一标识
    local cmd_parts=($cmd)
    
    # 提取命令信息
    local exe_name=$(basename "${cmd_parts[0]}")
    local params=("${cmd_parts[@]:1}")
    
    # 生成唯一标志：将所有参数用下划线连接
    local flag="${exe_name}"
    for param in "${params[@]}"; do
        flag="${flag}_${param}"
    done
    
    # 生成输出文件名
    local output_file="${flag}_${ORIGINAL_BASENAME}.bmp"
    
    # 构造完整命令
    local full_cmd="${cmd_parts[0]} $INPUT_FILE $output_file ${params[*]}"
    
    # 输出命令信息到终端和结果文件
    echo "执行命令: $full_cmd"
    echo "输出文件: $output_file"
    
    # 存储时间统计的临时文件
    local time_file="$TIME_STATS_DIR/time_${cmd_idx}.txt"
    
    {
        # 记录命令开始标记
        echo "命令: $full_cmd"
        echo "输出文件: $output_file"
        echo "命令输出:"
        
        # 执行命令，将标准输出和错误输出保存到结果文件，时间统计保存到临时文件
        { time eval "$full_cmd" 2>&1; } 2> >(tee -a "$time_file" >&2)
        
        # 添加时间统计信息
        echo "时间统计:"
        cat "$time_file"
        
        # 添加分隔符
        echo "---"
    } >> "$RESULT_FILE"  # 所有输出重定向到结果文件
}

# 执行所有命令
cmd_idx=0
for cmd in "$@"; do
    process_command "$cmd" "$cmd_idx"
    ((cmd_idx++))
done

# 清理临时目录
rm -rf "$TIME_STATS_DIR"

echo "执行完成，结果已保存到 $RESULT_FILE"