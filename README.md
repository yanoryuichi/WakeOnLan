# WakeOnLan

Wake-on-LAN のマジックパケットを送り、RDP 接続が可能になったらトースト通知で知らせる PowerShell スクリプト。

## セットアップ
1. `config.ini.example` を `config.ini` にコピーして編集する (`config.ini` は git 管理外)。
   - セクション名 (`[MyPC1]` など) は、起動して RDP 接続したいマシンの名前にする。1 マシン = 1 セクション。
   - 最低限必要なのは次の 2 つ。
     - `Mac`: そのマシンの MAC アドレス
     - `RdpHost`: そのマシンの IP アドレスまたはホスト名 (RDP 接続できるかの確認先)
   - `RdpHost` を書くと、RDP 接続できるようになった時にトースト通知が出る。通知にはセクション名が表示される。
   - 他の項目は必要に応じて。詳細は下の「設定項目」を参照。
2. 実行する。

```
powershell -ExecutionPolicy Bypass -File WakeOnLan.ps1 -Name MyPC1
```

`-Name` は `config.ini` のセクション名。省略すると最初のセクションを使う。

## 設定項目
| キー | 必須 | 既定値 | 説明 |
|---|---|---|---|
| Mac | ○ | - | 起動するマシンの MAC アドレス (`-` または `:` 区切り) |
| Broadcast | | 255.255.255.255 | パケットの送信先 (ブロードキャストアドレス。例: `192.168.1.255`) |
| Port | | 9 | 送信先 UDP ポート |
| DisplayName | | セクション名 | 通知に表示するマシン名 (通常は不要) |
| RdpHost | ○※ | (なし) | 起動するマシン自身の IP アドレスまたはホスト名。省略すると通知なし (※通知が必要なら必須) |
| RdpPort | | 3389 | RDP ポート |
| RdpTimeoutSec | | 60 | 確認のタイムアウト秒 |

## exe 化とショートカット (任意)
`WakeOnLan.ahk` (AutoHotkey v1) を exe にすると、ショートカットをダブルクリックするだけで、指定したマシンを起動できる。
exe は 1 つだけ作り、マシンごとにショートカットを作る。

### 1. exe を作る
AutoHotkey v1 に付属の Ahk2Exe でコンパイルする。

GUI の場合: `C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe` を起動し、Source に `WakeOnLan.ahk`、Destination に `WakeOnLan.exe` を指定して Convert する。

コマンドの場合:
```
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in WakeOnLan.ahk /out WakeOnLan.exe /bin "C:\Program Files\AutoHotkey\Compiler\Unicode 64-bit.bin"
```
(アイコンを付けたい場合は `/icon xxx.ico` を追加する)

`WakeOnLan.exe` は、同じフォルダの `WakeOnLan.ps1` と `config.ini` を使う。3 つを同じフォルダに置いたままにすること。

### 2. マシンごとにショートカットを作る
exe にマシン名 (`config.ini` のセクション名) を引数で渡すショートカットを作る。例として `[MyPC1]` 用:

1. `WakeOnLan.exe` を右クリック → 「ショートカットの作成」。
2. 作ったショートカットを右クリック → 「プロパティ」→「ショートカット」タブ。
3. 「リンク先」の末尾に半角スペースとセクション名を足す。
   ```
   "H:\path\to\WakeOnLan\WakeOnLan.exe" MyPC1
   ```
4. 「作業フォルダー」が exe のあるフォルダになっていることを確認して OK。
5. ショートカット名を `WakeOnLan MyPC1` などに変える。デスクトップやタスクバーに置いてもよい (exe 自体は動かさない)。

別のマシンは、ショートカットをコピーして、リンク先の末尾のセクション名だけを変える。

`*.exe` と `*.lnk` は git 管理外。
