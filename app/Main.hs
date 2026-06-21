{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wunused-imports #-}

module Main (main) where

import Acac (Submission, aggregate, nextFromSecond, parseArgs, renderTable, splitIntoWeeks, toJstDay)
import Control.Concurrent (threadDelay)
import Data.Aeson (eitherDecode)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time.Clock.POSIX (getPOSIXTime)
import Network.HTTP.Simple
  ( getResponseBody,
    getResponseStatusCode,
    httpLBS,
    parseRequest,
    setRequestHeader,
  )
import System.Environment (getArgs)
import System.Exit (die)

-- 取得期間。最低 1 週間、1 アクセスで取り切れるなら最大 4 週間まで表示する。
minWindowDays :: Int
minWindowDays = 7

maxWindowDays :: Int
maxWindowDays = 28

oneDaySeconds :: Int
oneDaySeconds = 86400

-- リクエスト間の sleep。API への礼儀で 1 秒超にする。
sleepBetweenRequests :: IO ()
sleepBetweenRequests = threadDelay 1100000

main :: IO ()
main = do
  args <- getArgs
  case parseArgs args of
    Left err -> die err
    Right username -> do
      now <- round <$> getPOSIXTime
      submissions <- fetchRecent username now
      let today = toJstDay now
          weeks = splitIntoWeeks today (aggregate submissions)
      putStrLn (renderTable weeks)

-- | 直近の提出を取得する。
-- まず4週間ぶんを1リクエストで試し、満杯(=1アクセスに収まらない)なら
-- 直近1週間に絞って取り直す(最低1週間は表示する)。
fetchRecent :: Text -> Int -> IO [Submission]
fetchRecent username now = do
  batch <- fetchPage username (now - maxWindowDays * oneDaySeconds)
  case nextFromSecond batch of
    Nothing -> pure batch
    Just _ -> do
      sleepBetweenRequests
      fetchPage username (now - minWindowDays * oneDaySeconds)

-- | 1 リクエストぶんの提出を取得する。
-- Cloudflare 対策で Accept-Encoding: gzip を付ける(http-conduit が自動で解凍する)。
fetchPage :: Text -> Int -> IO [Submission]
fetchPage username fromSecond = do
  let url =
        "https://kenkoooo.com/atcoder/atcoder-api/v3/user/submissions?user="
          ++ T.unpack username
          ++ "&from_second="
          ++ show fromSecond
  request <- setRequestHeader "Accept-Encoding" ["gzip"] <$> parseRequest url
  response <- httpLBS request
  let status = getResponseStatusCode response
  if status /= 200
    then die ("API returned HTTP " ++ show status)
    else case eitherDecode (getResponseBody response) of
      Left err -> die ("failed to parse API response: " ++ err)
      Right submissions -> pure submissions
