#!/usr/bin/env bash
# 兜町ボード: フェーズ別プロンプトを標準出力に組み立てる。
# 使い方: bash ci/build_prompt.sh <noon|wind|flash|final>
set -euo pipefail
PHASE="${1:-noon}"

# --- 共通の前置き（環境差分の指示） ---------------------------------------
cat <<'PRE'
あなたは「兜町ボード」の運用AIです。いまGitHub Actionsのランナー上で動いており、
カレントディレクトリが kabutocho-board リポジトリ（ブランチmain）としてチェックアウト済みです。

【最初に必ずやること】
1. `TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M %a'` を実行して日本時間の日付・時刻・曜日を確認する。
2. 土日、または日本の祝日（海の日など。年により変動するので日付から判断）なら「本日休場」と判断し、
   ファイルを一切変更せず、/tmp/notify.txt も作らずに、何もせず終了する。
3. 平日なら OPERATIONS.md と data/設計書_兜町ボード.md を最後まで読み、そこに書かれた
   憲法・データルート・見立てルール・4象限定義・成績表の作法に完全に従う。
   直近の data/candidates_*.json / data/results_*.json / data/yaskawa_entry_checklist.json と
   前日の archive/*.html も読んで文脈を把握する。

【この環境での上書きルール（OPERATIONS.md §4/§6の該当箇所より優先）】
- 発行・push はしない。git commit も git push もするな。PAT付きURLも使うな。
  あなたは作業ディレクトリ内のファイルを作成・更新するだけでよい。commit と push は
  この後のワークフローが GITHUB_TOKEN で自動的に行う。
- PushNotification ツールも send_later も存在しない。代わりに、そのフェーズで最も伝えるべき
  1行サマリー（いちばん確信度の高い見立て／安川(6506)の判定／今日の成績 のいずれか）を
  プレーンテキスト1行で `/tmp/notify.txt` に書き出す（改行なし・1文）。
- 自己予約はしない。今回は下記の指定フェーズの作業だけを行って終了する。
- 市況・株価・材料などのデータ収集は、あなたの WebSearch / WebFetch ツールで行う
  （OPERATIONS.md §2のデータルートに従い、鮮度検証・クロスチェックを怠らない。取れない数値は
  「概算」「未取得」と明示する＝憲法③）。
- index.html の <head> 内の manifest / apple-touch-icon 行は必ず維持する。

【今回のフェーズ】
PRE

case "$PHASE" in
  noon)
    cat <<'P'
= 昼バッチ =
- まず、前日以前に持ち越し（pending / unverified）になっている判定があれば、判定可能な分を
  今日のデータで確定させる（例：安川・ファストリの前日終値判定）。
- 市況把握 → 候補5〜7銘柄（常連13銘柄を必ずチェック＋発掘枠＋新顔🆕を2〜3枠）→ 各カードに
  材料・見立て（確信度●5段階）・アクション示唆（🟢/⏸/👀/🚫）→ 4象限に分類。該当なし象限は「なし」と明言。
- ボード最上部に「後場の作戦」3行（地合い／やる・やらない／注目筆頭）。
- 更新するファイル:
  * archive/YYYY-MM-DD.html （当日ボード。テンプレは前日archiveを踏襲。デザイン・文字サイズを維持）
  * index.html （当日ボードで上書き。<head>のmanifest/icon行は維持）
  * data/candidates_YYYYMMDD.json （当日の見立てログ）
  * data/yaskawa_entry_checklist.json （A/B/C条件を毎日判定してdaily_logに追記。3条件成立なら/tmp/notify.txtで【解除】通知）
- /tmp/notify.txt には、今日いちばん確信度の高い見立て（または安川判定）を1行で。
P
    ;;
  wind)
    cat <<'P'
= 12:15 風向き =
- 正午の先物・ドル円（株探12:00配信の市況記事、nikkei225jp.com/cme 等）を取得し、前場からの
  地合いの変化を今日のボード（index.html と当日の archive/YYYY-MM-DD.html）に「風向き」として追記する。
- 昼バッチの見立てを覆すような大きな変化があれば、後場の作戦3行を更新し、/tmp/notify.txt に1行で警告を書く。
  変化が小さければ notify.txt は作らなくてよい。
- 当日の data/candidates_YYYYMMDD.json に wind メモを追記してよい（既存の予想は消さない）。
P
    ;;
  flash)
    cat <<'P'
= 15:45 速報答え合わせ =
- 夕刊の話題株ルート（株探の話題株ピックアップ夕刊・動意株・S高S安引け一覧、関連記事リンク経由のID発見術）で、
  今日の見立てのうち判定できる分を○×判定する。判定はダブル基準（終値ベース＋後場高値+2%ベース）。
  ±0.5%はデッドバンドで引き分け。
- data/results_YYYYMMDD.json を作成/更新し、ボードに「今日の答え合わせ」と暫定成績を反映（index.html と当日archive）。
- まだ終値が取れない銘柄は pending として明示（憲法③）。
- /tmp/notify.txt には今日の速報成績（例: 本日 ○勝×敗）を1行で。
P
    ;;
  final)
    cat <<'P'
= 18:30 確定スイープ =
- 速報で保留だった銘柄の終値を確定させ、data/results_YYYYMMDD.json を確定版に更新する。
- 累計成績（勝/敗/分・確信度別較正・象限別勝率）を更新し、ボード下部の成績表に反映（index.html と当日archive）。
- どうしても終値が取れない分だけ pending として残し、「翌朝バッチで確定」と明示する。
- 金曜の場合は、週次の「見立ての癖」自己分析（強気弱気の偏り・機会損失・待ち推奨の損失回避回数）も生成してボードに載せる。
- /tmp/notify.txt には今日の確定成績と累計（例: 本日○勝×敗／累計n勝m敗）を1行で。
P
    ;;
  *)
    echo "unknown phase: $PHASE" >&2
    exit 1
    ;;
esac
