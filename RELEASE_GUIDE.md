# ゲームリリース手順書

このドキュメントは、Godotで開発した「弾幕系縦シューティング」ゲームをリリースするための詳細な手順書です。

## 目次
1. [リリース前の準備](#1-リリース前の準備)
2. [エクスポート設定](#2-エクスポート設定)
3. [プラットフォーム別設定](#3-プラットフォーム別設定)
4. [実際のエクスポート手順](#4-実際のエクスポート手順)
5. [配布方法](#5-配布方法)
6. [主要な配布プラットフォーム](#6-主要な配布プラットフォーム)
7. [最適化とテスト](#7-最適化とテスト)
8. [簡単リリース手順（推奨）](#8-簡単リリース手順推奨)

---

## 1. リリース前の準備

### 1.1 プロジェクト設定の確認

Godotエディタで以下の設定を確認・調整してください：

```
プロジェクト → プロジェクト設定 → Application
```

- **config/name**: `弾幕系縦シューティング`
- **config/version**: `1.0.0`（お好みのバージョン番号）
- **config/icon**: `res://icon.svg`

### 1.2 エクスポートテンプレートのダウンロード

```
エディタメニュー → エクスポートテンプレートを管理
→ 「ダウンロードしてインストール」をクリック
```

※ 初回のみ必要。Godotのバージョンに対応したテンプレートが自動ダウンロードされます。

---

## 2. エクスポート設定

### 2.1 エクスポートプリセットの追加

```
プロジェクト → エクスポート
→ 「追加」ボタンでプラットフォームを選択
```

### 2.2 推奨プラットフォーム

このゲームに適したプラットフォーム：

1. **HTML5** - 最も簡単、ブラウザで動作
2. **Windows Desktop** - PC向け
3. **Linux** - Linux PC向け
4. **macOS** - Mac向け

---

## 3. プラットフォーム別設定

### 3.1 HTML5 (Web) 設定

**プリセット名**: HTML5

**重要な設定項目**:
- **Vram Texture Compression / For Desktop**: 有効
- **HTML / Custom HTML Shell**: デフォルトのまま
- **HTML / Head Include**: 空白のまま

**推奨設定**:
```
Export Path: index.html
Runnable: チェック
Dedicated Server: チェックなし
```

### 3.2 Windows Desktop 設定

**プリセット名**: Windows Desktop

**重要な設定項目**:
- **Binary Format / 64 bits**: 有効（64bit版推奨）
- **Binary Format / Embed PCK**: 有効
- **Application / File Description**: `弾幕系縦シューティング`
- **Application / Product Name**: `弾幕系縦シューティング`
- **Application / Company Name**: あなたの名前/チーム名

### 3.3 Linux 設定

**プリセット名**: Linux

**重要な設定項目**:
- **Binary Format / 64 bits**: 有効
- **Binary Format / Embed PCK**: 有効

### 3.4 macOS 設定

**プリセット名**: macOS

**重要な設定項目**:
- **Application / Bundle Identifier**: `com.yourname.danmaku-shooting`
- **Application / Short Version**: `1.0.0`
- **Application / Version**: `1.0.0`

---

## 4. 実際のエクスポート手順

### 4.1 基本的なエクスポート手順

1. **プロジェクト → エクスポート** を開く
2. 作成したプリセットを選択
3. **「エクスポート」ボタン**をクリック
4. 保存先フォルダを選択
5. ファイル名を入力（例：`danmaku-shooting`）
6. **「保存」**をクリック

### 4.2 各プラットフォームの出力ファイル

#### HTML5の場合
```
出力ファイル:
- index.html（メインファイル）
- index.js
- index.wasm
- index.pck
- index.png（アイコン）
```

#### Windowsの場合
```
出力ファイル:
- danmaku-shooting.exe（実行ファイル）
```

#### Linuxの場合
```
出力ファイル:
- danmaku-shooting（実行ファイル）
```

#### macOSの場合
```
出力ファイル:
- danmaku-shooting.app（アプリケーションバンドル）
```

---

## 5. 配布方法

### 5.1 ファイルの準備

#### HTML5版の配布
1. エクスポートしたすべてのファイルを1つのフォルダにまとめる
2. フォルダをZIPファイルに圧縮
3. 配布プラットフォームにアップロード

#### デスクトップ版の配布
1. 実行ファイルを確認
2. 必要に応じてZIPファイルに圧縮
3. 配布プラットフォームにアップロード

### 5.2 テスト手順

リリース前に必ずテストしてください：

```
チェックリスト:
□ ゲームが正常に起動する
□ 操作（WASD/矢印キー、スペース）が動作する
□ ゲームオーバー・リスタートが機能する
□ 音が出る（ブラウザ版は最初のクリック後）
□ 適切に終了できる
```

---

## 6. 主要な配布プラットフォーム

### 6.1 初心者向け（推奨）

#### itch.io
- **URL**: https://itch.io
- **特徴**: 無料、簡単、インディーゲーム向け
- **対応**: HTML5、Windows、macOS、Linux
- **審査**: なし
- **収益**: 任意の分配率設定可能

### 6.2 中級者向け

#### Game Jolt
- **URL**: https://gamejolt.com
- **特徴**: ゲームコミュニティ、無料ゲーム中心
- **対応**: HTML5、デスクトップ版
- **審査**: なし

#### Newgrounds
- **URL**: https://www.newgrounds.com
- **特徴**: 老舗サイト、Web版メイン
- **対応**: HTML5
- **審査**: コミュニティ評価

### 6.3 上級者向け

#### Steam
- **URL**: https://steamworks.com
- **特徴**: 商用、大きなユーザーベース
- **対応**: Windows、macOS、Linux
- **審査**: あり（Steam Direct: $100）
- **収益**: Steam 30% / 開発者 70%

---

## 7. 最適化とテスト

### 7.1 リリース前最適化

#### ファイルサイズ削減
1. **未使用アセットの削除**
   ```
   プロジェクト設定 → Resources → Filters to export non-resource files
   ```

2. **テクスチャ圧縮設定**
   ```
   各画像ファイル → Import → Compress → Mode を確認
   ```

3. **音声ファイル圧縮**
   ```
   音声ファイル → Import → Compress を有効
   ```

### 7.2 パフォーマンステスト

以下の環境でテストを推奨：

```
最小動作環境:
- CPU: 1GHz以上
- RAM: 1GB以上
- GPU: OpenGL ES 3.0対応

推奨環境:
- CPU: 2GHz以上
- RAM: 2GB以上
- 最新のブラウザ（HTML5版）
```

---

## 8. 簡単リリース手順（推奨）

初めてリリースする方向けの最も簡単な手順：

### 8.1 itch.io でのHTML5リリース

#### ステップ1: ゲームのエクスポート
1. Godotで `プロジェクト → エクスポート`
2. `HTML5` プリセットを選択
3. `エクスポート` をクリック
4. 保存先に `index.html` として保存

#### ステップ2: itch.io アカウント作成
1. https://itch.io にアクセス
2. `Register` でアカウント作成
3. メールアドレス認証を完了

#### ステップ3: 新しいプロジェクト作成
1. ダッシュボードで `Create new project` をクリック
2. 以下の情報を入力：
   ```
   Title: 弾幕系縦シューティング
   Project URL: danmaku-shooting（お好みのURL）
   Short description: レトロスタイルの弾幕シューティングゲーム
   ```

#### ステップ4: ファイルアップロード
1. `Upload files` セクションで `Choose file` をクリック
2. エクスポートしたフォルダをZIP圧縮してアップロード
3. `This file will be played in the browser` をチェック
4. `HTML` を選択

#### ステップ5: ゲーム設定
```
Classification: Games
Genre: Action
Tags: Shooting, Retro, Pixel Art, Japanese
Release status: Released
Visibility: Public
```

#### ステップ6: 公開
1. `Save & view page` をクリック
2. プレビューでゲームをテスト
3. 問題なければページを公開

### 8.2 公開後のプロモーション

#### SNSでのシェア
- Twitter/X でゲームのスクリーンショットを投稿
- ハッシュタグ: `#indiegame #gamedev #shooting #retro`

#### itch.io内でのプロモーション
- ゲームジャムに参加
- コミュニティでの交流
- 定期的なアップデート

---

## 9. トラブルシューティング

### 9.1 よくある問題と解決方法

#### HTML5版で音が出ない
**原因**: ブラウザのオートプレイ制限
**解決**: ユーザーが最初にクリックするまで音声を無効にする

#### ゲームが重い
**原因**: 最適化不足
**解決**: 
- エネミーの数を制限
- 弾丸の寿命を短くする
- テクスチャサイズを確認

#### エクスポートに失敗する
**原因**: テンプレートの不備
**解決**: エクスポートテンプレートを再ダウンロード

### 9.2 サポートリソース

- **Godot公式ドキュメント**: https://docs.godotengine.org
- **Godot Community**: https://godotengine.org/community
- **itch.io Creator Guide**: https://itch.io/docs/creators

---

## 10. まとめ

この手順書に従ってリリースすることで、あなたの弾幕シューティングゲームを多くの人に楽しんでもらえます。

**推奨フロー**:
1. HTML5版でitch.ioリリース（最も簡単）
2. フィードバックを受けて改善
3. 他のプラットフォームへの展開を検討

リリース後も継続的なアップデートとコミュニティとの交流を大切にしてください。

---

**最終更新**: 2024年6月2日
**対象Godotバージョン**: 4.2以上