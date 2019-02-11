<!-- -*- coding:utf-8 -*- -->

# NetBSD ユーザランドのパッケージ化

このページでは、おおまかに出来ることを紹介しています。
裏側について、もう少し詳しい説明は[**こちら**](nbpkg-internals.md)です。


## 今できること

1. NetBSD 8.0 を Full Installation している環境で、
   ```
   nbpkg.sh full-upgrade
   ```
   を実行すると、
   NetBSD 8.0 stable の最新環境に更新できます。

1. NetBSD 8.0 から openssl だけアップグレードしたい時は？

   アップグレードしたいパッケージを install の引数で指定してください。
   ```
   # nbpkg.sh install base-crypto-shlib
   ```

1. え、パッケージ名は openssl ではないの？

   nbpkg.sh で最低限のエイリアスをかけています。
   ```
   # nbpkg.sh install openssl
   ```
   を実行した場合
   ```
   # nbpkg.sh install base-crypto-shlib
   ```
   を実行します。
   今、サポートしているエイリアスは
   bind named openssh openssl postfix
   です。
   

1. ミニマムインストールの状態から組み上げていく時は、どうすればいいの？
   ```
   # nbpkg.sh -a install 入れたいパッケージ
   ```
   を実行することで、入れたいパッケージのみをインストール出来ます。
   ***-a オプションが重要です***。
   
   たとえば、
   ベースしかない状態にCコンパイラだけを追加したいなら
   ```
   # nbpkg.sh -a install comp-c-bin
   ```
   を実行することでコンパイラがインストールされます
   依存関係を解決するうえで必要なパッケージも適宜インストールされます。
   8.0 リリースから変更がなければ 8.0 リリース版パッケージが、
   該当 8.0 ブランチ内のアップデートがあれば、
   8.0 アップデート版のパッケージがインストールされます。
   
   (***注意***:
   現在Cコンパイラのインストールは失敗します、
   syspkgsデータベースが間違っているためです)
   
   [TODO]syspkgsのlintを作ろうとしてます;-)。

1. サポートする(予定)の環境は、次のとおりです。
    1. バージョンは、NetBSD 8.0 7.0 および NetBSD-current (8.99.*)
    1. アーキテクチャは、daily build が提供するものすべて
    

## 構成要素

これらの要素から構成されます。
+ ユーザランドを分解する仕組み [basepkg](https://github.com/user340/basepkg)
+ basepkgを用いて作ったパッケージ群を配布する仕組み(本リポジトリ)
    + [nbpkg-build](https://github.com/fmlorg/netbsd-modular-userland/)
      以下の nbpkg-build がサーバの実体
    + [nbpkg-build](https://github.com/fmlorg/netbsd-modular-userland/)
      以下の nbpkg-data  は ident データベース構築のユーティリティ
+ クライアント(本リポジトリ)
    + [nbpkg-build](https://github.com/fmlorg/netbsd-modular-userland/)
      以下の nbpkg-client がクライアントのリファレンス実装です。
      pkgsrcのユーティリティの wapper ですが、
      それらを呼び出す前に環境設定やエイリアス展開など、
      いくらか便利な機能が追加されています。
      

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
