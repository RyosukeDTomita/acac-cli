{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wunused-imports #-}

module Acac
  ( Submission (..),
    parseArgs,
    toJstDay,
    pageSize,
    nextFromSecond,
    aggregate,
    splitIntoWeeks,
    renderTable,
  )
where

import Data.Aeson (FromJSON (parseJSON), withObject, (.:))
import Data.List (groupBy, intercalate, transpose)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time.Calendar (Day, dayOfWeek, diffDays, showGregorian)
import Data.Time.Clock (utctDay)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime)

-- | AtCoder Problems API の提出1件から表を作るために必要なフィールドを抽出したもの
data Submission = Submission
  { epochSecond :: Int,
    problemId :: Text,
    contestId :: Text,
    result :: Text
  }
  deriving (Show, Eq)

-- | AtCoder Problems API の提出JSONから必要なフィールドだけ取り出す。
-- 余分なフィールド(id,user_id,language など)は無視する。
instance FromJSON Submission where
  parseJSON =
    withObject "Submission" $ \o ->
      Submission
        <$> o .: "epoch_second"
        <*> o .: "problem_id"
        <*> o .: "contest_id"
        <*> o .: "result"

-- | コマンドライン引数からユーザ名を取り出す。
-- 引数はユーザ名1個だけを受け付け、それ以外は usage エラーを返す。
parseArgs :: [String] -> Either String Text
parseArgs [username] = Right (T.pack username)
parseArgs _args = Left "usage: acac <atcoder-username>"

-- | epoch秒(UTC基準)を JST(UTC+9) の日付に変換する。
-- AtCoder は JST 基準なので、日付の区切りも JST で行う。
-- ghci> posixSecondsToUTCTime $ fromIntegral 0
-- 1970-01-01 00:00:00 UTC
-- ghci> utctDay $ posixSecondsToUTCTime $ fromIntegral 0
-- 1970-01-01
toJstDay :: Int -> Day
toJstDay epochSecond = utctDay $ posixSecondsToUTCTime $ fromIntegral $ epochSecond + 9 * 3600

-- | APIが1リクエストで返す提出の最大件数(固定値)
pageSize :: Int
pageSize = 500

-- | 取得したバッチから次に投げる from_second を決める。
-- バッチが満杯(pageSize 件)なら続きがある可能性があるので最大 epoch+1 を返す。
-- pageSize 未満なら全件取り切ったとみなし Nothing(終了)。
nextFromSecond :: [Submission] -> Maybe Int
nextFromSecond batch
  | length batch < pageSize = Nothing
  | otherwise = Just $ maximum (map epochSecond batch) + 1

-- | 提出列をJSTの日ごとに集計する。
-- AC(result == "AC")だけを対象に、同じ問題の重複を除いた問題ラベル一覧を作る。
-- 日付は古い順(昇順)、各日の問題ラベルは昇順で返す。
aggregate :: [Submission] -> [(Day, [Text])]
aggregate submissions =
  [(day, Set.toAscList labels) | (day, labels) <- Map.toAscList grouped]
  where
    acs = filter (\s -> result s == "AC") submissions
    grouped =
      Map.fromListWith
        Set.union
        [ (toJstDay $ epochSecond s, Set.singleton $ formatProblemId (contestId s) (problemId s))
        | s <- acs
        ]

-- | 集計結果(1週間ぶん)を、今日(JST)から遡る7日刻みの週バケットに分ける。
-- 入力は古い順(昇順)を前提とし、古い週のグループが先(上)に来る。
splitIntoWeeks :: Day -> [(Day, [Text])] -> [[(Day, [Text])]]
splitIntoWeeks today xs = groupBy sameWeek xs
  where
    sameWeek :: (Day, [Text]) -> (Day, [Text]) -> Bool
    sameWeek a b = weeksAgo a == weeksAgo b
    weeksAgo :: (Day, [Text]) -> Integer
    weeksAgo (day, _) = diffDays today day `div` 7


