# GitHubへのプッシュ手順

リポジトリは正常に作成されました！
URL: https://github.com/orimizu/MiniShooter-Godot

## プッシュ方法

### オプション1: 個人用アクセストークンを使用（推奨）

1. GitHubで個人用アクセストークンを作成:
   - https://github.com/settings/tokens/new にアクセス
   - "repo" スコープを選択
   - トークンを生成してコピー

2. 以下のコマンドを実行（トークンをパスワードとして使用）:
```bash
git push -u origin main
# Usernameを聞かれたら: orimizu
# Passwordを聞かれたら: 生成したトークンを貼り付け
```

### オプション2: GitHub CLIを使用

1. GitHub CLIをインストール:
```bash
# Debian/Ubuntu
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

2. 認証とプッシュ:
```bash
gh auth login
gh repo clone orimizu/MiniShooter-Godot temp_dir
cp -r .git/* temp_dir/.git/
cd temp_dir
git push -u origin main
```

### オプション3: SSHキーを使用

1. SSHキーを生成（まだない場合）:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

2. 公開鍵をGitHubに追加:
   - https://github.com/settings/keys にアクセス
   - "New SSH key"をクリック
   - `cat ~/.ssh/id_ed25519.pub` の内容を貼り付け

3. リモートURLをSSHに変更してプッシュ:
```bash
git remote set-url origin git@github.com:orimizu/MiniShooter-Godot.git
git push -u origin main
```

## 確認

プッシュが成功したら、以下のURLでリポジトリを確認できます：
https://github.com/orimizu/MiniShooter-Godot