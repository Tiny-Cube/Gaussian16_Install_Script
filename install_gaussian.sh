#!/usr/bin/env sh

# Gaussian install script
# Zsh and Bash

# set color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0;0m' # no color

echo -e "${GREEN}========================================${NC}"
echo -e "${NC}       Gaussian ${GREEN}install script${NC}"
echo -e "${GREEN}========================================${NC}"

# check if root
if [ "$(id -u)" -eq 0 ]; then
	echo -e "${RED}error: do not use root to run this script!${NC}"
	exit 1
fi

# shell form
if [ -n "$ZSH_VERSION" ]; then
    SHELL_TYPE="zsh"
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_TYPE="bash"
    SHELL_CONFIG="$HOME/.bashrc"
else
    echo -e "${YELLOW}WARNING: not sure current shell form，default sh${NC}"
    SHELL_TYPE="sh"
    SHELL_CONFIG="$HOME/.profile"
fi

echo -e "${YELLOW}current shell:${NC} $SHELL_TYPE"

gaussian_tarball=""
install_dir=""

# help information
show_help() {
    echo -e "${RED}Instruction sets supported by the CPU:"
    grep -o -e see4_2 -e avx -e sse4a -e avx2 /proc/cpuinfo | sort -u | tr '\n' ' ' 
    echo -e ${NC}
    echo "usage: $0 [option]"
    echo "options:"
    echo "  -h, --help	        show help"
    echo "  -f, --file <path>   Gaussian.tar.gz path to the installation package"
    echo "  -d, --dir <path>    installed direction path"
    exit 0
}

#parse command arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -f|--file)
            gaussian_tarball="$2"
            shift 2
            ;;
        -d|--dir)
            install_dir="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}错误: 未知参数 '$1'${NC}"
            show_help
            ;;
    esac
done

# 函数: 检查命令是否存在
command_exists() {
    if [ "$SHELL_TYPE" = "zsh" ]; then
        (( $+commands[$1] ))
    else
        command -v "$1" >/dev/null 2>&1
    fi
}

# 验证必要的命令是否存在
echo -e "${YELLOW}正在检查必要的工具...${NC}"
for cmd in tar find grep; do
    if ! command_exists "$cmd"; then
        echo -e "${RED}错误: 需要安装 '$cmd' 命令才能继续!${NC}"
        exit 1
    else
        echo -e "${GREEN}✓${NC} $cmd"
    fi
done

# 函数: 检查文件是否存在并可读
check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}错误: 文件 '$1' 不存在!${NC}"
        return 1
    fi
    if [ ! -r "$1" ]; then
        echo -e "${RED}错误: 文件 '$1' 不可读!${NC}"
        return 1
    fi
    return 0
}


# 2. 提醒用户给出Gaussian的tar.gz文件路径
if [ -z "$gaussian_tarball" ]; then
    read -e -p "请输入Gaussian16安装包(tar.gz)的路径: " gaussian_tarball
    gaussian_tarball="${gaussian_tarball/#\~/$HOME}"
fi

# 检查压缩包是否存在
if ! check_file "$gaussian_tarball"; then
    exit 1
fi

# 验证文件扩展名
if [[ ! "$gaussian_tarball" =~ \.tar\.gz$ ]]; then
    echo -e "${RED}错误: 文件 '$gaussian_tarball' 不是tar.gz文件!${NC}"
    exit 1
fi

echo -e "${GREEN}使用安装包:${NC} $gaussian_tarball"

# 3. 给出Gaussian程序所在路径
echo -e "${YELLOW}请确认Gaussian程序文件位置:${NC}"
read -p "按Enter继续..."

# 4. 提醒用户给出Gaussian需要安装到的指定目录，如果没有则按默认处理
default_install_dir="$HOME/software/gaussian16"
if [ -z "$install_dir" ]; then
    read -e -p "请输入安装目录 (默认: $default_install_dir): " install_dir
    install_dir="${install_dir/#\~/$HOME}"

fi

if [ -z "$install_dir" ]; then
    install_dir="$default_install_dir"
fi

# 创建安装目录
mkdir -p "$install_dir"
if [ ! -d "$install_dir" ]; then
    echo -e "${RED}错误: 无法创建安装目录 '$install_dir'!${NC}"
    exit 1
fi

# 动态查找 g16 文件在压缩包中的路径
g16_file=$(tar -tf "$gaussian_tarball" | grep "/g16$" | tail -n 1)

if [ -z "$g16_file" ]; then
    echo "错误：压缩包中未找到 g16 可执行文件"
    exit 1
fi

g16_parent_dir=$(dirname "$g16_file")  # 获取上级目录
dir_level=$(echo "$g16_parent_dir" | tr -cd '/' | wc -c)
strip_components=$((dir_level))  # 保留最后一级目录

echo "g16 文件路径：$g16_file"
echo "上级目录：$g16_parent_dir"
echo "需要删除的目录层级：$strip_components"

# 解压命令（动态调整 strip-components）
echo -e "${GREEN}开始解压安装文件到:${NC} $install_dir"

tar -xzf "$gaussian_tarball" -C "$install_dir" --strip-components=$strip_components "$g16_parent_dir"/

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 解压安装文件失败!${NC}"
    exit 1
fi

echo -e "${GREEN}安装文件解压完成!${NC}"

g16_path="$install_dir/$(basename "$g16_parent_dir")" 

# 验证安装
if [ -f "$g16_path/g16" ]; then
    echo "✓ g16 文件已正确安装"
    echo -e "${GREEN}已找到g16程序:${NC} $g16_path"
else
    echo "! 未找到 "$g16_path/g16"，请检查解压结果"
    echo -e "${RED}错误: 无法找到g16程序!${NC}"
    exit 1
fi

# 5. 在对应shell配置文件中添加相关配置
echo -e "${GREEN}正在配置环境变量...${NC}"

# 函数: 添加环境变量到配置文件
add_to_config() {
    local config_line="$1"
    local config_file="$2"
    
    if ! grep -qF "$config_line" "$config_file"; then
        echo "$config_line" >> "$config_file"
        echo -e "${GREEN}已添加到 $config_file:${NC} $config_line"
    else
        echo -e "${YELLOW}已存在于 $config_file:${NC} $config_line"
    fi
}

# 添加Gaussian环境变量
add_to_config "export g16root=\"$install_dir\"" "$SHELL_CONFIG" #install_dir为g16文件的上级上级目录
add_to_config "export GAUSS_SCRDIR=$HOME/gaussian_scratch" "$SHELL_CONFIG"
add_to_config "source $g16_path/bsd/g16.profile" "$SHELL_CONFIG" #g16_dir 为g16文件的上级目录


# 创建临时目录
mkdir -p "$HOME/gaussian_scratch"
if [ ! -d "$HOME/gaussian_scratch" ]; then
    echo -e "${YELLOW}警告: 无法创建临时目录 '$HOME/gaussian_scratch'，请手动创建!${NC}"
fi


echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}      Gaussian install down!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}安装信息:${NC}"
echo -e "  版本: ${GREEN}$GAUSSIAN_VERSION${NC}"
echo -e "  安装目录: ${GREEN}$install_dir${NC}"
echo -e "  g16程序路径: ${GREEN}$g16_path${NC}"
echo -e "${YELLOW}使用说明:${NC}"
echo -e "  1. 执行以下命令使配置生效:"
echo -e "     ${GREEN}source $SHELL_CONFIG${NC}"
echo -e "  2. 测试Gaussian安装:"
echo -e "     ${GREEN}g16 --version${NC}"
echo -e "${GREEN}========================================${NC}"