-- | 週ごとに集計した結果を、全体で1つの box-drawing テーブル文字列にする。
-- ┌──────────────────┬────┬───────────────────────────────────────────────────┐
-- │ Date             │ AC │ Problems                                          │
-- ├──────────────────┼────┼───────────────────────────────────────────────────┤
-- │ 2026-05-26 (Tue) │ 2  │ abc081B abc290A                                   │
-- │ 2026-05-29 (Fri) │ 1  │ abc342C                                           │
-- │ 2026-05-30 (Sat) │ 6  │ abc460A abc460B abc460C abc460D awc0001A awc0001B │
-- │ 2026-05-31 (Sun) │ 1  │ abc460C                                           │
-- │ 2026-06-01 (Mon) │ 1  │ abc460D                                           │
-- ├──────────────────┼────┼───────────────────────────────────────────────────┤
-- │ week total       │ 11 │                                                   │
-- ├──────────────────┼────┼───────────────────────────────────────────────────┤
-- │ 2026-06-06 (Sat) │ 3  │ abc461A abc461B abc461C                           │
-- │ 2026-06-07 (Sun) │ 1  │ abc461C                                           │
-- │ 2026-06-08 (Mon) │ 1  │ abc144B                                           │
-- ├──────────────────┼────┼───────────────────────────────────────────────────┤
-- │ week total       │ 5  │                                                   │
-- ├──────────────────┼────┼───────────────────────────────────────────────────┤
-- │ 2026-06-09 (Tue) │ 5  │ abc106B abc120B abc122B abc136B abc150B           │
-- │ 2026-06-10 (Wed) │ 1  │ abc057C                                           │
-- │ 2026-06-11 (Thu) │ 1  │ abc095A                                           │
-- │ 2026-06-12 (Fri) │ 1  │ sumitrust2019D                                    │
-- │ 2026-06-13 (Sat) │ 3  │ abc462A abc462B abc462C                           │
-- │ 2026-06-15 (Mon) │ 5  │ APG4bA APG4bPythonA abc128C abc462B abc462D       │
-- ├──────────────────┼────┼───────────────────────────────────────────────────┤
-- │ week total       │ 16 │                                                   │
-- ├──────────────────┼────┼───────────────────────────────────────────────────┤
-- │ 2026-06-17 (Wed) │ 3  │ abc145C abc147C abc150C                           │
-- │ 2026-06-18 (Thu) │ 2  │ abc054C abc448B                                   │
-- │ 2026-06-19 (Fri) │ 5  │ abc054C abc245B abc273A abc425B awc0001B          │
-- │ 2026-06-20 (Sat) │ 6  │ abc029C abc153D abc247C abc463A abc463B abc463C   │
-- ├──────────────────┼────┼───────────────────────────────────────────────────┤
-- │ week total       │ 16 │                                                   │
-- └──────────────────┴────┴───────────────────────────────────────────────────┘
-- 列幅は全週で共通(内容に合わせる)。行は \n で連結する(末尾改行なし)。
renderTable :: [[(Day, [Text])]] -> String
-- intercalate "\n"でリストを結合しつつ、改行を入れる
renderTable weeks = intercalate "\n" $ [top, header] ++ concatMap weekSection weeks ++ [bottom]
  where
    -- (日付, ACデータ)を[日付, AC数, 問題一覧]に変換する
    rowCells :: (Day, [Text]) -> [String]
    rowCells (day, probs) = [showDayWithWeekday day, show $ length probs, T.unpack $ T.unwords probs]
    -- 週毎のAC数のデータを作成
    totalCells :: [(Day, [Text])] -> [String]
    totalCells week = ["week total", show $ sum [length probs | (_, probs) <- week], ""] -- 他の横列と数を揃えるために""で空の列を作成している。
    headerCells = ["Date", "AC", "Problems"]
    allCells = headerCells : concatMap (\week -> map rowCells week ++ [totalCells week]) weeks
    -- 表の横列の各要素ごとの長さを決める。
    widths = map (maximum . map length) $ transpose allCells
    -- widthsで定められた必要な横の長さになるまで空白で埋める。
    pad :: Int -> String -> String
    pad w s = " " ++ s ++ replicate (w - length s) ' ' ++ " "
    -- 表の横列を受取って|区切りを入れつつ、空白調整する。
    renderRow :: [String] -> String
    renderRow xs = "│" ++ intercalate "│" (zipWith pad widths xs) ++ "│"
    -- widthをもとに表の枠を作成する
    border :: String -> String -> String -> String
    border l m r = l ++ intercalate m (map (\w -> replicate (w + 2) '─') widths) ++ r
    top = border "┌" "┬" "┐"
    sep = border "├" "┼" "┤"
    bottom = border "└" "┴" "┘"
    header = renderRow headerCells
    weekSection :: [(Day, [Text])] -> [String]
    weekSection week = sep : map (renderRow . rowCells) week ++ [sep, renderRow $ totalCells week]

-- | 提出の contest_id と problem_id から表示用ラベルを作る。
-- 例: formatProblemId "abc457" "abc457_c" == "abc457C"
-- problem_id の最後の `_` 以降をサフィックスとみなし、大文字化して contest_id に連結する。
formatProblemId :: Text -> Text -> Text
formatProblemId contestId problemId = contestId <> T.toUpper suffix
  where
    suffix = T.takeWhileEnd (/= '_') problemId

-- | 日付を曜日付きの文字列にする。例: showDayWithWeekday ... == "2026-06-20 (Sat)"
showDayWithWeekday :: Day -> String
showDayWithWeekday day = showGregorian day ++ " (" ++ take 3 (show $ dayOfWeek day) ++ ")"
