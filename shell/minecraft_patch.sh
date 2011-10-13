#!/bin/sh
# coding: utf-8

export LANG=ja_JP.UTF-8

###########################################
# mac os用自動パッチワークシェルスクリプト
# 1. minecraft.jarのバックアップを取って
# 2. 解凍してファイルを置き換えて
# 3. 不要なものを削除して再度jarに固めて
# 4. 所定の位置に置きます
###########################################

MC_ROOT_DIR="/Users/$USER/Library/Application Support/minecraft"
MC_MOD_DIR=$1
MC_BAK_DIR=mc_backup
MC_BIN_DIR=bin
MC_WORK_DIR=mc_work
MC_BAK_FILENAME="`/bin/date +'%Y%m%d%H%M%S'`_minecraft.bak.jar"

function lineecho() {
        str=$1
        nonewline=$2
        if [ $nonewline = 1 ] ; then
                /bin/echo -n "$str"
        else
                /bin/echo "$str"
        fi
        return 0
}

function green() {
        lineecho "[32m$1[0m" $2
}

function red() {
        lineecho "[31m$1[0m" $2
}

function cyan() {
        lineecho "[36m$1[0m" $2
}

function white() {
        lineecho "[37m$1[0m" $2
}

function success_or_failed() {
        err=$1
        if [ $err = 0 ] ; then
                green "成功" 0
        else
                red "失敗" 0
                exit 1
        fi
        return 0
}

alias s_or_f=success_or_failed

function mc_exec() {
        mes=$1
        cmd=$2
        cyan $mes 1
        $cmd > /dev/null 2>&1
        s_or_f $?
        return 0
}


cd "$MC_ROOT_DIR"
white "
初期化処理
" 0
mc_exec "作業用ディレクトリの削除..." "/bin/rm -rf bin/$MC_WORK_DIR"
white "
バックアップ作成
" 0
if [ ! -d $MC_BAK_DIR ] ; then
        mc_exec "バックアップディレクトリの作成..." "/bin/mkdir $MC_BAK_DIR"
fi
mc_exec "バックアップファイルの作成..." "/bin/cp bin/minecraft.jar $MC_BAK_DIR/$MC_BAK_FILENAME"
white "
MODの適用
" 0
mc_exec "作業用ディレクトリの作成..." "/bin/mkdir bin/$MC_WORK_DIR"
mc_exec "作業用ディレクトリへファイルのコピー..." "/bin/cp bin/minecraft.jar bin/$MC_WORK_DIR"
cd bin/$MC_WORK_DIR
mc_exec "minecraft.jarの解凍..." "/usr/bin/jar xvf minecraft.jar"
mc_exec "MODの適用..." "/bin/cp -r $MC_MOD_DIR/* ."
mc_exec "不要なファイルの削除..." "/bin/rm -rf minecraft.jar META-INF/"
mc_exec "minecraft.jarの再圧縮..." "/usr/bin/jar cvf minecraft.jar *"
cd "$MC_ROOT_DIR"
mc_exec "minecraft.jarを設置..." "/bin/mv bin/$MC_WORK_DIR/minecraft.jar bin/minecraft.jar"
mc_exec "終了処理..." "/bin/rm -rf bin/$MC_WORK_DIR/"
white "
作業が完了しました
" 0
exit 0
