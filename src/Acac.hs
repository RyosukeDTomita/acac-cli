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
import Data.Function (on)
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

-- | 提出列を JST の日ごとに集計する。
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
        [ (toJstDay (epochSecond s), Set.singleton $ formatProblemId (contestId s) (problemId s))
        | s <- acs
        ]

-- | 集計結果(1週間ぶん)を、今日(JST)から遡る7日刻みの週バケットに分ける。
-- 入力は古い順(昇順)を前提とし、古い週のグループが先(上)に来る。
splitIntoWeeks :: Day -> [(Day, [Text])] -> [[(Day, [Text])]]
splitIntoWeeks today = groupBy ((==) `on` weeksAgo)
  where
    weeksAgo (day, _) = diffDays today day `div` 7


-- | 週ごとに集計した結果を、全体で1つの box-drawing テーブル文字列にする。
-- ヘッダは先頭に1つだけ。各週は区切り線で分け、週末に AC 数合計の Total 行を置く。
-- 列幅は全週で共通(内容に合わせる)。行は \n で連結する(末尾改行なし)。
renderTable :: [[(Day, [Text])]] -> String
renderTable weeks = intercalate "\n" ([top, header] ++ concatMap weekSection weeks ++ [bottom])
  where
    rowCells (day, probs) = [showDayWithWeekday day, show (length probs), T.unpack (T.unwords probs)]
    totalCells week = ["week total", show (sum [length probs | (_, probs) <- week]), ""]
    headerCells = ["Date", "AC", "Problems"]
    allCells = headerCells : concatMap (\week -> map rowCells week ++ [totalCells week]) weeks
    widths = map (maximum . map length) (transpose allCells)
    pad w s = " " ++ s ++ replicate (w - length s) ' ' ++ " "
    renderRow xs = "│" ++ intercalate "│" (zipWith pad widths xs) ++ "│"
    border l m r = l ++ intercalate m (map (\w -> replicate (w + 2) '─') widths) ++ r
    top = border "┌" "┬" "┐"
    sep = border "├" "┼" "┤"
    bottom = border "└" "┴" "┘"
    header = renderRow headerCells
    weekSection week = sep : map (renderRow . rowCells) week ++ [sep, renderRow (totalCells week)]

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
