<!-- -*- coding:utf-8 -*- -->

# NetBSD ユーザランドのパッケージ化

## 今できること

1. NetBSD 8.0 を Full Installation している環境で、
   nbpkg.sh full-upgrade を実行すると、
   NetBSD 8.0 stable の最新環境に更新できます。

1. サポートする(予定)の環境は、次のとおりです。
    1. バージョンは、NetBSD 8.0 7.0 および NetBSD-current (8.99.*)
    1. アーキテクチャは、daily build が提供するものすべて
    

## 構成要素

次の二つの要素から構成されます。
+ ユーザランドを分解する仕組み [basepkg](https://github.com/user340/basepkg)
+ basepkgを用いて作ったパッケージ群を配布する仕組み(nbpkg-build) 

このリポジトリは、配布サーバとクライアントのリファレンス実装です。


## 基本的な仕組み

1. サーバ側
    1. daily build からバイナリをダウンロード
    1. basepkgを用いてパッケージに分解
    1. パッケージの配布
1. ユーザ側(クライアント側)
    1. nbpkg.sh (pkgsrc/pkgtools/pkginのwrapper)を使いシステム更新


## 裏側

詳細は、
[こちら](nbpkg-internals.md)
