# Neštamoj / Нештамој

Нештамојフォントは字雲フォントの改変フォントです。

## これは何？どう使うの？

　Нештамојフォントを生成するツール一式です。

　WSL(Windows Subsystem for Linux) を含むLinux環境で動かすことを想定しています。以下のコマンドで各パッケージを用意してください。

```
sudo apt install fontforge-nox fonttools wget git
pip3 install requests
```

　macOSでbrewをお使いの場合は以下に読み替えてください。

```
brew install fontforge fonttools wget git
sudo pip3 install requests
```

　ツール一式をGitHubから取得します。

```
git clone https://github.com/farszan/Nesztamoj
```

　実行します。

```
cd Chelzas
./tasks
```

　buildフォルダ内にフォントファイル、グリフリストが生成されます。グリフウィキからのSVGファイルの取得およびttfファイルの生成に合わせて数時間かかります。SVGファイルはwork/glyphフォルダ内に保存されますが、すでにファイルが存在する場合は取得しません。ネットワークエラーなどで取得に失敗した場合は、途中で止まりますので、単純にtasksを再実行してください。

　現状ではとりあえずフォントを生成するためのツギハギスクリプトとなっていますが、将来的に整備することを考えています。ライセンスはMITライセンスです。
