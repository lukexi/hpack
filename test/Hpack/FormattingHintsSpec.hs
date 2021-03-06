module Hpack.FormattingHintsSpec (spec) where

import           Test.Hspec

import           Hpack.FormattingHints
import           Hpack.Render

spec :: Spec
spec = do
  describe "extractFieldOrder" $ do
    it "extracts field order hints" $ do
      let input = [
              "name:           cabalize"
            , "version:        0.0.0"
            , "license:"
            , "license-file: "
            , "build-type:     Simple"
            , "cabal-version:  >= 1.10"
            ]
      extractFieldOrder input `shouldBe` [
              "name"
            , "version"
            , "license"
            , "license-file"
            , "build-type"
            , "cabal-version"
            ]

  describe "extractSectionsFieldOrder" $ do
    it "splits input into sections" $ do
      let input = [
              "name:           cabalize"
            , "version:        0.0.0"
            , ""
            , "library"
            , "  foo: 23"
            , "  bar: 42"
            , ""
            , "executable foo"
            , "  bar: 23"
            , "  baz: 42"
            ]
      extractSectionsFieldOrder input `shouldBe` [("library", ["foo", "bar"]), ("executable foo", ["bar", "baz"])]

  describe "breakLines" $ do
    it "breaks input into lines" $ do
      let input = unlines [
              "foo"
            , ""
            , "   "
            , "  bar  "
            , "  baz"
            ]
      breakLines input `shouldBe` [
              "foo"
            , "  bar"
            , "  baz"
            ]

  describe "unindent" $ do
    it "unindents" $ do
      let input = [
              "   foo"
            , "  bar"
            , "   baz"
            ]
      unindent input `shouldBe` [
              " foo"
            , "bar"
            , " baz"
            ]

  describe "sniffAlignment" $ do
    it "sniffs field alignment from given cabal file" $ do
      let input = [
              "name:           cabalize"
            , "version:        0.0.0"
            , "license:        MIT"
            , "license-file:   LICENSE"
            , "build-type:     Simple"
            , "cabal-version:  >= 1.10"
            ]
      sniffAlignment input `shouldBe` Just 16

    it "ignores fields without a value on the same line" $ do
      let input = [
              "name:           cabalize"
            , "version:        0.0.0"
            , "description: "
            , "  foo"
            , "  bar"
            ]
      sniffAlignment input `shouldBe` Just 16

  describe "splitField" $ do
    it "splits fields" $ do
      splitField "foo:   bar" `shouldBe` Just ("foo", "   bar")

    it "accepts fields names with dashes" $ do
      splitField "foo-bar: baz" `shouldBe` Just ("foo-bar", " baz")

    it "rejects fields names with spaces" $ do
      splitField "foo bar: baz" `shouldBe` Nothing

    it "rejects invalid fields" $ do
      splitField "foo bar" `shouldBe` Nothing

  describe "sniffIndentation" $ do
    it "sniff alignment from executable section" $ do
      let input = [
              "name: foo"
            , "version: 0.0.0"
            , ""
            , "executable foo"
            , "    build-depends: bar"
            ]
      sniffIndentation input `shouldBe` Just 4

    it "sniff alignment from library section" $ do
      let input = [
              "name: foo"
            , "version: 0.0.0"
            , ""
            , "library"
            , "    build-depends: bar"
            ]
      sniffIndentation input `shouldBe` Just 4

    it "ignores empty lines" $ do
      let input = [
              "executable foo"
            , ""
            , "    build-depends: bar"
            ]
      sniffIndentation input `shouldBe` Just 4

    it "ignores whitespace lines" $ do
      let input = [
              "executable foo"
            , "  "
            , "    build-depends: bar"
            ]
      sniffIndentation input `shouldBe` Just 4

  describe "sniffCommaStyle" $ do
    it "detects leading commas" $ do
      let input = [
              "executable foo"
            , "  build-depends:"
            , "      bar"
            , "    , baz"
            ]
      sniffCommaStyle input `shouldBe` Just LeadingCommas

    it "detects trailing commas" $ do
      let input = [
              "executable foo"
            , "  build-depends:"
            , "    bar,  "
            , "    baz"
            ]
      sniffCommaStyle input `shouldBe` Just TrailingCommas

    context "when detection fails" $ do
      it "returns Nothing" $ do
        sniffCommaStyle [] `shouldBe` Nothing
