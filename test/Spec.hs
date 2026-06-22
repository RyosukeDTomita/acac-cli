{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wunused-imports #-}

import Acac (Submission (..), aggregate, nextFromSecond, pageSize, parseArgs, renderTable, splitIntoWeeks, toJstDay)
import Data.Aeson (eitherDecode)
import Data.List (intercalate)
import Data.Text (Text)
import Data.Time.Calendar (fromGregorian)
import Test.Hspec

-- テスト用に Submission を組み立てるヘルパ。
mkSub :: Int -> Text -> Text -> Text -> Submission
mkSub sec problem contest res =
  Submission
    { epochSecond = sec,
      problemId = problem,
      contestId = contest,
      result = res
    }

main :: IO ()
main = hspec $ do
  describe "FromJSON Submission" $ do
    it "parses required fields and ignores extra ones" $
      eitherDecode
        "{\"id\":123,\"epoch_second\":1781650800,\"problem_id\":\"abc457_c\",\"contest_id\":\"abc457\",\"user_id\":\"foo\",\"language\":\"Haskell\",\"result\":\"AC\"}"
        `shouldBe` Right
          Submission
            { epochSecond = 1781650800,
              problemId = "abc457_c",
              contestId = "abc457",
              result = "AC"
            }

  describe "parseArgs" $ do
    it "returns the username for a single argument" $
      parseArgs ["HathawayNoa"] `shouldBe` Right "HathawayNoa"
    it "fails with a usage message when no argument is given" $
      parseArgs [] `shouldBe` Left "usage: acac <atcoder-username>"
    it "fails with a usage message when too many arguments are given" $
      parseArgs ["a", "b"] `shouldBe` Left "usage: acac <atcoder-username>"

  describe "toJstDay" $ do
    it "treats a UTC 2026-06-16 23:00 epoch as 2026-06-17 in JST" $
      toJstDay 1781650800 `shouldBe` fromGregorian 2026 6 17

  describe "nextFromSecond" $ do
    it "returns Nothing when the batch is smaller than the page size" $
      nextFromSecond [mkSub 100 "a_a" "a" "AC"] `shouldBe` Nothing
    it "returns Nothing for an empty batch" $
      nextFromSecond [] `shouldBe` Nothing
    it "returns max epoch + 1 when the batch is full (pageSize)" $
      nextFromSecond [mkSub sec "a_a" "a" "AC" | sec <- [1 .. pageSize]]
        `shouldBe` Just (pageSize + 1)

  describe "aggregate" $ do
    -- 1781650800 = JST 2026-06-17, 1781478000 = JST 2026-06-15
    let submissions =
          [ mkSub 1781650800 "abc457_c" "abc457" "AC",
            mkSub 1781650800 "abc457_d" "abc457" "AC",
            mkSub 1781650800 "abc457_c" "abc457" "AC", -- 同じ問題の重複AC
            mkSub 1781650800 "abc457_e" "abc457" "WA", -- AC でないので除外
            mkSub 1781478000 "abc456_a" "abc456" "AC"
          ]
    it "groups AC submissions by JST day, dedups problems, oldest day first" $
      aggregate submissions
        `shouldBe` [ (fromGregorian 2026 6 15, ["abc456A"]),
                     (fromGregorian 2026 6 17, ["abc457C", "abc457D"])
                   ]

  describe "splitIntoWeeks" $ do
    it "buckets days into 7-day windows counted back from today, oldest week first" $
      splitIntoWeeks
        (fromGregorian 2026 6 21)
        [ (fromGregorian 2026 6 10, ["x"]),
          (fromGregorian 2026 6 14, ["y"]),
          (fromGregorian 2026 6 17, ["z"]),
          (fromGregorian 2026 6 20, ["w"])
        ]
        `shouldBe` [ [ (fromGregorian 2026 6 10, ["x"]),
                       (fromGregorian 2026 6 14, ["y"])
                     ],
                     [ (fromGregorian 2026 6 17, ["z"]),
                       (fromGregorian 2026 6 20, ["w"])
                     ]
                   ]

  describe "renderTable" $ do
    let weeks =
          [ [(fromGregorian 2026 6 8, ["abc144B"])],
            [ (fromGregorian 2026 6 15, ["abc456A"]),
              (fromGregorian 2026 6 17, ["abc457C", "abc457D"])
            ]
          ]
        expected =
          intercalate
            "\n"
            [ "┌──────────────────┬────┬─────────────────┐",
              "│ Date             │ AC │ Problems        │",
              "├──────────────────┼────┼─────────────────┤",
              "│ 2026-06-08 (Mon) │ 1  │ abc144B         │",
              "├──────────────────┼────┼─────────────────┤",
              "│ week total       │ 1  │                 │",
              "├──────────────────┼────┼─────────────────┤",
              "│ 2026-06-15 (Mon) │ 1  │ abc456A         │",
              "│ 2026-06-17 (Wed) │ 2  │ abc457C abc457D │",
              "├──────────────────┼────┼─────────────────┤",
              "│ week total       │ 3  │                 │",
              "└──────────────────┴────┴─────────────────┘"
            ]
    it "renders one table with a single header, per-week Total, and shared column widths" $
      renderTable weeks `shouldBe` expected
